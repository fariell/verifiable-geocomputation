# P2 · LLM 自动形式化 GeoProofBench 基准评测 · W1 设计文档

> **论文工作名**: Can LLMs Auto-Formalize Geospatial Algorithms?  
> **选题**: A（PI 2026-09-09 01:43 拍板）  
> **阶段**: W1 设计 + 任务包（本文件）；**不跑模型**  
> **闭环叙事**: P1「建基准」→ P2「用基准首次系统评测 AI 形式化能力边界」  
> **主投**: NeurIPS Datasets & Benchmarks / ICLR；备 JGSA / IJGIS  
> **投稿 DDL**: 2026-11-10（W9）  
> **版本**: W1.0 · 2026-09-09 · Cursor task16-W1

---

## 0. 一页纸摘要

本基准回答一个可证伪的问题：

> 给定地理算法的自然语言规约 + 参考实现，当前 LLM 能否产出可被 Dafny / Lean
> 机器检验的形式化规约与证明？失败落在哪些结构上？

与 miniF2F / ProofNet 的差异化不在「再做一个数学题库」，而在**地理算法特有结构**：

1. 规则网格上的遍历与邻接（D8 / 4-邻）
2. 浮点比较与容差语义（ε_tol、FAIL-TOLERANCE）
3. 拓扑不变式（流域唯一、出口集合）
4. 终止性度量（`decreases` / WellFounded / 鸽笼）
5. **阴性结果**（反例 as feature：环不终止、ZT ⇏ Horn、45° 旋转超容差）

**主指标**: `verify@1`、`verify@3`；**杀手锏指标**: `semantic fidelity`
（含单独报告 *verified but drifted*）。

本周（W1）只交付设计与任务包；W2 基建；W3–W5 主实验；W6–W7 撰写；W8–W9 投稿。

---

## 1. 研究问题与假设

### 1.1 主研究问题（RQ）

| ID | 问题 |
|---|---|
| RQ1 | LLM 在 L1 单算子命题上的 `verify@1` 是否显著高于 L2/L3？ |
| RQ2 | iterative repair（≤3 轮）对 `verify@3 − verify@1` 的增益在哪一层最大？ |
| RQ3 | *verified but drifted*（F7）在地理结构命题上是否显著高于纯代数命题？ |
| RQ4 | few-shot 非同命题样例是否降低 F3/F4/F5，或反而引入模板漂移？ |

### 1.2 工作假设（可被数据推翻）

- **H1**: L1 通过率 > L2 > L3（难度分层有效）。
- **H2**: F5（终止性度量）与 F6（浮点语义）是地理特有高发失败模式。
- **H3**: L3 反例题上，模型更易「洗白」阴性结果（F7/F8），而非正确构造反例 witness。
- **H4**: repair 提升 compile@* 多于 semantic fidelity（修编译 ≠ 修语义）。

### 1.3 非目标（W1–W9 明确不做）

- 不训练 / 不微调模型权重。
- 不声称「某模型已能替代形式化工程师」。
- 不修改 P1 已 FORM-LOCK 的 SciDA manuscript（`papers/P2/manuscript.md`）。
- 不把未跑通的结果写成 PASS（Honesty Protocol）。

---

## 2. 任务定义（Benchmark Task）

### 2.1 输入（喂给 LLM）

每个任务项 YAML 提供两类**仅输入**：

1. `natural_spec`: 自然语言规约（从 `docs/phase2/PROP_CHAIN.md` 与 `formal/**` 头注释抽取）
2. `reference_impl`: 参考实现路径（Python / 已有 driver），只读，用于理解算子行为

可选（few-shot 档）:

3. 一个**非同命题**的已验证样例外泄（见 §5），不得是本任务 `gold_formal`

### 2.2 输出（模型应生成）

- 目标语言为 `target: dafny | lean` 之一。
- 完整可解析文件：函数 / lemma / theorem 签名 + 证明体（可含 `assume` 则记 F8 风险）。
- 不得要求模型「只写伪代码」。

