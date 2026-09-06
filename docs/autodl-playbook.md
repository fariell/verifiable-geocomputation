# AutoDL 作战手册 · Verifiable Geocomputation 云端工作流

> **决策(2026-09-06,PI)**:源码在本机 Cursor 写(上下文),实验在 AutoDL 跑。
> 改完用本机 `sync_push.sh` / `scp` overlay 到 `/root/verigis/repo`。
> **禁止只在 AutoDL 生成源码**——Cursor 挂不上上下文,会和本机分叉。
> 结果留在 `~/.workbuddy/`,不必 results_pull。
> 硬件与预算见 [`autodl-rental.md`](autodl-rental.md)。

## 〇、一句话

本机改完 overlay:

```powershell
cd "E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation"
bash scripts/autodl/sync_push.sh
```

然后 AutoDL 跑:

```bash
source /etc/network_turbo
source ~/.elan/env
export PATH="/usr/local/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'bash scripts/autodl/verify_all.sh'
```

产物读 `~/.workbuddy/summary_*.txt` 和 `~/.workbuddy/jobs/*.log`。

**销毁实例会丢系统盘。** 长活数据放到 `/root/autodl-tmp/`。仓在 `/root/autodl-tmp/verigis/repo`,`/root/verigis/repo` 为软链。

---

## 一、本机 overlay(源码同步)

`scripts/autodl/sync_push.sh` 把本机 `formal/`、`scripts/autodl/`、`experiments/phase1/*.py|*.sh` overlay 到云端。
凭据走 `autodl.env`(gitignore)+ `~/.autodl_pwd`,不进仓库。
单文件也可用本机 `scp -P <port> 本地文件 root@host:云端路径`。

`results_pull.sh` 仍不作为日常:结果留云端,贴回 chat 即可。

---

## 二、首次装机:`setup.sh`(已完成,可重入)

`scripts/autodl/setup.sh` 在 autoDL 实例里**装 Lean + Dafny + GDAL/Python + clone 本仓 + 跑冒烟**。

为何不用 `provision.sh`:那是为本地 WSL 设计的,带 `./scripts/wsl/remedy.sh` 那套本地补救逻辑。autoDL 网络好(国际出口通畅),**直接走官方路径**:
- Lean: `curl https://elan.lean-lang.org/elan-init.sh | sh`(elan 反而在云端好装)
- Dafny: `wget https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip`,自带 unzip

跑法(已在实例内,可重入):

```bash
source /etc/network_turbo
python3 /root/verigis/repo/scripts/autodl/jupyter_progress.py \
  'bash /root/verigis/repo/scripts/autodl/setup.sh'
```

实例里大约做这些事(脚本本身):
1. `apt`(已是 root 则不用 sudo)装 unzip/git/curl/gdal-bin 等
2. `source /etc/network_turbo`(GitHub 学术加速;**不开则 elan/Dafny 会 443 超时**)
3. Lean: `elan-init` → toolchain 4.18.0
4. Dafny v4.11.0(.zip → /opt/dafny)
5. Python venv + numpy/scipy(osgeo 不阻塞 W1)
6. 已有 overlay 则不 `git clone`
7. 冒烟:`dafny verify` Abs + `lake build`(可选,首次 30-60 min)

**详细输出**会写到 `~/.workbuddy/setup_<时间戳>.log`。
lean 或 dafny 没装上时脚本以 **rc=1** 退出,不要把 rc=0 当成工具链就绪。

---

## 三、日常跑批:`verify_all.sh`

`scripts/autodl/verify_all.sh` 在云端跑"今天该验的几件事":

1. **Dafny P-001**(已知 19 verified,作为锚点再验)
2. **Dafny P-002**(新命题,SMT 可能超时 → 收集 stderr)
3. **Lean P-001**:`lake build` 或单独 `lake env lean VeriGIS/HornSlope`(mathlib 已暖机后秒过)
4. **Lean P-002**:把 P-002 的 Lean 版本也跑了(完成 Lean/Dafny 双重证明)
5. **GPB-019** DEM 噪声实验入口(若 `experiments/phase1/` 里已经有 benchmark 脚本就跑)

每项跑完都把 stdout/stderr + 摘要 append 到 `~/.workbuddy/verify_<时间戳>.log`。
**关键**:脚本还把摘要写到 `~/.workbuddy/summary_<时间戳>.txt`。

跑法:

```bash
source /etc/network_turbo && source ~/.elan/env
python3 /root/verigis/repo/scripts/autodl/jupyter_progress.py \
  'bash /root/verigis/repo/scripts/autodl/verify_all.sh'
```

---

## 四、结果留在云端(不再 results_pull)

摘要:`~/.workbuddy/summary_*.txt`  
全文:`~/.workbuddy/verify_*.txt` / `setup_*.log` / `jobs/*.log`

