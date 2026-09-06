# CURSOR_INBOX — 洛书 → Cursor 指令信箱

> 这是洛书与 Cursor 的**直连通道**,取代人工中转。洛书把指令写在这里(STATUS=PENDING),
> Cursor 读它执行,把结果写回 `docs/CURSOR_OUTBOX.md`,再把本文件 STATUS 改成 DONE。
> 任何人都不需要复制粘贴这段文字。

---

## §A · 当前活跃任务(读这个)

STATUS: PENDING
UPDATED: 2026-09-06 19:42
TASK: **task9** · 多分辨率迁移 (5×5 5m → 256² 5m → 30m SRTM → LiDAR 点云)

### A.0 主任务链(必跑)

```
task7.5 = AutoDL cloud settle P-COMP-1 + P-006 T6 (5 闸)
    ↓
    (云端响应间隙 5-15 min 内起草 task8A 的非 verify 文件)
    ↓
task8A = P-COMP-3 反例素材 (本机完整闸)
```

### A.1 task7.5 · 5 闸云端复核(主任务先)

```bash
source /etc/network_turbo
source ~/.elan/env
export PATH="/usr/local/bin:/opt/dafny:$HOME/.elan/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/PCOMP_1.dfy'
python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P006_terminate_under_strict.dfy'
cd formal/lean4 && lake build
cd /root/verigis/repo
bash experiments/phase2/run_p_comp_1.sh
```

OUTBOX 段名:**## P-COMP-1 + T6 云端复核(task7.5)**,续 task7 段之后。5 闸每闸按 CURSOR_LOOP §三 格式(`[task] / [step] / [cmd] / [rc] / [key lines] / [gates] / [verdict] / [blocker]`)。

#### task7.5 严令
- **不重写代码**(task7 已 commit 2fe6a3a,本次只复核)
- **不动 README / PROP_CHAIN / this-week / MEMORY**
- **不 git push**(PI 17:21 stop 还在)
- 真值从 `autoDL登录信息.txt` 读,绝不下地
- 完成后:
  - INBOX `STATUS: DONE`(本节 §A),UPDATED 改 current ts
  - 改 P006_README.md「没证什么」段第 6 条 `VERIFY PENDING →` 云端 verdict
  - 末尾总结:`task7.5 verdict = PASS / FAIL / BLOCKED`

### A.2 task7.5 间隙(task7.5 跑的时候起草 task8A 模型,不做 verify)

在 5-15 分钟云端 verify 等待期间,**起草 task8A 的非验证文件**(代码骨架,wolfram 穷举,dafny/lean 头注释 + lemma 框架,manim 动画骨架)。**不执行**任何 verify / lake build / run_*.sh。理由:任务期间只能 1 个 Bash 会话,verdict 期间留 CPU 给云端 verify。

task8A 起草文件清单(写到对应路径即可,verify 留给 task7.5 收尾后):

| 路径 | 内容 |
|---|---|
| `experiments/phase2/p_comp_3.py` | 数值对比 ZT 曲率 vs Horn 拟合斜率的 2 反例 |
| `experiments/phase2/p_comp_3.wl` | 穷举小格网,ZT 与 Horn 输出差异实例 |
| `experiments/phase2/p_comp_3_README.md` | 反例叙事(§"没证什么"开篇)<br>任务 8A 的目标/边界/产物清单 |
| `formal/dafny/PCOMP_3.dfy` | 反例 witness 占位 + lemma 框架(留 TODO 字段)|
| `formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean` | 反例 witness 占位(留 TODO) |

### A.3 task8A · P-COMP-3 反例素材(主任务二,本机完整闸)

**命题(PROP_CHAIN.md §3):**
> P-003 ZT 剖面曲率(基于张量)与 P-004 Horn 二次(单方向拟合)不是同一函数族;
> 二者无可形式化的互推关系 **— 这是命题 P-COMP-3 的否定式,作为"组合命题的边界案例"入库**。

#### 7 件套

| # | 路径 | 类型 | 要点 |
|---|---|---|---|
| 1 | `experiments/phase2/p_comp_3.py` | driver | 2 反例场景 + ZT vs Horn 数值对比图 + 1 致 P-001(slope≥0)的反向约束 demo |
| 2 | `experiments/phase2/p_comp_3.wl` | Wolfram | 穷举 4^k 格网(同 P-COMP-1)找 ZT 与 Horn 输出差异的最小实例 |
| 3 | `experiments/phase2/p_comp_3_manim.py` | manim | 左:ZT 曲率热图;右:Horn 拟合曲面;并排箭头标"不可互推" |
| 4 | `experiments/phase2/run_p_comp_3.sh` | shell | `GPB-023 ENTRY: NEGATIVE-RESULT PASS` 收尾(NEGATIVE 不是 FAIL)|
| 5 | `formal/dafny/PCOMP_3.dfy` | Dafny | include P-003 + P-004;`NonEntailed : Witness` 类型;`negResult` 引理(找反例 instance)|
| 6 | `formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean` | Lean | 同 Dafny 独立重述;`Examples : zt ≠ horn` |
| 7 | `formal/dafny/PCOMP_3_README.md` | 台账 | 关键:**"它不是 bug,是 feature — 展示了组合命题的边界"** |

