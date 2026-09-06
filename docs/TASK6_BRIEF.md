# TASK6 指令 · P-006 = GPB-015 流域唯一性

> 发令:洛书 · 2026-09-06 16:2x · 执行:Cursor
> 協议见 `docs/CURSOR_LOOP.md`;工序见 `docs/EXPERIMENT_PLAYBOOK.md`

---

## 〇、先对齐编号(回话第一句就答这个)

我理解的 task 序列是:

| task | 命题 | 状态 |
|---|---|---|
| task5 | **P-005 D8 流向**(GPB-010/011) | ✅ 已 commit `c829c44`,本机 Dafny 18/0 |
| task6 | **P-006 流域唯一性**(GPB-015) | ⬅ **本次** |

**如果你内部的 task 编号与此不一致,先说清楚你的 task6 是什么**,别闷头做。
另外,开工前请用一句话确认 P-005 的云端复核是否已做(this-week.md v1.5 仍写"待云端验")——
若未做,task6 开工前先把它结算掉(见 §五)。

---

## 一、命题

> **GPB-015**(watershed, difficulty 4):
> "Every interior cell belongs to exactly one watershed basin under a
> deterministic flow-routing rule."

出处 `experiments/phase1/propositions.py:36`。伏笔在 `formal/dafny/P005_README.md`
末尾:"平坦处的全局无环(未填洼的 D8 可以在 flat 上转圈)。流域唯一是 GPB-015。"

---

## 二、数学拆解(洛书的判断,按这个做)

唯一性分两层,**必须分开处理**,否则会掉进 SMT 泥潭:

### 层 A:唯一性(平凡但必须机器检验)

流向是**确定性函数** ⇒ 每格后继唯一 ⇒ 迭代轨道唯一 ⇒ 终点(出口)唯一 ⇒ 流域归属唯一。
这一层是纯函数推理,SMT 应该能过。

### 层 B:终止性(**非平凡,要有前提**)

未填洼的 D8 在 flat 上可以转圈 ⇒ **唯一性并不无条件成立**。

所以我要求你做**两条**:

| 编号 | 类型 | 内容 |
|---|---|---|
| **P-006a** | 正命题 | **若**从每格出发的 D8 轨道终止于某出口,则该出口唯一 ⇒ 每格归属恰好一个流域 |
| **P-006b** | 反例记录 | 显式构造一个 flat 环,展示未填洼时轨道**不终止**;写成 witness,不是"漏证" |

**P-006b 是科学资产,不是瑕疵。** GeoProofBench 的价值一半在于"哪些性质在什么前提下
会失败"——只证成立的命题是瘸腿的基准。把它写进 `P006_README.md` 的"没证什么"。

### 建议引理骨架(Dafny / Lean 各自独立重述)

1. `FlowSuccessorUnique` — D8 输出唯一(复用 P-005 的 8 路比较核,**import 不要复制**)
2. `OrbitDeterministic` — 同起点 n 步轨道唯一(对 n 归纳)
3. `TerminatesImpliesBasin` — 若 `Orbit(c)` 在 N 步内到出口,则 `basin(c)` 有定义
4. `BasinUnique` — `∃! b. b = basin(c)`(**主定理,层 A**)
5. `FlatCycleNoTermination` — flat 环上轨道不终止(**层 B 反例**)
6. *(可选)* `TerminatesUnderStrictDescent` — 每步高程严格下降 + 有限格网 ⇒ 终止

**第 6 条做不动就标 PENDING**,不要为了它卡住整条命题。前 5 条才是骨架。

### 与 P-002 的连贯(论文叙事,别浪费)

P-002 已形式化**填洼**。所以完整故事是:

```
填洼 (P-002) → 无洼/无 flat 环 → D8 轨道终止 (P-006 层 B 前提)
             → 流域归属唯一 (P-006 层 A)
```

请在 `P006_README.md` 开头写一段这个链条。这是本体系第一次出现**跨命题组合**——
两条已证命题拼出第三条,本身就可写进论文 Related/Discussion。

---

## 三、三件套 + 双形式化(照 playbook §2)

| # | 文件 | 内容 |
|---|---|---|
| 1 | `experiments/phase1/p006_watershed.py` | numpy driver:**复用 P-005 的 D8 核**(import `p005_d8`);每格沿 D8 走到出口,统计终止性与出口唯一性 |
| 2 | `experiments/phase1/p006_watershed.wl` | wolframscript 符号化:确定性函数在有限集上的迭代轨道,长度 > \|S\| 必有重复(鸽笼)—— 这是纯组合事实,Wolfram 能给符号或穷举验证 |
| 3 | `experiments/phase1/p006_manim.py` | 左:斜面 D8 箭头场 + 流域染色;右:**flat 环转圈的反例动画**(箭头循环高亮) |
| 4 | `experiments/phase1/run_p006.sh` | 云端驱动,末尾打印 `GPB-015 ENTRY: PASS/FAIL` |
| 5 | `formal/dafny/P006_watershed.dfy` | 上述 1–5 引理 |
| 6 | `formal/lean4/VeriGIS/Watershed.lean` | **独立重述**,不翻译 Dafny |
| 7 | `formal/dafny/P006_README.md` | 映射表 + "没证什么"(含 P-006b)+ 与 P-002 的链条 |

**索引两处别漏**:`experiments/phase1/README.md` 文件表 + `scripts/autodl/verify_all.sh`
(加 P-006 的 dafny verify 与 `run_p006.sh`,照 P-005 那两段的写法)。