把关键行贴回 chat 即可。不要为了归档再 scp 回 Windows。

---

## 四点五、JupyterLab 上跑长任务时的进度观察

`setup.sh` 首次装机含 Lake build 可能跑 30–60 min,在此期间 PI 不会一直
盯屏。**直接 `bash scripts/autodl/setup.sh` 在 cell 里跑**有两个坑:
1. Jupyter cell 的 stdout 默认走 ZMQ 流,长时间无输出的话 PI 看不到任何进度,
   误判"hang 住了"
2. 即便出成果,Dafny `1 verified,0 errors` 这种里程碑淹没在几百行里,扫不到

提供 `scripts/autodl/jupyter_progress.py` 解决。**setup.sh / verify_all.sh 完全
不改**,helper 通过 `subprocess.Popen + bufsize=1` 流式抓 + 注解 + 心跳。

**最简用法**(首次装机,在 JupyterLab cell):

```python
import sys
sys.path.insert(0, '/root/verigis/repo/scripts/autodl')     # 仅首次
from jupyter_progress import run_streamed

rc, log = run_streamed(
    'bash /root/verigis/repo/scripts/autodl/setup.sh',
    cwd='/root/verigis/repo',
    heartbeat_min=30,   # 默认 30 min;长任务可调到 15 或 60
)
print('DONE rc=', rc, 'log=', log)
```

**日常验**(已在 setup 跑通后):

```python
rc, log = run_streamed('bash /root/verigis/repo/scripts/autodl/verify_all.sh',
                       cwd='/root/verigis/repo')
```

**观测到的输出长这样**(截 autoDL Jupyter 实际渲染):

```
🚀  START @ 14:02:18   elapsed 0:00:00
   $  bash /root/verigis/repo/scripts/autodl/setup.sh
   log → /root/.workbuddy/jobs/20260907_140218.log
   cwd → /root/verigis/repo
   heartbeat = 30 min
────────────────────────────────────────────────────────────────────────
   14:02:19  +    0:00  AutoDL setup START @ 2026-09-07 14:02:19
   14:02:19  +    0:01  ==[1/7] apt 基础工具 ==         📍 节点 1/7 完成
   14:02:35  +    0:17    ℹ apt 完成(unzip/git/curl/wget/gdal-bin/zstd)
   14:02:36  +    0:18  ==[2/7] Lean 4.18 via elan ==   📍 节点 2/7 完成
   14:02:42  +    0:24    ✅ lean Lean (version 4.18.0, ...)
   14:02:42  +    0:24    ✅ lake 4.18.0 ...
    ⏳  心跳 @ 14:32:48  已静默 30 min;最后输出: '  ⏳  lake build 增量编译...'
   14:32:54  + 30:36  Dafny program verifier finished with 19 verified, 0 errors   ✅ VERIFY:19 verified / 0 errors
────────────────────────────────────────────────────────────────────────
✅  END @ 14:32:54  rc=0  elapsed=30:36  log=/root/.workbuddy/jobs/20260907_140218.log
```

四种信号一眼可辨:
- **`📍 节点 N/M 完成`** — 节点里程碑(setup.sh 的 `==[N/M]==` 行)
- **`✅ VERIFY: 19 verified / 0 errors`** — Dafny/Lean 验证完成
- **`⏳  心跳 @ HH:MM:SS  已静默 N min`** — 长时间无输出时的 ping,默认 30 min
- **`✅ END rc=0`** — 整任务成功;`rc≠0` 即失败

**完整 stdout 落 `~/.workbuddy/jobs/<时间戳>.log`**,事后在 AutoDL 上重读即可。

**配置经环境变量**(不开新接口):

```python
import os
os.environ['AUTODL_HEARTBEAT_MIN'] = '15'   # 心跳 15 min 一次
os.environ['AUTODL_POLL_EVERY']    = '5'    # polling 5 s 一次(默认)
```

**`%run` 用法**(不想 import):

```python
%run /root/verigis/repo/scripts/autodl/jupyter_progress.py
run_streamed('bash /root/verigis/repo/scripts/autodl/verify_all.sh',
             cwd='/root/verigis/repo')
```

`heartbeat_min=0.05` 是一次跑通的小窍门 — 让"心跳 3 秒就来一次",
能确认即使 Lake 在编译,pi 也看得到进度。

---

## 五、本地 WSL 还用得上吗?(降级规则)

迁不意味着弃。**本地 WSL 保留,但用途收窄**:
| 任务 | 主场 |
| --- | --- |
| Lean/Dafny 跑通链路 | **autoDL** ✓ |
| Lake build / mathlib 编译 | **autoDL** ✓ |
| 长实验(GPB-019 / GPB-005 / 大数据集) | **autoDL** ✓ |
| 本地 LLM 评测 32B-Q4 | autoDL(日后) |
| **小改 .dfy 后的快速 lint** | WSL(已装 dafny,改完即可验) |
| **写论文/码代码** | 本机(在 Git Bash 里) |
| **没有网时应急** | 备用 |

