# CURSOR_INBOX — 洛书 → Cursor 指令信箱

> 这是洛书与 Cursor 的**直连通道**,取代人工中转。洛书把指令写在这里(STATUS=PENDING),
> Cursor 读它执行,把结果写回 `docs/CURSOR_OUTBOX.md`,再把本文件 STATUS 改成 DONE。
> 任何人都不需要复制粘贴这段文字。

---

## §A · 当前活跃任务(读这个)

STATUS: W3/BLOCKED-PI
UPDATED: 2026-09-09 14:06
TASK: **task16-W3 · L1 主实验**(等 PI 解阻后重跑 `--require-live`)
      W3.5 双线已完成:7/8 端点网络可达;推荐 siliconflow/deepseek 但缺匹配 key;
      Anthropic 有 `ANTHROPIC_AUTH_TOKEN` 仍 HTTP 403。见 OUTBOX W3.5 + API_REACHABILITY.md。
      PI 三选一:(a) SILICONFLOW/DEEPSEEK/DASHSCOPE key (b) HTTPS_PROXY (c) OpenRouter/改模型决定

> **🚀 2026-09-09 01:50 自动化升级(PI 01:43 拍板)**:不再需要 PI 每次手写 "go"。
> 本机已部署 **INBOX watcher + Cursor headless CLI(`agent -p --force`)**:
> INBOX 的 STATUS 只要是非 DONE 状态,watcher 自动调起 Cursor 执行本文件 §A 的任务,
> 执行日志落 `_autorun/logs/`,Cursor 写 OUTBOX 自报 + commit。
> **你的唯一职责**:做完一段 → 把 §A 的 STATUS 改成下一段的 `PENDING`(见 §A.11.6 自推进链),
> watcher 会自动接上下一段。全程 PI 零点击。

> **19:49 秘书默契生效**(PI 决定):Workbuddy token 预算紧,改 pure-secretary 模式 —
> 不再写 paper / 改代码 / 跑实验,只负责 dispatch + monitor + 反馈。
> 写论文 + 跑实验 + commit code 全归 Cursor (Pro 会员)。Workbuddy 读本 INBOX 后派
> 任务给 Cursor,Cursor 写 OUTBOX 自报,Workbuddy 监督 push gate 与 token 节流。
>
> **20:39 PI 二次拍板**(本次):"先把 task10.5 至 task14 做完,先不考虑上传 github,
> 等最终确定文章最终形态了再上传" → push gate 升级到 **FINAL-FORM 触发**:
> SciDA 投稿/期刊接收/公开 **任一** + paper v_final 形态锁 **同时** = push 1 次解锁。
> 仅"任务完成"不再 = push 触发;**全部 paper 形态定稿 + 提交动作** 才解锁。

### A.0 主任务链(单任务,但含 3 子段,可由 Cursor 并发处理)

```
┌─ task10 (SciDA 投稿冲刺) ────────────────────────────────────────┐
│  段 A · cover letter (papers/P2/cover_letter.md)              │
│       写给 SciDA Editor-in-Chief,2-3 页,highlight 5 novel:    │
│       (i)  GeoProofBench benchmark suite                       │
│       (ii) Dafny + Lean 双轨形式化机器证明                       │
│       (iii) 反例 as feature (P-006b 4-ring + ZT vs Horn)        │
│       (iv) conditional theorem 边界                              │
│       (v)  数据集 + reference impl 一站                            │
│  段 B · Zenodo deposit (~500 MB)                              │
│       上传 phase1+phase2 results / formal/*.dfy+lean /         │
│       benchmark/ / figures/*.mp4 → 申请 DOI,链接挂进 §A.5       │
│  段 C · proofread R2                                           │
│       通读 papers/P2/manuscript.md (~1219 行),                  │
│       - 引用统一 v_final.§X(去掉 v1.x §X 残留)                │
│       - §9.2 不留 PENDING(全部云端 PASS,见 v1.3 NUM + task9)   │
│       - 末行签 v1.4 (含 v1.3 NUM + task9 evidence)             │
│       - 5 处引用一致性 (Data availability / Code availability) │
└────────────────────────────────────────────────────────────────────┘
秘书只看:cover_letter.md + Zenodo DOI + commit hash + push gate
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

### A.7 task9.5 · paper v_final 整合(全归 Cursor)

> 19:49 PI 重定义角色:Workbuddy token 紧,写论文全归 Cursor (Pro 会员)。
> Workbuddy 只 dispatch + monitor。本任务 Cursor 接手,Workbuddy 不下场。

#### 整合目标

把 v1.0 + v1.1 SUPP + v1.3 NUM 三份 outline **合并为 single** `papers/P2-geoproofbench/manuscript.md`(或 `.tex`,推荐 md) — 这是 SciDA 投稿唯一稿件。

#### 三源模板

| 源 | 行数 | 处理 |
|---|---|---|
| `docs/PAPER_P2_OUTLINE.md`(v1.0) | 469 | 主体 §1-§6,§7 (原版骨架),§9.2 limitations,§A.1 intro |
| `docs/PAPER_P2_v1.1_SUPP.md` | 368 | §7.5 worked example 骨架,§8.5 反例库,§9.4 honest pending,§A.5 行数表 |
| `docs/PAPER_P2_v1.3_NUM.md` | 176 | §7.5.4 实测数值,§A.6 profiling,§B.3 整合路径说明 |

#### 操作清单(Cursor 执行)

```
1. 创建 papers/P2-geoproofbench/ 目录(mkdir)
2. 拷贝 v1.0 全文件 → papers/P2-geoproofbench/manuscript.md(初稿)
3. 段对齐 v1.0 §7.3 → 用 v1.1 §7.5.1-7.5.2 + v1.3 §7.5.4 替换
   (保留 v1.0 命题陈述,加 v1.1 接口面 + v1.3 实测数据)