### 2.3 隐藏基线（绝不喂给模型）

- `gold_formal`: 仓内已验证的 `.dfy` / `.lean` 路径
- 评测时用于：编译/验证对照 + semantic fidelity 比对

### 2.4 期望裁决

| `expected_verdict` | 含义 |
|---|---|
| `PASS` | 应证明正向命题（机器检验通过且语义对齐） |
| `NEG` | 应构造反例 / 否定式（如 `zt ≠ horn`、环无不动点）；「证成永真」记 F7 |

### 2.5 Schema（与 INBOX A.11.2 对齐）

```yaml
id: GPB-xxx
difficulty: L1 | L2 | L3
target: dafny | lean
natural_spec: |
  <自然语言规约>
reference_impl: experiments/...
gold_formal: formal/...
expected_verdict: PASS | NEG
# 扩展字段（W1 加入，便于 W2 harness）
prop_family: P-001 | P-002 | ... | P-COMP-n
lemma_hint: <可选, 不喂模型, 仅 harness 日志>
notes: <ID 碰撞 / caveat>
```

### 2.6 GPB 编号诚实说明

历史原因导致 **填洼种子层** 与 **Phase2 组合命题** 曾共用 GPB-021/022/023 号段
（见 `formal/dafny/P002_README.md` vs `experiments/phase2/p_comp_*.py`）。
本基准任务包采用：

- **文件名**唯一：`experiments/p2_llm/tasks/<id>.yaml`
- YAML `id` 字段与文件名一致；冲突处用后缀消歧（例：`GPB-021-fill-mono` vs `GPB-021-pcomp1`）
- `notes` 字段写明历史撞号，避免论文表格误读

---

## 3. 难度分层（核心实验设计）

| 层 | 内容 | 题量目标 | 科学意图 |
|---|---|---|---|
| **L1** | 单算子 P-001..P-006 已 verify 引理 | ≥13 | 基线能力；预期高通过率 |
| **L2** | 组合 P-COMP-1/2/4/5 | ≥5 | 前提传递 / import 组合 |
| **L3** | 反例 / neg-result | ≥3 | 语义漂移与「洗白」压力测试 |

W1 交付 **22** 个任务项（L1=14, L2=5, L3=3），满足 ≥21。

### 3.1 L1 覆盖矩阵

| 家族 | 代表性质 | 目标语言分配 |
|---|---|---|
| P-001 Horn 坡度 | 平坦为零 / 非负 / 平面精确 | dafny + lean |
| P-002 填洼 1D | 单调 / 非降 / 幂等 | dafny + lean |
| P-002-bis 2D | RaiseNbr 单调 | dafny |
| P-003 ZT 曲率 | 二次精确 / Laplacian≤0 | dafny + lean |
| P-004 相容性 | 二次精确 / 三次 O(w²) | dafny |
| P-005 D8 | 洼地无流 / 平面恒定 | dafny + lean |
| P-006 流域 | BasinUnique / 严格下降终止 | dafny + lean |

### 3.2 L2 覆盖矩阵

| ID | 命题 | 关键义务 |
|---|---|---|
| GPB-021-pcomp1 | 填洼 ⇒ 流域唯一 | 组合前提 (i)–(v)，不复制核 |
| GPB-022-pcomp2 | 全平面闭包 | 大网格数值端 + 形式化尺寸无关 |
| GPB-025-pcomp4 | 重采样同伦 | R_α；不含 45°（45° 进 L3） |
| GPB-026-pcomp5 | 幂等 / 元一致 | Fill∘Fill = Fill |
| GPB-021-pcomp1-lean | 同命题 Lean 重述 | 双轨一致性 |

### 3.3 L3 覆盖矩阵（不可洗白）