WSL 不再试图装"完整工具链"——**已装好的不删**(dafny 还在),
**不再追装** GDAL/Lean toolchain(那两件事的边际收益是负的)。

---

## 六、当前任务清单(谁来都按这个推)

| # | 任务 | 跑在哪 | 预估时间 | 状态 |
| --- | --- | --- | --- | --- |
| 0 | `sync_push.sh` overlay 本机源码 | 本机 → autoDL | 1 min | ✅ 日常入口(Cursor 改完就 overlay) |
| 1 | 首次 `setup.sh` | autoDL | 10–20 min | ✅ 2026-09-06 09:59 · Lean 4.18 / Dafny 4.11 |
| 2 | `lake build` 暖通 mathlib | autoDL | 30–60 min | ✅ mathlib 已暖;增量 2 秒过 |
| 3 | Dafny P-001 + P-002 | autoDL | 2 min | ✅ 19 + 24 verified, 0 errors |
| 4 | Lean P-001 `lake build` | autoDL | 1 min | ✅ 2026-09-06 10:07 success |
| 5 | Lean P-002 `PitFilling.lean` | autoDL | 增量 | ✅ 2026-09-06 10:29 lake build success |
| 6 | GPB-019 入口 | autoDL | <1 s | ✅ 2026-09-06 10:41 ENTRY PASS |
| 7 | P-003 曲率 | 本机写 → autoDL 验 | — | ✅ Dafny 12:43 · 52 verified / 0 errors; Lean 11:45; GPB-003 PASS |
| 8 | P-002-bis 2D 邻域抬升 | 本机写 → autoDL 验 | — | ✅ Dafny 12:54 · 19 verified / 0 errors; Lean 12:53 `Built VeriGIS.PitFilling2D` |
| 9 | P-004 Horn w→0 | 本机写 → autoDL 验 | — | ✅ Dafny 13:08 · 22 verified / 0 errors; Lean `Built VeriGIS.Consistency`; ALGEBRA PASS |

---

## 七、安全护栏

| 红线 | 处置 |
| --- | --- |
| 密码写进任何 .sh / .py / commit message | 严禁。`~/.autodl_pwd` 是唯一可读来源 |
| 跑超过 2 小时 GPU(¥4+) | 改无卡模式装,GPU 只在跑实际评测时开 |
| 无 git push 用例外的强行推送 | 没有。即便开了 vLLM/SGlang 模型,也走 `/root/autodl-tmp/` 不进系统盘 |
| `git push` 进 autoDL 实例仓库 | 不,实例 repo 是只读工作区,**同步用 rebase from upstream**,不要 push 走 autoDL 出网 |
| 烧钱到月初没规划 | 设消费上限 ¥300/月(账户里改,不要靠脚本监控) |

---

## 八、故障排查(快速索引)

| 现象 | 解 |
| --- | --- |
| `sshpass: command not found` | 装 sshpass(见 §一) |
| `Connection refused on port <your-autoDL-port>` | 实例已关机;进 autoDL 网页控制台 → 实例 → "开机" |
| `dafny verify` 在云端报 unzip 类错 | autoDL 镜像几乎一定有 unzip;若报缺,Setup 已带 `apt install -y unzip` |
| `lake build` 首次 30-60 min 不动 | **正常**,mathlib 大;开 `tail -f ~/.workbuddy/setup_*.log` 看进度 |
| `verification timeout` SMT | `lake build` 加 `--timeout 120` 或把 .dfy 拆 |
| 拉回的结果发现 `summary_*.txt` 空 | 查 `~/.workbuddy/verify_*.log` 原文,看哪一步 hang |

---

## 九、为什么不是本地(2026-09-06 的反思)

迁 autoDL 不是因为本地"装不上",而是因为**装这件事不该再花一晚**:

| 因素 | 本地 WSL | autoDL |
| --- | --- | --- |
| Lean toolchain 318 MB | 反复断,3 次 270M 卡 | 一次性秒下 |
| Dafny .zip 63 MB | apt-cache 0 结果,只能 ZIP | wget 30 秒 |
| GitHub release 限流 | 60 req/h | 不限 |
| mathlib 编译 | 30–60 min 卡本机 CPU | 不卡本机,可睡前开 |
| 重启/休眠对链路的影响 | Windows 重启 = 工具链可能丢 | 实例状态独立 |
| 本机 CPU 占用 | 影响写代码体验 | 零 |

唯一不能迁的是**写代码**——依然在本机 Cursor 改 `.dfy` / `.lean` / 实验脚本,
然后 `bash scripts/autodl/sync_push.sh` overlay,在 AutoDL 跑。结果读 `~/.workbuddy/`。

---

_创建日期:2026-09-06 · 主路径决策记录,洛书整理_