4. 段对齐 v1.0 §8.4 → 用 v1.1 §8.5 (反例库)替换
5. 段对齐 v1.0 §9.2 → 用 v1.1 §9.4 (honest pending)+ v1.3 §A.6 (profiling)
6. figures:experiments/phase*/figures/*.mp4 → papers/P2-geoproofbench/figures/
7. proofread 第 1 轮:
   - 引用 §7.5.4 时须配套 v_final §7.3(不再写 illustrative 数字)
   - §9.2 不留 PENDING,task9.5 已闭环可改 "已云端 PASS"
   - 末行签处改 v_final.version = v1.4 (含 v1.3 NUM + task9 evidence)
```

#### 期望产出

- `papers/P2-geoproofbench/manuscript.md` ~1219 行 ≈ SciDA 8-10 页
- 引用统一指向 v_final.§X
- 5 处"v1.x 引用" 全部升级为 v_final.§X
- 末行签 `version: v1.4 (incl. v1.3 NUM + task9 evidence)  2026-09-XX`

#### Workbuddy 不下场铁律(本任务期间)

- Workbuddy **不**写、改、删任何 manuscript.md 行
- Workbuddy **不**做 proofread
- Workbuddy 只验:
  1. `papers/P2-geoproofbench/manuscript.md` 文件存在
  2. 长度 ≈ 1219 ± 50 行
  3. commit hash 进日志
  4. push gate 守住(local only)
- 错误反馈到 OUTBOX 第 4 段 (`## paper v_final 整合(task9.5)`)
  Cursor 看到后再修;Workbuddy 不直接动文件

#### 完成后

- INBOX §A STATUS=DONE + UPDATED 改 current ts
- 末尾 verdict:pass = manuscript.md 存在 + 长 1219 ± 50 行
- git commit `docs(manuscript): v_final 整合 (v1.0+v1.1+v1.3 → papers/P2/manuscript.md)` (local only)
- OUTBOX 新增一段 `## paper v_final 整合(task9.5)`

### A.8 task10 · SciDA 投稿冲刺(本机段,主任务)

> 目标:Scientific Data 2026-11-15 投稿窗口。3 子段并发,由 Cursor 处理,
> Workbuddy 不下场(token 节流)。

#### 段 A:cover letter(papers/P2/cover_letter.md)

```
致:Scientific Data Editor-in-Chief
```

结构:
- 第 1 段:研究意义(空间计算结果是否可机器证明 / benchmark / dataset 作为 reference software)
- 第 2 段:novel contribution(5 项,与 §A.0 一致)
- 第 3 段:数据描述(6 算子 + 3 组合 + 4 反例 + 5 noise + 4 套 DEM 全栈)
- 第 4 段:验证方法(Dafny + Lean 双闸 / 17 verified / 12 verified / 2760 modules / 0 errors)
- 第 5 段:数据可获得性(Zenodo DOI + GitHub 公开仓库 repo URL,公开时机 = 接收后一次性公开)
- 第 6 段:作者贡献说明(以 AUTHOR.md 为准)
- 第 7 段:funding / 利益冲突 / ethics declaration

字数:~800-1000 词。

#### 段 B:Zenodo deposit

Zenodo 上传清单(估重):
```
experiments/phase1/results/        — gpb003..006 + phase1_metrics.json  ~30 MB
experiments/phase2/results/        — gpb021/023 + task9 多分辨率 metrics  ~50 MB
formal/dafny/*.dfy                 — 7 文件, ~80 KB
formal/lean4/**/*.lean             — 10+ 文件, ~50 KB + lake 构建缓存  ~200 MB
benchmark/                         — GeoProofBench v0.1, ~50 MB
experiments/phase1/figures/*.mp4   — 4 mp4, ~600 KB
experiments/phase2/figures/*.mp4   — 2 mp4 (含 MultiresFillThenWatershed.mp4 task9 新)
experiments/phase1/results/*.csv   — geoproofbench_v0.1_batch1, ~5 MB
papers/P2/manuscript.md            — ~120 KB
papers/P2/figures/                 — 含 task9 manim, ~600 KB
─────────────────────────────────────────────────────────────
估算总大小:~330-380 MB,峰值 ~500 MB(带 lake 缓存)
```

DOI 申请:
```
访问 https://zenodo.org/deposit/new
填表:
- upload type = "dataset" + "software"
- title = "GeoProofBench v0.1: a verified spatial-computation benchmark suite for terrain algorithms"
- author = "Yinggang Guo" (其他作者见 AUTHOR.md)
- description = 见 papers/P2/manuscript.md §Abstract (v_final.§3)
- keywords = "spatial computation, formal verification, DEM, GeoProofBench"
- license = CC-BY-4.0 (data) + MIT (code)
- related identifier = GitHub repo 待 push 后填
```

**生成 DOI 后**:
- 把 DOI 链接(如 `https://doi.org/10.5281/zenodo.XXXXXXX`)挂到 `papers/P2/manuscript.md` §A.5 (Data availability)
- 把 DOI 链接也写到 cover letter §5

#### 段 C:proofread R2 第二轮

```
目标文件:papers/P2/manuscript.md (~1219 行)
校验项:
1. 引用统一
   - 所有 "v1.0 §X" / "v1.1 §X" / "v1.3 §X" → "v_final §X" 
2. §9.2 limitations
   - 不留 PENDING(全部云端 PASS,见 v1.3 NUM + task9 evidence)
   - 末行签 v1.4 (含 v1.3 NUM + task9 4-DEM evidence)
3. 5 处引用一致性
   - Author name (Yinggang Guo / 郭迎钢)
   - ORCID (0000-0002-8207-9941)
   - Affiliation (Northwest Institute of Nuclear Technology, Xi'an 710024)
   - Email (fariel_gyg@163.com)
   - License (CC-BY-4.0 data + MIT code)
4. 双盲审准备
   - §Acknowledgements 留空(或写 "Removed for review")
   - 不要在 §A.1 提及 PI 名字以外的私有信息
5. 通读错别字 / 标点 / 中英混排一致性
```

#### 验收标准(task10 verdict)

| 段 | 文件 | 期望 |
|---|---|---|
| 段 A | papers/P2/cover_letter.md | ~800-1000 词,7 段结构完整 |
| 段 B | Zenodo deposit + DOI | DOI 链接挂进 manuscript §A.5 + cover letter §5 |
| 段 C | papers/P2/manuscript.md | 引用统一 / 末行签 v1.4 / 5 处一致性 PASS |

#### 严令(secretary-protocol)

- **Workbuddy 不下场**:不写 cover letter / 不上传 Zenodo / 不改 manuscript 行
- **Workbuddy 只验**:
  1. `papers/P2/cover_letter.md` 存在 + 长度 800-1000 词
  2. Zenodo DOI 链接挂进 manuscript §A.5
  3. manuscript 末行签 = `v1.4`
  4. commit hash (建议 3 commit,段 A/B/C 各 1)
- **不 git push**(PI 18:22 push gate 永久,SciDA 投稿触发 push 解锁 1 次)

#### 完成后

- INBOX §A STATUS=DONE + UPDATED 改 current ts
- 末尾 verdict:PASS = 段 A 文件存在 + 段 B DOI 挂入 + 段 C 末行签 v1.4
- git commit 3 条(local only):
  - `docs(cover): SciDA cover letter (任务 A)`
  - `chore(zenodo): upload GeoProofBench v0.1 + DOI 链接挂入(任务 B)`
  - `docs(proofrd): v1.4 终稿(任务 C)`
- OUTBOX 新增一段 `## SciDA 投稿冲刺(task10)`

**push gate 解锁说明**:SciDA 投稿 *即将* 解锁 push gate 第一次,但**投稿后** PI 拍板才 push。
不投稿 = 不 push。投稿 = 解除一次 push。

**20:39 升级**:push gate 触发点扩为 "FINAL-FORM" —— SciDA 投稿/期刊接收/公开
任一 + paper v_final 形态锁同时 = 解锁 1 次 push。仅任务完成不 = push。

---

### A.9 task10.5–task14 串行链 · 主任务(本轮起跑)

**PI 20:39 二次拍板**:"先把 10.5 至 14 做完,先不考虑 github,等最终形态定再上传"
→ 5 任务串行投递,Cursor 可派子任务并发(段 A/B/C 风格),每段独立 commit。

#### A.9.0 总体节奏(建议,Cursor 可调整)

```
task10.5 (~2-3 天) P-COMP-2 全平面闭包
     ↓
task11   (~1 周)    P-COMP-4 重采样同伦 (upscale/downscale/旋转)
     ↓
task12   (~1 周)    P-COMP-5 元一致:算子相同输入相同输出
     ↓
task13   (~1 周 +)   真实 DEM 多样性 (LiDAR/IFSAR/3 套真实数据)
     ↓
task14   (~1-2 天)   v1.4 NUM 升级:task9/10.5/11/12/13 数据写进 §7.6 multires + diversity 段
     ↓
(paper v_final 形态锁)
     ↓
(SciDA 投稿 / 期刊接收 / 公开) 任一 → push gate 解锁 1 次
```

#### A.9.1 task10.5 · P-COMP-2 全平面闭包

[step] 填洼 ⇒ 流域 在 **256² 全平面**(整张图纯平面 0 起伏)与 **256² 行扰动**(沿行
       加 ε ∈ {1e-6, 1e-4} 噪声)上验证 4 门控 + Wolfram 穷举全 256 cell
[端]   本机(主)+ AutoDL(重 verify PCOMP_2.dfy 24/0 同 PCOMP_1 17/0 同 P006_T6 12/0)
[新文件]
       formal/dafny/PCOMP_2.dfy
       formal/lean4/VeriGIS/Composition/PitFillingThenWatershedPlane.lean
       experiments/phase2/p_comp_2.py (256² 全平面 + 256² 行扰动)
       experiments/phase2/results/gpb024_pcomp2_*/{metrics,wolfram,verify}.{json,txt,log}
