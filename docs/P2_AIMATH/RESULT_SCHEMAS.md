# P2_AIMATH · 结果表骨架（RESULT_SCHEMAS）

> **阶段**: task16-W3.5b 离线基建  
> **用途**: W3–W5 主实验落盘列名与口径；**空表不含任何实测 verify@**（诚实协议）。  
> **主设计格**: 4 模型 × 3 prompt × ≥21 题 × k=5（样本）—— 与 `docs/P2_AIMATH/DESIGN.md` §6 对齐。

---

## 1. 单元粒度（一行 = 一次生成样本）

| 列名 | 类型 | 口径 |
|---|---|---|
| `run_id` | str | `{task_id}__{model}__{prompt_id}__k{sample_index}__r{repair_round}` |
| `task_id` | str | YAML `id`（如 `GPB-001-flat`） |
| `difficulty` | enum | `L1` / `L2` / `L3` |
| `target` | enum | `dafny` / `lean` |
| `expected_verdict` | enum | `PASS` / `NEG` |
| `prop_family` | str | 如 `P-001` / `P-COMP-3` |
| `model` | str | **锁定版本串**（例 `deepseek-chat` / `claude-sonnet-4-20250514`） |
| `model_provider` | str | `anthropic` / `openai_compat` / … |
| `api_base` | str | 实际请求 base URL（不含 key） |
| `call_date` | date | UTC `YYYY-MM-DD` |
| `temperature` | float | 固定 `0.0`（DESIGN） |
| `prompt_id` | enum | `P0` / `P1` / `P2` |
| `prompt_template_sha256` | hex | 渲染后模板 hash |
| `sample_index` | int | `0..k-1`，主实验 `k=5` |
| `repair_round` | int | `0` = 初生成；P2 最多到 `3` |
| `compile_rc` | int\|null | `0` 解析/编译成功；null = 工具链缺失未跑 |
| `verify_rc` | int\|null | `0` 机器检验通过；null = 未跑 |
| `timed_out` | bool | 验证器超时 |
| `compile_ok` | bool | 派生：`compile_rc==0` |
| `verify_ok` | bool | 派生：`verify_rc==0` 且非 timeout |
| `fidelity_label` | enum | 见 `score_semantic.py`（启发式；F7 需人审） |
| `drift_suspect` | bool | 启发式 F7 嫌疑 |
| `failure_codes` | list[str] | `F1`–`F8`（可多选；人审覆盖自动建议） |
| `raw_path` | path | `experiments/p2_llm/results/raw/{run_id}.json` |
| `gen_path` | path | `.dfy` / `.lean` 旁路文件 |
| `notes` | str | 自由文本；禁止把 fixture 标成 live |

---

## 2. 聚合指标表（论文主表；W3 起填，空则写 `—`）

列口径（**禁止编造**）：

| 列名 | 口径 |
|---|---|
| `model` | 版本串 |
| `prompt_id` | P0/P1/P2 |
| `difficulty` | L1/L2/L3 或 `ALL` |
| `n_tasks` | 该层题数 |
| `n_samples` | 有效 live 样本数（不含 fixture） |
| `compile@1` | 初生成 `compile_ok` 比例 |
| `verify@1` | 初生成 `verify_ok` 比例（★主） |
| `verify@3` | repair≤3 后 `verify_ok` 比例（★主） |
| `repair_gain` | `verify@3 − verify@1` |
| `semantic_fidelity` | 人审对齐率（非启发式独断） |
| `verified_but_drifted` | 通过验证但 F7 比例（★杀手锏） |
| `wilson_lo` / `wilson_hi` | verify@1 的 Wilson 95% CI（可选） |

### 2.1 空表模板（4×3；数值格一律 `—`）

| model | prompt | L1 compile@1 | L1 verify@1 | L1 verify@3 | L2 verify@1 | L3 verify@1 | drifted | n_live |
|---|---|---|---|---|---|---|---|---|
| M1 (TBD) | P0 | — | — | — | — | — | — | 0 |
| M1 (TBD) | P1 | — | — | — | — | — | — | 0 |
| M1 (TBD) | P2 | — | — | — | — | — | — | 0 |
| M2 (TBD) | P0 | — | — | — | — | — | — | 0 |
| M2 (TBD) | P1 | — | — | — | — | — | — | 0 |
| M2 (TBD) | P2 | — | — | — | — | — | — | 0 |
| M3 (TBD) | P0 | — | — | — | — | — | — | 0 |
| M3 (TBD) | P1 | — | — | — | — | — | — | 0 |
| M3 (TBD) | P2 | — | — | — | — | — | — | 0 |
| M4 (TBD) | P0 | — | — | — | — | — | — | 0 |
| M4 (TBD) | P1 | — | — | — | — | — | — | 0 |
| M4 (TBD) | P2 | — | — | — | — | — | — | 0 |

> 模型四档在 DESIGN §4 锁定后替换 `M1..M4`；在拿到 live key 前 **n_live 保持 0**。

---

## 3. JSON 落盘约定

```
experiments/p2_llm/results/
  raw/{run_id}.json          # API meta + 原文（可复现）
  raw/{run_id}.dfy|.lean     # 抽出的源码
  scored/{run_id}.verify.json
  scored/{run_id}.semantic.json
  scored/l1_batch_w3.json    # batch 汇总（可含 BLOCKED）
  api_reachability.json      # W3.5a 可达性
  figures/*.png              # make_figures.py 输出
```

**Fixture 隔离**: `model` 含 `fixture` 或 `status=GENERATED_FIXTURE` 的行 **不得** 进入 `verify@*` 聚合。

---

## 4. 失败模式计数表（空）

| code | name | count | pct |
|---|---|---|---|
| F1 | 语法/解析 | — | — |
| F2 | 类型/签名 | — | — |
| F3 | 前置条件弱化 | — | — |
| F4 | 循环不变式缺失 | — | — |
| F5 | 终止性度量缺失 | — | — |
| F6 | 浮点/数值语义 | — | — |
| F7 | 语义漂移 | — | — |
| F8 | 过度强化前提 | — | — |

详见 `docs/P2_AIMATH/ANNOTATION_MANUAL.md`。