#### Python driver 三门控(本机跑)

```
[PASS] zt_curv_signedmax vs horn_d2_compress on grid-A  (ZT 1.41e-2, Horn 0.21)
[PASS] zt_curv_signedmax vs horn_d2_compress on grid-B  (ZT 6.97e-2, Horn 0.07)
[PASS] gemetric_persistence:both-sides drop to 0 along stream direction
GPB-023 ENTRY: NEGATIVE-RESULT PASS
```

门控解释:
- 同一组高程上,Zernike-Torrance 曲率与 Horn 二次精度差异显著 → 反例成立
- 二者都能消出"几何上"稳定的梯度结构 → 不是个别坏数据导致

#### 严令(同 task7.5 习惯)
- 不复制 P-003/P-004 核:`include` / `import` 不写,只引用
- 不动 README / PROP_CHAIN / this-week / MEMORY
- 不 git push
- OUTBOX 续写在 "## P-COMP-1 + T6 云端复核(task7.5)"段之后,改名 "## P-COMP-3 反例素材(task8A)"
- 完成后:
  - INBOX STATUS=DONE, UPDATED 改 current ts
  - 末尾总结:`task8A verdict = PASS / FAIL / BLOCKED`
  - git commit `feat(phase2): P-COMP-3 反例素材(NEGATIVE-RESULT PASS)`

### A.4 完成汇报格式(继承 CURSOR_LOOP §三)

```
[task]      task7.5 / task8A
[step]      <本步名>
[cmd]       <实际命令>
[rc]        <退出码>
[key lines] <7 行以内关键输出>
[gates]     <本步验证门>
[verdict]   PASS / FAIL / BLOCKED
[blocker]   <仅 FAIL/BLOCKED 时填>
```

### A.5 别忘了
- 本机 `python3 scripts/autodl/jupyter_progress.py '...'` 自动捕获 elapsed 与 log
- 云端缺 wolfram 时直接 SKIP,不报错

### A.6 task9 · 多分辨率迁移(主任务三,本机 + AutoDL 双端)

> **范围**:从 `plane-5m` 5×5 扩到 `terrain-A` 256² → `SRTM-30m` 3601² → LiDAR 点云降采样栅格。
> 目标:**同一算法 + 同一形式化**在 4 套 DEM 上全部 PASS,从而支撑 v1.4 / 顶级期刊(TGIS / JGSA)。
> **不阻塞 SciDA 投稿**(2026-11-15)— paper v_final 仍按 v1.3 NUM 走。

#### 任务清单(逐项给阶段)

```
阶段 1 (本机, ~30 min)                          验证多分辨率 metrics 一致性
  ├── 输入准备:
  │   ├── plane-5m      : 5×5, 5m    (已有, 测试基线)
  │   ├── terrain-A     : 256², 5m   (experiments/phase1/results 已存在, 复用)
  │   ├── SRTM-30m      : 3601², 30m (需 download from USGS, 已有 N32E110 tile?)
  │   └── LiDAR-downsampled : 从 USGS TNM 或 自采, 1m → 256²  (新)
  │       (如 LiDAR 缺, 用 256² 5m × 3 套 OK 即可)
  ├── 对每套:
  │   ├── bash experiments/phase2/run_p_comp_1.sh
  │   ├── 4 门控 metric + 出口计数 + 长程
  │   └── 写 results/gpb024_PLANE / gpb024_TERRAIN_A / gpb024_SRTM_30M /
  │          results/gpb024_LIDAR / metrics.json

阶段 2 (AutoDL, ~15 min, 等 P-COMP-1 + T6 重 verify)
  ├── python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/PCOMP_1.dfy'
  ├── python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P006_terminate_under_strict.dfy'
  └── cd formal/lean4 && lake build
      ├── 期望:PCOMP_1 17/0 + T6 12/0 + lake 2760 modules 0 errors
      └── 形式化证明**不依赖网格尺寸**,所以预期可直接过;
          如果挂,先看 SMT timeout, --timeout 200 加跑

阶段 3 (本机, ~10 min)                          Wolfram 多分辨率穷举
  ├── 对每套 DEM 的粗化版 (256² → 8², 3601² → 16²),跑 p_comp_*.wl
  └── 输出 pigeonholeAll + descentAllFix + ringHasFixedPoint 三判(应保持 True/True/False)

阶段 4 (本机, ~15 min)                          manim 多分辨率对比
  ├── 对每套 DEM 渲染 FillThenWatershedMultiresStencil.mp4
  │   4 子图:plane-5m / terrain-A / SRTM-30m / LiDAR-down
  └── experiments/phase2/figures/MultiresFillThenWatershed.mp4

阶段 5 (~30 min)                                 README + 表
  ├── formal/dafny/PCOMP_1_MULTIRES_README.md (dafny readme, 解释形式化与分辨率无关)
  ├── docs/phase2/MULTIRES_TABLE.md (3-4 列: DEM / n_pit / n_term / uniq_out / longest / verd)
  ├── v1.3 NUM SUPP 写"任务 9 v1.4 row" 占位 (我后面补)
  └── this-week.md 加 task9 row (我后面补)
```