[产出]  4 门控 PASS ×2 套 + Wolfram 256² 穷举都收敛 + dafny 24/0 + lake 不依赖网格尺寸
[验收]  gpb024_metrics.json gates 4 全 PASS;wolfram parsed=true
[commit] feat(phase2): task10.5 P-COMP-2 全平面闭包 PASS (plane=256²/256² d=1e-6 → 收敛 e=4.5M cells, descent+fixed 双 True)

---

#### A.9.2 task11 · P-COMP-4 重采样同伦 (upscale / downscale / 旋转)

[step] 同一 DEM 在 resolution 倍率 {0.5×, 1×, 2×, 4×} + 旋转 {0°, 45°, 90°} 下
       跑 P-COMP-1:验证"算子在重采样/旋转下与原图结果差 ≤ ε_tol"(同伦性 homomorphism)
[端]   本机(主)+ AutoDL(可选,dafny 不依赖分辨率)
[新文件]
       formal/dafny/PCOMP_4_homotopy.dfy  (新增 — 证明同伦不变量)
       experiments/phase2/p_comp_4.py
       experiments/phase2/results/gpb025_pcomp4_*/{metrics,wolfram,verify}.{json,txt,log}
[产出]  resolution×rotation 矩阵 (4×3 = 12 cells) 全 OK
       dafny PCOMP_4 — 17/0(引入"重采样算子 R_α : DEM → DEM"作为参数化算子)
