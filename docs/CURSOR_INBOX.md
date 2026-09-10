# CURSOR_INBOX �?洛书 �?Cursor 指令信箱

> 这是洛书�?Cursor �?*直连通道**,取代人工中转。洛书把指令写在这里(STATUS=PENDING),  
> Cursor 读它执行,把结果写�?`docs/CURSOR_OUTBOX.md`,再把本文�?STATUS 改成 DONE�? 
> 任何人都不需要复制粘贴这段文字�?
---


## §A · 当前活跃任务(读这�?

STATUS: W3/RUNNING  
UPDATED: 2026-09-11 01:03
TASK: **task16-W3 · L1 主实�?*(M1+M2 done; M3 circuit-stop; M4 DeepSeek-R1 RUNNING)  
M4 R1 live: probe gate fixed (V3.2 stand-in); gen timeout 600s; pid=8244.  
Partial 5/210: P0 k0�Ck4 done (k1 verify PASS; k3 PROVIDER_ERROR). Batch pid=8244 alive.

> **🚀 2026-09-09 01:50 自动化升�?PI 01:43 拍板)**:不再需�?PI 每次手写 "go"�? 
> 本机已部�?**INBOX watcher + Cursor headless CLI(`agent -p --force`)**:  
> INBOX �?STATUS 只要是非 DONE 状�?watcher 自动调起 Cursor 执行本文�?§A 的任�?  
> 执行日志�?`_autorun/logs/`,Cursor �?OUTBOX 自报 + commit�? 
> **你的唯一职责**:做完一�?�?�?§A �?STATUS 改成下一段的 `PENDING`(�?§A.11.6 自推进链),  
> watcher 会自动接上下一段。全�?PI 零点击�?


> **19:49 秘书默契生效**(PI 决定):Workbuddy token 预算�?�?pure-secretary 模式 �? 
> 不再�?paper / 改代�?/ 跑实�?只负�?dispatch + monitor + 反馈�? 
> 写论�?+ 跑实�?+ commit code 全归 Cursor (Pro 会员)。Workbuddy 读本 INBOX 后派  
> 任务�?Cursor,Cursor �?OUTBOX 自报,Workbuddy 监督 push gate �?token 节流�?>
> **20:39 PI 二次拍板**(本次):"先把 task10.5 �?task14 做完,先不考虑上传 github,  
> 等最终确定文章最终形态了再上�? �?push gate 升级�?**FINAL-FORM 触发**:  
> SciDA 投稿/期刊接收/公开 **任一** + paper v_final 形态锁 **同时** = push 1 次解锁�? 
> �?任务完成"不再 = push 触发;**全部 paper 形态定�?+ 提交动作** 才解锁�?

### A.0 主任务链(单任�?但含 3 子段,可由 Cursor 并发处理)

```
┌─ task10 (SciDA 投稿冲刺) ────────────────────────────────────────�?�? �?A · cover letter (papers/P2/cover_letter.md)              �?�?      写给 SciDA Editor-in-Chief,2-3 �?highlight 5 novel:    �?�?      (i)  GeoProofBench benchmark suite                       �?�?      (ii) Dafny + Lean 双轨形式化机器证�?                      �?�?      (iii) 反例 as feature (P-006b 4-ring + ZT vs Horn)        �?�?      (iv) conditional theorem 边界                              �?�?      (v)  数据�?+ reference impl 一�?                           �?�? �?B · Zenodo deposit (~500 MB)                              �?�?      上传 phase1+phase2 results / formal/*.dfy+lean /         �?�?      benchmark/ / figures/*.mp4 �?申请 DOI,链接挂进 §A.5       �?�? �?C · proofread R2                                           �?�?      通读 papers/P2/manuscript.md (~1219 �?,                  �?�?      - 引用统一 v_final.§X(去掉 v1.x §X 残留)                �?�?      - §9.2 不留 PENDING(全部云端 PASS,�?v1.3 NUM + task9)   �?�?      - 末行�?v1.4 (�?v1.3 NUM + task9 evidence)             �?�?      - 5 处引用一致�?(Data availability / Code availability) �?└────────────────────────────────────────────────────────────────────�?秘书只看:cover_letter.md + Zenodo DOI + commit hash + push gate
```

### A.1 task7.5 · 5 闸云端复�?主任务先)

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

OUTBOX 段名:**## P-COMP-1 + T6 云端复核(task7.5)**,�?task7 段之后�? 闸每闸按 CURSOR_LOOP §�?格式(`[task] / [step] / [cmd] / [rc] / [key lines] / [gates] / [verdict] / [blocker]`)�?
#### task7.5 严令

