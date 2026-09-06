# 实验工序手册 · 给 Cursor 的标准作业流程

> **给谁**:接手 `verifiable-geocomputation` 的 AI(Cursor / 洛书分身 / 其它)。
> **何时读**:每次开一条新命题(P-00X)之前;不确定某个步骤该在哪台机器跑时。
> **上位文档**:`CURSOR_HANDOFF.md`(项目全貌)、`.cursorrules`(4 条铁律)。
> **本文件只管一件事**:一个命题从 0 到 DONE 的标准工序。
>
> 更新:2026-09-06 13:20(环境格局有重大变化,见 §1)

---

## §1 本机 / 云端分工(2026-09-06 重新测定,**已推翻旧认知**)

| 能力 | 本机 (Win + Git Bash) | WSL | AutoDL |
|---|---|---|---|
| **wolframscript** | ✅ `/c/Program Files/Wolfram Research/WolframScript/wolframscript` | ? | ❌ **没有** |
| **manim** | ✅ `/c/ProgramData/anaconda3/Scripts/manim` | ? | ? |
| **numpy** | ✅ anaconda py **3.12.7** / numpy 1.26.4 | ? | ✅ venv |
| **dafny** | ❌ | ✅ 4.11.0 | ✅ |
| **lake / lean** | ❌ | ❌ 未装 | ✅ |
| **git push** | ✅ **现在通了**(GCM 已配,`user.name=fariell`) | — | — |

### ⚠️ 三条硬结论(别再踩)

1. **符号计算必须在本地跑**。`wolframscript` 只在 PI 本机有,AutoDL 没有。
   Cursor 的 `p003/p004` driver 里那句 "AutoDL has no wolframscript" 是真的,
   所以云端跑实验时 wolfram 那步会**静默 skip** —— 想要 wolfram 结果,**必须回本机跑**。
2. **`experiments/phase1/*.py` 用 anaconda python 跑**,不是 managed python:
   ```bash
   "/c/ProgramData/anaconda3/python.exe" experiments/phase1/p005_d8.py
   ```
   managed python 3.13.12 **没有 numpy**,直接 `python xxx.py` 会 ImportError。
3. **本机到 GitHub 已经能推**(2026-09-06 实测 `git push origin main` 成功)。
   旧 memory 里"本机网络不通"**已过期**,不要再拿它当不 push 的借口。

### 分工铁律

```
符号计算 (.wl)      → 本机 anaconda python
可视化  (manim)     → 本机 anaconda python
形式化  (.dfy/.lean)→ AutoDL(dafny verify / lake build)
numpy 对照           → 两边都行;driver 必须"缺 wolfram/manim 也能 PASS"
```

---

## §2 一个命题的标准三件套(沿用 Cursor 已建立的约定)

每个 `P-00X` 产出 **6 个文件**,缺一不可:

| 文件 | 作用 | 跑在哪 |
|---|---|---|
| `formal/dafny/P00X_*.dfy` | Dafny 形式化 | AutoDL `dafny verify` |
| `formal/lean4/VeriGIS/*.lean` | Lean 对偶(**独立重述**,别翻译) | AutoDL `lake build` |
| `formal/dafny/P00X_README.md` | 命题说明:证了什么 / 没证什么 / 怎么跑 | — |
| `experiments/phase1/p00X_*.py` | numpy driver + `subprocess` 调 wolfram/manim | 本机 anaconda |
| `experiments/phase1/p00X_*.wl` | Wolfram **独立复算**(从数学式重新推,不信 Dafny) | 本机 wolframscript |
| `experiments/phase1/p00X_manim.py` | Manim 场景 | 本机 manim |
| `experiments/phase1/run_p00X.sh` | runner(云端用 `$VENV/bin/python`) | AutoDL |

再动两处索引:
- `formal/lean4/VeriGIS.lean` 加 `import VeriGIS.<NewModule>`
- `scripts/autodl/verify_all.sh` 加 P-00X 的 dafny 块 + 实验块