[验收]  gpb025 row 12 cells 11 PASS + 1 cells FAIL-TOLERANCE 详记
[commit] feat(phase2): task11 P-COMP-4 重采样同伦 PASS (plane 重采样+旋转 12/12 (σ ≤ 1e-6))

---

#### A.9.3 task12 · P-COMP-5 元一致 (metaproperty consistency)

[step] "同一输入 P-COMP-1 跑 N 次结果相同(until floating-point order)" — 元性质:
       - 幂等性 idempotent: f(f(DEM)) == f(DEM) (在 ℤ 域上严格,ℝ 容差 ε_tol)
       - 输入顺序无关: 不同 tile/worker 调度结果差 ≤ ε_tol
       - 同输入同输出跨语言: Python(numpy) ↔ Lean(合乐) ↔ Dafny(SMT) 三码 hash 一致
[端]   本机(主)+ AutoDL(重 verify Python↔Lean↔Dafny 一致性 hash)
[新文件]
       formal/dafny/PCOMP_5_idempotent.dfy
       formal/lean4/VeriGIS/Composition/PitFillingIdempotent.lean
       experiments/phase2/p_comp_5.py
       experiments/phase2/results/gpb026_pcomp5_*/{metrics,verify}.{json,log}
[产出]
       Python/Lean/Dafny 三码 hash 一致表 (rows: 4 DEM × 3 code)
       dafny 15/0(幂等性 + 输入无关性)
       lake build 0 errors (P006_T6 idempotent variant)
[验收]  gpb026 hash 三码一致 + idempotent×inputs 矩阵全 PASS
[commit] feat(phase2): task12 P-COMP-5 元一致 PASS (Python↔Lean↔Dafny hash 12/12 一致, idempotent 4/4)

---

#### A.9.4 task13 · 真实 DEM 多样性(LiDAR / IFSAR / 3 套)

[step] 拿 3 套真实公开 DEM(至少 1 套 LiDAR + 1 套 IFSAR + 1 套公开 aerial photogrammetry):
       - USGS 3DEP LiDAR(如 N34W119 LA, ~1m,1km²)
       - IFSAR(如 Alaska SAR, 5m, 100km²)
       - Copernicus DEM GLO-30(全球 1°×1° 切,30m,公开)
[端]   本机(下载 + 预处理 + 跑 P-COMP-1 + manim 对比)
[新文件]
       experiments/phase2/p_comp_realworld.py
       experiments/phase2/results/gpb027_realworld/{lidar,ifsar,copernicus}/metrics.json
       experiments/phase2/figures/RealWorldDiversity.mp4
[产出]  3 套真实 DEM P-COMP-1 跑通,3 mp4 子图对比(ridgeline/drainage density/sink count)
[验收]  3 metrics 全 PASS + mp4 渲染 3 子图 + figure caption 引 paper §7.7
[commit] feat(phase2): task13 真实 DEM 多样性 PASS (USGS-LiDAR / IFSAR-AK / Copernicus 3/3)

---

#### A.9.5 task14 · v1.4 NUM 升级:task9/10.5/11/12/13 写进 paper §7.6

[step] 把 task9 多分辨率 + 10.5 全平面 + 11 同伦 + 12 元一致 + 13 真实数据
       **写进** papers/P2/manuscript.md 的 §7.6 multires + diversity + metaprop 段
[端]   Workbuddy 不下场;Cursor 全责(PI 决定)
[新文件]
       docs/PAPER_P2_v1.4_NUM.md  (SUPP 模式,同 v1.3 NUM)
       papers/P2/manuscript.md 改写 §7.6
[产出]
       §7.6.1 task9 多分辨率(plane 9/3/3 / terrain-A 64516/98/351 / SRTM 12.95M/6.03M/28 / LiDAR 64516/20137/13)
       §7.6.2 task10.5 全平面闭包 + 噪声扰动
       §7.6.3 task11 重采样同伦 12 cells σ ≤ 1e-6
       §7.6.4 task12 元一致 Python↔Lean↔Dafny hash 12/12
       §7.6.5 task13 真实 DEM 多样性 3/3 (USGS-LiDAR / IFSAR-AK / Copernicus)
[验收]  paper §7.6.1-7.6.5 全有真实 data;末行签 v1.5
[commit] docs(manuscript): v1.5 NUM 升级 (§7.6 multires+diversity 真实数据 5 段)

---

#### A.9.6 串行链约束(本轮铁律)

- **5 任务串行,不允许并发派**:任务链顺序约束 10.5 → 11 → 12 → 13 → 14
  (理由:11 同伦用 10.5 全平面基线;12 元一致用 10.5/11 数据;14 整合 11/12/13)
- **每个 task 必须独立 commit**:每跑完一段 → `INBOX §A STATUS = SEG<n>/PENDING` →
  Cursor 写 OUTBOX 该段 + git commit → 下一段才能起跑
- **不阻塞 SciDA 11-15 投稿**:本轮 4 任务跑完 → task14 写进 §7.6 → paper v_final 形态锁
  → 解锁 push。**paper 投稿不依赖 4 任务**;投完可继续在 revision 里加 task14 段
