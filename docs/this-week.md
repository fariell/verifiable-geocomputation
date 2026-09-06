# 本周执行清单 · This Week (2026-09-06)

> **源码在本机 Cursor,实验在 AutoDL。** 改完 overlay。禁止只在 AutoDL 生成源码。
> 云端工作目录:`/root/verigis/repo` → `/root/autodl-tmp/verigis/repo`(软链)。日志:`~/.workbuddy/`。

W1:Dafny P-001 19 / P-002 24 verified 0 errors;Lean P-001 lake build success。
W2 Lean P-002:10:29 `Built VeriGIS.PitFilling`。
W3 GPB-019:10:41 AutoDL **ENTRY: PASS**(rc=0)。
P-003 闭环:Dafny 12:43 **52 verified / 0 errors**;Lean 11:45;GPB-003 ENTRY PASS。
P-002-bis 闭环:Dafny 12:54 **19 verified / 0 errors**;Lean 12:53 `Built VeriGIS.PitFilling2D`。
P-004 闭环:Dafny 13:08 **22 verified / 0 errors**;Lean `Built VeriGIS.Consistency`;**GPB-019 ALGEBRA ENTRY: PASS**。

---

## 日常

本机(改完源码后):

```powershell
cd "E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation"
bash scripts/autodl/sync_push.sh
```

单文件也可用 `scp -P <your-autoDL-port> 本地文件 <your-autoDL-host>:云端路径`(host/port 以 `autodl.env` 为准)。

AutoDL:

```bash
source /etc/network_turbo
source ~/.elan/env
export PATH="/usr/local/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'bash scripts/autodl/verify_all.sh'
```

---

## GPB-019(2026-09-06 10:41 AutoDL,log `~/.workbuddy/jobs/20260906_104126.log`)

| dx | nx | slope_rmse | slope_r | curv_rmse | curv_r |
|---|---|---|---|---|---|
| 4.0 | 50 | 4.31e-02 | 0.999491 | 6.97e-02 | 0.6533 |
| 2.0 | 100 | 1.86e-02 | 0.999856 | 1.41e-01 | 0.3462 |
| 1.0 | 200 | 1.16e-02 | 0.999936 | 2.98e-01 | 0.1566 |
| 0.5 | 400 | 8.01e-03 | 0.999968 | 1.49e-01 | 0.9061 |

噪声(dx=1):sigma 0/1/2/5 → slope RMSE 0.012 / 0.427 / 0.936 / 2.61;曲率立刻炸到 ~8–10。

门控:slope_corr(dx=1)≥0.999;细网格 RMSE < 粗网格;曲率 corr(dx=1)<0.5(对照)。三项 PASS。

注意:曲率对照只钉在 dx=1(复现 Phase 1 corr≈0.157)。dx=0.5 时 curv_r=0.906,细网格上 naive 曲率会开始「看起来一致」——这是 P-003 的素材,不是 GPB-019 失败。

---

## 等你拍板 / 下一步

P-004 已 0 errors + 实验 PASS。说 **commit**(含本机 `HornStencil.mp4` / `gpb004_cubic_remainder.png`)。

下一刀按路线图是 **P-005**(D8 流向确定性与闭合性,GPB-010/011)。Wolfram 余项与 Manim 仍走 `subprocess`。

---

_v1.4 · 2026-09-06 · P-004 Dafny 22/0 + Lean + ALGEBRA PASS_
