# 本周执行清单 · This Week (2026-09-06 收尾)

> **源码在本机 Cursor,实验在 AutoDL。** 改完 overlay。禁止只在 AutoDL 生成源码。
> 云端工作目录:`/root/verigis/repo` → `/root/autodl-tmp/verigis/repo`(软链)。日志:`~/.workbuddy/`。

---

## 1. 时间线(本周 GPB 累计)

| 时刻 (CST) | 事件 | 闸 | 结果 |
|---|---|---|---|
| 09/05 (W1) | P-001 一阶算子 | Dafny 19/0 + lake | PASS |
| 09/05 (W1) | P-002 PitFilling | Dafny 24/0 + lake | PASS |
| 09/05 (W2) | P-002-bis 2D | Dafny 19/0 + lake `Built VeriGIS.PitFilling2D` | PASS |
| 09/05 (W2) | P-003 | Dafny 52/0 + lake `Built VeriGIS.CurvatureZT` | PASS |
| 09/06 (W3) | GPB-019 一致性 | AutoDL run_p_gp019.sh | **ENTRY: PASS**(slope_corr ≥ 0.999) |
| 09/06 (W3) | P-004 Horn 二次 | Dafny 22/0 + lake `Built VeriGIS.Consistency` | PASS |
| 09/06 (W3, 上午) | **P-005 D8 8 路** (`c829c44`) | 本机 Dafny 18/0 + lake | PASS 本机 |
| 09/06 17:38 | P-005 云端复核 | dafny 18/0 + `Build completed successfully` | **云端 PASS**(17:38 CST) |
| 09/06 17:38 | **P-006 层 A** 本机 numpy+Wolfram | 4 门控 PASS(含 P-006b 4 环反例 + wolfram pigeonhole) | PASS |
| 09/06 17:44 | P-006 manim | `figures/WatershedStencil.mp4` 191 640 B | PASS |
| 09/06 17:46 | P-006 层 A 云端 dafny | **20 verified / 0 errors** | PASS |
| 09/06 17:48 | P-006 云端 lake + run_p006 | `VeriGIS.Watershed +1` + 3 门控 PASS + wolfram SKIP | PASS |

- **GPB-014**(P-005 D8 八路核) ✓ → `formal/dafny/P005_d8.dfy` + `formal/lean4/VeriGIS/D8.lean`
- **GPB-015**(P-006 流域唯一性) ✓ → `formal/dafny/P006_watershed.dfy`(20 verified)+ `formal/lean4/VeriGIS/Watershed.lean`
- **GPB-021**(P-COMP-1 填洼 ⇒ 流域唯一) ◌ → Phase 2 第 1 条组合命题,由 INBOX-2026-09-06 17:55 后启动

---

## 2. GPB-019 累计表(2026-09-06 10:41 AutoDL,log `~/.workbuddy/jobs/20260906_104126.log`)

| dx | nx | slope_rmse | slope_r | curv_rmse | curv_r |
|---|---|---|---|---|---|
| 4.0 | 50 | 4.31e-02 | 0.999491 | 6.97e-02 | 0.6533 |
| 2.0 | 100 | 1.86e-02 | 0.999856 | 1.41e-01 | 0.3462 |
| 1.0 | 200 | 1.16e-02 | 0.999936 | 2.98e-01 | 0.1566 |
| 0.5 | 400 | 8.01e-03 | 0.999968 | 1.49e-01 | 0.9061 |

噪声(dx=1):sigma 0/1/2/5 → slope RMSE 0.012 / 0.427 / 0.936 / 2.61;曲率立刻炸到 ~8–10。

门控:slope_corr(dx=1)≥0.999;细网格 RMSE < 粗网格;曲率 corr(dx=1)<0.5(对照)。三项 PASS。
**注意**(P-003 素材,不是 GPB-019 失败):dx=0.5 时 curv_r=0.906,细网格上 naive 曲率「看起来一致」,已留 P-003 处理。

---

## 3. P-006 第 6 条 `TerminatesUnderStrictDescent` —— 留 PENDING,但已规划

`P006_README.md` 第"没证什么"段明示 — 严格下降 ⇒ 终止未机器证明,改走 P-002 填洼 ⇒ 无环的
组合命题(下条)。这条 PENDING 将由本仓 `INBOX-2026-09-06 17:55` 任务链触发,
合并入 P-COMP-1 `TerminatesUnderStrictDescent` 子引理。

---

## 4. 等你拍板 / 下一步

1. **PUSH 当前仓**(8ce0ee6 → 476afa1 → 33282c1 ...)到 GitHub:
   ```bash
   cd "E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation"
   git push origin main
   ```
   你点名"上传/自己传"我执行。

2. **Phase 2 入口**(17:55 INBOX 已武装):
   - (A) **P-COMP-1** = P-002 ∘ P-006 组合证明(`docs/phase2/PROP_CHAIN.md` 2.2 五步骨架 →
     2.4 executable spec)
   - (B) **P-006 第 6 条** `TerminatesUnderStrictDescent`(在 P-COMP-1 框架内一并证)
   两者一起是同一次 Cursor session 内的工作,Dafny+Lean 双轨,7+1 件套扩展。

3. **Phase 2 之后的路线**(已草案,未 commit):
   - 10 月:P-COMP-1 + P-COMP-2(全平面 ⇒ 流域唯一)
   - 11 月:P-COMP-3(不对称反例,叙事素材)
   - 12 月:P-COMP-4(重采样同伦)
   详见 `docs/phase2/SCOPE.md` 与 `docs/PAPER_P2_OUTLINE.md`。

---

## 5. 日常(自动化,无需问)

本机(改完源码后):
```powershell
cd "E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation"
bash scripts/autodl/sync_push.sh
```

AutoDL:
```bash
source /etc/network_turbo
source ~/.elan/env
export PATH="/usr/local/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'bash scripts/autodl/verify_all.sh'
```

---

_v2.0 · 2026-09-06 17:55 · P-005 云端 PASS ✓,P-006 五闸全绿 ✓,GPB-014/015 入累计_;
_INBOX 17:55 武装 P-COMP-1 + 第 6 条 · local commit(s) at d6bcaae/66fd312/8ce0ee6,NOT YET pushed_