- **段 B Zenodo DOI** 从 task10 BLOCKED 状态继续等 PI 操作(不阻链)
- **Workbuddy 不下场**:不写 paper / 不改 .dfy / .lean / .py / .md 实质内容;
  只动 INBOX/OUTBOX/cursorrules 三个协议文件 + 归档 commit

---

#### A.9.7 完成汇报格式(每段 1 行)

```
[task]      task<n> / 段 X (1-line purpose)
[step]      详述实现路径
[cmd]       实际执行命令
[rc]        exit code
[key lines] 数行关键产出(文件路径/size/metrics/hashes)
[gates]     每条 gate PASS/FAIL
[verdict]   PASS / BLOCKED / FAIL
[blocker]   (仅 BLOCKED/FAIL 时填)具体阻塞点 + PI 拍板项
```

段 PASS → commit + INBOX §A STATUS=SEG<n+1>/PENDING;全段 PASS 后 STATUS=DONE。
段 BLOCKED → 不 commit,Cursor OUTBOX 自报阻塞点,Workbuddy 通知 PI。
段 FAIL → Cursor 不自纠(Workbuddy 看后帮派,或 PI 拍板换路径)。

---

### A.10 paper 形态锁协议(PI 23:40 拍 v1.5 = FORM LOCK)

**锁生效**:2026-09-06 23:40 CST,PI 拍板「v1.5 = 形态锁」。

**触发器矩阵(FINAL-FORM push gate)**:

```
                    ┌──────────────────────┐
                    │  FIRST  (已点亮 23:40)│
                    │  paper v_final 形态锁 │
                    └──────────┬───────────┘
                               │ AND (同时)
                    ┌──────────▼───────────┐
                    │  SECOND (待 PI 操作) │
                    │  SciDA 投稿 / 接受   │
                    │  / 公开 任一          │
                    └──────────┬───────────┘
                               │ 两触发器都点
                    ┌──────────▼───────────┐
                    │  push gate 解锁 1 次 │
                    │  (一次性,PI 拍板 push) │
                    └──────────────────────┘
```

**锁定后铁律**(forms lock protocol,违反则 red flag):

1. **paper v1.5 内容不再改**:
   - `papers/P2/manuscript.md` / `papers/P2-geoproofbench/manuscript.md` 形态封顶
   - 引用 / 段标题 / § 号 / 表格 / 图表 caption / 末行版本签名不动
   - 唯一允许:错别字 / 排版微调 ≤ 5 字 / 段(由 task15 proofread R3 处理)
   - 大动 → unlock 流程:PI 显式撤销形态锁 → INBOX §A.10 LOCK-NOTE 反拍
   
2. **不放心的数字不加**(Honesty Protocol):
   - 任何数字必须能溯源到 `experiments/*/results/gpb*/metrics.json`
   - synthetic 数据(如 §7.6.1 SRTM/LiDAR synthetic)必须保留 caveat
   - FAIL-TOLERANCE 反例(如 §7.6.3 4/12)必须保留,不可洗白

3. **段 B Zenodo DOI**:
   - 现为 BLOCKED(PI 未上传 zip 拿 DOI)
   - task15 即可解锁:PI 上传 → Cursor 改 §A.5 + cover letter §5 挂真 DOI
   - DOI 是 **不在** 形态锁内(可挂;格式 + place 不变即合规)

4. **第二触发器触发方式**:
   - 投稿:PI 把 manuscript 投到 SciDA editorial system 后回报 INBOX
   - 接受:期刊发 acceptance letter,PI 拍板"接受"
   - 公开:PI 拍"公开"(repo / arXiv / Zenodo 任一公开发)
   - 任一发生 → 秘书监控 push gate 即可解锁 → 一次性 `git push origin main`

5. **unlock 流程**(若必须改 paper):
   - PI 拍 "unlock v1.5 → v1.6" 或指明改什么
   - 改 → 末行签 v1.6 → 重新 Lock → push 重新触发矩阵

**Cursor 接到本 INBOX 当前 STATUS=DONE-LOCKED**:
- [mailbox-noop] 规则触发 → 不要重复执行 task10.5..14
- 等 INBOX §A status 改回 PENDING 由 PI 触发新任务(典型:task15 DOI 补挂 / task16 proofread R3)
- 错进 OUTBOX 不动

**Workbuddy 监控钩子**:
- 每 round:grep `STATUS: DONE-LOCKED` 在 INBOX §A
- 同步检查 LOCK:行存在;若消失 → red flag,提醒 PI
- push gate + 形态锁双条件 = 解锁 1 次

---

### A.11 task16 · 第二篇 P2「LLM 自动形式化 GPB 基准评测」(PI 2026-09-09 01:43 拍板)

**A.11.0 立项**

- **选题 A**:LLM 能否把地理算法规约自动转成可机器检验的 Dafny/Lean 规约?失败模式是什么?
- **闭环叙事**:P1「建基准」→ P2「用基准首次系统评测 AI 形式化能力边界」
- **AI for Math 硬标签**:差异化在**地理算法特有结构**(网格遍历 / 浮点比较 / 拓扑不变式 / 终止性度量),
  miniF2F / ProofNet 是纯数学,无人系统做过这块
- **目标期刊**:主 NeurIPS Datasets & Benchmarks / ICLR;备 JGSA / IJGIS
- **投稿 DDL**:2026-11-10(W9)

**A.11.1 本轮只做 W1(9/9–9/15)—— 设计 + 任务包,不跑模型**

