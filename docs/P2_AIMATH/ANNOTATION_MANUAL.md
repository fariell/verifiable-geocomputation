# P2_AIMATH · 失败模式标注手册（F1–F8）

> **阶段**: task16-W3.5b  
> **目的**: 多人标注一致性；自动建议（compiler / `score_semantic`）**不能**单独定稿 F7/F8。  
> **铁律**: 不得删除 F1–F8；可增子类（如 F6a）；不得把 fixture / 未跑 live 标成论文失败分布。

---

## 0. 标注流程（推荐）

1. **自动建议**: `compile_rc`/`verify_rc`/stderr → 建议 F1/F2；`drift_suspect` → 建议 F7。  
2. **人审**: 对照 `natural_spec` + `gold_formal`（评测者可见 gold；模型不可见）。  
3. **多选**: 一条样本可有主码 + 辅码（例主 F5、辅 F3）。  
4. **双人交叉**: ≥20% 样本双标；不一致进仲裁表。

---

## 1. 类别定义与 GPB 示例

### F1 · 语法 / 解析错误

| 项 | 内容 |
|---|---|
| **判定** | 解析器/编译器在词法或句法层失败（括号、缩进、未知 tactic 拼写）。 |
| **边界** | 若仅类型错误 → F2；若文件空 → 记 EMPTY，可辅标 F1。 |
| **GPB 例** | `GPB-001-flat`：生成 `lemma FlatSlopeZero(C: real w: real)` 缺逗号 → Dafny parse error。 |

### F2 · 类型 / 签名错误

| 项 | 内容 |
|---|---|
| **判定** | 解析通过，但函数/lemma 参数类型、返回类型、泛型与调用不匹配。 |
| **边界** | 签名对但 `requires` 过弱 → F3；证明体用错引理名但类型过 → 偏 F4/语义。 |
| **GPB 例** | `GPB-007-hessian`：`Hessian` 返回 `real` 却按矩阵索引使用。 |

### F3 · 前置条件缺失或弱化

| 项 | 内容 |
|---|---|
| **判定** | 相对 gold / natural_spec，丢掉关键 `requires`（如 `w > 0`、有限高程、网格连通）。 |
| **边界** | 弱化后仍“碰巧” verify 通过且命题已变 → **同时标 F7**。 |
| **GPB 例** | `GPB-001-flat`：去掉 `w > 0.0`，把除零未定义行为洗成永真。 |

### F4 · 循环不变式缺失

| 项 | 内容 |
|---|---|
| **判定** | 含循环/递归的填洼、流域遍历等，缺 `invariant` / 归纳假设导致 verify 失败。 |
| **边界** | 终止性单独缺 → F5；两者常共现，主码取“最先阻塞 verify 的原因”。 |
| **GPB 例** | `GPB-010-pit` / `GPB-021-pcomp1`：PitFill 循环无 `invariant` 保持“高程不降”。 |

### F5 · 终止性度量缺失

| 项 | 内容 |
|---|---|
| **判定** | 缺 `decreases` / WellFounded / 鸽笼度量；或度量与循环变量无关。 |
| **边界** | 有度量但语义证明错命题 → F7；仅编译缺关键字 → 可 F1+F5。 |
| **GPB 例** | `GPB-T6-terminate-lean` / `GPB-015-basin`：流域迭代无 `decreases`。 |

### F6 · 浮点 / 数值语义错配

| 项 | 内容 |
|---|---|
| **判定** | ε_tol、比较符（`<` vs `≤`）、FAIL-TOLERANCE、归一化约定与规约不符。 |
| **边界** | 纯整数格网命题误用浮点公理 → F6；把容差失败洗成 PASS → F7。 |
| **GPB 例** | `GPB-025-rot45-neg`：45° 旋转超容差被写成“同伦成立”。 |

### F7 · 语义漂移（通过验证但证明错命题）★

| 项 | 内容 |
|---|---|
| **判定** | `verify_rc==0`，但证明的不是 `natural_spec`（换命题、证永真、洗白 NEG）。 |
| **边界** | 启发式 `VERIFIED_BUT_DRIFT_SUSPECT` **必须人审**后才能定稿 F7。 |
| **GPB 例** | `GPB-023-pcomp3-neg`：应证 ZT⇏Horn，模型证明 `true` 或同构错误引理仍 verify 通过。 |
| **GPB 例** | `GPB-015b-ring-neg`：4-环不终止被证成“存在不动点”。 |

### F8 · 过度强化前提（平凡化）

| 项 | 内容 |
|---|---|
| **判定** | 加入过强 `requires` / `assume`，使原命题退化为平凡真。 |
| **边界** | `assume false` 且 verify 过 → F8（常兼 F7）。合理收紧与 gold 同级不算 F8。 |
| **GPB 例** | `GPB-002-planar`：`requires false` 或限定单点 DEM 后证 slope 性质。 |

---

## 2. 决策树（简版）

```
empty? → EMPTY (optional F1)
timed_out? → TIMEOUT (no F-code until retry)
compile fail parse? → F1
compile/type fail? → F2
verify fail:
  missing requires vs spec? → F3
  missing invariant? → F4
  missing decreases? → F5
  numeric/ε mismatch? → F6
  else → F2/F4 按 stderr
verify pass:
  assume/过强 requires 平凡化? → F8 (+F7 if drifted)
  NEG 无 witness / 命题已换? → F7
  else → aligned (no failure code)
```

---

## 3. 多人一致性协议

| 规则 | 说明 |
|---|---|
| 训练集 | 每人先标同一 12 条 gold 校准集（含 ≥2 条 F7/F8） |
| 指标 | Cohen's κ（主码）；目标 κ ≥ 0.70 再标全库 |
| 仲裁 | 第三人；记录 `adjudication_note` |
| 禁止 | 按模型名偏见标注；禁止因“想提高某模型分数”改码 |

---

## 4. 与结果表衔接

- 单元行 `failure_codes: ["F5","F3"]`  
- 聚合见 `RESULT_SCHEMAS.md` §4  
- 图：`make_figures.py` 失败模式分布图只读**人审后**计数（W3.5 离线 fixture 图仅演示管道）
