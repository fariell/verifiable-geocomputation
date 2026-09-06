# Phase 1 回顾 · SCOPE_RETRO

> Phase 1 实际达成 vs 设计目标的对照回顾。本文件在 Phase 1 即将闭合(P-006 云端 PASS 之后)  
> 时回顾,Luoshu 起草,2026-09-06。  
> 与 `docs/phase2/SCOPE.md` 对称;后者是前瞻,本文件是回顾。



---

## 1. 一句话定位

**Phase 1 = 算子层**:在五类 DEM 算子(坡度 / 坡向 / 曲率 / 山体阴影 / 流向 / 流域等)  
中**先证 6 条孤立命题**(P-001..P-006),同时把 GeoProofBench v0.1 的 20 条候选命题  
种子集种下,作为 Phase 2 组合层与 Phase 3 智能体层的不可压缩基底。

---

## 2. 设计目标 vs 实际交付

| 设计目标(`phase1/README.md` §目标) | 计划                     | 实际交付                                                                          |
| ---------------------------- | ---------------------- | ----------------------------------------------------------------------------- |
| 1. 算子可复现性(闭式导数 + FD 对比)      | GPB-019,dx∈{4,2,1,0.5} | ✅ **GPB-019 ENTRY: PASS** 10:41 CST,slope_r=0.99994,曲率 corr(dx=1)=0.157       |
| 2. GeoProofBench 20 命题种子     | M3 子集                  | ✅ `experiments/phase1/results/geoproofbench_v0.1_batch1.json`(20 条 G/C/H/V/D) |
| 3. Lean 4 工具链冒烟              | elan 装通                | ⚠️ elan 下载超时跳过;在 WSL2 / AutoDL 重做                                             |

| 设计目标(P-001..P-006 路线) | 计划 | 实际交付                                           |
| --------------------- | -- | ---------------------------------------------- |
| P-001 slope 非负        | ✓  | ✅ Dafny 19 verified / 0 errors                 |
| P-002 填洼(1D)          | ✓  | ✅ Dafny 24/0;Lean `Built VeriGIS.PitFilling`   |
| P-002-bis 填洼(2D)      | ✓  | ✅ Dafny 19/0;Lean `Built VeriGIS.PitFilling2D` |
| P-003 剖面曲率 ZT         | ✓  | ✅ Dafny 52/0,**回收 Phase1 错误模板**                |
| P-004 Horn 二次精确       | ✓  | ✅ Dafny 22/0;Lean `Built VeriGIS.Consistency`  |
| P-005 D8 8 路分数        | ✓  | ✅ Dafny 本机 18/0 + **17:38 CST 云端复核 PASS**      |
| P-006 流域唯一            | ✓  | ⏳ 本机七件套到位,云端 verify pending(Cursor 收尾中)        |

---

## 3. 设计判断的命中与偏差

### 3.1 命中 ✅

- **合成 DEM + 闭式导数**:验算机制天然可达,所有 P-00X 双轨通过
- **numpy + 可选 wolframscript**:依赖脆弱不影响主体,本机 0 故障跑完
- **Lean 与 Dafny 独立重述**:**未发生翻译偏差**(经验 E4 反复有效);P-002 复用 P-001 lemmas 不重写
- **D8 核复用**:**P-005 → P-006 走通 import 而非复制**(TASK6_BRIEF §四 E1 印证)

### 3.2 偏差 ⚠

- **`pushd` 收尾**:本机 commit `c829c44` (`feat(formal): P-005 D8 8-way scores (local Dafny 18/0)`)  
  在落到 origin 之后被 PI 推回云端 verify,造成"本机干了一半就在 origin"的轻度分裂;  
  经验:大命题云端验前,**先 commit 本机,再 push + 云端验,不要先云端后 push**
- **曲率 corr=0.157 不是 bug,是发现**(REPORT.md §三):用以证实研究纲领的必要性
- **elan 下载 270 MiB 卡点**:用 `.crdownload` 续传方案修(参见今日 memory)

---

## 4. 与 Phase 2 的对接点

| Phase 1 产物                        | Phase 2 复用方式                                      |
| --------------------------------- | ------------------------------------------------- |
| P-002 填洼                          | P-COMP-1 的左操作符(详见 `docs/phase2/PROP_CHAIN.md` §2) |
| P-005 D8 8 路                      | P-006 + P-COMP-1 的算子后端(import 不复制)                |
| P-006 流域唯一                        | P-COMP-1 的右操作符                                    |
| `propositions.py` 20 命题           | Phase 2 提至 30+ 条(GPB-021..025 已草在 `SCOPE.md` §3)  |
| `formal/dafny/P00X_README.md` × 6 | Phase 2 P2 论文 §7.3 直接引用,不重写                       |

---

## 5. Phase 1 → 移交清单

PI 与洛书确认 Phase 1 闭合后,以下动作一并执行:

- [ ] `c829c44` 从「待云端验」推到「PASS」
- [ ] `this-week.md` 截止到本周 P-006 PASS 时,刷到 v1.6
- [ ] `docs/phase1/REPORT.md` 重新写一遍,**覆盖 P-001..P-006 全 arc**(本 SCOPE_RETRO 是新版骨架)
- [ ] `papers/PAPER_P2_OUTLINE.md` §7/§8 实写时可调用本回顾作为数据基线
- [ ] 把 phase1 转入"维护模式",不再频繁 commit,只修 Lean / Dafny 兼容性回归

---

## 6. 关键交叉引用

- `experiments/phase1/README.md` — 现行索引(目录索引 + 三个入口)
- `experiments/phase1/REPORT.md` — 旧版早期报告(**待覆盖**)
- `formal/dafny/P00X_README.md` — 6 条命题机器化账本
- `docs/EXPERIMENT_PLAYBOOK.md` §四 — 10 条经验(E1..E10)出处
- `docs/phase2/SCOPE.md` — 接下来一阶段的对照前瞻
- `docs/phase2/PROP_CHAIN.md` — P-COMP-1 = 本 phase 产物的"组合方向"

---

*v0.1 占位 · 2026-09-06 · 闭合后 v1.0(届时记录实际 commit hash 与云端 PASS 时间戳)*