交付物(4 项,缺一不可):

| # | 产物 | 验收 |
|---|---|---|
| 1 | `docs/P2_AIMATH/DESIGN.md` | ≥ 300 行:任务定义、模型清单、prompt 策略、指标、失败模式 taxonomy、统计方法、威胁有效性 |
| 2 | `experiments/p2_llm/tasks/` | ≥ 21 个任务项 YAML(L1 单算子 + L2 组合 + L3 反例),从 `formal/` 现有命题抽取 |
| 3 | `experiments/p2_llm/prompts/` | 3 档 prompt 模板:zero-shot / few-shot / repair |
| 4 | `docs/P2_AIMATH/RISKS.md` | API 成本、额度、可复现性、P1 返修撞期的对策 |

**A.11.2 任务包 schema**(每个任务项)

```yaml
id: GPB-xxx                    # 沿用 GPB 编号
difficulty: L1 | L2 | L3
target: dafny | lean
natural_spec: |                # 喂给 LLM 的输入 ①
  <命题的自然语言规约,从 docs/phase2/PROP_CHAIN.md / formal 文件注释抽取>
reference_impl: experiments/phase1/xxx.py   # 喂给 LLM 的输入 ②
gold_formal: formal/dafny/xxx.dfy           # ★ 不喂给 LLM,仅作评测基线
expected_verdict: PASS | NEG                # NEG = 反例类命题(应证伪)
```

**A.11.3 难度分层**(本 benchmark 的核心设计,把 B 的科学问题装进 A 的实验)

| 层 | 内容 | 题量 | 预期 |
|---|---|---|---|
| **L1** | 单算子 P-001..P-006(已 verify) | ~13 | 高通过率 |
| **L2** | 组合 P-COMP-1/2/4/5 | ~5 | 中 |
| **L3** | 反例 / neg-result(P-COMP-3、ring_terminated=False、45° FAIL-TOL) | ~3 | 低,且最易语义漂移 |

**A.11.4 模型清单(4 个,固定版本 + temperature=0 + k=5)**

建议 4 档覆盖:1 个强推理(Claude Opus/Sonnet 5 系)、1 个 GPT-5.x、1 个 Gemini 3.x、
1 个国产低价(DeepSeek-V3 / Qwen-Max)。**成本优先**:优先用 Cursor Pro 已有额度 + 低价 API,控制 k=5。
DESIGN.md 里写清每个模型的确切版本串与调用日期。

**A.11.5 prompt 策略(3 档对比)**

- **P0 zero-shot**:仅 natural_spec
- **P1 few-shot**:natural_spec + 1 个**非同命题**的已验证 .dfy 样例
- **P2 iterative repair**:把编译器/验证器报错喂回,最多 3 轮

**A.11.6 指标(6 个,主指标 2 个)**

| 指标 | 定义 |
|---|---|
| compile@1 | 生成代码能否被 `dafny /compile:0` 解析 / `lake env lean` 解析 |
| **verify@1** ★主 | 一次生成即通过机器检验的比例 |
| **verify@3** ★主 | repair ≤3 轮后通过比例 |
| repair gain | verify@3 − verify@1 |
| **semantic fidelity** ★杀手锏 | 生成规约与 gold_formal 语义一致率;**单独报告 "verified but drifted"**(通过了验证但证明的不是原命题)比例 |
| failure taxonomy | F1–F8 分布 |

> **semantic fidelity 是本 benchmark 与 miniF2F/ProofNet 最大的差异化**:
> 形式化验证通过 ≠ 证明对了命题。这是地理算法(浮点、网格、拓扑)最易翻车处。

**A.11.7 失败模式分类学 v0**(Cursor 可扩充,但不得删类)

| 码 | 类别 |
|---|---|
| F1 | 语法 / 解析错误 |
| F2 | 类型 / 签名错误 |
| F3 | 前置条件缺失或弱化 |
| F4 | 循环不变式缺失 |
| F5 | 终止性度量(variant / decreases)缺失 |
| F6 | 浮点 / 数值语义错配 |
| **F7** | **语义漂移(通过验证但证明错命题)** |
| F8 | 过度强化前提(把真命题证成平凡命题) |

**A.11.8 诚实协议**(继承 P1 惯例,不可破)

- **不编造结果**:跑不通记 FAIL,不给模型"擦屁股"
- 记录模型版本串 / 调用日期 / temperature / prompt 模板 hash
- 全部 raw 输出落 `experiments/p2_llm/results/raw/`,可复现
- 已有反例资产(P-006b 4-环、ZT vs Horn、45° FAIL-TOL)**不可洗白**

**A.11.9 自推进链(自动化核心,PI 01:43 要求"全程零点击")**

```
W1/PENDING ──完成──▶ Cursor 自改 STATUS: W2/PENDING ──watcher 自动调起──▶ W2 …
                                    ……
W9/PENDING ──完成──▶ STATUS: DONE
```

- **Cursor 职责**:每段做完 → 自己把 §A 的 `STATUS:` 改成下一段 `W<n+1>/PENDING`
  → 写 OUTBOX 新段 → `git commit`(local,**不 push**)
- **watcher 职责**:本机计划任务每 5 分钟扫 STATUS,非 DONE 且无 agent 在跑 → 自动调起 Cursor
- **PI 职责**:零。只在周报/异常时看一眼
- **push gate**:P2 形态锁 + P2 投稿 双触发器齐备才解锁;**W1–W9 期间一律不 push**

**A.11.10 汇报格式**(继承 §A.4)

