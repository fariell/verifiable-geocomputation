# 命题链回顾 · PROP_CHAIN_RETRO · Phase 1 实际产出

> Phase 1 实际形成的命题链与设计原案的差量。Luoshu 起草,2026-09-06。
> 与 `docs/phase2/PROP_CHAIN.md`(前瞻)对称为本回顾。

---

## 1. 设计预期的链 vs 实际跑出的链

### 1.1 设计原案(`benchmark/problems/v0.1.md` + R10 大纲)

- **G** 坡度算子 15 条 → 关键 GPB-001 (slope ≥ 0),GPB-019 (Horn 一致性)
- **C** 曲率算子 8 条 → 关键 GPB-003 (aspect 正交), GPB-007 (抛物峰剖面)
- **H** 水文分析 15 条 → 关键 GPB-010 (D8 pit), GPB-015 (流域唯一)
- **V** 可视域 7 条(留待 P-COMP-4)
- **D** 变化检测 5 条(留待 Phase 3)

### 1.2 实际落地(M3 sprint 已闭合 + P-006 在闭合)

```
GPB-019 一致性基线        ╱═════════════╗
                                   ║
P-001 = GPB-001 slope 非负 ╌╌╌╌╌╌╌╌╌╝══════════╗
                                          ║
P-002 = GPB-021 填洼(1D)╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╝ ╌╌╌╗
                                          ║ ║
P-002-bis 2D 填洼 ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╝  ║
                                ┌──╮           ║  ← P-COMP-1 已在前瞻中
                                ▼  ▼           ║
P-003 = GPB-003 剖面曲率 ZT(回收 Phase 1 错模板)║
                                │              ║
P-004 = GPB-019 Horn 二次精确 ─┘              ║
                                │              ║
                                │ (D8 8 路核) ║
                                ▼              ║
                          P-005 = GPB-010 D8 8 路 ║
                                            ║
                                ┌──╮           ║
                                ▼  ▼           ║
P-006 = GPB-015 流域唯一(在闭合)╌╌╌╌╌╌╌╌╌╌╌╌╌╌╝
                          (+ GPB-021 在前瞻)
```

**主线**:slope → pit-fill → D8 → watershed。**意外收获**:`experiment.py`
里被错标的 ZT 模板在 P-003 被回收(详见 README §三"是发现,不是 bug")。

---

## 2. 命题链上的关键设计决策

### 2.1 D8 核复用(P-005 → P-006)

- 设计:`p005_d8` 写一次,P-006 直接 `import p005_d8`(**TASK6_BRIEF §四 E1**)
- 实际:**Cursor 已落地**,P-006 七件套现含 `from p005_d8 import D8_kernel`
- 价值:Phase 2 P-COMP-1 可继续 import 不复制;9 条命题可共用一份核

### 2.2 Lean 与 Dafny 独立重述(经验 E4)

| 命题 | Lean 模块 | Dafny 文件 | 验证器差异 |
|---|---|---|---|
| P-001 SlopeNonneg | `VeriGIS.Plane` | `P001_dafny.dfy` | Dafny 19/0;Lean (待补,占位)|
| P-002 填洼 | `VeriGIS.PitFilling` | `P002_2d.dfy` | Dafny 24/0;Lean ✅ |
| P-002-bis 2D | `VeriGIS.PitFilling2D` | (同人 P-002 序章)| Dafny 19/0;Lean ✅ |
| P-003 ZT Hessian | `VeriGIS.HessianZT` | `P003_curvature.dfy` | Dafny 52/0;Lean ✅ |
| P-004 Horn 二次 | `VeriGIS.Consistency` | `P004_consistency.dfy` | Dafny 22/0;Lean ✅ |
| P-005 D8 | `VeriGIS.D8Scores` | `P005_d8.dfy` | **本机 18/0 + 17:38 CST 云端 PASS** |
| P-006 流域 | `VeriGIS.Watershed` | `P006_watershed.dfy` | 本机 OK,云端 pending |

### 2.3 失败案例与"显式标注"原则

- **P-006b flat 4-环反例**:`experiments/phase1/p006_watershed.wl` 显式构造
  4-环,D8 不终止。**这是"没证什么"资产**,写进 `P006_README.md` 与 P2 论文 §9.3。
- **经验 E1**:SMT 不喜递归扫描 → P-005 八路分数显式比较,避免搜索不动点
- **经验 E3**:`sqrt` 是超越函数 → 用平方比较规避
- **经验 E8**:`.gitignore` 行尾注释失效 → 已修

---

## 3. 跨命题组合(Phase 2 起,Phase 1 已有雏形)

| 已有组合 | 出处 | Phase 2 走向 |
|---|---|---|
| D8 核被 P-005 写一次、P-006 直接 import | 实验代码 import 链 | 推 P-COMP-1 复用同样 import 方式 |
| 抛物面 ZT(hxx+2k≈0)既是 P-003 验证对象,也是 P-004 对照 | prop 层的隐含对偶 | 可成 P-COMP-3 反例素材:"不可互推" |
| GPB-019 一致性作为所有算子命题的"对照用例" | 评分机制 | Phase 2 给每条 P-COMP-N 做同样的对照 |

---

## 4. 与 P2 论文 §7.3 (Operator-level) 段对位

论文在撰写 §7.3 Operator-level propositions 时,**直接引用**本文件 + 6 份
`formal/dafny/P00X_README.md`,**不重写**。这是 §7 与 §5 同时能收紧的关键:
方法与引言都建立在"机器可验证账本"之上,而不是 PI 的人话复述。

具体引用顺序:

1. §7.3.1 GPB-001 + P-001(坡度非负)— 论文首例,引"算子独立可证"概念
2. §7.3.2 P-002 + P-002-bis(填洼)— "链"的物质基础,从 1D 到 2D
3. §7.3.3 P-003 + P-004(剖面曲率对照)— "回收错模板"的发现时刻
4. §7.3.4 P-005(D8 8 路)— 水文线起点
5. §7.3.5 P-006(流域唯一)— 链的当前顶点,同时给 §7.4 Composition 留口子

---

## 5. 已闭合 arc 的金句(论文 §5 直接抄)

> "从零起步,六个月时间在算子层证明 6 条命题:它们各自独立成立、机器可检验、
>  其中一条(P-003)甚至回收了一类生产代码里的静默数值错误。这件事本身就是
>  可验证空间计算范式的合法性证明。"

> "更关键的是它们**连得起来**:填洼 ⇒ 流域唯一成立,二阶命题可证。
>  这是 Phase 1 已经埋下的 Phase 2 引信。"

---

## 6. 关键交叉引用

- `docs/phase2/PROP_CHAIN.md` §2 — P-COMP-1 在 Phase 2 的展开
- `docs/phase2/SCOPE.md` — Phase 2 整体定位
- `experiments/phase1/README.md` — 现行目录索引
- `formal/dafny/P00X_README.md` × 6 — 单台账
- `docs/EXPERIMENT_PLAYBOOK.md` §四 — 经验 E1..E10
- `docs/TASK6_BRIEF.md` §四 — P-006 七件套模板(给 P-COMP-1 复用)

---

_v0.1 占位 · 2026-09-06 · P-006 闭合后 v1.0(届时填 commit hash 与云端 PASS 时间戳)_
