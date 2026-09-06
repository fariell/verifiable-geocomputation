"""
jupyter_progress.py — AutoDL JupyterLab 上的长任务进度观察器
====================================================================

设计目标
--------
让 PI 在 AutoDL JupyterLab 上跑 `setup.sh`(10-60 min)、
`verify_all.sh`、`lake build` 这种长任务时,**不至于失联**:
  1. 流式输出每个 stdout 行,前面带 `HH:MM:SS +HH:MM:SS`,实时可读
  2. 自动识别节点信号 `==[N/M] 节名 ==`,自动追加 `📍 节点完成`
  3. 自动识别 Dafny 里程碑 `finished with X verified, Y errors`,追加 `✅ VERIFY`
  4. 若指定时间内无新输出,默认每 30 min 喷一行 `⏳ 心跳`,不让 PI 误判 hang
  5. 完整 stdout 同时落到 `~/.workbuddy/jobs/<时间戳>.log`,事后可重读
  6. Ctrl-C 或 cell 中断时,killpg 把整个进程组送 SIGTERM,不遗留孤儿

依赖
----
Python 3.10+ 标准库,无第三方包。JupyterLab 6.x / 7.x 通用。
`setup.sh` / `verify_all.sh` 配套使用,**无需修改**。

用法(在 JupyterLab cell 里)
---------------------------
>>> import sys
>>> sys.path.insert(0, '/root/verigis/repo/scripts/autodl')   # 仅一次
>>> from jupyter_progress import run_streamed
>>> rc, log = run_streamed(
...     'bash /root/verigis/repo/scripts/autodl/setup.sh',
...     cwd='/root/verigis/repo',
...     heartbeat_min=30,            # 每 30 min 无新输出就 ping 一次
... )

也可作为模块单独 import;若想"裸跑",用 `%run -i jupyter_progress.py`。
"""
from __future__ import annotations

import os
import re
import signal
import subprocess
import sys
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path

__all__ = ["run_streamed"]
__version__ = "2026-09-06"

# --------------------------------------------------------------------------
# 正则
# --------------------------------------------------------------------------
# 节点信号:`==[2/4] Dafny P-001 + P-002 ==` 或 `[1/7] apt 基础工具`
NODE_RE = re.compile(
    r"==\[\s*(\d+)\s*/\s*(\d+)\s*\][^=]*==|^\[\s*(\d+)\s*/\s*(\d+)\s*\]\s+\S+"
)
# Dafny 验证里程碑:`Dafny program verifier finished with 19 verified, 0 errors`
DAFNY_RE = re.compile(
    r"Dafny program verifier finished with (\d+) verified,\s*(\d+) errors?"
)
# Lake 编译里程碑(可选识别)
LAKE_RE = re.compile(r"lake build(?:\s+(.+?))?\s*$|Compiling\s+(\S+)")


# --------------------------------------------------------------------------
# 心跳线程
# --------------------------------------------------------------------------
class Heartbeat:
    """每 ~5 s 检查一次,若 idle 超过阈值就喷 ping。daemon=True。

    设计权衡:`check_every`(polling 周期)必须 << `interval`(触发门槛),
    否则第一次心跳要等满 interval 才出现 — 用户会觉得"卡住不动了"。

    默认 5 s polling × 30 min 门槛,意味着 idle 满 30 min 后最多 5 s 内必触发。
    """

    def __init__(
        self,
        interval_min: float = 30.0,
        check_every: float = 5.0,  # 默认稀 polling;用户可经 AUTODL_POLL_EVERY 收紧
    ):
        self.interval = max(5.0, interval_min * 60.0)  # 触发门槛至少 5 s
        self.check_every = max(1.0, check_every)        # polling 至少 1 s
        self.last_new = time.monotonic()
        self.last_line = "(尚无输出)"
        self.lock = threading.Lock()
        self.stop = threading.Event()
        self.t = threading.Thread(
            target=self._tick, daemon=True, name="autoDL-heartbeat"
        )

    def start(self) -> None:
        self.t.start()

    def tick(self, line: str) -> None:
        with self.lock:
            self.last_new = time.monotonic()
            self.last_line = line[:160]

    def shutdown(self) -> None:
        self.stop.set()

    def _tick(self) -> None:
        while not self.stop.wait(self.check_every):
            with self.lock:
                idle = time.monotonic() - self.last_new
                last = self.last_line
            if idle >= self.interval:
                self._emit(
                    f"⏳  心跳 @ {datetime.now():%H:%M:%S}  "
                    f"已静默 {int(idle // 60)} min;最后输出: {last!r}"
                )

    @staticmethod
    def _emit(msg: str) -> None:
        print("\n" + msg + "\n", flush=True)


# --------------------------------------------------------------------------
# Jupyter-friendly print:Jupyter 默认 stdout 是行缓冲,但保险起见强制 flush
# --------------------------------------------------------------------------
def _say(msg: str) -> None:
    print(msg, flush=True)