```
## <段名>(task16-W<n>)
[task]      ...
[step]      ...
[cmd]       ...
[rc]        ...
[verdict]   PASS / FAIL / BLOCKED
[blocker]   (仅 BLOCKED/FAIL 时填)
```

---

### A.12 · task16-W3.5 解阻双线(PI 2026-09-09 02:50 拍板)

**背景**:W2/W3 卡在同一个点 —— 本机出口访问不到 live LLM API:
```
code.newcli.com    → ConnectTimeout ~42s
api.anthropic.com  → HTTP 403 "Request not allowed"   ← 注意是 403(通了但被拒),不是网络不通
```
W3 的离线部分已全过(schema 22/22、L1 14 题、prompt dry-validate 28/28),
`run_l1_batch.py --require-live` 是唯一缺口。**未编造任何 verify@ 数字,诚实协议保持。**

#### A.12.1 线 1 · LLM API 端点可达性实测(先做,最高优先级)

**铁律:只报实测数字,不许臆测、不许凭印象下结论。**

对每个候选端点做四层探测,逐项记录:

| 层 | 检查 | 记录字段 |
|---|---|---|
| L1 | DNS 解析 | resolve_ok / resolve_ip / resolve_ms |
| L2 | TCP 连接 | tcp_ok / tcp_ms |
| L3 | TLS 握手 | tls_ok / tls_ms / cert_cn |
| L4 | HTTP 探针 | http_status / http_ms / err_class(DNS/TCP/TLS/HTTP-403/HTTP-401/timeout/other) |

**候选端点清单**(逐个实测,一个不落):

| # | 端点 | 说明 |
|---|---|---|
| 1 | `https://api.anthropic.com/v1/messages` | 官方,当前 403 |
| 2 | `https://openrouter.ai/api/v1/chat/completions` | 聚合,OpenAI 兼容,一个 key 通吃 Claude/GPT/Gemini |
| 3 | `https://api.siliconflow.cn/v1/chat/completions` | 硅基流动,国内直连,OpenAI 兼容 |
| 4 | `https://api.deepseek.com/chat/completions` | DeepSeek,国内直连 |
| 5 | `https://open.bigmodel.cn/api/paas/v4/chat/completions` | 智谱 GLM |
| 6 | `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` | 通义千问,OpenAI 兼容模式 |
| 7 | `https://api.moonshot.cn/v1/chat/completions` | Moonshot/Kimi |
| 8 | 环境变量代理探测 | 检查 `HTTPS_PROXY` / `HTTP_PROXY` / `ALL_PROXY` 是否已设;若已设,再测一次 #1 看是否解阻 |

**无 key 时的处理**:不要因为没 key 就跳过。**先做 L1–L3**(DNS/TCP/TLS 不需要 key),
再加一次**无 key 的 L4 探针** —— 401/403 恰恰证明"可达"(被拒 ≠ 不通),而 timeout/DNS 失败
证明"不可达"。这两类必须区分清楚,这是本次探测的核心价值。

**产物**:
- `experiments/p2_llm/results/api_reachability.json` — 机器可读,每端点 4 层字段全记录
- `docs/P2_AIMATH/API_REACHABILITY.md` — 人读矩阵表 + **推荐方案**(分级:
  推荐 / 可用 / 不可用),并明确写出"需要 PI 提供什么"(key / 代理 / 账号)

**门禁**:`rc=0` 即 PASS(探测本身成功即达标,**不要求任何端点真的可用**)。
探测出"全部不可达"也是有效结果,如实报。

#### A.12.2 线 2 · 离线基建(不依赖 API,与线 1 并行/串行均可)

目的:等 API 一通就能直接灌数据,不浪费等待窗口。

| # | 交付物 | 验收 |
|---|---|---|
| 1 | `tests/test_scoring.py` — `score_semantic.py` 单元测试 | 覆盖:编译失败 / verify 失败 / verify 通过但语义漂移(F7)/ 超时 / 空输出,≥ 8 case 全过 |
| 2 | `docs/P2_AIMATH/RESULT_SCHEMAS.md` — 结果表骨架 | 主表(4 模型 × 3 prompt × 21 题 × k=5)列名 + 每列口径 + 空表 markdown 模板 |
| 3 | `docs/P2_AIMATH/ANNOTATION_MANUAL.md` — 失败模式标注手册 | F1–F8 每类给 ≥1 个真实 GPB 示例 + 判定规则 + 边界情况(多人标注一致性怎么保证) |
| 4 | `experiments/p2_llm/harness/make_figures.py` — 图生成脚本 | 输入结果 JSON,输出 4 图:难度分层柱图 / 模型对比 / repair gain 曲线 / 失败模式分布 |
| 5 | `experiments/p2_llm/harness/run_all_offline.py` — 一键离线自检 | 跑 fixture → 评分 → 出图,全链路不碰网络,rc=0 |

**门禁**:5 项全交付 + 离线自检 rc=0 = PASS。

#### A.12.3 自推进与回报

- 双线做完 → 把 §A STATUS 改成 `W3/PENDING`(**不是 W4**),让 watcher 重跑 W3 主实验;
  若线 1 探测到可用端点且环境里有 key,则**直接用该端点试跑 1 个 cell**(GPB-001-flat, P0, k=1),
  拿到真实 API 响应后 STATUS 改 `W3/PENDING` 并说明"已验证通路"。
- 若线 1 全不可达 → STATUS 保持 `W3/BLOCKED-PI`,并在 OUTBOX 明确列出**需要 PI 提供的三选一**:
  (a) 可用 base_url + key / (b) 代理地址 / (c) 改用某国产模型的决定。
