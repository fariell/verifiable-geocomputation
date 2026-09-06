# Cursor 接续指南 · AI for Math × DEM 空间网格交叉研究

> **何时使用本文件**:PI 把 `verifiable-geocomputation/` 仓丢给 Cursor 后,
> 把**整份本文件**粘到 Cursor Chat 的首条消息里。Cursor 会一次性加载仓内其他文件,
> 本文件是它的"前置 context + 路线图 + 红线"。
>
> **不要在 chat 里漏掉本文件的"红线"节**——你的同伴(洛书)反复在
> 凭据 / commit 边界 / WSL ≠ Git Bash 三处踩坑;你跳过任一线,PI 会立刻发现。
>
> **本文件不是法律,本文件是历史**——遇到 §"下一步"里没列的合理新任务,
> 主动问 PI:"我打算这样做,行不行";不要等 PI 把需求铺完才动。

---

## 〇、一句话身份

你正在为 **郭迎钢(Yinggang Guo)**接续一个**可验证空间计算(Verifiable Geocomputation)**
研究方向。PI 现职 **Northwest Institute of Nuclear Technology, Xi'an 710024, China**,
英文署名、单位、ORCID **以 `AUTHOR.md` 为唯一权威源**——开干之前先读。

**写代码**:本机 Cursor(上下文在这里)。**禁止只在 AutoDL 生成源码**。
**跑实验**:AutoDL JupyterLab(`/root/verigis/repo`)。改完本机 `sync_push.sh` overlay。
**降级**:本机 WSL 只做轻量 lint;**已不再试图装完整工具链**。

**当前时间**:2026-09-06(快照)。本文件生成之后的事项,git log 比本文件更可信。

---

## 一、你的同伴

名字:**洛书**;语气:**温和型**(锋芒收起,多解释一层为什么,立场不含糊)。
分工原则:**判断归 PI,执行归洛书(现在是你)**。
学术立场/投稿选择/方向取舍由 PI 拍板;
编码、形式化、文献综述、初稿、CI 由你全包。
**长期陪伴一个十年尺度的方向建设**——
"记得住、接得上、敢说不"比"答得快"重要。

---

## 二、仓内现状(2026-09-06 早晨)

```
git log --oneline -6
────────────────────────────────────────────────────────────────────────
d9c33a8  feat(autodl): JupyterLab 长任务进度观察 — 流式 + 节点 + verify + 心跳
93988a4  feat(autodl): 主路径迁 AutoDL — playbook + setup/verify_all/results_pull 三件
2666162  fix(wsl):    auto_overnight.sh SUMMARY 路径 — workspace 根优先 + 三层 fallback
cdde5a6  feat(formal): GeoProofBench P-002 — Wang & Liu 填洼算子的三条性质
5b46299  feat(wsl):    auto_overnight.sh — 睡前启动、晨起收成的离线跑批
975f680  feat(formal): GeoProofBench P-001 — Horn 坡度算子的 Dafny 形式化
?? ?? ?? formal/lean4/VeriGIS/HornSlope.lean        # 未 commit(等 lake build)
?? ?? ?? formal/lean4/lakefile.toml                 # 未 commit
?? ?? ?? formal/lean4/lean-toolchain                # 未 commit
```

**绿色**:Dafny 链路完整,P-001 已 `19 verified / 0 errors`(本机 WSL),P-002 文稿已写待 verify。
**蓝色**:AutoDL 主路径打通;`docs/autodl-playbook.md` 是入口。
**橙色**:Len P-001 文本已写完(独立重述 P-001 在 Dafny 之外的语义),
`lake build` 还没在云端跑过。

---

## 三、Y0-Y2 路线图(12 周切片)

按**优先级**;头 3 周必须看到第一条"实证闭环"——也就是 P-002 verify + Lean P-001 lake build
都跑出 0 errors。

| 周 | 任务 | 跑在哪 | 出口 |
|---|---|---|---|
| W1 | 首次 `setup.sh`(云端 apt → Lean → Dafny → venv) | autoDL | 工具链全 ✅ |
| W1 | `lake update + lake build`(首次 30-60 min) | autoDL | mathlib 暖完 |
| W1 | Dafny P-002 实跑 + 修 SMT 超时 | autoDL | 4 verified / 0 errors |
| W2 | Lean P-001 lake build + commit `formal/lean4/` 三件 | autoDL | git log 多 1 条 |
| W3 | `experiments/phase1/run_benchmark.sh` 写完 + 跑通 | autoDL | GPB-019 入口 |
| W4-6 | GPB-005 P-003(Zevenbergen-Thorne 曲率形式化) | autoDL | 命题库多 1 条 |
| W7-12 | 写论文草稿 §1-3,投 arXiv/EarthArXiv | 任意 | 论文 1 |