# --------------------------------------------------------------------------
# 主函数
# --------------------------------------------------------------------------
def run_streamed(
    cmd: str,
    cwd: str | None = None,
    heartbeat_min: float = 30.0,
    env_extra: dict | None = None,
    log_dir: str = "/root/.workbuddy/jobs",
    show_full_cmd: bool = True,
) -> tuple[int, str]:
    """
    长任务流式执行,带节点识别与心跳。

    参数
    ----
    cmd : str
        要运行的 shell 命令(在云端容器内执行)。常见用法:
            'bash /root/verigis/repo/scripts/autodl/setup.sh'
            'bash /root/verigis/repo/scripts/autodl/verify_all.sh'
            'cd /root/verigis/repo && lake build formal/lean4'
    cwd : str | None
        工作目录。None 表示沿用 Jupyter 当前工作目录(容器内打开 terminal 时已 cd)。
    heartbeat_min : float
        心跳间隔(分钟)。默认 30,可用 `AUTODL_HEARTBEAT_MIN=15` 环境变量覆盖。
    env_extra : dict | None
        额外环境变量(覆盖优先于 os.environ)。
    log_dir : str
        完整 stdout 落盘的目录。默认 `/root/.workbuddy/jobs/`。
    show_full_cmd : bool
        启动行是否打印完整命令。CI 上太长时关掉。

    返回
    ----
    (returncode:int, log_path:str)
        log_path 是本次执行的完整 stdout/stderr 文件路径,可重读、可 scp。
    """
    # env 覆盖
    try:
        hb_min = float(os.environ.get("AUTODL_HEARTBEAT_MIN", heartbeat_min))
    except ValueError:
        hb_min = heartbeat_min

    Path(log_dir).mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = Path(log_dir) / f"{ts}.log"

    env = os.environ.copy()
    env.setdefault("PYTHONUNBUFFERED", "1")
    env.setdefault("FORCE_COLOR", "0")
    if env_extra:
        env.update(env_extra)

    hb = Heartbeat(interval_min=hb_min)
    hb.start()

    _say("\n🚀  START @ " + datetime.now().strftime("%H:%M:%S")
         + "   elapsed 0:00:00")
    if show_full_cmd:
        _say(f"   $  {cmd}")
    _say(f"   log → {log_path}")
    _say(f"   cwd → {cwd or os.getcwd()}")
    _say(f"   heartbeat = {hb_min:g} min")
    _say("─" * 72)

    start = time.monotonic()
    rc = -1

    try:
        with open(log_path, "w", encoding="utf-8") as logf:
            try:
                proc = subprocess.Popen(
                    cmd,
                    shell=True,
                    cwd=cwd,
                    env=env,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    bufsize=1,
                    text=True,
                    start_new_session=True,  # 自成一组,便于 killpg
                )
            except FileNotFoundError as e:
                _say(f"❌  启动失败:{e}")
                return 127, str(log_path)

            try:
                for raw in proc.stdout:
                    line = raw.rstrip("\n")
                    elapsed = _fmt(time.monotonic() - start)
                    wall = datetime.now().strftime("%H:%M:%S")
                    note = _annotate(line)
                    _say(f"   {wall}  +{elapsed:>8}  {line}{note}")
                    logf.write(line + "\n")
                    logf.flush()
                    hb.tick(line)
                rc = proc.wait()
            except KeyboardInterrupt:
                _say("\n⚠️  KeyboardInterrupt — 发送 SIGTERM 到子进程组")
                _try_kill_pg(proc)
                rc = proc.wait(timeout=15)
                raise
            except Exception as e:
                _say(f"\n❌  watch 异常:{e!r} — 强杀子进程组")
                _try_kill_pg(proc)
                rc = proc.wait(timeout=15)
                raise
    finally:
        hb.shutdown()

    elapsed = _fmt(time.monotonic() - start)
    sym = "✅" if rc == 0 else "❌"
    _say("─" * 72)
    _say(
        f"{sym}  END @ {datetime.now():%H:%M:%S}  "
        f"rc={rc}  elapsed={elapsed}  log={log_path}"
    )
    _say("")
    return rc, str(log_path)


# --------------------------------------------------------------------------
# 小工具
# --------------------------------------------------------------------------
def _fmt(secs: float) -> str:
    """把秒格式化成 H:MM:SS 或 M:SS(紧凑)。"""
    s = int(secs)
    h, rem = divmod(s, 3600)
    m, ss = divmod(rem, 60)
    if h:
        return f"{h}:{m:02d}:{ss:02d}"
    return f"{m}:{ss:02d}"


def _annotate(line: str) -> str:
    """根据一行内容追加注解;返回空字符串或带前导空格的注解。"""
    m = NODE_RE.search(line)
    if m:
        # 匹配 ==[N/M]== 或 [N/M] 两种
        n = m.group(1) or m.group(3)
        total = m.group(2) or m.group(4)
        return f"   📍 节点 {n}/{total} 完成"
    m = DAFNY_RE.search(line)
    if m:
        verified, errors = int(m.group(1)), int(m.group(2))
        sym = "✅" if errors == 0 else "❌"
        return f"   {sym} VERIFY:{verified} verified / {errors} errors"
    return ""


def _try_kill_pg(proc: subprocess.Popen) -> None:
    try:
        os.killpg(proc.pid, signal.SIGTERM)
    except (ProcessLookupError, PermissionError):
        try:
            proc.terminate()
        except Exception:
            pass


# --------------------------------------------------------------------------
# 命令行入口(可选):python jupyter_progress.py 'echo hi'
# --------------------------------------------------------------------------
def _cli() -> int:
    if len(sys.argv) < 2:
        print("usage: python jupyter_progress.py <cmd...>")
        return 2
    cmd = " ".join(sys.argv[1:])
    rc, log = run_streamed(cmd)
    return rc


if __name__ == "__main__":
    sys.exit(_cli())
