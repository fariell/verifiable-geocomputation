# Phase 2 范围 · Verifiable Geocomputation

> **本文件定义 Y0-Y2 阶段性 phase 2 的范围、出口、与 Phase 1 的边界**。  
> 起草:Luoshu,2026-09-06。落仓前 PI 拍板。



---

## 1. 一句话定位

**Phase 1 = 算子层(每个算子单独成立);Phase 2 = 组合层(算子之间的组合命题成立);Phase 3 = 系统层(智能体自动发现新命题,飞轮启动)。**

Phase 2 是连接「算子独立可证」与「智能体可发现」的桥梁,核心交付是**把已证的孤立命题  
组合成二阶命题**,并把"组合命题如何机器检验"这一方法学本身做出范式。

---

## 2. 与路线图 + 三层资产的对位

| 层     | 资产    | Phase 1 产出                | **Phase 2 产出**                  | Phase 3                  |
| ----- | ----- | ------------------------- | ------------------------------- | ------------------------ |
| L1 流量 | 论文    | —                         | **P2 旗舰论文**(GeoProofBench v0.1) | P0 纲领 + P4 GeoMath-Agent |
| L2 壁垒 | 基准    | GPB-001..020(50 候选中已种 20) | **GPB-021..099**(组合命题族 + 一阶扩展)  | GPB-100..300 v1.0        |
| L2 壁垒 | 库     | VeriGIS.Plane, .D8(7 模块)  | **VeriGIS.Composition**(组合/传递性) | VeriGIS.Auto(智能体调用)      |
| L2 壁垒 | 排行榜   | GPB-019 slope 一项          | GPB-019..099 全榜(60+ 项)          | 全榜 + 自动化更新               |
| L3 复利 | 标准/SI | —                         | —                               | OGC/ISO 提案草案             |

**最重要的**:Phase 2 的 L1 论文 P2 才是 Y0 末必须投稿的"可见度资产"(roadmap Y0 验收:  
1 篇 online + 2 篇 under review + 3 篇预印本)。Phase 1 的产出只是 P2 的素材。

---

## 3. Phase 2 五条候选命题(先选 5 条做样板,再扩到 30+)

| 内部 id        | 内容                                       | 涉及 P-                          | 候选 GPB- |
| ------------ | ---------------------------------------- | ------------------------------ | ------- |
| **P-COMP-1** | 填洼 + D8 ⇒ 无 flat 环 + 流域出口唯一              | **P-002**(填洼)+ **P-006**(流域唯一) | GPB-021 |
| P-COMP-2     | 填洼 + 流向恒定 ⇒ 全网格每格轨道终止于唯一出口               | P-002 + P-005 平面恒定 + P-006     | GPB-022 |
| P-COMP-3     | Horn 二次精确 + ZT 剖面 ≠ 平面曲率任一 ⇒ 两者不可互推      | P-003 + P-004                  | GPB-023 |
| P-COMP-4     | 半径 r 可视域 ⇒ 半径 2r 可视域 ⊇ 点集(单调)            | 新算子 viewshed                   | GPB-024 |
| P-COMP-5     | 平面 resampling ⇒ slope = 0 仍成立(P-002 弱同伦) | GPB-018 已被种                    | GPB-025 |

**P-COMP-1 是 Phase 2 的旗舰**:它把 P-002(已证)+ P-006(在证)组合成一条新的  
"先填洼,再做流域分析"的工业流水线规范,且**用机器检验证明这条流水线端到端可用**。  
已在 `docs/TASK6_BRIEF.md` §二 后段以"与 P-002 的连贯"形式首次出现。

---

## 4. 完成判据(Phase 2 退出标准)

- [ ] **5 条组合命题**全套 GPB 名 + Dafny + Lean + .py/.wl + README + manim(沿用 P-006 七件套模板)
- [ ] P-COMP-1 在 Lean / Dafny 双轨通过(`lake build` + `dafny verify`,双 PASS)
- [ ] README 中明确"在 GPB-021 之上还能成立的更高阶命题"列出 **≥3 条**
- [ ] `experiments/phase2/` 目录骨架完成(README + run_phase2.sh + verify_all.sh 新增钩子)
- [ ] L1 论文 P2 的 §7 Method 与 §8 Experiments 部分可以用 P-COMP-1 当叙事主线填实
- [ ] 不引入新外部依赖(只用 Lean/Dafny/numpy/manim/wolframscript 与 Phase 1 同栈)

---

## 5. 不做什么(护栏)

- ❌ **不并入新算子**(viewshed/contour 等独立算子留到 Phase 3;Phase 2 只用 P-001..P-006 已存在的算子做组合)
- ❌ **不动 LLM/智能体训练**(Phase 2 不写 agent,智能体飞轮是 Phase 3 的 Y2 任务)
- ❌ **不扩张到矢量/点云/时空**(vision.md 明确死守 DEM)
- ❌ **不与他人方法做对比实验**(本方向无他人可比,Y0-Y2 不要假装对比)

---

## 6. 排期骨架(2026-09 → 2027-06)

| 月份      | 关键产物                          | 负责人                  |
| ------- | ----------------------------- | -------------------- |
| 2026-10 | P-COMP-1 Lean/Dafny 骨架        | PI 主导,Cursor 走 inbox |
| 2026-11 | P-COMP-1 README + manim + .py | Cursor               |
| 2026-11 | **P2 论文投稿 Scientific Data**   | PI + 洛书              |
| 2026-12 | P-COMP-2/3/4/5 补全             | 多轮 inbox             |
| 2027-01 | GPB-021..099 提名,排行榜上线         | PI 审定                |
| 2027-03 | under review 返修 + Phase 3 设计  | PI 主导                |
| 2027-06 | Phase 2 闭环文档 + 移交             | 洛书                   |

---

## 7. 关键交叉引用

- `docs/vision.md` — 三层资产结构 + "不做什么"护栏
- `docs/roadmap.md` — Y0-Y7 路线图 + 12 课题分布
- `benchmark/problems/v0.1.md` — 已种 GPB-001..020,本 phase 把 50 候选往 300 推
- `docs/TASK6_BRIEF.md` §二 — P-COMP-1 的数学动机首次在此出现
- `papers/TEMPLATE.md` — P2 论文投稿模板(落仓路径:`papers/P2-geoproofbench/`)
- `papers/README.md` — 论文命名 P0/P1/P2/P3/P4 + C1/L*

---

*Phase 2 v0.1 占位 · 2026-09-06 · 待 PI 审定*