### 为什么 `.wl` 必须"独立复算"

`.dfy` 证明"我写的算子满足命题";`.wl` 从**数学定义重新推一遍**同一算子。
两边对上 ⇒ 形式化没写错算子;对不上 ⇒ 至少一边有 bug。
**这是交叉验证,不是重复劳动。** P-005 就是三方一致(Dafny / numpy / Wolfram 都给 W 和 NW)。

---

## §3 wolframscript 调用模板(照抄,别改结构)

Cursor 的 `p005_d8.py::eval_wolfram()` 已经是好模板,固化如下:

```python
def eval_wolfram(dest: str) -> dict:
    exe = shutil.which("wolframscript") or shutil.which("wolframscript.exe")
    wl  = os.path.join(HERE, "p00X_name.wl")
    payload = {"available": False, "reason": "wolframscript not on PATH"}
    if not exe:                       # 云端没装 → skip,绝不能 fail
        print("  wolframscript: skip (%s)" % payload["reason"]); return payload
    if not os.path.isfile(wl):
        payload["reason"] = "missing .wl"; return payload
    try:
        proc = subprocess.run([exe, "-file", wl],
                              capture_output=True, text=True,
                              timeout=90, cwd=HERE)
    except (OSError, subprocess.TimeoutExpired) as err:
        payload["reason"] = str(err); return payload
    stdout = (proc.stdout or "").strip()
    payload.update({"available": proc.returncode == 0,
                    "returncode": proc.returncode, "stdout": stdout[-2000:]})
    # JSON-BEGIN / JSON-END 优先,退化到最后一个 {...}
    s, e = stdout.find("JSON-BEGIN"), stdout.find("JSON-END")
    blob = stdout[s+len("JSON-BEGIN"):e] if s >= 0 and e > s else ""
    if not blob:
        s, e = stdout.rfind("{"), stdout.rfind("}")
        blob = stdout[s:e+1] if s >= 0 and e > s else ""
    if blob:
        try: payload["parsed"] = json.loads(blob.strip())
        except json.JSONDecodeError: pass
    with open(os.path.join(dest, "p00X_wolfram.txt"), "w", encoding="utf-8") as fh:
        fh.write(stdout + "\n")
    return payload
```

**.wl 脚本约定**:
- 末尾 `Print["JSON-BEGIN"]; Print[ExportString[<|...|>, "RawJSON"]]; Print["JSON-END"]; Exit[0]`
- `Exit[0]` 必须有,否则 rc 可能非 0
- 用 `Assuming[...]` 做**符号化**验证,不要只代 A=1,w=1 的数值点
  (数值点只能证"这组数对",符号化才证"所有参数都对")

**本机自测一条**:
```bash
wolframscript -file experiments/phase1/p005_d8.wl
```
期望:输出 `A=1 B=0 -> W`、`A=1 B=1 -> NW` + JSON 块,rc=0。

---

## §4 manim 可视化模板

```python
def maybe_manim(dest: str) -> dict:
    info = {"rendered": False}
    cmd = [sys.executable, "-m", "manim", "-ql", "--disable_caching",
           "--media_dir", dest, os.path.join(HERE, "p00X_manim.py"), "SceneName"]
    if os.environ.get("P00X_MANIM", "0") != "1":
        print("  manim: skip (set P00X_MANIM=1 to render)")
        info["cmd"] = " ".join(cmd); return info
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    info["returncode"] = proc.returncode
    info["rendered"] = proc.returncode == 0
    if proc.returncode != 0:
        print((proc.stderr or proc.stdout or "")[-800:])
    return info
```

要点:
- **默认关闭**,用 env `P00X_MANIM=1` 开 —— 渲染慢,不能拖慢每次实验
- `-ql` 低质量快速预览;要正式片再 `-qh`
- `--media_dir` 指向 `results/gpb00X/`(该目录已被 .gitignore 拦,中间产物不进仓)
- **成品要进仓**:把最终视频/关键帧拷到 `experiments/phase1/figures/` 再 commit
  (参照 `38b486c` 保留 P-003 视频与图的做法)