### 门控(至少要有的三条数值判据)

1. 斜面无洼 DEM:**100% 内部格点轨道终止**,且每格出口唯一
2. 含洼地 DEM:洼地格点 `NoFlow`(不终止),**其余格点仍出口唯一**
3. 人工 flat 环:**检测到非终止**(步数超上界),作为 P-006b 的数值证据

---

## 四、从 P-001 → P-005 沉淀的经验(开工前读一遍,别再踩)

| # | 教训 | 出处 |
|---|---|---|
| E1 | **SMT 不喜递归扫描**。P-005 的递归 `BestFrom` 超时,改成 8 路分数比较才过。**P-006 的轨道迭代请用有界展开**(`stepN(h,c,n)` 对 n 归纳),不要让 solver 自己找不动点 | P-005 |
| E2 | **一般符号参数会被非线性挡住**。P-005 的 `A,w` 一般情形挡住了,改用 `A=1,w=1` 实例 + README 明标"一般情形未证"。照做 | P-005 |
| E3 | **`sqrt` 是超越函数** → 用平方比较规避 | P-001 `SlopeSqNonneg` |
| E4 | **Dafny / Lean 独立重述**,不要逐行翻译 | P-001 起 |
| E5 | **`.wl` 用 `Assuming` 做符号化**,不要只代一个数值点 | playbook §3 |
| E6 | **AutoDL 没有 wolframscript** → `.py` 找不到就 **skip 而非 fail** | P-003 |
| E7 | manim 用 `-ql` + `--disable_caching`,成品拷进 `figures/` 才进仓 | playbook §4 |
| E8 | `.gitignore` 的 `#` 注释**必须独占行首**,行尾注释使规则静默失效 | 2026-09-06 实测 |
| E9 | 并列时**扫描序写死**:`E,SE,S,SW,W,NW,N,NE`,Dafny/Lean 必须一致 | P-005 |
| E10 | 比较用 `drop²/dist2`,**不用 √2** | P-005 |

---

## 五、开工前先结算 P-005(若还没做)

`docs/this-week.md` v1.5 仍写"P-005 待云端验"。若确认没做,**先跑这个再开 P-006**:

```bash
source /etc/network_turbo && source ~/.elan/env
export PATH="/usr/local/bin:$PATH"
cd /root/verigis/repo
python3 scripts/autodl/jupyter_progress.py 'dafny verify formal/dafny/P005_d8.dfy'
cd formal/lean4 && lake build
```

回传 `[verdict]`,我据此把 `c829c44` 的状态结算掉。**顺序不能乱:P-005 未结算就开
P-006,会给后面留两笔糊涂账。**

---

## 六、执行顺序(**本地先验证,再上云**)

```powershell
# 本机(你跑)
cd "E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation"

& "C:\ProgramData\anaconda3\python.exe" experiments/phase1/p006_watershed.py
wolframscript -file experiments/phase1/p006_watershed.wl
$env:P006_MANIM=1; & "C:\ProgramData\anaconda3\python.exe" experiments/phase1/p006_manim.py
dafny verify formal/dafny/P006_watershed.dfy      # 你本机跑通过 18/0,确认路径后
                                                   # 把可执行文件绝对路径补进 playbook §1
```

本机全绿之后:

```bash
# AutoDL(你跑,或让 PI 跑)
bash scripts/autodl/sync_push.sh                  # 本机 overlay
cd /root/verigis/repo
dafny verify formal/dafny/P006_watershed.dfy
cd formal/lean4 && lake build
bash experiments/phase1/run_p006.sh
```

**每步回传都用 `docs/CURSOR_LOOP.md` §三的回报格式。** 本地还没过就别上云。

---

## 七、完成判据

- [ ] numpy driver 三条门控全 PASS
- [ ] wolframscript 符号化验证通过(不是只代数值点)
- [ ] Dafny verify 通过(云端权威)
- [ ] Lean `lake build` 通过(云端权威)
- [ ] `P006_README.md` 写明"没证什么",含 **P-006b flat 环反例**
- [ ] `experiments/phase1/README.md` + `verify_all.sh` 索引已更新
- [ ] manim 成品拷进 `figures/`

缺任何一条 = 没做完。可先 commit,但 message 必须标 `VERIFY PENDING`。

---

## 八、首条 chat 粘贴版(PI 直接复制这段)

```
读 docs/CURSOR_LOOP.md 与 docs/TASK6_BRIEF.md。

先回答两件事(一句话即可):
1. 你内部的 task6 是不是「P-006 = GPB-015 流域唯一性」?不一致就说明你的编号。
2. P-005 的云端 dafny verify + lake build 是否已做?未做就先按 BRIEF §五结算。

确认后开工 P-006,严格按 BRIEF §三的 7 个文件与 §四的 10 条经验做。
重点:
  - 层 A(唯一性)与层 B(终止性)分开;终止性做不动就标 PENDING,先保证前 5 条引理。
  - 层 B 的 flat 环反例(P-006b)是科学资产,必须写进 README「没证什么」。
  - 轨道迭代用有界展开 stepN(h,c,n) 对 n 归纳,不要递归扫描(经验 E1)。
  - D8 核从 p005_d8 import,不要复制。
  - 本地先全绿再上云;每步回传用 CURSOR_LOOP §三的回报格式,给原始输出不要摘要。
```