- OUTBOX 新增段 `## LLM 自动形式化 GPB 基准 · W3.5 解阻(task16-W3.5)`,
  含 `[task]/[step]/[cmd]/[rc]/[key lines]/[gates]/[verdict]/[blocker]`。
- 两段独立 commit:`feat(p2_llm): task16-W3.5a API 可达性实测` / `feat(p2_llm): task16-W3.5b 离线基建`。

**绝对禁止**:编造任何 `verify@` / `compile@` 数字;把 fixture 结果当真实模型结果上报;
修改 `papers/` 下任何内容(P1 形态锁);git push。

---

### A.13 · task16-W3 解阻路径收窄(洛书 2026-09-09 23:1x 实测)

**实测补充(A.12.1 未覆盖 ANTHROPIC_BASE_URL)**:

| 项 | 实测 |
|---|---|
| `ANTHROPIC_BASE_URL` | `https://code.newcli.com/claude`(Cursor 订阅网关) |
| DNS | ok 18 ms → 118.193.240.41 |
| TCP :443 | **timeout 30 s** → 网络层不可达 |
| 公共 DoH(dns.google / cloudflare-dns) | 全被挡(timeout / RST)→ 换 DNS 绕不过 |
| `api.anthropic.com` | 维持 **403** → 业务层拒绝,非网络故障 |

⇒ **A.12.1 的选项 (b)「配代理」无效**:网关是出口限制(不是代理缺失),
官方是账号/区域策略(代理不改账号)。**实际只剩 (a) 国产 key / (c) OpenRouter 或改模型。**

**新交付(已 commit)**:`experiments/p2_llm/harness/openai_compat.py`

原 harness 只认 Anthropic `/v1/messages` + `x-api-key`,**给了国产 key 也跑不了**;
现新增 `--backend openai`,支持 siliconflow / deepseek / dashscope / zhipu /
moonshot / openrouter 六个 OpenAI 兼容端点(`chat_url` 取自实测可达的 URL)。

**PI 给 key 后的解阻命令(一条)**:

```bash
export SILICONFLOW_API_KEY=...      # 或 DEEPSEEK_API_KEY / DASHSCOPE_API_KEY / ...
cd experiments/p2_llm/harness
python run_l1_batch.py --backend openai --require-live --prompts P0,P1 --k 5
```

- provider 自动探测(有哪个 key 用哪个);指定用 `export P2_LLM_PROVIDER=deepseek`
- 未显式给 `--model` 时自动套用该 provider 的 `default_model`
- 无 key → 明确 BLOCKED、`cells=[]`,绝不编造 verify@

拿到真实响应后按 A.12.3:STATUS 改 `W3/PENDING`(或直接推进 W4),OUTBOX 新开段回报。

**当前自检(无 key 环境,非模型结果)**:离线自检 `schema_ok=true` / `figures_n=4` /
`n_live=0`;dry-run 22/22 tasks + 2/2 prompts PASS;`--backend openai --require-live`
返回 BLOCKED 且 `cells=[]`。

**依赖提示**:harness 需要 `httpx` / `pyyaml` / `jsonschema`。
**缺 `jsonschema` 会让 `schema_ok` 假性变 false**(不是任务 YAML 出错),排查时先查依赖。

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
- **task9(2026-09-06 19:42-20:13,STATUS=CLOSED)** = 多分辨率迁移 5×5 → 256² → 3601² → LiDAR; commit `6a54d4c` (plane 9/3/3; terrain-A 64516/98/351; SRTM 12.95M/6.03M/28; LiDAR 64516/20137/13)
- **task9.5(2026-09-06 19:49-20:13,STATUS=CLOSED)** = paper v_final 整合 (v1.0+v1.1+v1.3 → papers/P2/manuscript.md); commit `cedfa77`
- **task10(2026-09-06 20:24-20:35,STATUS=BLOCKED-DOI)** = SciDA 投稿冲刺 (段 A cover_letter PASS c31981e / 段 B Zenodo DOI PENDING-PI / 段 C proofread R2 v1.4 PASS 29f1529);push 解锁待 PI 上传 zip + 拿真实 DOI
- **task10.5(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = P-COMP-2 全平面闭包 256² + 256² noise
- **task11(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = P-COMP-4 重采样同伦 resolution×rotation 12 cells
- **task12(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = P-COMP-5 元一致 Python↔Lean↔Dafny hash 一致
- **task13(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = 真实 DEM 多样性 USGS-LiDAR + IFSAR + Copernicus 3/3
- **task14(2026-09-06 20:39-23:45,STATUS=LOCKED)** = v1.5 NUM 升级:task9/10.5/11/12/13 写 paper §7.6;PI 23:40 拍 v1.5 = FORM LOCK 触发第一触发器
- **task15(2026-09-09 01:37,STATUS=CLOSED)** = 28 commits 一次性 push(d6bcaae..c2a5000),FINAL-FORM 双触发器已消费,远端 GitHub 同步完成
- **task16(2026-09-09 01:43-PENDING,STATUS=ACTIVE)** = 第二篇 P2「LLM 自动形式化 GPB 基准评测」;W1 设计 → W9 投稿 11/10;**本机自动化已部署**(Cursor headless CLI + INBOX watcher + 计划任务每 5 min),PI 零点击

### B.3 触发器(`.cursorrules` `[mailbox]` 规则契约)
- Cursor session 启动时自动 `Read` 本文件
- STATUS=PENDING → 执行 §A
- STATUS=DONE/CLOSED → 不动
- 改本文件只能由洛书(Cursor 不改 INBOX 优先级/约束/直终态)