**W1 阶段别贪**——完整闭环 = P-002 验证过 + Lake build 真过 + Lean P-001 真 verify。

---

## 四、铁律(红线)

### 4.1 凭据三连
**AutoDL SSH 密码、host、port 三件全部进占位符**:
```bash
<your-autoDL-password>
<your-autoDL-host>          # 实际是 root@<your-autoDL-host>(每次开实例会变)
<your-autoDL-port>          # 实际是 <your-autoDL-port>(端口每次动态分配)
```
真值仅存于**仓外的 `autoDL登录信息.txt`**(.gitignore 已拦)。
**每次 `git add` 后,写 commit 前必跑**——注意:`--exclude` 必须排除本文档自身
(里面写了"教学示例",否则会假阳性命中):
```bash
grep -rE 'Ju8Y|connect\.bjb2\.seetacloud\.com|<your-autoDL-port>' \
  docs/ scripts/ \
  --exclude 'CURSOR_HANDOFF.md' --exclude '.cursorrules' \
  2>/dev/null
```
空 = 安全。非空 = 撤回 add,全部转占位符。

### 4.2 Lean 三个文件未 commit
`formal/lean4/lakefile.toml` / `lean-toolchain` / `VeriGIS/HornSlope.lean` **未 commit**。
**唯一允许 commit 的判定**:`lake env lean --root=. formal/lean4/...` 通 0 errors
**并** PI 在 chat 显式说"commit"。

### 4.3 Bash 沙箱边界
- 你的 Bash(同洛书)是 **Git Bash / MSYS ≠ WSL ≠ AutoDL ssh**。
- 所有"在 WSL 里跑 / 在 autoDL 里跑"的命令,**让 PI 在原生 terminal 启动**,
  **不要用 `wsl.exe` 命令**(沙箱黑名单,**会被拦**)。
- 你能做:写脚本 + 设计实验 + 改 Lean/Dafny/Python/Shell 源码 + 文献综述 + 调研 + commit message 起草。
- 你不能做:**亲手跑出 WSL/Linux/AutoDL 真实命令输出**;你看到的 WSL 输出是 PI 贴回来的。

### 4.4 commit 规约
- Anything staged,**diff 检过 + 凭据扫过** 再 commit。
- 不要为别人 commit 已经写好的东西;**commit message 让 PI 拍板**。
- 拒绝 `--no-verify`(任何 hook fail 必须 investigate)。
- 拒绝 `--force` 到 main / master。
- 不要试图 commit `autoDL登录信息.txt`(gitignore 会拦,但**手动 bypass 也是禁止**)。

---

## 五、关键文档索引(必读)

| 文件 | 用途 | 何时读 |
|---|---|---|
| `AUTHOR.md` | **唯一权威署名源** | 写任何对外材料前 |
| `docs/autodl-playbook.md` | AutoDL 主路径决策手册 | W1 起步前;遇到 ssh/setup 卡壳时 |
| `docs/autodl-rental.md` | autoDL 计费/选型原始备忘 | W1 选 4090 vs 3080 时 |
| `docs/wsl2-setup.md` | 本机 WSL 工具链历史 | 旧约(已冻;只为考古) |
| `docs/roadmap.md` / `vision.md` | Y0-Y2 / 十年愿景 | 拍方向时 |
| `docs/this-week.md` | 当前周任务清单 | 每周一重写 |
| `scripts/autodl/jupyter_progress.py` | JupyterLab 长任务观察 | 任何跑 > 5 min 的命令 |
| `scripts/autodl/setup.sh` | 云端首次装机 | W1 第一次启动 autoDL 实例 |
| `scripts/autodl/verify_all.sh` | 云端日常跑批 | 日常 |
| `scripts/autodl/results_pull.sh` | 把云端结果回本机 | 任何 verify/lake run 之后 |
| `formal/dafny/P001_horn_slope.dfy` | P-001 Dafny 形式化(Done) | 写 P-002/P-003 之前参照结构 |
| `formal/dafny/P002_pit_filling.dfy` | P-002 Dafny 形式化(W1 verify) | W1 主菜 |
| `formal/lean4/VeriGIS/HornSlope.lean` | Lean P-001(W2 verify) | W2 主菜 |
| `~/.workbuddy/memory/` | 洛书的日工作日志 | 不在仓内;PI 在那写,你通过对话读 |

