# P2_AIMATH · LLM API 可达性矩阵（task16-W3.5a）

> **探测时间**: 2026-09-09T06:01:49Z（本机）  
> **脚本**: `experiments/p2_llm/harness/probe_api_reachability.py`  
> **机器可读**: `experiments/p2_llm/results/api_reachability.json`  
> **铁律**: 下表数字全部来自本次实测；无 key 的 L4 以 401/403 证明「可达但被拒」，timeout/DNS 证明「不可达」。

---

## 1. 环境快照（实测）

| 项 | 值 |
|---|---|
| `HTTPS_PROXY` / `HTTP_PROXY` / `ALL_PROXY` | **未设置** |
| `ANTHROPIC_AUTH_TOKEN` | **已设置**（Machine env；值未写入本仓） |
| `ANTHROPIC_API_KEY` | 未设置 |
| `OPENROUTER_API_KEY` / `SILICONFLOW_*` / `DEEPSEEK_*` / `ZHIPU_*` / `DASHSCOPE_*` / `MOONSHOT_*` | **均未设置** |
| Probe timeout | 25 s |

---

## 2. 四层可达性矩阵

图例：✓ = ok；✗ = fail；— = skipped。`err_class` 以 JSON 为准。

| # | 端点 | L1 DNS | L2 TCP | L3 TLS | L4 HTTP | status / ms | err_class | 分级 |
|---|---|---|---|---|---|---|---|---|
| 1 | `api.anthropic.com/v1/messages` | ✓ 23.0 ms → 160.79.104.10 | ✓ 231.6 ms | ✓ 545.4 ms CN=`api.anthropic.com` TLS1.3 | ✓ | **403** / 685.5 | HTTP-403 | **可用**（网络通；业务拒） |
| 2 | `openrouter.ai/.../chat/completions` | ✓ 21.3 ms | ✓ 331.7 ms | ✓ 474.7 ms CN=`openrouter.ai` | ✓ | **401** / 966.6 | HTTP-401 | **可用**（缺 key） |
| 3 | `api.siliconflow.cn/.../chat/completions` | ✓ 18.8 ms | ✓ 82.6 ms | ✓ 223.0 ms CN=`*.siliconflow.cn` | ✓ | **401** / 328.1 | HTTP-401 | **可用**（缺 key） |
| 4 | `api.deepseek.com/chat/completions` | ✓ 21.6 ms | ✓ 60.5 ms | ✓ 148.7 ms CN=`api.deepseek.com` | ✓ | **401** / 247.7 | HTTP-401 | **可用**（缺 key） |
| 5 | `open.bigmodel.cn/.../chat/completions` | ✓ 20.4 ms | ✓ 61.5 ms | ✓ 159.4 ms CN=`*.bigmodel.cn` | ✓ | **401** / 278.9 | HTTP-401 | **可用**（缺 key） |
| 6 | `dashscope.aliyuncs.com/compatible-mode/...` | ✓ 30.2 ms | ✓ 65.4 ms | ✓ 163.2 ms CN=`*.aliyuncs.com` | ✓ | **401** / 236.8 | HTTP-401 | **可用**（缺 key） |
| 7 | `api.moonshot.cn/v1/chat/completions` | ✓ 17.1 ms | ✓ 63.1 ms | ✓ 228.0 ms CN=`*.moonshot.cn` TLS1.2 | ✓ | **401** / 357.2 | HTTP-401 | **可用**（缺 key） |
| 8 | Anthropic via env proxy | — | — | — | — | skipped | skipped-no-proxy | **不可用**（无代理 env） |

**汇总**: 8 探测 / **7 可用** / 1 不可用（代理重测跳过）。**无一端点 DNS/TCP/TLS 失败。**

### L4 响应摘录（无密钥泄露）

| 端点 | body_excerpt（截断） |
|---|---|
| anthropic | `"type":"forbidden","message":"Request not allowed"` |
| openrouter | `No cookie auth credentials found` code 401 |
| siliconflow | `Token is invalid.` code 30014 |
| deepseek | `Authentication Fails (governor)` |
| zhipu | `Header中未收到Authorization参数` |
| dashscope | `You didn't provide an API key... Bearer` |
| moonshot | `Incorrect API key provided` |

---

## 3. 分级与推荐方案

### 推荐（首选）

**硅基流动 `https://api.siliconflow.cn/v1/chat/completions`**

- 理由（实测）: 国内直连，L2 TCP **82.6 ms**、L4 **328 ms**，401 证明通路；OpenAI 兼容，一套 key 可挂 DeepSeek/Qwen 等。
- **阻塞**: 环境无 `SILICONFLOW_API_KEY`。

### 可用（备选，均需对应 key）

| 优先级 | 端点 | 备注 |
|---|---|---|
| 2 | DeepSeek | L4 最快档之一（247.7 ms）；缺 `DEEPSEEK_API_KEY` |
| 3 | DashScope（通义） | OpenAI compatible-mode；缺 `DASHSCOPE_API_KEY` |
| 4 | Moonshot / Zhipu | 同样 401；缺 key |
| 5 | OpenRouter | 海外聚合，一个 key 通 Claude/GPT/Gemini；缺 `OPENROUTER_API_KEY` |
| 6 | Anthropic 官方 | **网络可达**但 L4=**403 Request not allowed**；本机已有 `ANTHROPIC_AUTH_TOKEN`，仍可能被 IP/地区策略拒（与 W2/W3 一致） |

### 不可用

- **Anthropic via proxy**: 本机未设任何 `*_PROXY`，无法验证代理解阻。

---

## 4. 需要 PI 提供的三选一（解阻 W3 live）

任选其一即可让 W3 `--require-live` 继续：

| 选项 | PI 动作 | 预期效果 |
|---|---|---|
| **(a) 国产 OpenAI 兼容 key** | 设置 `SILICONFLOW_API_KEY` 或 `DEEPSEEK_API_KEY` / `DASHSCOPE_API_KEY`（User 或 Process env）+ 告知模型名 | **推荐路径**；harness 需接 OpenAI-compatible backend（W3 重跑时加） |
| **(b) 代理** | 设置 `HTTPS_PROXY` 指向可出站 Anthropic 的代理，再测 endpoint #8 | 可能解开 Anthropic 403（需实测验证，不臆测） |
| **(c) OpenRouter / 改模型决定** | 提供 `OPENROUTER_API_KEY`，或拍板「本轮只用 DeepSeek/Qwen，不做 Claude」 | 绕过 Anthropic 地区策略 |

> **不要把 key 写进 git / INBOX / OUTBOX。** 只设环境变量。

---

## 5. 与 W2/W3 结论对齐（诚实）

| 既往 | 本次复核 |
|---|---|
| `code.newcli.com` ConnectTimeout | 本次清单未含该 gateway（W3.5 候选表以 INBOX A.12.1 为准） |
| `api.anthropic.com` HTTP 403 | **复现**（无 key 探针 403；与「通了但被拒」一致） |
| 「出口访问不到 live LLM API」 | **部分修正**: 6+ 国产/聚合端点 **L1–L4 全通**（401），问题从「网络不通」精确为「**缺匹配 key / Anthropic 业务层 403**」 |

未编造任何 `verify@` / `compile@` 数字。