| ID | 阴性资产 | 正确行为 |
|---|---|---|
| GPB-023-pcomp3 | ZT ⇏ Horn | 给 witness，`expected_verdict: NEG` |
| GPB-015b-ring | P-006b 4-环无不动点 | 证明环后继永不终止 |
| GPB-025-rot45 | 45° FAIL-TOLERANCE | 报告超容差，不改标 PASS |

---

## 4. 模型清单（4 档，固定协议）

> PI 未在 W1 钉死商业版本串时，采用下表**候选钉扎**；W3 首次调用当日把
> 响应头里的真实 `model` 字段回写本表「锁定串」列，并记入 raw JSON。

| 档 | 角色 | 候选版本串（W1） | 调用约束 |
|---|---|---|---|
| M1 | 强推理 | `claude-sonnet-4-20250514`（Cursor Pro 额度优先） | temperature=0；k=5 |
| M2 | 通用强 | `gpt-5-2025-08-07`（或账户当日最新 GPT-5.x 锁定串） | temperature=0；k=5 |
| M3 | 长上下文 | `gemini-2.5-pro` | temperature=0；k=5 |
| M4 | 国产低价 | `deepseek-chat` / DeepSeek-V3 锁定串 | temperature=0；k=5 |

### 4.1 采样与种子

- 每任务 × 每模型 × 每 prompt 档：最多 **k=5** 独立采样（同一 temperature=0 时若 API 仍非确定，保留 seed 字段）。
- 主表报告：`pass@1` 用第 1 样本；`pass@k` 用 k 次或的上界（论文方法节写清）。
- **禁止**根据验证器反馈人工改模型输出再记 PASS（那是 repair 档的正式流程，须记录轮次）。

### 4.2 成本控制原则

1. 优先消耗 Cursor Pro / 已有额度。
2. L1 全量 × 4 模型 × 3 prompt；L2/L3 若预算紧，可先 M1+M4 全量，M2/M3 抽样（须在 RISKS 与论文 Limitations 声明）。
3. 单任务 token 上限：输入 ≤ 8k tokens；repair 累计 ≤ 24k。

### 4.3 可复现元数据（每条 raw 必含）

```json
{
  "task_id": "GPB-001-flat",
  "model": "<locked string>",
  "call_date": "YYYY-MM-DD",
  "temperature": 0,
  "prompt_id": "P0|P1|P2",
  "prompt_template_sha256": "<hex>",
  "sample_index": 0,
  "repair_round": 0,
  "raw_text": "...",
  "compile_rc": null,
  "verify_rc": null
}
```

落盘目录：`experiments/p2_llm/results/raw/`（W3+ 写入；W1 只建空目录占位）。

---

## 5. Prompt 策略（3 档对比）

模板文件：

| 档 | 文件 | 内容 |
|---|---|---|
| P0 zero-shot | `experiments/p2_llm/prompts/P0_zero_shot.md` | 仅 natural_spec + 输出格式约束 |
| P1 few-shot | `experiments/p2_llm/prompts/P1_few_shot.md` | + 1 个非同命题已验证样例 |
| P2 repair | `experiments/p2_llm/prompts/P2_repair.md` | 验证器 stderr 回灌，最多 3 轮 |

### 5.1 Few-shot 样例选择规则（防泄漏）

- 样例命题家族 ≠ 当前 `prop_family`。
- 样例不得来自同一 `gold_formal` 文件。
- L3 任务的 few-shot **不得**给「如何洗白反例」的正面证明样例；可给另一 L1 代数引理。

### 5.2 Repair 协议

1. Round 0：按 P0 或 P1 生成。
2. 若 compile 失败 → 把完整报错（截断至 4k chars）填入 P2。
3. 若 compile 过但 verify 失败 → 同样回灌。
4. 最多 3 轮；仍失败记 `verify@3=0`，保留最后一轮 taxonomy。

### 5.3 系统约束（所有档共用）