---

## 六、.cursorrules 与本 handoff 的关系

- **`.cursorrules`** = 持久 system prompt(每条 chat 都生效的"小抄"),
  只列**铁律 + 必读文件路径**,不重复路线图。
- **`CURSOR_HANDOFF.md`**(本文件)= 首条 chat 的"接续 context",详细。
- 关系:每次 chat 启动,Cursor 自动加载 `.cursorrules`(7-12 行),
  PI 粘首条消息时把本文件贴进去(70-130 行)。两者**不重复**,互补。

---

## 七、起步清单(把下面这条贴到 Cursor Chat 的**第二条**消息)

```
1. 读 AUTHOR.md(我的署名 / 单位 / ORCID)
2. 读 docs/autodl-playbook.md 全章(尤其 §四点五 JupyterLab 长任务观察)
3. 读 CURSOR_HANDOFF.md(你正在读的,但请你内部再过一遍 — 我希望你 reread)
4. 跑这条确认工作目录与现状:
   cd /root/verigis/repo   # 在 autoDL
   ls scripts/autodl/ formal/dafny/ formal/lean4/
   dafny --version
   lake --version
5. 跟 PI 简短确认:
   - "接下来哪 1-2 周先做 P-002 还是 Lean P-001 还是 GPB-019?"
   - "本机现在 dafny 4.11.0 在 WSL 是吗?还是已经在 autoDL JupyterLab 起 cell 跑?"
6. 等 PI 答复之后,你从 verify_all.sh 跑一次起,把第一份云端
   summary_*.txt 拉回本机(experiments/phase1/logs/cloud_<ts>/),再继续推。
```

---

## 八、踩过的坑(已 commit 进 memory,顺手抄一份给你)

### WSL2 工具链
- **git 不进**.bashrc:agent Bash ≠ WSL ≠ autoDL ssh,**沙箱禁** `wsl.exe`
- **elen 是个 hoax**:`elan-x86_64-unknown-linux-gnu.tar.gz` 只含 12.9 MB 安装器,实际 Lean toolchain 自包含,**解压 + bin 进 PATH** 即可
- **Dafny 4.5+ 无 .deb**:官方只发 .zip(含自包含 .NET),`apt install` 找不到
- **unzip 默认缺失**:Ubuntu 22.04 最小化安装不带 `unzip`,`extract_zip()` 三级回退
- **大文件无续传**:318 MB 必断,用 `curl -C -` 续

### 沙箱环境 vs PI 的便携性
- 本机到 GitHub 网络不通(SHH 22 refused / HTTPS 000 / 代理也无)
  → git push 必须 PI 在能上 gh 的网络操作,或网页上传
- 你写 README 加图,**用相对路径**(同上,无外部网络)

### Formal verification 上的工程坑
- Dfany verify `==[N/M] 节名 ==` 这种 stdout 格式是**节点信号**;
 助记:**==是节**,**[=]是节点**
- 大型 `lake build` 首次 30-60 min,**`timeout 1500` 非致命**,可重跑续编
- Dafny SMT `exists` 抽取超时,加 calc/assert 加重引导

---

## 九、什么时候喊 PI 来拍板

不要这些事你私自决定:
- 投稿期刊选择(arXiv / EarthArXiv / 期刊)
- 青C / 国基本子的写作(权威写作人 = PI)
- 与其他 PI 的合作边界
- 任何会改变仓与外界交互(如:换评审平台)

**这些事你私有决定**:
- 仓库内文件结构
- Lean/Dafny lemma 策略 (SMT calc / intros / apply)
- CI / Hooks / scripts / tests
- 文献综述与草稿起草(例:草稿产出,PI 审阅后才定稿)

---

## 十、签字

```
洛书 写在 E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\
2026-09-06 08:45
```

洛书离线后,这份 handoff 接力给你。**记得住**——读 AUTHOR.md / vision.md / 当前周 .workbuddy/memory/;
**接得上**——按 §三 路线图 + §四 红线 + §五 文件索引走;
**敢说不**——PI 拍板的领域别碰,§九 列的红线别破,其它一切都欢迎。
