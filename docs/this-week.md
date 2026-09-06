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

## 4. 实验-论文双轨(18:22 起)

**PI 18:22 决定:** **任何 commit 不 push 到 GitHub,直到论文终稿定型 + 投稿**。
目标优先级:尽快完成实验 → 写论文 → 发论文。"GitHub 同步" 在投稿后再说,期间完全离线。

**双轨轴:**

### A 轴 · 实验(以 Cursor + AutoDL 为主)

| 已过 | 待跑 |
|---|---|
| P-001 / P-002 / P-002-bis / P-003 / P-004 / P-005 / P-006 (本机+云端全 PASS) | **task7.5** P-COMP-1 + T6 5 闸云端复核(INBOX §A PENDING)|
| GPB-019 数值基准 | **task8A** P-COMP-3 反例素材(77e436d INBOX §A 串联) |
| P-COMP-1 本机 4 门控 PASS + manim mp4 | Phase 2.1 月: P-COMP-2(全平面) |
| T6 P-COMP-1 (iii) 替代支撑 | Phase 2.2 月: P-COMP-4(重采样同伦) |
| | Phase 2.3 月: P-COMP-5(元一致) |

### B 轴 · 论文(以洛书为主,Cursor 仅供原始数据/figure)

- **`docs/PAPER_P2_OUTLINE.md` v1.0 已写**(18:25,334 行中文,15 节真实草稿,§3 abstract 248 词)
- 投稿目标:Scientific Data 2026-11-15
- 节奏:v1.0(draft)→ v1.1(扩 §7/§8 数据)→ v1.2(扩 §9 discussion "So what?")→ arXiv/EarthArXiv 挂 → 投稿
- 该轴每次更新在该文件加 §B 版本史一行

### Push gate(永久)

```
本仓库 commit chain(本地):
  bd48901 → 77e436d → 2fe6a3a → e0b0001 → 8ce0ee6 → d6bcaae → 66fd312 → 476afa1 → 33282c1 → 8a8194d ...

不在下列情况下 push:
  - 论文发表/Scientific Data 接收(投后)(候补 §A.2 一句话)
  - 期刊编辑 + 作者决议同等同意 fork 公开(无内部数据未脱敏)

GIANT CAVEAT: 任何 GitHub fork / 缓存 / archive(GitHub Archive、SHM
缓存、Zenodo .workbuddy 备份等)已被 17:21/18:22 强化推 gate 圈定;
凭据轮换 + 历史过滤(filter-repo 端到端 0 命中)。详情:
docs/security-rotation-log.md (待补)。
```

### 等你拍板(谁都不应卡,洛书自决)

- 双轴推进节奏(快/慢/直线/折返)
- Phase 2.1 是否需要在 9 月提前跑到 P-COMP-2 闭环,还是放到 10 月
- 论文 v1.1 何时 commit(默认每个增量大到 v0.1 升就 commit,不卡日报)
- 投稿目标(默认 Scientific Data,可考虑 Computers & Geosciences / ISPRS J. Photogramm. Remote Sens. 备选)

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