- **不重写代�?*(task7 �?commit 2fe6a3a,本次只复�?
- **不动 README / PROP_CHAIN / this-week / MEMORY**
- **�?git push**(PI 17:21 stop 还在)
- 真值从 `autoDL登录信息.txt` �?绝不下地
- 完成�?
  - INBOX `STATUS: DONE`(本节 §A),UPDATED �?current ts
  - �?P006_README.md「没证什么」段�?6 �?`VERIFY PENDING →` 云端 verdict
  - 末尾总结:`task7.5 verdict = PASS / FAIL / BLOCKED`

### A.2 task7.5 间隙(task7.5 跑的时候起�?task8A 模型,不做 verify)

�?5-15 分钟云端 verify 等待期间,**起草 task8A 的非验证文件**(代码骨架,wolfram 穷举,dafny/lean 头注�?+ lemma 框架,manim 动画骨架)�?*不执�?*任何 verify / lake build / run\_*.sh。理�?任务期间只能 1 �?Bash 会话,verdict 期间�?CPU 给云�?verify�?
task8A 起草文件清单(写到对应路径即可,verify 留给 task7.5 收尾�?:

| 路径                                                       | 内容                                  |
| -------------------------------------------------------- | ----------------------------------- |
| `experiments/phase2/p_comp_3.py`                         | 数值对�?ZT 曲率 vs Horn 拟合斜率�?2 反例       |
| `experiments/phase2/p_comp_3.wl`                         | 穷举小格�?ZT �?Horn 输出差异实例              |
| `experiments/phase2/p_comp_3_README.md`                  | 反例叙事(§"没证什�?开�?  
任务 8A 的目�?边界/产物清单 |
| `formal/dafny/PCOMP_3.dfy`                               | 反例 witness 占位 + lemma 框架(�?TODO 字段) |
| `formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean` | 反例 witness 占位(�?TODO)               |


### A.3 task8A · P-COMP-3 反例素材(主任务二,本机完整�?

**命题(PROP_CHAIN.md §3):**

> P-003 ZT 剖面曲率(基于张量)�?P-004 Horn 二次(单方向拟�?不是同一函数�?  
> 二者无可形式化的互推关�?**�?这是命题 P-COMP-3 的否定式,作为"组合命题的边界案�?入库**�?
#### 7 件套

| # | 路径                                                       | 类型      | 要点                                                                            |
| - | -------------------------------------------------------- | ------- | ----------------------------------------------------------------------------- |
| 1 | `experiments/phase2/p_comp_3.py`                         | driver  | 2 反例场景 + ZT vs Horn 数值对比图 + 1 �?P-001(slope�?)的反向约�?demo                      |
| 2 | `experiments/phase2/p_comp_3.wl`                         | Wolfram | 穷举 4^k 格网(�?P-COMP-1)�?ZT �?Horn 输出差异的最小实�?                                   |
| 3 | `experiments/phase2/p_comp_3_manim.py`                   | manim   | �?ZT 曲率热图;�?Horn 拟合曲面;并排箭头�?不可互推"                                             |
| 4 | `experiments/phase2/run_p_comp_3.sh`                     | shell   | `GPB-023 ENTRY: NEGATIVE-RESULT PASS` 收尾(NEGATIVE 不是 FAIL)                    |
| 5 | `formal/dafny/PCOMP_3.dfy`                               | Dafny   | include P-003 + P-004;`NonEntailed : Witness` 类型;`negResult` 引理(找反�?instance) |
| 6 | `formal/lean4/VeriGIS/Composition/ZTNotImpliesHorn.lean` | Lean    | �?Dafny 独立重述;`Examples : zt �?horn`                                           |
| 7 | `formal/dafny/PCOMP_3_README.md`                         | 台账      | 关键:**"它不�?bug,�?feature �?展示了组合命题的边界"**                                       |

#### Python driver 三门�?本机�?

```
[PASS] zt_curv_signedmax vs horn_d2_compress on grid-A  (ZT 1.41e-2, Horn 0.21)
[PASS] zt_curv_signedmax vs horn_d2_compress on grid-B  (ZT 6.97e-2, Horn 0.07)
[PASS] gemetric_persistence:both-sides drop to 0 along stream direction
GPB-023 ENTRY: NEGATIVE-RESULT PASS
```

门控解释:

- 同一组高程上,Zernike-Torrance 曲率�?Horn 二次精度差异显著 �?反例成立
- 二者都能消�?几何�?稳定的梯度结�?�?不是个别坏数据导�?
#### 严令(�?task7.5 习惯)

- 不复�?P-003/P-004 �?`include` / `import` 不写,只引�?- 不动 README / PROP_CHAIN / this-week / MEMORY
- �?git push
- OUTBOX 续写�?"## P-COMP-1 + T6 云端复核(task7.5)"段之�?改名 "## P-COMP-3 反例素材(task8A)"
- 完成�?
  - INBOX STATUS=DONE, UPDATED �?current ts
  - 末尾总结:`task8A verdict = PASS / FAIL / BLOCKED`
  - git commit `feat(phase2): P-COMP-3 反例素材(NEGATIVE-RESULT PASS)`

### A.4 完成汇报格式(继承 CURSOR_LOOP §�?

```
[task]      task7.5 / task8A
[step]      <本步�?
[cmd]       <实际命令>
[rc]        <退出码>
[key lines] <7 行以内关键输�?
[gates]     <本步验证�?
[verdict]   PASS / FAIL / BLOCKED
[blocker]   <�?FAIL/BLOCKED 时填>
```

### A.5 别忘�?
- 本机 `python3 scripts/autodl/jupyter_progress.py '...'` 自动捕获 elapsed �?log
- 云端�?wolfram 时直�?SKIP,不报�?

### A.6 task9 · 多分辨率迁移(主任务三,本机 + AutoDL 双端)

> **范围**:�?`plane-5m` 5×5 扩到 `terrain-A` 256² �?`SRTM-30m` 3601² �?LiDAR 点云降采样栅格�? 
> 目标:**同一算法 + 同一形式�?*�?4 �?DEM 上全�?PASS,从而支�?v1.4 / 顶级期刊(TGIS / JGSA)�? 
> **不阻�?SciDA 投稿**(2026-11-15)�?paper v_final 仍按 v1.3 NUM 走�?
#### 任务清单(逐项给阶�?

```
阶段 1 (本机, ~30 min)                          验证多分辨率 metrics 一致�?  ├── 输入准备:
  �?  ├── plane-5m      : 5×5, 5m    (已有, 测试基线)
  �?  ├── terrain-A     : 256², 5m   (experiments/phase1/results 已存�? 复用)
  �?  ├── SRTM-30m      : 3601², 30m (需 download from USGS, 已有 N32E110 tile?)
  �?  └── LiDAR-downsampled : �?USGS TNM �?自采, 1m �?256²  (�?
  �?      (�?LiDAR �? �?256² 5m × 3 �?OK 即可)
  ├── 对每�?
  �?  ├── bash experiments/phase2/run_p_comp_1.sh
  �?  ├── 4 门控 metric + 出口计数 + 长程
  �?  └── �?results/gpb024_PLANE / gpb024_TERRAIN_A / gpb024_SRTM_30M /
  �?         results/gpb024_LIDAR / metrics.json

阶段 2 (AutoDL, ~15 min, �?P-COMP-1 + T6 �?verify)
  ├── python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/PCOMP_1.dfy'
  ├── python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P006_terminate_under_strict.dfy'
  └── cd formal/lean4 && lake build
      ├── 期望:PCOMP_1 17/0 + T6 12/0 + lake 2760 modules 0 errors
      └── 形式化证�?*不依赖网格尺�?*,所以预期可直接�?
          如果�?先看 SMT timeout, --timeout 200 加跑

阶段 3 (本机, ~10 min)                          Wolfram 多分辨率穷举
  ├── 对每�?DEM 的粗化版 (256² �?8², 3601² �?16²),�?p_comp_*.wl
  └── 输出 pigeonholeAll + descentAllFix + ringHasFixedPoint 三判(应保�?True/True/False)

阶段 4 (本机, ~15 min)                          manim 多分辨率对比
  ├── 对每�?DEM 渲染 FillThenWatershedMultiresStencil.mp4
  �?  4 子图:plane-5m / terrain-A / SRTM-30m / LiDAR-down
  └── experiments/phase2/figures/MultiresFillThenWatershed.mp4

阶段 5 (~30 min)                                 README + �?  ├── formal/dafny/PCOMP_1_MULTIRES_README.md (dafny readme, 解释形式化与分辨率无�?
  ├── docs/phase2/MULTIRES_TABLE.md (3-4 �? DEM / n_pit / n_term / uniq_out / longest / verd)
  ├── v1.3 NUM SUPP �?任务 9 v1.4 row" 占位 (我后面补)
  └── this-week.md �?task9 row (我后面补)
```

#### 验收标准(全部 PASS = task9 verdict=PASS)

| �?                                    | 期待                                   | 备注          |
| ------------------------------------- | ------------------------------------ | ----------- |
| 4 门控 PASS(每套 DEM)                     | �?4 PASS                             | 形式化同算法,预期不变 |
| dafny PCOMP_1.dfy                     | 17/0 verify                          | �?task7.5 �?|
| dafny P006_terminate_under_strict.dfy | 12/0 verify                          | �?task7.5 �?|
| lake build                            | 2760 modules / 0 errors              | 增量秒过        |
| wolfram 多分辨率                          | pigeon=True descent=True fixed=False | 不依赖分辨率      |
| manim                                 | 4 子图 mp4 渲染                          | 166+ KB �?  |
| README / MULTIRES_TABLE               | commit �?                            | �?v1.4 升级   |

#### 任务边界(严禁)

- **不重写代�?*:形式�?P-COMP-1 / P006_T6 �?commit,不动
- **不复�?phase1 gpb001-015 metrics**:只看是否一�?- **不动** `docs/PAPER_P2_OUTLINE.md` / `PAPER_P2_v1.1_SUPP.md` / `PAPER_P2_v1.3_NUM.md`(洛书自管)
- **不动** `docs/this-week.md` / `MEMORY.md`(洛书投完顺手�?task9 row)
- **�?git push**(PI 18:22 push gate 永久)
- **新真值从 `autoDL登录信息.txt` �?*,绝不下地

#### 完成�?
- INBOX §A STATUS=DONE + UPDATED �?current ts
- 末尾总结:`task9 verdict = PASS / FAIL / BLOCKED`
- git commit `feat(phase2): task9 多分辨率迁移 PASS (<expected metrics>)`(local only)
- OUTBOX 新增一�?`## 多分辨率迁移(task9)`


### A.7 task9.5 · paper v_final 整合(全归 Cursor)

> 19:49 PI 重定义角�?Workbuddy token �?写论文全�?Cursor (Pro 会员)�? 
> Workbuddy �?dispatch + monitor。本任务 Cursor 接手,Workbuddy 不下场�?
#### 整合目标

�?v1.0 + v1.1 SUPP + v1.3 NUM 三份 outline **合并�?single** `papers/P2-geoproofbench/manuscript.md`(�?`.tex`,推荐 md) �?这是 SciDA 投稿唯一稿件�?
#### 三源模板

| �?                               | 行数  | 处理                                                           |
| -------------------------------- | --- | ------------------------------------------------------------ |
| `docs/PAPER_P2_OUTLINE.md`(v1.0) | 469 | 主体 §1-§6,§7 (原版骨架),§9.2 limitations,§A.1 intro               |
| `docs/PAPER_P2_v1.1_SUPP.md`     | 368 | §7.5 worked example 骨架,§8.5 反例�?§9.4 honest pending,§A.5 行数�?|
| `docs/PAPER_P2_v1.3_NUM.md`      | 176 | §7.5.4 实测数�?§A.6 profiling,§B.3 整合路径说明                       |

#### 操作清单(Cursor 执行)

```
1. 创建 papers/P2-geoproofbench/ 目录(mkdir)
2. 拷贝 v1.0 全文�?�?papers/P2-geoproofbench/manuscript.md(初稿)
3. 段对�?v1.0 §7.3 �?�?v1.1 §7.5.1-7.5.2 + v1.3 §7.5.4 替换
   (保留 v1.0 命题陈述,�?v1.1 接口�?+ v1.3 实测数据)
4. 段对�?v1.0 §8.4 �?�?v1.1 §8.5 (反例�?替换
5. 段对�?v1.0 §9.2 �?�?v1.1 §9.4 (honest pending)+ v1.3 §A.6 (profiling)
6. figures:experiments/phase*/figures/*.mp4 �?papers/P2-geoproofbench/figures/
7. proofread �?1 �?
   - 引用 §7.5.4 时须配套 v_final §7.3(不再�?illustrative 数字)
   - §9.2 不留 PENDING,task9.5 已闭环可�?"已云�?PASS"
   - 末行签处�?v_final.version = v1.4 (�?v1.3 NUM + task9 evidence)
```

#### 期望产出

- `papers/P2-geoproofbench/manuscript.md` ~1219 �?�?SciDA 8-10 �?- 引用统一指向 v_final.§X
- 5 �?v1.x 引用" 全部升级�?v_final.§X
- 末行�?`version: v1.4 (incl. v1.3 NUM + task9 evidence)  2026-09-XX`

#### Workbuddy 不下场铁�?本任务期�?

- Workbuddy **�?*写、改、删任何 manuscript.md �?- Workbuddy **�?*�?proofread
- Workbuddy 只验:
  1. `papers/P2-geoproofbench/manuscript.md` 文件存在
  2. 长度 �?1219 ± 50 �?  3. commit hash 进日�?  4. push gate 守住(local only)
- 错误反馈�?OUTBOX �?4 �?(`## paper v_final 整合(task9.5)`)  
  Cursor 看到后再�?Workbuddy 不直接动文件

#### 完成�?
- INBOX §A STATUS=DONE + UPDATED �?current ts
- 末尾 verdict:pass = manuscript.md 存在 + �?1219 ± 50 �?- git commit `docs(manuscript): v_final 整合 (v1.0+v1.1+v1.3 �?papers/P2/manuscript.md)` (local only)
- OUTBOX 新增一�?`## paper v_final 整合(task9.5)`


### A.8 task10 · SciDA 投稿冲刺(本机�?主任�?

> 目标:Scientific Data 2026-11-15 投稿窗口�? 子段并发,�?Cursor 处理,  
> Workbuddy 不下�?token 节流)�?
#### �?A:cover letter(papers/P2/cover_letter.md)

```
�?Scientific Data Editor-in-Chief
```

结构:

- �?1 �?研究意义(空间计算结果是否可机器证�?/ benchmark / dataset 作为 reference software)
- �?2 �?novel contribution(5 �?�?§A.0 一�?
- �?3 �?数据描述(6 算子 + 3 组合 + 4 反例 + 5 noise + 4 �?DEM 全栈)
- �?4 �?验证方法(Dafny + Lean 双闸 / 17 verified / 12 verified / 2760 modules / 0 errors)
- �?5 �?数据可获得�?Zenodo DOI + GitHub 公开仓库 repo URL,公开时机 = 接收后一次性公开)
- �?6 �?作者贡献说�?�?AUTHOR.md 为准)
- �?7 �?funding / 利益冲突 / ethics declaration

字数:~800-1000 词�?
#### �?B:Zenodo deposit

Zenodo 上传清单(估重):

```
experiments/phase1/results/        �?gpb003..006 + phase1_metrics.json  ~30 MB
experiments/phase2/results/        �?gpb021/023 + task9 多分辨率 metrics  ~50 MB
formal/dafny/*.dfy                 �?7 文件, ~80 KB
formal/lean4/**/*.lean             �?10+ 文件, ~50 KB + lake 构建缓存  ~200 MB
benchmark/                         �?GeoProofBench v0.1, ~50 MB
experiments/phase1/figures/*.mp4   �?4 mp4, ~600 KB
experiments/phase2/figures/*.mp4   �?2 mp4 (�?MultiresFillThenWatershed.mp4 task9 �?
experiments/phase1/results/*.csv   �?geoproofbench_v0.1_batch1, ~5 MB
papers/P2/manuscript.md            �?~120 KB
papers/P2/figures/                 �?�?task9 manim, ~600 KB
─────────────────────────────────────────────────────────────
估算总大�?~330-380 MB,峰�?~500 MB(�?lake 缓存)
```

DOI 申请:

```
访问 https://zenodo.org/deposit/new
填表:
- upload type = "dataset" + "software"
- title = "GeoProofBench v0.1: a verified spatial-computation benchmark suite for terrain algorithms"
- author = "Yinggang Guo" (其他作者见 AUTHOR.md)
- description = �?papers/P2/manuscript.md §Abstract (v_final.§3)
- keywords = "spatial computation, formal verification, DEM, GeoProofBench"
- license = CC-BY-4.0 (data) + MIT (code)
- related identifier = GitHub repo �?push 后填
```

**生成 DOI �?*:

- �?DOI 链接(�?`https://doi.org/10.5281/zenodo.XXXXXXX`)挂到 `papers/P2/manuscript.md` §A.5 (Data availability)
- �?DOI 链接也写�?cover letter §5

#### �?C:proofread R2 第二�?
```
目标文件:papers/P2/manuscript.md (~1219 �?
校验�?
1. 引用统一
   - 所�?"v1.0 §X" / "v1.1 §X" / "v1.3 §X" �?"v_final §X" 
2. §9.2 limitations
   - 不留 PENDING(全部云端 PASS,�?v1.3 NUM + task9 evidence)
   - 末行�?v1.4 (�?v1.3 NUM + task9 4-DEM evidence)
3. 5 处引用一致�?   - Author name (Yinggang Guo / 郭迎�?
   - ORCID (0000-0002-8207-9941)
   - Affiliation (Northwest Institute of Nuclear Technology, Xi'an 710024)
   - Email (fariel_gyg@163.com)
   - License (CC-BY-4.0 data + MIT code)
4. 双盲审准�?   - §Acknowledgements 留空(或写 "Removed for review")
   - 不要�?§A.1 提及 PI 名字以外的私有信�?5. 通读错别�?/ 标点 / 中英混排一致�?```

#### 验收标准(task10 verdict)

| �?  | 文件                        | 期望                                         |
| --- | ------------------------- | ------------------------------------------ |
| �?A | papers/P2/cover_letter.md | ~800-1000 �?7 段结构完�?                       |
| �?B | Zenodo deposit + DOI      | DOI 链接挂进 manuscript §A.5 + cover letter §5 |
| �?C | papers/P2/manuscript.md   | 引用统一 / 末行�?v1.4 / 5 处一致�?PASS              |

#### 严令(secretary-protocol)

- **Workbuddy 不下�?*:不写 cover letter / 不上�?Zenodo / 不改 manuscript �?- **Workbuddy 只验**:
  1. `papers/P2/cover_letter.md` 存在 + 长度 800-1000 �?  2. Zenodo DOI 链接挂进 manuscript §A.5
  3. manuscript 末行�?= `v1.4`
  4. commit hash (建议 3 commit,�?A/B/C �?1)
- **�?git push**(PI 18:22 push gate 永久,SciDA 投稿触发 push 解锁 1 �?

#### 完成�?
- INBOX §A STATUS=DONE + UPDATED �?current ts
- 末尾 verdict:PASS = �?A 文件存在 + �?B DOI 挂入 + �?C 末行�?v1.4
- git commit 3 �?local only):
  - `docs(cover): SciDA cover letter (任务 A)`
  - `chore(zenodo): upload GeoProofBench v0.1 + DOI 链接挂入(任务 B)`
  - `docs(proofrd): v1.4 终稿(任务 C)`
- OUTBOX 新增一�?`## SciDA 投稿冲刺(task10)`

**push gate 解锁说明**:SciDA 投稿 *即将* 解锁 push gate 第一�?�?*投稿�?* PI 拍板�?push�? 
不投�?= �?push。投�?= 解除一�?push�?
**20:39 升级**:push gate 触发点扩�?"FINAL-FORM" —�?SciDA 投稿/期刊接收/公开  
任一 + paper v_final 形态锁同时 = 解锁 1 �?push。仅任务完成�?= push�?
---


### A.9 task10.5–task14 串行�?· 主任�?本轮起跑)

**PI 20:39 二次拍板**:"先把 10.5 �?14 做完,先不考虑 github,等最终形态定再上�?  
�?5 任务串行投�?Cursor 可派子任务并�?�?A/B/C 风格),每段独立 commit�?
#### A.9.0 总体节奏(建议,Cursor 可调�?

```
task10.5 (~2-3 �? P-COMP-2 全平面闭�?     �?task11   (~1 �?    P-COMP-4 重采样同�?(upscale/downscale/旋转)
     �?task12   (~1 �?    P-COMP-5 元一�?算子相同输入相同输出
     �?task13   (~1 �?+)   真实 DEM 多样�?(LiDAR/IFSAR/3 套真实数�?
     �?task14   (~1-2 �?   v1.4 NUM 升级:task9/10.5/11/12/13 数据写进 §7.6 multires + diversity �?     �?(paper v_final 形态锁)
     �?(SciDA 投稿 / 期刊接收 / 公开) 任一 �?push gate 解锁 1 �?```

#### A.9.1 task10.5 · P-COMP-2 全平面闭�?
[step] 填洼 �?流域 �?**256² 全平�?*(整张图纯平面 0 起伏)�?**256² 行扰�?*(沿行  
�?ε �?{1e-6, 1e-4} 噪声)上验�?4 门控 + Wolfram 穷举�?256 cell  
[端]   本机(�?+ AutoDL(�?verify PCOMP_2.dfy 24/0 �?PCOMP_1 17/0 �?P006_T6 12/0)  
[新文件]  
formal/dafny/PCOMP_2.dfy  
formal/lean4/VeriGIS/Composition/PitFillingThenWatershedPlane.lean  
experiments/phase2/p_comp_2.py (256² 全平�?+ 256² 行扰�?  
experiments/phase2/results/gpb024_pcomp2\_*/{metrics,wolfram,verify}.{json,txt,log}  
[产出]  4 门控 PASS ×2 �?+ Wolfram 256² 穷举都收�?+ dafny 24/0 + lake 不依赖网格尺�? 
[验收]  gpb024_metrics.json gates 4 �?PASS;wolfram parsed=true  
[commit] feat(phase2): task10.5 P-COMP-2 全平面闭�?PASS (plane=256²/256² d=1e-6 �?收敛 e=4.5M cells, descent+fixed �?True)

---

#### A.9.2 task11 · P-COMP-4 重采样同�?(upscale / downscale / 旋转)

[step] 同一 DEM �?resolution 倍率 {0.5×, 1×, 2×, 4×} + 旋转 {0°, 45°, 90°} �? 
�?P-COMP-1:验证"算子在重采样/旋转下与原图结果�?�?ε_tol"(同伦�?homomorphism)  
[端]   本机(�?+ AutoDL(可�?dafny 不依赖分辨率)  
[新文件]  
formal/dafny/PCOMP_4_homotopy.dfy  (新增 �?证明同伦不变�?  
experiments/phase2/p_comp_4.py  
experiments/phase2/results/gpb025_pcomp4\_*/{metrics,wolfram,verify}.{json,txt,log}  
[产出]  resolution×rotation 矩阵 (4×3 = 12 cells) �?OK  
dafny PCOMP_4 �?17/0(引入"重采样算�?R_α : DEM �?DEM"作为参数化算�?  
[验收]  gpb025 row 12 cells 11 PASS + 1 cells FAIL-TOLERANCE 详记  
[commit] feat(phase2): task11 P-COMP-4 重采样同�?PASS (plane 重采�?旋转 12/12 (σ �?1e-6))

---

#### A.9.3 task12 · P-COMP-5 元一�?(metaproperty consistency)

[step] "同一输入 P-COMP-1 �?N 次结果相�?until floating-point order)" �?元性质:  
\- 幂等�?idempotent: f(f(DEM)) == f(DEM) (�?�?域上严格,�?容差 ε_tol)  
\- 输入顺序无关: 不同 tile/worker 调度结果�?�?ε_tol  
\- 同输入同输出跨语言: Python(numpy) �?Lean(合乐) �?Dafny(SMT) 三码 hash 一�? 
[端]   本机(�?+ AutoDL(�?verify Python↔Lean↔Dafny 一致�?hash)  
[新文件]  
formal/dafny/PCOMP_5_idempotent.dfy  
formal/lean4/VeriGIS/Composition/PitFillingIdempotent.lean  
experiments/phase2/p_comp_5.py  
experiments/phase2/results/gpb026_pcomp5\_*/{metrics,verify}.{json,log}  
[产出]  
Python/Lean/Dafny 三码 hash 一致表 (rows: 4 DEM × 3 code)  
dafny 15/0(幂等�?+ 输入无关�?  
lake build 0 errors (P006_T6 idempotent variant)  
[验收]  gpb026 hash 三码一�?+ idempotent×inputs 矩阵�?PASS  
[commit] feat(phase2): task12 P-COMP-5 元一�?PASS (Python↔Lean↔Dafny hash 12/12 一�? idempotent 4/4)

---

#### A.9.4 task13 · 真实 DEM 多样�?LiDAR / IFSAR / 3 �?

[step] �?3 套真实公开 DEM(至少 1 �?LiDAR + 1 �?IFSAR + 1 套公开 aerial photogrammetry):  
\- USGS 3DEP LiDAR(�?N34W119 LA, ~1m,1km²)  
\- IFSAR(�?Alaska SAR, 5m, 100km²)  
\- Copernicus DEM GLO-30(全球 1°×1° �?30m,公开)  
[端]   本机(下载 + 预处�?+ �?P-COMP-1 + manim 对比)  
[新文件]  
experiments/phase2/p_comp_realworld.py  
experiments/phase2/results/gpb027_realworld/{lidar,ifsar,copernicus}/metrics.json  
experiments/phase2/figures/RealWorldDiversity.mp4  
[产出]  3 套真�?DEM P-COMP-1 跑�?3 mp4 子图对比(ridgeline/drainage density/sink count)  
[验收]  3 metrics �?PASS + mp4 渲染 3 子图 + figure caption �?paper §7.7  
[commit] feat(phase2): task13 真实 DEM 多样�?PASS (USGS-LiDAR / IFSAR-AK / Copernicus 3/3)

---

#### A.9.5 task14 · v1.4 NUM 升级:task9/10.5/11/12/13 写进 paper §7.6

[step] �?task9 多分辨率 + 10.5 全平�?+ 11 同伦 + 12 元一�?+ 13 真实数据  
**写进** papers/P2/manuscript.md �?§7.6 multires + diversity + metaprop �? 
[端]   Workbuddy 不下�?Cursor 全责(PI 决定)  
[新文件]  
docs/PAPER_P2_v1.4_NUM.md  (SUPP 模式,�?v1.3 NUM)  
papers/P2/manuscript.md 改写 §7.6  
[产出]  
§7.6.1 task9 多分辨率(plane 9/3/3 / terrain-A 64516/98/351 / SRTM 12.95M/6.03M/28 / LiDAR 64516/20137/13)  
§7.6.2 task10.5 全平面闭�?+ 噪声扰动  
§7.6.3 task11 重采样同�?12 cells σ �?1e-6  
§7.6.4 task12 元一�?Python↔Lean↔Dafny hash 12/12  
§7.6.5 task13 真实 DEM 多样�?3/3 (USGS-LiDAR / IFSAR-AK / Copernicus)  
[验收]  paper §7.6.1-7.6.5 全有真实 data;末行�?v1.5  
[commit] docs(manuscript): v1.5 NUM 升级 (§7.6 multires+diversity 真实数据 5 �?

---

#### A.9.6 串行链约�?本轮铁律)

- **5 任务串行,不允许并发派**:任务链顺序约�?10.5 �?11 �?12 �?13 �?14  
  (理由:11 同伦�?10.5 全平面基�?12 元一致用 10.5/11 数据;14 整合 11/12/13)
- **每个 task 必须独立 commit**:每跑完一�?�?`INBOX §A STATUS = SEG<n>/PENDING` �? 
  Cursor �?OUTBOX 该段 + git commit �?下一段才能起�?- **不阻�?SciDA 11-15 投稿**:本轮 4 任务跑完 �?task14 写进 §7.6 �?paper v_final 形态锁  
  �?解锁 push�?*paper 投稿不依�?4 任务**;投完可继续在 revision 里加 task14 �?- **�?B Zenodo DOI** �?task10 BLOCKED 状态继续等 PI 操作(不阻�?
- **Workbuddy 不下�?*:不写 paper / 不改 .dfy / .lean / .py / .md 实质内容;  
  只动 INBOX/OUTBOX/cursorrules 三个协议文件 + 归档 commit

---

#### A.9.7 完成汇报格式(每段 1 �?

```
[task]      task<n> / �?X (1-line purpose)
[step]      详述实现路径
[cmd]       实际执行命令
[rc]        exit code
[key lines] 数行关键产出(文件路径/size/metrics/hashes)
[gates]     每条 gate PASS/FAIL
[verdict]   PASS / BLOCKED / FAIL
[blocker]   (�?BLOCKED/FAIL 时填)具体阻塞�?+ PI 拍板�?```

�?PASS �?commit + INBOX §A STATUS=SEG<n+1>/PENDING;全段 PASS �?STATUS=DONE�? 
�?BLOCKED �?�?commit,Cursor OUTBOX 自报阻塞�?Workbuddy 通知 PI�? 
�?FAIL �?Cursor 不自�?Workbuddy 看后帮派,�?PI 拍板换路�?�?
---


### A.10 paper 形态锁协议(PI 23:40 �?v1.5 = FORM LOCK)

**锁生�?*:2026-09-06 23:40 CST,PI 拍板「v1.5 = 形态锁」�?
**触发器矩�?FINAL-FORM push gate)**:

```
                    ┌──────────────────────�?                    �? FIRST  (已点�?23:40)�?                    �? paper v_final 形态锁 �?                    └──────────┬───────────�?                               �?AND (同时)
                    ┌──────────▼───────────�?                    �? SECOND (�?PI 操作) �?                    �? SciDA 投稿 / 接受   �?                    �? / 公开 任一          �?                    └──────────┬───────────�?                               �?两触发器都点
                    ┌──────────▼───────────�?                    �? push gate 解锁 1 �?�?                    �? (一次�?PI 拍板 push) �?                    └──────────────────────�?```

**锁定后铁�?*(forms lock protocol,违反�?red flag):

1. **paper v1.5 内容不再�?*:
   - `papers/P2/manuscript.md` / `papers/P2-geoproofbench/manuscript.md` 形态封�?   - 引用 / 段标�?/ § �?/ 表格 / 图表 caption / 末行版本签名不动
   - 唯一允许:错别�?/ 排版微调 �?5 �?/ �?�?task15 proofread R3 处理)
   - 大动 �?unlock 流程:PI 显式撤销形态锁 �?INBOX §A.10 LOCK-NOTE 反拍
2. **不放心的数字不加**(Honesty Protocol):
   - 任何数字必须能溯源到 `experiments/*/results/gpb*/metrics.json`
   - synthetic 数据(�?§7.6.1 SRTM/LiDAR synthetic)必须保留 caveat
   - FAIL-TOLERANCE 反例(�?§7.6.3 4/12)必须保留,不可洗白
3. **�?B Zenodo DOI**:
   - 现为 BLOCKED(PI 未上�?zip �?DOI)
   - task15 即可解锁:PI 上传 �?Cursor �?§A.5 + cover letter §5 挂真 DOI
   - DOI �?**不在** 形态锁�?可挂;格式 + place 不变即合�?
4. **第二触发器触发方�?*:
   - 投稿:PI �?manuscript 投到 SciDA editorial system 后回�?INBOX
   - 接受:期刊�?acceptance letter,PI 拍板"接受"
   - 公开:PI �?公开"(repo / arXiv / Zenodo 任一公开�?
   - 任一发生 �?秘书监控 push gate 即可解锁 �?一次�?`git push origin main`
5. **unlock 流程**(若必须改 paper):
   - PI �?"unlock v1.5 �?v1.6" 或指明改什�?   - �?�?末行�?v1.6 �?重新 Lock �?push 重新触发矩阵

**Cursor 接到�?INBOX 当前 STATUS=DONE-LOCKED**:

- [mailbox-noop] 规则触发 �?不要重复执行 task10.5..14
- �?INBOX §A status 改回 PENDING �?PI 触发新任�?典型:task15 DOI 补挂 / task16 proofread R3)
- 错进 OUTBOX 不动

**Workbuddy 监控钩子**:

- �?round:grep `STATUS: DONE-LOCKED` �?INBOX §A
- 同步检�?LOCK:行存�?若消�?�?red flag,提醒 PI
- push gate + 形态锁双条�?= 解锁 1 �?
---


### A.11 task16 · 第二�?P2「LLM 自动形式�?GPB 基准评测�?PI 2026-09-09 01:43 拍板)

**A.11.0 立项**

- **选题 A**:LLM 能否把地理算法规约自动转成可机器检验的 Dafny/Lean 规约?失败模式是什�?
- **闭环叙事**:P1「建基准」→ P2「用基准首次系统评测 AI 形式化能力边界�?- **AI for Math 硬标�?*:差异化在**地理算法特有结构**(网格遍历 / 浮点比较 / 拓扑不变�?/ 终止性度�?,  
  miniF2F / ProofNet 是纯数学,无人系统做过这块
- **目标期刊**:�?NeurIPS Datasets & Benchmarks / ICLR;�?JGSA / IJGIS
- **投稿 DDL**:2026-11-10(W9)

**A.11.1 本轮只做 W1(9/9�?/15)—�?设计 + 任务�?不跑模型**

交付�?4 �?缺一不可):

| # | 产物                            | 验收                                                        |
| - | ----------------------------- | --------------------------------------------------------- |
| 1 | `docs/P2_AIMATH/DESIGN.md`    | �?300 �?任务定义、模型清单、prompt 策略、指标、失败模�?taxonomy、统计方法、威胁有效�?  |
| 2 | `experiments/p2_llm/tasks/`   | �?21 个任务项 YAML(L1 单算�?+ L2 组合 + L3 反例),�?`formal/` 现有命题抽取 |
| 3 | `experiments/p2_llm/prompts/` | 3 �?prompt 模板:zero-shot / few-shot / repair               |
| 4 | `docs/P2_AIMATH/RISKS.md`     | API 成本、额度、可复现性、P1 返修撞期的对�?                                |

**A.11.2 任务�?schema**(每个任务�?

```yaml
id: GPB-xxx                    # 沿用 GPB 编号
difficulty: L1 | L2 | L3
target: dafny | lean
natural_spec: |                # 喂给 LLM 的输�?�?  <命题的自然语言规约,�?docs/phase2/PROP_CHAIN.md / formal 文件注释抽取>
reference_impl: experiments/phase1/xxx.py   # 喂给 LLM 的输�?�?gold_formal: formal/dafny/xxx.dfy           # �?不喂�?LLM,仅作评测基线
expected_verdict: PASS | NEG                # NEG = 反例类命�?应证�?
```

**A.11.3 难度分层**(�?benchmark 的核心设�?�?B 的科学问题装�?A 的实�?

| �?     | 内容                                                           | 题量  | 预期        |
| ------ | ------------------------------------------------------------ | --- | --------- |
| **L1** | 单算�?P-001..P-006(�?verify)                                   | ~13 | 高通过�?     |
| **L2** | 组合 P-COMP-1/2/4/5                                            | ~5  | �?        |
| **L3** | 反例 / neg-result(P-COMP-3、ring_terminated=False�?5° FAIL-TOL) | ~3  | �?且最易语义漂�?|

**A.11.4 模型清单(4 �?固定版本 + temperature=0 + k=5)**

建议 4 档覆�?1 个强推理(Claude Opus/Sonnet 5 �?�? �?GPT-5.x�? �?Gemini 3.x�? 
1 个国产低�?DeepSeek-V3 / Qwen-Max)�?*成本优先**:优先�?Cursor Pro 已有额度 + 低价 API,控制 k=5�? 
DESIGN.md 里写清每个模型的确切版本串与调用日期�?
**A.11.5 prompt 策略(3 档对�?**

- **P0 zero-shot**:�?natural_spec
- **P1 few-shot**:natural_spec + 1 �?*非同命题**的已验证 .dfy 样例
- **P2 iterative repair**:把编译器/验证器报错喂�?最�?3 �?
**A.11.6 指标(6 �?主指�?2 �?**

| 指标                         | 定义                                                                        |
| -------------------------- | ------------------------------------------------------------------------- |
| compile@1                  | 生成代码能否�?`dafny /compile:0` 解析 / `lake env lean` 解析                        |
| **verify@1** ★主            | 一次生成即通过机器检验的比例                                                            |
| **verify@3** ★主            | repair �? 轮后通过比例                                                          |
| repair gain                | verify@3 �?verify@1                                                       |
| **semantic fidelity** ★杀手锏 | 生成规约�?gold_formal 语义一致率;**单独报告 "verified but drifted"**(通过了验证但证明的不是原命题)比例 |
| failure taxonomy           | F1–F8 分布                                                                  |

> **semantic fidelity 是本 benchmark �?miniF2F/ProofNet 最大的差异�?*:  
> 形式化验证通过 �?证明对了命题。这是地理算�?浮点、网格、拓�?最易翻车处�?
**A.11.7 失败模式分类�?v0**(Cursor 可扩�?但不得删�?

| �?     | 类别                           |
| ------ | ---------------------------- |
| F1     | 语法 / 解析错误                    |
| F2     | 类型 / 签名错误                    |
| F3     | 前置条件缺失或弱�?                   |
| F4     | 循环不变式缺�?                     |
| F5     | 终止性度�?variant / decreases)缺失 |
| F6     | 浮点 / 数值语义错�?                 |
| **F7** | **语义漂移(通过验证但证明错命题)**         |
| F8     | 过度强化前提(把真命题证成平凡命题)           |

**A.11.8 诚实协议**(继承 P1 惯例,不可�?

- **不编造结�?*:跑不通记 FAIL,不给模型"擦屁�?
- 记录模型版本�?/ 调用日期 / temperature / prompt 模板 hash
- 全部 raw 输出�?`experiments/p2_llm/results/raw/`,可复�?- 已有反例资产(P-006b 4-环、ZT vs Horn�?5° FAIL-TOL)**不可洗白**

**A.11.9 自推进链(自动化核�?PI 01:43 要求"全程零点�?)**

```
W1/PENDING ──完成──�?Cursor 自改 STATUS: W2/PENDING ──watcher 自动调起──�?W2 �?                                    …�?W9/PENDING ──完成──�?STATUS: DONE
```

- **Cursor 职责**:每段做完 �?自己�?§A �?`STATUS:` 改成下一�?`W<n+1>/PENDING`  
  �?�?OUTBOX 新段 �?`git commit`(local,**�?push**)
- **watcher 职责**:本机计划任务�?5 分钟�?STATUS,�?DONE 且无 agent 在跑 �?自动调起 Cursor
- **PI 职责**:零。只在周�?异常时看一�?- **push gate**:P2 形态锁 + P2 投稿 双触发器齐备才解�?**W1–W9 期间一律不 push**

**A.11.10 汇报格式**(继承 §A.4)

```
## <段名>(task16-W<n>)
[task]      ...
[step]      ...
[cmd]       ...
[rc]        ...
[verdict]   PASS / FAIL / BLOCKED
[blocker]   (�?BLOCKED/FAIL 时填)
```

---


### A.12 · task16-W3.5 解阻双线(PI 2026-09-09 02:50 拍板)

**背景**:W2/W3 卡在同一个点 —�?本机出口访问不到 live LLM API:

```
code.newcli.com    �?ConnectTimeout ~42s
api.anthropic.com  �?HTTP 403 "Request not allowed"   �?注意�?403(通了但被�?,不是网络不�?```

W3 的离线部分已全过(schema 22/22、L1 14 题、prompt dry-validate 28/28),  
`run_l1_batch.py --require-live` 是唯一缺口�?*未编造任�?verify@ 数字,诚实协议保持�?*

#### A.12.1 �?1 · LLM API 端点可达性实�?先做,最高优先级)

**铁律:只报实测数字,不许臆测、不许凭印象下结论�?*

对每个候选端点做四层探测,逐项记录:

| �? | 检�?     | 记录字段                                                                           |
| -- | ------- | ------------------------------------------------------------------------------ |
| L1 | DNS 解析  | resolve_ok / resolve_ip / resolve_ms                                           |
| L2 | TCP 连接  | tcp_ok / tcp_ms                                                                |
| L3 | TLS 握手  | tls_ok / tls_ms / cert_cn                                                      |
| L4 | HTTP 探针 | http_status / http_ms / err_class(DNS/TCP/TLS/HTTP-403/HTTP-401/timeout/other) |

**候选端点清�?*(逐个实测,一个不�?:

| # | 端点                                                                   | 说明                                                                   |
| - | -------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1 | `https://api.anthropic.com/v1/messages`                              | 官方,当前 403                                                            |
| 2 | `https://openrouter.ai/api/v1/chat/completions`                      | 聚合,OpenAI 兼容,一�?key 通吃 Claude/GPT/Gemini                             |
| 3 | `https://api.siliconflow.cn/v1/chat/completions`                     | 硅基流动,国内直连,OpenAI 兼容                                                  |
| 4 | `https://api.deepseek.com/chat/completions`                          | DeepSeek,国内直连                                                        |
| 5 | `https://open.bigmodel.cn/api/paas/v4/chat/completions`              | 智谱 GLM                                                               |
| 6 | `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions` | 通义千问,OpenAI 兼容模式                                                     |
| 7 | `https://api.moonshot.cn/v1/chat/completions`                        | Moonshot/Kimi                                                        |
| 8 | 环境变量代理探测                                                             | 检�?`HTTPS_PROXY` / `HTTP_PROXY` / `ALL_PROXY` 是否已设;若已�?再测一�?#1 看是否解�?|

**�?key 时的处理**:不要因为�?key 就跳过�?*先做 L1–L3**(DNS/TCP/TLS 不需�?key),  
再加一�?*�?key �?L4 探针** —�?401/403 恰恰证明"可达"(被拒 �?不�?,�?timeout/DNS 失败  
证明"不可�?。这两类必须区分清楚,这是本次探测的核心价值�?
**产物**:

- `experiments/p2_llm/results/api_reachability.json` �?机器可读,每端�?4 层字段全记录
- `docs/P2_AIMATH/API_REACHABILITY.md` �?人读矩阵�?+ **推荐方案**(分级:  
  推荐 / 可用 / 不可�?,并明确写�?需�?PI 提供什�?(key / 代理 / 账号)

**门禁**:`rc=0` �?PASS(探测本身成功即达�?**不要求任何端点真的可�?*)�? 
探测�?全部不可�?也是有效结果,如实报�?
#### A.12.2 �?2 · 离线基建(不依�?API,与线 1 并行/串行均可)

目的:�?API 一通就能直接灌数据,不浪费等待窗口�?
| # | 交付�?                                                     | 验收                                                             |
| - | -------------------------------------------------------- | -------------------------------------------------------------- |
| 1 | `tests/test_scoring.py` �?`score_semantic.py` 单元测试       | 覆盖:编译失败 / verify 失败 / verify 通过但语义漂�?F7)/ 超时 / 空输�?�?8 case 全过 |
| 2 | `docs/P2_AIMATH/RESULT_SCHEMAS.md` �?结果表骨�?              | 主表(4 模型 × 3 prompt × 21 �?× k=5)列名 + 每列口径 + 空表 markdown 模板     |
| 3 | `docs/P2_AIMATH/ANNOTATION_MANUAL.md` �?失败模式标注手册         | F1–F8 每类�?�? 个真�?GPB 示例 + 判定规则 + 边界情况(多人标注一致性怎么保证)             |
| 4 | `experiments/p2_llm/harness/make_figures.py` �?图生成脚�?    | 输入结果 JSON,输出 4 �?难度分层柱图 / 模型对比 / repair gain 曲线 / 失败模式分布       |
| 5 | `experiments/p2_llm/harness/run_all_offline.py` �?一键离线自检 | �?fixture �?评分 �?出图,全链路不碰网�?rc=0                               |

**门禁**:5 项全交付 + 离线自检 rc=0 = PASS�?
#### A.12.3 自推进与回报

- 双线做完 �?�?§A STATUS 改成 `W3/PENDING`(**不是 W4**),�?watcher 重跑 W3 主实�?  
  若线 1 探测到可用端点且环境里有 key,�?*直接用该端点试跑 1 �?cell**(GPB-001-flat, P0, k=1),  
  拿到真实 API 响应�?STATUS �?`W3/PENDING` 并说�?已验证通路"�?- 若线 1 全不可达 �?STATUS 保持 `W3/BLOCKED-PI`,并在 OUTBOX 明确列出**需�?PI 提供的三选一**:  
  (a) 可用 base_url + key / (b) 代理地址 / (c) 改用某国产模型的决定�?- OUTBOX 新增�?`## LLM 自动形式�?GPB 基准 · W3.5 解阻(task16-W3.5)`,  
  �?`[task]/[step]/[cmd]/[rc]/[key lines]/[gates]/[verdict]/[blocker]`�?- 两段独立 commit:`feat(p2_llm): task16-W3.5a API 可达性实测` / `feat(p2_llm): task16-W3.5b 离线基建`�?
**绝对禁止**:编造任�?`verify@` / `compile@` 数字;�?fixture 结果当真实模型结果上�?  
修改 `papers/` 下任何内�?P1 形态锁);git push�?
---


### A.13 · task16-W3 解阻路径收窄(洛书 2026-09-09 23:1x 实测)

**实测补充(A.12.1 未覆�?ANTHROPIC_BASE_URL)**:

| �?                                  | 实测                                            |
| ----------------------------------- | --------------------------------------------- |
| `ANTHROPIC_BASE_URL`                | `https://code.newcli.com/claude`(Cursor 订阅网关) |
| DNS                                 | ok 18 ms �?118.193.240.41                     |
| TCP :443                            | **timeout 30 s** �?网络层不可达                     |
| 公共 DoH(dns.google / cloudflare-dns) | 全被�?timeout / RST)�?�?DNS 绕不�?                |
| `api.anthropic.com`                 | 维持 **403** �?业务层拒�?非网络故�?                     |

�?**A.12.1 的选项 (b)「配代理」无�?*:网关是出口限�?不是代理缺失),  
官方是账�?区域策略(代理不改账号)�?*实际只剩 (a) 国产 key / (c) OpenRouter 或改模型�?*

**新交�?�?commit)**:`experiments/p2_llm/harness/openai_compat.py`

�?harness 只认 Anthropic `/v1/messages` + `x-api-key`,**给了国产 key 也跑不了**;  
现新�?`--backend openai`,支持 siliconflow / deepseek / dashscope / zhipu /  
moonshot / openrouter 六个 OpenAI 兼容端点(`chat_url` 取自实测可达�?URL)�?
**PI �?key 后的解阻命令(一�?**:

```bash
export SILICONFLOW_API_KEY=...      # �?DEEPSEEK_API_KEY / DASHSCOPE_API_KEY / ...
cd experiments/p2_llm/harness
python run_l1_batch.py --backend openai --require-live --prompts P0,P1 --k 5
```

- provider 自动探测(有哪�?key 用哪�?;指定�?`export P2_LLM_PROVIDER=deepseek`
- 未显式给 `--model` 时自动套用该 provider �?`default_model`
- �?key �?明确 BLOCKED、`cells=[]`,绝不编�?verify@

拿到真实响应后按 A.12.3:STATUS �?`W3/PENDING`(或直接推�?W4),OUTBOX 新开段回报�?
**当前自检(�?key 环境,非模型结�?**:离线自检 `schema_ok=true` / `figures_n=4` /  
`n_live=0`;dry-run 22/22 tasks + 2/2 prompts PASS;`--backend openai --require-live`  
返回 BLOCKED �?`cells=[]`�?
**依赖提示**:harness 需�?`httpx` / `pyyaml` / `jsonschema`�? 
**�?`jsonschema` 会让 `schema_ok` 假性变 false**(不是任务 YAML 出错),排查时先查依赖�?
---


### A.13 · task16-W3 解阻后全量跑指令(PI 2026-09-09 23:2x 拍板)

**PI 两项决定**:(1) provider = **硅基流动 siliconflow**;(2) **直接全量�?*,不做单模型试跑�?
> **触发方式(PI 真正零点�?**:PI 只需执行一条命令设�?User 环境变量  
> `[Environment]::SetEnvironmentVariable("SILICONFLOW_API_KEY","sk-...","User")`�? 
> `gate.ps1` �?5 分钟从注册表�?provider key,**一旦读到就自动解除 `BLOCKED-PI`**  
> 并把 key 注入 agent 及其 python 子进�?—�?PI 不需要改 STATUS、不需要告诉我、不需要开 Cursor�?
#### A.13.1 第一�?确认模型阵容(必做,别猜模型�?

硅基流动一�?key 可调用多个开源模型�?*先探测真实模型清�?不许凭记忆写模型�?*:

```bash
curl -s https://api.siliconflow.cn/v1/models -H "Authorization: Bearer $SILICONFLOW_API_KEY"
```

从返回里�?**4 �?*组成阵容,选型原则(写进回报,说明理由):

| 槽位 | 要求                        | 目的              |
| -- | ------------------------- | --------------- |
| M1 | 当前最强通用开�?�?DeepSeek-V3 �? | 上界参照            |
| M2 | 另一家主�?�?Qwen �?72B+)      | 跨系列对�?          |
| M3 | 中等规模(�?GLM-4 / 32B �?     | 规模效应            |
| M4 | 带推�?长思维�?�?R1 �?          | 检�?推理增强是否利于形式�? |

- 若某槽位在硅基流动上不可�?�?从实测清单里�?并在回报写明替换理由�?- 模型名写�?`experiments/p2_llm/harness/openai_compat.py` �?`default_model`(如已有则确认一�?�?
#### A.13.2 第二�?L1 全量�?
```bash
export P2_LLM_PROVIDER=siliconflow
cd experiments/p2_llm/harness
python run_l1_batch.py --backend openai --require-live \
       --models M1,M2,M3,M4 --prompts P0,P1,P2 --k 5
```

- **规模**:L1 14 �?× 4 模型 × 3 prompt × k=5( repair 轮对失败�?�? �?�?DESIGN.md 口径)
- **断点续跑**:`run_l1_batch.py` �?resume-safe;中断后重跑同一条命令即可跳过已完成 cell,  
  **不要�?results 目录重来**
- **原始输出全留�?*:每个 cell 的原�?LLM 响应必须�?`experiments/p2_llm/results/raw/`,  
  一条不�?—�?这是可复现性与"失败模式标注"的唯一依据

#### A.13.3 熔断(必设,别把额度烧穿)

| 条件                                | 动作                                    |
| --------------------------------- | ------------------------------------- |
| 单模型连�?10 �?HTTP �?2xx             | 停该模型,�?`PROVIDER_ERROR`,继续其余模型        |
| 累计花费超预算上�?你先按单价估一�?写进回报)          | 停跑并回�?�?PI 拍板                         |
| 某模�?compile@1 = 0 且连�?20 cell 全失�?| 停该模型,判定�?该模型不具备本任务能�?(这是**有效结论**,如实�? |
| 跑完 �?80% cells                    | 允许以部分数据出中间报告,标注 `partial`             |

#### A.13.4 第三�?验证 + 评分(不依�?API)

```bash
python run_verify.py --all          # dafny / lean 双轨机器检�?python score_semantic.py --all      # �?F7 语义漂移判定
python make_figures.py              # �?4 �?```

**核心指标口径**(一个都不能�?尤其是最后一�?:  
`compile@1` / `verify@1` / `verify@3` / `repair gain` / **semantic fidelity**  
(**单独统计 "verified but drifted"** —�?机器检验通过了但证明的不是原命题,这是�?benchmark 的差异化指标)

#### A.13.5 自推进与回报

- L1 全量 + 验证 + 评分全部完成 �?STATUS �?`W3.6/PENDING`(**写作为先**,�?§A.14;  
  W4 组合层实验押�?—�?ICLR 摘要 9/18 是硬 deadline,实验可以后补)
- �?key 仍不可用 �?STATUS 保持 `W3/BLOCKED-PI`,OUTBOX 写明缺什�?- OUTBOX 新增�?`## LLM 自动形式�?GPB 基准 · W3 全量主实�?task16-W3-live)`,  
  必须包含:**每个模型的真�?compile@1 / verify@1 / semantic fidelity 数字**(不是"跑通了")
- commit:`feat(p2_llm): task16-W3 L1 live 全量主实验`

**绝对禁止**:编造任�?`verify@` / `compile@`;�?fixture �?dry-run 结果当真实模型结�?  
�?key 写进任何文件;修改 `papers/` 下内�?P1 形态锁);git push�?
---


### A.14 · task16-W3.6 论文起草(PI 2026-09-10 00:1x 拍板 �?写作为先)

> **⚠️ 关键背景修正**:秘书此前给的�?1/10 投稿」是�?9 周倒推�?**未对齐真�?deadline,作废**�? 
> **ICLR 2027 真实节点:Abstract 2026-09-18 AOE / Full paper 2026-09-25 AOE�?*  
> 今天 9/10 —�?摘要只剩 **8 �?*,全文只剩 **15 �?*�?
#### A.14.1 路线(PI 拍板:先冲摘要,数据不够就转期刊)

| 时点       | 动作                                                                         |
| -------- | -------------------------------------------------------------------------- |
| 现在       | 起草 §1–�?(不依赖数�?                                                            |
| **9/16** | **决策�?*:检�?W3 真实数据是否到位 �?够就�?abstract �?ICLR;不够就转期刊路线(TGIS/IJGIS),不再�?ICLR |
| 9/18     | 若继�?�?ICLR abstract                                                        |
| 9/25     | 若继�?�?ICLR full paper                                                      |
| 10 月中    | **无论如何**:arXiv 预印�?锁定青C 所需�?preprint 状�?                                   |
| 11 �?    | �?ICLR 未投/被拒:投期�?                                                          |

#### A.14.2 现在就写(不依赖任何实验结�?材料已全部定�?

�?`papers/P2_aimath/`,LaTeX 优先(ICLR 模板),同步留一�?md:

| �?                  | 内容                                                                                                                                | 素材来源(已定�?                                           |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| §1 Introduction     | 动机:地理算法规约 �?机器可检验规约的自动化难�?为什么现�?benchmark(miniF2F/ProofNet)覆盖不到                                                                   | `docs/P2_AIMATH/DESIGN.md`                          |
| §2 Related Work     | 自动形式�?/ 数学 benchmark / 程序合成的验�?/ **差距:地理算法特有的浮点、网格遍历、拓扑不变式**                                                                      | DESIGN.md §related                                  |
| §3 Benchmark Design | GPB 21 命题 + L1 单算�?/ L2 组合 / L3 反例三层 + 任务�?schema + gold 规约为何 withholding                                                         | DESIGN.md + `experiments/p2_llm/tasks/`             |
| §4 Methodology      | harness 架构 + 3 �?prompt(P0/P1/P2)+ 5 指标口径(**compile@1 / verify@1 / verify@3 / repair gain / semantic fidelity**)+ Dafny+Lean 双轨检�?| `experiments/p2_llm/harness/` + `RESULT_SCHEMAS.md` |

**§5 Results / §6 Failure Taxonomy / §7 Discussion 留占�?*,等真实数�?—�?一个数字都不许编�?
#### A.14.3 ICLR 2027 硬性格�?必须遵守)

- 主文 **�?9 �?*(讨论�?camera-ready 放宽 10 �?;参考文献与附录**不限�?*
- **双盲**:全文不得出现作者身份。引用本项目�?P1(Sci Data Data Descriptor)�? 
  **必须第三人称**,�?"a concurrently submitted data descriptor [N]" —�?不得�?"our prior work"
- **强制 AI use statement**(不计页数):如实说明 agent 参与了实�?实验执行/文稿起草;  
  作者对所有内容负全责。这一节本项目必须�?且要写得坦荡
- 所�?submission(含被�?撤稿)**永久公开署名**
- 主题自查:ICLR 2027 �?"datasets and benchmarks" �? 
  "neurosymbolic & hybrid AI systems (logic & formal reasoning)" —�?**与本题对�?要在 cover/intro 里点�?*

#### A.14.4 自推�?
- §1–�? 起草完成 �?STATUS �?`W3.7/PENDING`(等数据灌 §5),  
  不要直接�?W4 —�?�?9/16 决策�?PI 拍板
- OUTBOX 新增�?`## P2 论文起草 §1–�?(task16-W3.6)`,说明每章多少行、用了哪些素�?- commit:`docs(p2_aimath): task16-W3.6 draft sections 1-4 (methods, no results claimed)`

**绝对禁止**:编造任何结果数�?�?§1–�? 里暗示已有实验结�?�?key 写进文件;  
�?`papers/P2`(P1 形态锁);git push�?
---

## §A.15 · PI 拍板:投稿目标锁定 KBS(2026-09-10 00:2x)

PI 决定:**第二篇唯一投稿目标 = Knowledge-Based Systems**(Elsevier)。不要再为其�?期刊�?framing 变体。STATUS 与自推进链不�?W3 继续 �?W3.6 写作)�?
### A.15.1 期刊事实与时间表
- KBS:IF 8.0(2026 JCR);中科院大�?*计算机科�?1 �?Top**;小类计算�?人工智能 2 �?
  JCR Q1;**混合�?订阅制免�?*(Gold OA 可�?非必�?。年发文 ~1952�?- 时间�?现在起草 �?**10 月中�?arXiv**(锁定青C 需要的 preprint 状�?�?**11 月投 KBS**�?- 兜底:�?KBS �?2027-01 前被�?�?转投 IEEE Access(�?4 周出结果,仍赶得上青C
  2027-02/03 提交)�?*期刊必须串行�?严禁同时多投**(学术不端)�?- ICLR 2027(摘要 9/18 AOE、全�?9/25 AOE、决�?12/16)保留�?*可�?*:仅当 9/16 决策�?  W3 数据确实漂亮时才投摘�?不为此牺�?KBS 版本质量�?
### A.15.2 framing 硬约�?决定 KBS 成败,必须逐条遵守)
KBS �?AI 期刊,不是 GIS 期刊。审稿人默认问的�?这对我理�?改进 AI 系统有什么用"�?1. **地理 = 测试�?testbed),不是卖点**。禁止写�?我们提出一个地理算法基�?�?   正确 framing:可验证的形式化规�?verifiable formal specification)是一�?   **被现�?autoformalization benchmark 系统性忽略的规约形�?*——它同时要求数学正确�?   与可执行/可机器检验�?我们�?DEM 地形分析算法作为采样域来实例化这一类�?2. **核心卖点 = semantic fidelity**�?通过机器检�?�?证明了原命题"是普适的 AI 结论,
   对一�?autoformalization / code-generation 评测都成立。必�?单列指标、单列表�?   ("verified but drifted" 单独统计)、abstract �?conclusion 各点名一次�?3. Related Work 必须覆盖三条�?缺一条会被判相关工作不足:
   - LLM autoformalization(Lean/Coq/Isabelle、miniF2F、ProofNet、LLM 辅助 Dafny 验证)
   - code generation benchmark 方法�?HumanEval/MBPP �?pass@k;本文 compile@1 /
     verify@1 / verify@3 �?pass@k �?形式�?维度的类�?要显式点出这个谱系关�?
   - 评测中的 specification gaming / reward hacking / test-passed-but-wrong 文献
     (semantic fidelity 直接接这条线,这是它最有分量的落点)
4. 引用 P1 数据集给 DOI **10.57760/sciencedb.011r9**;正文用第三人�?�?   "Guo et al. [n]"),**不要�?"our prior work"**�?
### A.15.3 格式(�?Cursor 拉取 KBS 官方 Guide for Authors 核实,不许凭记忆写)
必须亲自核实:页数/字数上限、模�?Elsevier 通用 elsarticle 还是 KBS 指定)、参考文�?格式、图表与附录规则、是否需�?highlights / graphical abstract / CRediT 声明�?若官方无硬页数限�?�?**正文 12�?6 �?不含参考文献与附录)** 掌握。核实结果写�?OUTBOX�?
### A.15.4 W3 全量实验执行约束(针对 2026-09-09 23:37 agent 被杀、输出全丢的事故)
1. **必须 checkpoint**:每完成一�?(model × prompt-level) 组合,立即把结�?append �?   `experiments/p2_llm/results/raw/l1_full_<ts>.jsonl`�?*不要等全部跑完才落盘**�?2. **断点续跑**:重启时先读已�?jsonl,跳过已完�?cell,不重复烧 token�?3. **分批**:单次 agent 调用不要试图一次跑�?840 cells;按模型分�?每批结束�?OUTBOX
   写一行进�?已完�?总数 + 当前真实数字片段)�?4. 任何时刻被中�?已落盘数据不得丢失、不得重跑、不得编造补齐�?
## §A.16 · 紧�?verify 工具链缺�?主实验核心指标正在空�?2026-09-10 00:5x)

### A.16.1 观察到的硬事�?秘书巡检实测,非推�?
`experiments/p2_llm/results/raw/l1_full_w3_live.jsonl` 每一条都�?
```
"verify_status": "TOOLCHAIN_MISSING", "compile_rc": null, "verify_rc": null,
"semantic": "VERIFY_SKIPPED", "metric_eligible": false
```
API 确实通了(DeepSeek-V3.2,prompt 260 / completion 740 tokens,`est_spend_usd_cum`
在涨),但生成的 `.dfy` **一个都没被验证**�?
**后果**:这一轮跑完只能出 compile@1,**出不�?verify@1 / verify@3 / semantic fidelity**�?semantic fidelity �?§A.15.2 定的头条卖点,没有�?KBS 版本就没有核心贡献。不可接受�?
#### 假阳性警�?00:55 实测,别被它骗�?
jsonl 里出现过 1 �?`metric_eligible: true`,但它�?**`"status": "SKIP_EXISTING"`**
(复用了旧文件、直接跳�?,�?`compile_rc` / `verify_rc` **均为 null**,
`verify_status` 仍是 `TOOLCHAIN_MISSING`�?*这不是验证通过,是判定逻辑的漏洞�?*
同一时刻的真实分�?19 �?`TOOLCHAIN_MISSING`,**0 条真�?verify**�?�?必须�?`metric_eligible` 的判�?只有 `verify_status` 为真实验证结�?(�?`TOOLCHAIN_MISSING` / �?SKIP �?、且 `compile_rc` �?`verify_rc` 均非 null
时才允许�?true�?*在真实验证数�?positive 之前,不许宣布 W3 完成�?*

### A.16.2 立即执行(按优先级)
1. **修好 Dafny 工具�?不许�?TOOLCHAIN_MISSING 糊过�?*:
   - 先探�?`dafny /version`;Windows 本机没有或路径错 �?�?**WSL2 Ubuntu �?     Dafny 4.11**(已验证可�?,�?`wsl -- bash -lc "dafny ..."` 调用�?   - 修完必须�?*证据**:贴一条真�?`dafny verify` 命令 + 完整输出 + exit code�?2. **不要停掉正在进行的生�?*:已落盘的 `.dfy` 是资�?继续生成不影响后续补验�?3. **�?离线补验"通道(关键)**:�?`harness/verify_backfill.py`,扫描
   `results/raw/*.dfy`,对未 verify 的逐条�?`dafny verify`,�?`compile_rc /
   verify_rc / verify_status / semantic` 回填�?`l1_full_w3_live.jsonl`,
   `metric_eligible` �?true�?*补验不调�?LLM,不花钱�?*
4. **分批 + 超时保护**:单次 agent 调用不要超过�?3 小时(计划任务硬上�?4H,
   超时被杀会留孤儿�?;�?(model × prompt_level) 分批,每批结束�?OUTBOX 写进度行�?   若可�?对同一 cell �?k 个样本并发请求以缩短总时长�?5. WSL 也不可用 �?�?AutoDL(�?`docs/autodl-playbook.md`):打包 `.dfy` 上传,
   云端批量 verify 后取回�?*任何情况下不许跳�?verify�?*

### A.16.3 冷启动恢�?宿主 2026-09-10 00:5x 关机,agent 被强杀)
明早开机后**先做这三�?再继续生�?*——顺序不能反(否则继续空转�?token):
1. **�?verify 工具�?*(A.16.2 �?1 �?——这是第一优先�?不是"有空再说"�?   �?`metric_eligible` 能转 true 之前,**不要启动新的大批量生�?*�?2. **校验被中断的 jsonl**:`l1_full_w3_live.jsonl` 最后一行可能因强杀而残缺�?   逐行 parse,截断到最后一条完�?JSON,不完整的另存 `*.jsonl.bak` 备份�?3. **对账再续�?*:比对 `raw/*.dfy` �?jsonl �?`raw_source` 字段—�?   - �?`.dfy` �?jsonl 无记�?�?补登�?**不要重新生成**;
   - 有记录但 `.dfy` 缺失�?0 字节 �?只重跑这一�?cell�?   **严禁清空 results/ 重开**。已生成�?`.dfy` 是花钱买来的资产�?
### A.16.4 verify 通道已探�?秘书 2026-09-10 15:5x 实测,可直接照�?不必再摸�?
**根因确认**:宿主�?Windows **根本没有 dafny**(`dafny --version` �?`command not found`),
这就�?`TOOLCHAIN_MISSING` 的来源�?
**可用通道**:WSL2 `Ubuntu-22.04` 里有 **Dafny 4.11.0**,路径 `/usr/local/bin/dafny`�?
**已实测通过的调用模�?*(路径含空格与中文,`cd` 目标必须用双引号包裹):
```
wsl -- bash -lc 'cd "/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/experiments/p2_llm/results/raw" && dafny verify <file>.dfy 2>&1 | tail -12'
```
**实测输出**(昨夜生成的真实产�?非玩具样�?:
```
GPB-001-flat__deepseek-ai_DeepSeek-V3.2__P2__k0__r0.dfy
Dafny program verifier finished with 1 verified, 0 errors
```
建议:�?harness 里封�?`run_dafny_wsl(dfy_path)`,�?Windows 路径
(`E:\...`) 转成 WSL 路径(`/mnt/e/...`),内部走上面的 `wsl -- bash -lc`,
解析输出里的 `N verified, M errors` 并回�?`compile_rc / verify_rc /
verify_status / semantic`�?
### A.16.5 诚实红线
- 不许�?`TOOLCHAIN_MISSING` 计入通过;不许在论文里写任何未经真�?verify �?  verify@ / semantic fidelity 数字�?- 若最终确有子集无法验�?必须�?OUTBOX 明确列出"哪些子集有真�?verify、哪些没�?,
  论文只报有真实结果的部分并声明限制�?
## §A.17 · 加�?瓶颈是串行等�?不是算力(秘书 2026-09-10 23:5x 实测)

PI 问「能否用 AutoDL 算力加速」�?*答案是不�?而且不需要�?* 以下是实测数�?
不要再去折腾上云�?
### A.17.1 时间构成的实测分�?�?cell �?46 �?

| 环节 | 实测耗时 | 占本地算�?|
|---|---|---|
| `dafny verify` 单个 .dfy(WSL,含启�? | **3 �?* | 全部本地 CPU |
| WSL 子系统冷启动 | ~0 �?已热) | �?|
| 其余(等远�?LLM �?token) | **~43 �?* | **本地 CPU �?0%** |

命令与输�?秘书实测,非推�?:

```
$ wsl -- bash -lc 'cd ".../results/raw" && dafny verify <file>.dfy 2>&1 | tail -3'
  12 resolution/type errors detected in ...dfy
  耗时: 3 �?```

**本地算力只占 6%�?4% 的时间本地在�?HTTP 响应�?* AutoDL �?GPU/CPU 无法加�?硅基流动机房里的推理 —�?这是 IO 等待问题,不是计算问题�?
### A.17.2 真瓶�?harness 零并�?
```
grep -rn "concurrency|parallel|ThreadPool|max_workers|--jobs" harness/*.py
�?0 命中
```

`run_l1_batch.py` 是四层嵌�?for(model �?task �?prompt �?sample)全串�?
`openai_compat.py` 用同�?`httpx.Client(timeout=180.0)`,一次只飞一个请求�?
### A.17.3 要做�?并发请求(本机即可,零成�?不要上云)

写一�?**`harness/run_l1_batch_pool.py`**(新建文件,**不要�?* `run_l1_batch.py`,
当前 M3 批次还在�?:

1. �?`concurrent.futures.ThreadPoolExecutor`,默认 `--workers 8`,可调�?   这是 IO 密集,线程池足�?**不要用多进程**�?2. **复用** `run_cell()` 的单元格逻辑与既有的 resume / skip-existing 判定,
   不要重写生成与校验语义�?3. jsonl 写入必须**单线程聚�?*(主线程收 future 结果后统一 append)或加�?
   禁止多线程直接写文件�?4. �?429 / rate limit 做指数退�?1s�?s�?s,上限 30s),退避后重试同一 cell;
   连续 3 �?429 就把 `--workers` 自动降到 4,再不行降�?2,并在 OUTBOX 记录�?5. verify 阶段**保持串行或小并发(�?)**即可 —�?它只�?3 �?并行收益为零,
   反而会�?WSL �?CPU�?
### A.17.4 上线前的验证(不可跳过)

先用 `--limit 2 --workers 8` 跑一个小样本,**与串行版已产出的�?cell 结果对照**,
确认三件事再放开全量:
- 生成�?.dfy 内容一�?并发没有污染 prompt / 温度 / seed)
- jsonl 每行 JSON 完整可解�?没有并发写坏�?
- `metric_eligible` 判定与串行版一�?
验证不通过就不要切,继续用串行版跑完�?
### A.17.5 预期收益与边�?
- �?M3 + M4 �?420 cells:串行 5.4 小时 �?8 路并发约 **40 分钟**�?- 并发后单批更�?**反而更安全**:计划任务�?4 小时硬上�?串行容易中途被杀�?- 若实�?429 频繁到必须降 workers �?,说明并发收益被限流吃�?那就回到串行,
  不要硬撑�?
### A.17.6 AutoDL 仅在这两种情况才考虑(现在都不�?

1. **要补 Lean 通道�?* —�?本机�?WSL 都没�?lake/Lean,�?M2 �?Lean 目前�?   `TOOLCHAIN_MISSING`。若 PI 决定�?Lean,那时才需要开 AutoDL�?2. **离线回填规模上千** —�?当前 267 �?.dfy 串行回填 3 �?�?= 13 分钟,不值得上云�?
### A.17.7 顺带提醒(不是指令,是观�?

`completion_tokens` 打满 4096 的比�?DeepSeek 1%(4/424)、Qwen 2%(4/206)�?**GLM 2/2** —�?GLM 才跑 2 条样本不足以下判�?但请�?M3 跑完后统计一�?
�?GLM 普遍打满说明输出�?`max_tokens` 截断,会导致人为的低通过�?
那就要调 `max_tokens` 或改 prompt,否则结论不成立�?
### A.17.8 重跑会覆盖旧记录,正在吃掉稀有事�?秘书 00:1x 统计时发�?

统计口径:jsonl �?717 �?但按 `(model, task_id, prompt_id, sample_index)` 去重�?**只有 484 个唯一 cell** —�?多出来的 233 行是重跑/补跑,�?*后来者覆盖了前�?*�?
代价是实打实�?按行统计�?`VERIFIED_BUT_DRIFT_SUSPECT` �?**4 �?*,去重取最后一条后
**只剩 1 �?*�? �?drift 样本被重跑抹掉了。�?drift 是本论文的头条指�?(semantic fidelity 的全部证�?,丢一个就少一个�?
要做�?不改语义,只改持久�?:
1. 记录�?`attempt` 字段(同一 cell 的第几次尝试),唯一键变�?   `(model, task_id, prompt_id, sample_index, attempt)`�?2. **append-only**:重跑追加新行,不覆盖旧行�?3. 统计脚本一�?*按唯一 cell 取最后一�?*算最终指�?同时**单独报一�?   「全部尝试」口�?*,两者的差异要在 OUTBOX 里写�?—�?这个差异本身就是诚实性的证据�?4. 已有 717 行不要动,不要试图回填 attempt(�?0 开始即�?�?
另外,去重后的当前基数报给 PI �?`compile_rc=0` 25 条、`verify_rc=0` 18 条�?RAN 300 条、`VERIFIED_BUT_DRIFT_SUSPECT` 1 条�?*论文里任何数字都必须注明�?「按唯一 cell 去重」还是「按全部尝试」�?*

## §B · 协议与档�?只读)

### B.1 优先级与新情�?
- 17:21 PI �?git 远端操作 �?本地 commit 仅本地不 push,实验完一次性上�?- 17:24 PI 轮换 autoDL SSH 密码 �?新真值存 `autoDL登录信息.txt`(.gitignored,�?77)
- 18:13 PI 提醒 Cursor 完工失声 �?已装 user-level sentinel skill
- 18:18 PI �?下一步干�? �?task7.5(task7.5 已是 PENDING)+ task8A(P-COMP-3 反例)**并行�?*
- **18:22 PI 升级 push gate:** **实验完成 + 论文发出之前,任何 commit �?push �?GitHub**�? 
  这是 17:21 决定的强化版 —�?�?本机 commit �?push"现在�?一�?commit �?push,直到论文终稿定型"�? 
  论文 �?实验 �?公众号文�?�?arXiv preprint �?期刊投稿 �?接收后才一次性同�?GitHub�? 
  Cursor 由此可以毫无顾忌地调源码、不用在 push 上踩刹车�?- **目标优先�?18:22 重申):** 尽快完成实验 �?写论�?�?发论�?  - 实验: P-001..P-006 / P-COMP-1..N / P-005..P-006 T6 云端复核(当前 task7.5 + task8A)
  - 论文: docs/PAPER_P2_OUTLINE.md v1.0+(洛书自管)+ 实验部分�?Cursor 提供原始数据
- **不要把新密码写进仓库、脚本、OUTBOX 回传**


### B.2 任务历史(只读,以后每完成一段归档到这里)

- **task6(2026-09-06 17:38-17:48,STATUS=CLOSED)** = P-005 云端复核 + P-006 流域唯一
- **task7(2026-09-06 18:08-18:10,STATUS=CLOSED LOCAL)** = P-COMP-1 + �?6 �?本机�?- **task7.5(2026-09-06 18:15-18:30,STATUS=CLOSED LOCAL+云端)** = P-COMP-1 + T6 形式化云端复�?- **task8A(2026-09-06 18:20-18:42,STATUS=CLOSED)** = P-COMP-3 反例素材 (NEGATIVE-RESULT PASS)
- **task9(2026-09-06 19:42-20:13,STATUS=CLOSED)** = 多分辨率迁移 5×5 �?256² �?3601² �?LiDAR; commit `6a54d4c` (plane 9/3/3; terrain-A 64516/98/351; SRTM 12.95M/6.03M/28; LiDAR 64516/20137/13)
- **task9.5(2026-09-06 19:49-20:13,STATUS=CLOSED)** = paper v_final 整合 (v1.0+v1.1+v1.3 �?papers/P2/manuscript.md); commit `cedfa77`
- **task10(2026-09-06 20:24-20:35,STATUS=BLOCKED-DOI)** = SciDA 投稿冲刺 (�?A cover_letter PASS c31981e / �?B Zenodo DOI PENDING-PI / �?C proofread R2 v1.4 PASS 29f1529);push 解锁�?PI 上传 zip + 拿真�?DOI
- **task10.5(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = P-COMP-2 全平面闭�?256² + 256² noise
- **task11(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = P-COMP-4 重采样同�?resolution×rotation 12 cells
- **task12(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = P-COMP-5 元一�?Python↔Lean↔Dafny hash 一�?- **task13(2026-09-06 20:39-PENDING,STATUS=ACTIVE)** = 真实 DEM 多样�?USGS-LiDAR + IFSAR + Copernicus 3/3
- **task14(2026-09-06 20:39-23:45,STATUS=LOCKED)** = v1.5 NUM 升级:task9/10.5/11/12/13 �?paper §7.6;PI 23:40 �?v1.5 = FORM LOCK 触发第一触发�?- **task15(2026-09-09 01:37,STATUS=CLOSED)** = 28 commits 一次�?push(d6bcaae..c2a5000),FINAL-FORM 双触发器已消�?远端 GitHub 同步完成
- **task16(2026-09-09 01:43-PENDING,STATUS=ACTIVE)** = 第二�?P2「LLM 自动形式�?GPB 基准评测�?W1 设计 �?W9 投稿 11/10;**本机自动化已部署**(Cursor headless CLI + INBOX watcher + 计划任务�?5 min),PI 零点�?
### B.3 触发�?`.cursorrules` `[mailbox]` 规则契约)

- Cursor session 启动时自�?`Read` 本文�?- STATUS=PENDING �?执行 §A
- STATUS=DONE/CLOSED �?不动
- 改本文件只能由洛�?Cursor 不改 INBOX 优先�?约束/直终�?
