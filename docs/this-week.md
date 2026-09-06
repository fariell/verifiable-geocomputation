# 本周执行清单 · This Week (2026-09-06 · W1 闭环 · 实验室迁云)

> **PI 决策(10:09)**:后续所有实验只在 AutoDL 开展。本机不再跑、不再双向同步。
> 工作目录:`/root/verigis/repo`。日志:`~/.workbuddy/`。

W1 已达成:Dafny P-001 19 / P-002 24 verified 0 errors;Lean P-001 `lake build` success。

---

## 日常(只在 AutoDL)

```bash
source /etc/network_turbo
source ~/.elan/env
export PATH="/usr/local/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'bash scripts/autodl/verify_all.sh'
```

不要再跑本机 `sync_push.sh` / `results_pull.sh`。

---

## 等你拍板

1. **commit** — 云端这份仓目前没有 `.git`(当初 overlay 跳过了 clone)。若要留历史,在 AutoDL 里 `git init` 后你再说「commit」。不要把密码写进提交。
2. **防销毁** — 系统盘在销毁实例时会没。是否把仓迁到 `/root/autodl-tmp/verigis/repo`,你定。
3. **W2 选一条**(都在 AutoDL 做):
   - Lean P-002(填洼双形式化)
   - GPB-019 `run_benchmark.sh`
   - P-003 曲率(对着 corr=0.157)

---

_v0.5 · 2026-09-06 · 实验不再回本机_
