# P2_AIMATH · Risks & Mitigations（W1）

> Companion to `docs/P2_AIMATH/DESIGN.md`.  
> Scope: API cost, quotas, reproducibility, collision with P1 SciDA timeline.  
> Date: 2026-09-09 · task16-W1

---

## 1. API 成本

| 风险 | 影响 | 对策 |
|---|---|---|
| 4 模型 × 22 题 × 3 prompt × k=5 × repair×3 爆炸 | 预算超支，实验中断 | 成本优先：Cursor Pro 额度 → DeepSeek；L2/L3 可先 M1+M4 全量 |
| 长 Lean 上下文重复 import | token 浪费 | harness 截断 reference_impl 至关键函数；prompt 限 8k in |
| 失败重试无上限 | 静默烧钱 | 每任务硬顶 repair 3；compile 连续 F1×5 则熔断该题 |

**粗算（W1 量级，非实测账单）**:  
若平均 4k in + 2k out / 次，全因子约 22×4×3×5 ≈ 1320 次生成 + 部分 repair，
优先路径（M1+M4，k=1 smoke → k=5）可把现金 API 压到低价档。  
**W1 不产生账单**（不跑模型）。

## 2. 额度与限流

| 风险 | 对策 |
|---|---|
| Cursor / Anthropic / OpenAI / Google / DeepSeek 日限额 | 错峰；指数退避；断点续跑（按 task_id 跳过已有 raw） |
| 单 key 被封 | 密钥仅存仓外；占位符入库；轮换不写进 git |
| 模型下架改名 | DESIGN §4「锁定串」以首呼响应为准；论文写 call_date |

## 3. 可复现性

| 风险 | 对策 |
|---|---|
| temperature=0 仍非确定 | 存 raw + seed + model 串 + prompt sha256 |
| 工具链版本漂 | 钉 Dafny 4.11；Lean/lake 与 P1 AutoDL 构建一致 |
| 评测机本机 vs AutoDL | 本机生成；权威 verify 可云端复核；差异记 OUTBOX |
| gold 泄漏进预训练 | Limitations 披露；主表仍报；可选「holdout 改写 natural_spec」消融在 W8 |

## 4. 与 P1 返修 / SciDA 撞期

| 风险 | 对策 |
|---|---|
| SciDA revision 要改实验 | P1 FORM LOCK；P2 独立目录 `docs/P2_AIMATH/`、`experiments/p2_llm/` |
| PI 时间被投稿占满 | W1–W2 自动化 watcher；周报仅异常打断 |
| 共用 AutoDL GPU/CPU | P2 verify 以 CPU SMT/Lean 为主；避开 P1 大 job 窗口 |
| 误改 `papers/P2/manuscript.md` | .cursorrules form-lock；harness 禁止写该路径 |

## 5. 科学风险

| 风险 | 对策 |
|---|---|
| L3 仅 3 题，统计力弱 | 预声明探索性；主检验放 L1 vs L3 描述性对比 |
| F7 标注主观 | 双人抽检；争议协议 |
| 模型「背出」gold | semantic fidelity 仍查方向；必要时改写规格做敏感度分析 |
| ID 撞号（GPB-021 等） | 任务 id 带后缀；DESIGN 诚实脚注 |

## 6. 工程风险

| 风险 | 对策 |
|---|---|
| YAML schema 漂移 | W2 加 jsonschema 校验 |
| Windows 路径 / PowerShell | harness 用 pathlib；云端 bash |
| manim / wolfram 与本评测无关 | 不依赖；reference 只用 .py/.dfy/.lean |
| `ANTHROPIC_BASE_URL` (code.newcli.com) ConnectTimeout | W2+W3 复测同败；fallback `api.anthropic.com` 仍 403；**W3 STATUS=W3/BLOCKED** 等 PI 可达 key/代理或 AutoDL 出口；gate.ps1 对 BLOCKED noop 防烧 token |

## 7. 法律与伦理

- 遵守各 API ToS；不把未授权数据上传。
- 不声称模型可替代安全攸关水文决策证明。
- 负面结果完整公开（投稿后 / 接收后按 P2 push gate）。

## 8. 熔断条件（触发则 STATUS=BLOCKED）

1. 单周 API 现金支出超过 PI 口头预算（PI 填数）。
2. 工具链无法在本机或 AutoDL 复现 compile 闸。
3. 发现 harness 曾把 gold 正文注入 prompt。

## 9. 责任划分

| 角色 | 职责 |
|---|---|
| Cursor | 设计、基建、跑实验、写 OUTBOX、local commit |
| Workbuddy | 只 dispatch/monitor（不下场） |
| PI | 预算、模型最终钉扎、投稿档选择 |

---

*End of RISKS.md*