- 使用精确算术 / `real` 或 `int` 按 gold 风格；禁止静默改成浮点「近似证明」。
- 禁止 `assume` 主定理结论；若出现，判 F8。
- Dafny：可 `include` 已有模块，但**不得**粘贴 gold 全文。
- Lean：可 `import VeriGIS.*` 已有模块，同样禁止粘贴 gold。

---

## 6. 评价指标（6 个）

| 指标 | 定义 | 角色 |
|---|---|---|
| compile@1 | 第 1 次生成可被 `dafny /compile:0` 或 `lake env lean` 解析 | 辅助 |
| **verify@1** | 一次生成即 `dafny verify` / Lean 通过 | ★主 |
| **verify@3** | repair ≤3 轮后通过 | ★主 |
| repair gain | verify@3 − verify@1 | 诊断 |
| **semantic fidelity** | 与 gold 语义一致（见 §6.1） | ★杀手锏 |
| failure taxonomy | F1–F8 分布 | 解释 |

### 6.1 Semantic fidelity 操作化

对「verify 已通过」的样本，人工+规则联合判定：

1. **签名对齐**: 主定理/lemma 名称与量化结构是否对应 gold（允许改名，不允许改命题方向）。
2. **前置条件**: 是否弱化 / 删除关键 `requires`（弱化 → F3 或 F7）。
3. **结论方向**: PASS 题不得证成否定；NEG 题不得删掉反例只证平凡真。
4. **几何语义**: 网格邻接、出口、曲率符号约定是否与 reference 一致。

输出三类互斥标签：

- `faithful` — 通过且语义对齐
- `verified_but_drifted` — 通过但漂移（计入 F7）
- `not_verified` — 未通过（再标 F1–F6/F8）

**论文必须单独成表报告 drifted 比例**——这是相对 miniF2F 的核心卖点。

### 6.2 统计方法（预注册级）

- 主比较：难度层 × prompt 档 的 verify@1 / verify@3（Wilson 区间）。
- 模型间：同一任务配对，McNemar 或 bootstrap（任务为聚类单位）。
- 多重比较：预先指定主检验 =「L1 vs L3 的 verify@1 差」；其余为探索性。
- 效应量：风险差 + 比值比；样本量小则以描述统计 + 置信区间为主，不硬宣称 p 黑客。

### 6.3 分层报告模板（W5 填数）

```
           | compile@1 | verify@1 | verify@3 | drifted | n
L1 × P0    |           |          |          |         |
L1 × P1    |           |          |          |         |
L1 × P2    |           |          |          |         |
L2 × …     |           |          |          |         |
L3 × …     |           |          |          |         |
```

---

## 7. 失败模式分类学 v0（F1–F8）

| 码 | 类别 | 地理算法典型触发 |
|---|---|---|
| F1 | 语法 / 解析错误 | 括号、缩进、Lean tactic 拼写 |
| F2 | 类型 / 签名错误 | `real` vs `int`、Grid 维数 |
| F3 | 前置条件缺失或弱化 | 丢掉 `w > 0`、丢掉无洼前提 |
| F4 | 循环不变式缺失 | 填洼扫描、stepN 归纳 |
| F5 | 终止性度量缺失 | 无 `decreases` / 无 WellFounded |
| F6 | 浮点 / 数值语义错配 | 把 ε_tol 证成恒等；忽略 O(w²) |
| **F7** | **语义漂移** | 通过验证但命题已换 |
| F8 | 过度强化前提 | 只在常数 DEM 上证「定理」 |

### 7.1 扩充规则

- Cursor / 标注者可**新增子类**（如 F6a 容差、F6b 符号约定），但**不得删除** F1–F8。
- 每条失败样本可双标（主类 + 次类），论文主图用主类。

### 7.2 标注流程（W4–W5）

1. 自动：compiler/verifier 出口 → 建议 F1/F2。
2. 半自动：diff 对 gold 的 AST/关键词 → 建议 F3/F7/F8。
3. 人工：剩余样本；争议由 PI 抽检 10%。