#### 验收标准(全部 PASS = task9 verdict=PASS)

| 闸 | 期待 | 备注 |
|---|---|---|
| 4 门控 PASS(每套 DEM) | 全 4 PASS | 形式化同算法,预期不变 |
| dafny PCOMP_1.dfy | 17/0 verify | 同 task7.5 数 |
| dafny P006_terminate_under_strict.dfy | 12/0 verify | 同 task7.5 数 |
| lake build | 2760 modules / 0 errors | 增量秒过 |
| wolfram 多分辨率 | pigeon=True descent=True fixed=False | 不依赖分辨率 |
| manim | 4 子图 mp4 渲染 | 166+ KB 套 |
| README / MULTIRES_TABLE | commit 上 | 给 v1.4 升级 |

#### 任务边界(严禁)

- **不重写代码**:形式化 P-COMP-1 / P006_T6 已 commit,不动
- **不复制 phase1 gpb001-015 metrics**:只看是否一致
- **不动** `docs/PAPER_P2_OUTLINE.md` / `PAPER_P2_v1.1_SUPP.md` / `PAPER_P2_v1.3_NUM.md`(洛书自管)
- **不动** `docs/this-week.md` / `MEMORY.md`(洛书投完顺手补 task9 row)
- **不 git push**(PI 18:22 push gate 永久)
- **新真值从 `autoDL登录信息.txt` 读**,绝不下地

#### 完成时

- INBOX §A STATUS=DONE + UPDATED 改 current ts
- 末尾总结:`task9 verdict = PASS / FAIL / BLOCKED`
- git commit `feat(phase2): task9 多分辨率迁移 PASS (<expected metrics>)`(local only)
- OUTBOX 新增一段 `## 多分辨率迁移(task9)`

---

## §B · 协议与档案(只读)

### B.1 优先级与新情况
- 17:21 PI 停 git 远端操作 → 本地 commit 仅本地不 push,实验完一次性上传
- 17:24 PI 轮换 autoDL SSH 密码 → 新真值存 `autoDL登录信息.txt`(.gitignored,行 77)
- 18:13 PI 提醒 Cursor 完工失声 → 已装 user-level sentinel skill
- 18:18 PI 让"下一步干活" → task7.5(task7.5 已是 PENDING)+ task8A(P-COMP-3 反例)**并行链**
- **18:22 PI 升级 push gate:** **实验完成 + 论文发出之前,任何 commit 不 push 到 GitHub**。
  这是 17:21 决定的强化版 —— 原"本机 commit 不 push"现在是"一切 commit 不 push,直到论文终稿定型"。
  论文 → 实验 → 公众号文章 → arXiv preprint → 期刊投稿 → 接收后才一次性同步 GitHub。
  Cursor 由此可以毫无顾忌地调源码、不用在 push 上踩刹车。
- **目标优先级(18:22 重申):** 尽快完成实验 → 写论文 → 发论文
  - 实验: P-001..P-006 / P-COMP-1..N / P-005..P-006 T6 云端复核(当前 task7.5 + task8A)
  - 论文: docs/PAPER_P2_OUTLINE.md v1.0+(洛书自管)+ 实验部分由 Cursor 提供原始数据
- **不要把新密码写进仓库、脚本、OUTBOX 回传**

### B.2 任务历史(只读,以后每完成一段归档到这里)
- **task6(2026-09-06 17:38-17:48,STATUS=CLOSED)** = P-005 云端复核 + P-006 流域唯一
- **task7(2026-09-06 18:08-18:10,STATUS=CLOSED LOCAL)** = P-COMP-1 + 第 6 条 本机段
- **task7.5(2026-09-06 18:15-18:30,STATUS=CLOSED LOCAL+云端)** = P-COMP-1 + T6 形式化云端复核
- **task8A(2026-09-06 18:20-18:42,STATUS=CLOSED)** = P-COMP-3 反例素材 (NEGATIVE-RESULT PASS)
- **task9(2026-09-06 19:42-PENDING,STATUS=ACTIVE)** = 多分辨率迁移 5×5 → 256² → 3601² → LiDAR

### B.3 触发器(`.cursorrules` `[mailbox]` 规则契约)
- Cursor session 启动时自动 `Read` 本文件
- STATUS=PENDING → 执行 §A
- STATUS=DONE/CLOSED → 不动
- 改本文件只能由洛书(Cursor 不改 INBOX 优先级/约束/直终态)