**本机渲染一条**:
```bash
cd experiments/phase1
P005_MANIM=1 "/c/ProgramData/anaconda3/python.exe" p005_d8.py
```
期望 `manim rc=0`,产物在 `results/gpb005/videos/p005_manim/480p15/D8Stencil.mp4`。

---

## §5 完成判据(什么叫"这条命题做完了")

一条 `P-00X` 只有**全部打勾**才算 DONE:

- [ ] `formal/dafny/P00X_*.dfy` — `dafny verify` 报 `N verified, 0 errors`(AutoDL)
- [ ] `formal/lean4/VeriGIS/*.lean` — `lake build` 0 errors(AutoDL)
- [ ] `p00X_*.py` — numpy gates 全 PASS(**本机 anaconda**)
- [ ] `p00X_*.wl` — wolframscript 输出与 Dafny 断言一致(**本机**,云端会 skip)
- [ ] `p00X_manim.py` — `manim rc=0`(**本机**,`P00X_MANIM=1`)
- [ ] `P00X_README.md` — 写清"证了什么 / **没证什么** / 怎么跑"
- [ ] `scripts/autodl/verify_all.sh` 已接入
- [ ] commit + push

**形式化未 verify 时也可以先 commit**,但 commit message **必须**写明
`VERIFY PENDING`(参照 `ffa49cb`)。**不许把 pending 写成已完成。**

---

## §6 实验顺序(接 P-005 往后)

命题库 20 条(`experiments/phase1/propositions.py`),已覆盖:
GPB-001/002/019 (P-001)、005/006/020 (P-002 + bis)、003 (P-003)、
019 (P-004)、**010/011 (P-005,刚做完)**。

### 下一步:`P-006 = GPB-015 流域唯一性`(推荐主线)

> GPB-015 (watershed, difficulty 4):
> "Every interior cell belongs to exactly one watershed basin under a
> deterministic flow-routing rule."

**为什么是它**:
1. `formal/dafny/P005_README.md` 已埋伏笔:"流域唯一是 GPB-015"
2. 科学连贯:D8 流向确定性 (P-005) → 流域划分唯一性 (P-006),一条完整故事线
3. 论文价值高,流域是水文核心算子

**但要先把 P-005 的形式化验证补上**,再开 P-006 —— 顺序不能乱:

```
[立即] 1. AutoDL: bash scripts/autodl/verify_all.sh
           → 拿 P-005 的 dafny verify + lake build 结果
       2. 若 FAIL:修 P005_d8.dfy / D8.lean,重跑
       3. 若 PASS:commit "P-005 verified",把 ffa49cb 的 PENDING 状态结算掉
[然后] 4. 开 P-006 (GPB-015),按 §2 三件套 + §3 §4 模板
```

### 备选(快速扩充覆盖率,可与主线并行)

| 命题 | 算子 | 难度 | 为什么快 |
|---|---|---|---|
| GPB-016 | TPI | 2 | 平面上 TPI = 0,一行公式 |
| GPB-017 | TRI | 2 | 非负性 + 平面为零 |
| GPB-009 | hillshade | 3 | 平面 = 255·sin(altitude) |
| GPB-004 | aspect | 3 | 东向坡 aspect = 90°(注意 cartographic 约定!) |

这几条 difficulty 2–3,**一天能出 2–3 条**,适合把 GeoProofBench 的覆盖率先拉起来。

---

## §7 每次开新命题前的自检