---

## 8. 评测 Harness 设计（W2 实现，W1 定接口）

### 8.1 目录约定

```
experiments/p2_llm/
  tasks/*.yaml
  prompts/P0_*.md P1_*.md P2_*.md
  harness/                 # W2
    run_generate.py
    run_verify.py
    score_semantic.py
  results/
    raw/                   # 模型原文
    scored/                # 指标 JSON
```

### 8.2 验证命令（与 P1 一致）

```bash
# Dafny
dafny /compile:0 <generated.dfy>          # compile@*
dafny verify <generated.dfy>              # verify@*

# Lean
lake env lean <generated.lean>            # 解析+类型
# 或放入 VeriGIS 树后 lake build
```

云端权威复核仍走 AutoDL `/root/verigis/repo`（见 `.cursorrules` [lab]）；W3+ 由 PI/脚本触发，本 W1 不 SSH。

### 8.3 门禁

- generated 文件不得覆盖 `formal/` 下 gold。
- 写入仅限 `experiments/p2_llm/results/`。
- 凭据占位符铁律不变。

---

## 9. 威胁有效性（Threats to Validity）

### 9.1 内部有效性

- **数据泄漏**: gold 可能出现在模型预训练或 Cursor 上下文。缓解：报告「仓内文件是否可能进上下文」；主实验用 API 隔离会话；few-shot 只用非同命题。
- **评测泄漏**: 修复时把 gold 贴进 prompt → 严禁；harness 断言 prompt 不含 `gold_formal` 正文。
- **非确定性**: temperature=0 仍可能漂移 → 记 model 串与日期；k=5。

### 9.2 外部有效性

- 任务全部来自本实验室 GeoProofBench 子集，不代表全部 GIS 算子。
- 仅 Dafny 4.x + Lean 4 / lake；不覆盖 Isabelle/Coq。
- 真实 DEM 多样性（GPB-027）不进入 W1 任务包（避免下载波动）；可作 W5 扩展讨论。

### 9.3 构念有效性

- `verify@*` ≠ 证明工程师可用性；需配合 semantic fidelity。
- 人工 fidelity 标注有主观性 → 双人抽检 + 争议协议。

### 9.4 结论有效性

- 样本量 ~22 任务 × 4 模型 × 3 prompt × k，多重比较风险高 → 预注册主检验。
- 阴性题少（3）→ L3 结论以定性 + 置信区间为主。

---

## 10. 与 P1 资产的接口

| P1 资产 | P2 用法 |
|---|---|
| `formal/dafny/*.dfy` | gold_formal |
| `formal/lean4/VeriGIS/**` | gold_formal |
| `experiments/phase1/*.py` | reference_impl（L1） |
| `experiments/phase2/p_comp_*.py` | reference_impl（L2/L3） |
| `docs/phase2/PROP_CHAIN.md` | natural_spec 来源 |
| `papers/P2/manuscript.md` | **只读引用**；FORM LOCK，不改 |

P2 论文将是**第二篇**独立稿件（目录 `docs/P2_AIMATH/` + 未来 `papers/P2_AIMATH/`），不解锁 P1 形态锁。

---

## 11. 九周日程（对齐 INBOX）

| 周 | 窗口 | 交付 |
|---|---|---|
| W1 | 9/9–9/15 | DESIGN + tasks + prompts + RISKS（本轮） |
| W2 | 9/16–9/22 | harness + smoke 1 任务 × 1 模型 |
| W3 | 9/23–9/29 | 主实验启动 L1 |
| W4 | 9/30–10/6 | L2 + 开始 taxonomy |
| W5 | 10/7–10/13 | L3 + fidelity 标注 + 主表 |
| W6 | 10/14–10/20 | 论文 Method/Experiments 初稿 |
| W7 | 10/21–10/27 | Related/Intro/Limitations |
| W8 | 10/28–11/3 | 内审 + 补实验 |
| W9 | 11/4–11/10 | 投稿 NeurIPS D&B / ICLR |

自推进链：`W1/PENDING → … → W9/PENDING → DONE`；每段 local commit，**不 push** 直至 P2 自身投稿触发器。

---

## 12. 伦理与披露

- 使用第三方 API 时遵守服务商 ToS；不上传未授权隐私 DEM（本基准以合成与已公开驱动为主）。
- 论文披露：模型版本、温度、prompt hash、是否可能仓内泄漏。
- 负面结果完整报告（含 drifted），不选择性删题。

---

## 13. W1 验收清单

- [x] `docs/P2_AIMATH/DESIGN.md` ≥ 300 行
- [x] `experiments/p2_llm/tasks/` ≥ 21 YAML
- [x] `experiments/p2_llm/prompts/` 含 P0/P1/P2
- [x] `docs/P2_AIMATH/RISKS.md`
- [ ] 模型 API 实测（留给 W2/W3）
- [ ] 任何 verify@ 数字（W1 **禁止编造**）

---

## 14. 开放决策（记给 PI，不阻塞 W1）

1. M2/M3 最终商业版本串以 W3 首呼锁定为准。
2. 是否把 GPB-027 真实 DEM 扩成 L2 附加题（下载稳定性风险，见 RISKS）。
3. 主投 NeurIPS D&B vs ICLR 的最终二选一在 W7 前拍板。

---

## 附录 A · 任务包索引（W1）

详见 `experiments/p2_llm/tasks/`。摘要：

**L1 (14)**  
GPB-001-flat, GPB-001-nonneg-lean, GPB-002-planar, GPB-P002-mono, GPB-P002-nd-lean,
GPB-P002-idem, GPB-P002bis-raise, GPB-007-hessian, GPB-005-lap-lean, GPB-019-quad,
GPB-010-pit, GPB-011-plane-lean, GPB-015-basin, GPB-T6-terminate-lean

**L2 (5)**  
GPB-021-pcomp1, GPB-022-pcomp2-lean, GPB-025-pcomp4, GPB-026-pcomp5, GPB-021-pcomp1-lean

**L3 (3)**  
GPB-023-pcomp3-neg, GPB-015b-ring-neg, GPB-025-rot45-neg

## 附录 B · 参考命令（评测侧，非 W1 执行）

```text
dafny verify formal/dafny/P001_horn_slope.dfy
dafny verify formal/dafny/PCOMP_1.dfy
cd formal/lean4 && lake build
```

## 附录 C · 写作立场（给未来论文 Intro）

不要写「LLM 即将取代证明助手」。要写：

> 我们提供第一个面向**地理空间算法结构**的自动形式化评测床；
> 揭示验证通过与语义忠实之间的裂缝；并把反例资产保留为一级公民。

## 附录 D · 与 Honesty Protocol 的对照表

| 禁止 | 本设计如何遵守 |
|---|---|
| 编造 verify 数字 | W1 无实验数字 |
| 洗白 45° / 环 / ZT-Horn | L3 三题强制 NEG |
| 改 P1 manuscript | FORM LOCK，只读 |
| git push | W1–W9 默认禁止 |
| 凭据入库 | 占位符 |

## 附录 E · 术语表

| 术语 | 含义 |
|---|---|
| GPB | GeoProofBench 命题编号 |
| drifted | verified but drifted |
| repair gain | verify@3 − verify@1 |
| gold_formal | 隐藏的已验证形式化文件 |
| NEG | 期望产出反例/否定式 |

## 附录 F · 变更日志

| 日期 | 版本 | 变更 |
|---|---|---|
| 2026-09-09 | W1.0 | 初稿：任务定义、分层、模型、prompt、指标、F1–F8、威胁、日程 |

---

*End of DESIGN.md (W1). Next: STATUS → W2/PENDING for harness scaffolding.*