1. 读 `CURSOR_HANDOFF.md` §四 铁律(凭据 / Lean 边界 / 沙箱 / commit)
2. 确认分工:哪些步骤本机、哪些 AutoDL(§1)
3. 建 6 个文件 + 2 处索引(§2)
4. 本机先跑通 driver + wolfram + manim,**再** sync 到云端验形式化
5. 形式化 verify 结果出来再结算 commit 状态(§5)
6. `git add` 后必跑凭据扫描。**注意排除三份文档自身** —— 它们为了教
   "该扫什么"而写了真值片段,不排除会假阳性命中自己:
   ```bash
   git diff --cached -- . \
     ':(exclude)CURSOR_HANDOFF.md' \
     ':(exclude).cursorrules' \
     ':(exclude)docs/EXPERIMENT_PLAYBOOK.md' \
     | grep -cE '<your-autoDL-password>|<your-autoDL-host>|<your-autoDL-port>'
   ```
   返回 0 才能 commit。
   (真值只在仓外的 `autoDL登录信息.txt`,`.gitignore` 已拦)

---

## §8 已验证可跑的命令清单(本机,2026-09-06 实测)

```bash
# 1. wolframscript 独立复算
wolframscript -file experiments/phase1/p005_d8.wl
# → A=1 B=0 -> W ; A=1 B=1 -> NW ; rc=0

# 2. driver(numpy + wolfram,gates)
"/c/ProgramData/anaconda3/python.exe" experiments/phase1/p005_d8.py
# → 3 gates 全 PASS ; GPB-010/011 ENTRY: PASS

# 3. manim 渲染
cd experiments/phase1
P005_MANIM=1 "/c/ProgramData/anaconda3/python.exe" p005_d8.py
# → manim rc=0

# 4. 推送(GitHub 已通)
git push origin main
# → 5bc667d..827a597 main -> main

# 5. AutoDL 形式化验证(需要 PI 在云端触发)
bash scripts/autodl/verify_all.sh
```

---

## §9 粘给 Cursor 的消息模板(PI 直接复制这段)

```
先读这三份,按顺序:
  1. CURSOR_HANDOFF.md        (项目全貌 + 4 条铁律)
  2. docs/EXPERIMENT_PLAYBOOK.md  (标准工序:本机/云端分工、三件套、模板、完成判据)
  3. .cursorrules             (持续小抄)

当前状态:
  P-001 ~ P-005 已写完并 commit,push 到 origin/main(commit 827a597)。
  P-005 的**实证半边已在本机跑通**(numpy gates 全 PASS、
  wolframscript 独立复算 W/NW、manim rc=0),
  但**形式化半边(Dafny / Lean)还没 verify** —— commit ffa49cb 标了 VERIFY PENDING。

你的任务,按顺序来,每步做完先报结果再走下一步:

  [1] 在 AutoDL 跑:bash scripts/autodl/verify_all.sh
      重点看 P-005 的 dafny verify 与 lake build 是否 0 errors。
      (本机没有 dafny/lake,这步只能在云端跑)

  [2] 若 P-005 verify 通过:
      - commit 一条 "P-005 verified",把 ffa49cb 的 PENDING 状态结算掉
      - 然后开 P-006 = GPB-015 流域唯一性(P005_README 里埋的伏笔)

  [3] 若 P-005 verify 失败:
      - 贴出完整报错,修 P005_d8.dfy / VeriGIS/D8.lean,重跑
      - 不要绕过验证直接 commit 成"完成"

  [4] 开 P-006 时严格按 EXPERIMENT_PLAYBOOK §2 的 6 文件 + 2 处索引,
      §3/§4 的 wolframscript 与 manim 模板照抄。
      记住分工:符号计算(.wl)和可视化(manim)在**本机 anaconda python** 跑,
      形式化验证在 **AutoDL** 跑 —— 云端没有 wolframscript。

  [5] 每条命题的完成判据见 §5,八项全打勾才算 DONE。

环境事实(2026-09-06 实测,别再按旧印象走):
  - 本机有 wolframscript、manim、anaconda numpy 1.26.4
  - 本机到 GitHub 已能 push(GCM 已配,user.name=fariell)
  - AutoDL 有 dafny 和 lake,**没有 wolframscript**
```

---

*洛书 2026-09-06 13:20 写于 P-005 落地之后*
