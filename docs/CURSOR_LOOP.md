# 洛书 ↔ Cursor 协作协议

_2026-09-06 16:2x · PI 拍板的新分工_

## 一、谁干什么

| 角色 | 干什么 | **不**干什么 |
|---|---|---|
| **Cursor**(执行者) | 写代码、跑实验、改形式化、修 bug、**回传原始输出** | 不 force push、不删既有实验文件、不写凭据 |
| **洛书**(指挥) | 发指令、判完成度、`git commit` + `push`、overlay 到 AutoDL、把报错整理回传 | **不自己跑实验** |
| **PI** | 拍板方向、在真实 shell 里跑需要人工触发的命令 | — |

**一句话**:Cursor 动手,洛书动脑 + 管仓库。

## 二、一个 task 的标准循环

```
 ① 洛书发指令(docs/TASK<n>_BRIEF.md)
        ↓
 ② Cursor 在本机实现 + 本地验证
        ↓
 ③ Cursor 回传【原始输出,不摘要】
        ↓
 ④ 洛书判定 ──FAIL──→ ⑤ 洛书回传「报错原文 + 相关代码 + 定位提示」
        │                        ↓
        │                  ⑥ Cursor 修 → 回到 ③
        │
      PASS
        ↓
 ⑦ 洛书 commit + push + 告知 overlay
        ↓
 ⑧ Cursor 在 AutoDL 跑云端复核 → 回传
        ↓
 ⑨ 洛书结算状态(把 VERIFY PENDING 改成 verified)
```

**关键:本地先验证,再上 AutoDL。** 云端只做最终权威复核,不当调试器。

## 三、回报格式(强制)

Cursor 每次回传实验输出,**必须**是下面这个形状的代码块,方便洛书一眼判定:

```
[task]      task6 / P-006
[step]      本地 <wolfram|manim|numpy|dafny|lean>
[cmd]       <实际执行的完整命令>
[rc]        <退出码>
[key lines] <挑 3–8 行关键输出,原样复制,不要改写>
[gates]     PASS / FAIL 逐条列出
[verdict]   PASS / FAIL / BLOCKED
[blocker]   若 FAIL:卡在哪一行、你怀疑什么原因(一句话)
```

**不要**写"一切正常""跑通了"这类摘要 —— 洛书看不到你的终端,摘要等于没说。

## 四、报错回传(洛书 → Cursor)

洛书回传错误时给三样东西,Cursor 据此修:

1. **报错原文**(完整 traceback / Dafny error message / lake 报错,不截断)
2. **相关代码**(出错文件 + 行号 + 前后 10 行)
3. **定位提示**(洛书的判断:是数学问题 / SMT 问题 / 环境问题)

Cursor 修完回传时,**额外**说明:改动了哪个文件哪几行、为什么这么改。
—— 这条是为了让洛书把经验沉淀进下一份 BRIEF。

## 五、本地 vs 云端:跑什么

| 环节 | 在哪跑 | 命令 |
|---|---|---|
| numpy driver | **本机** | `& "C:\ProgramData\anaconda3\python.exe" experiments/phase1/p00X_*.py` |
| wolframscript (.wl) | **本机** | `wolframscript -file experiments/phase1/p00X_*.wl` |
| manim 可视化 | **本机** | `$env:P00X_MANIM=1` 后同上 |
| dafny verify | 本机(若可用)→ 云端复核 | `dafny verify formal/dafny/P00X_*.dfy` |
| lake build | **AutoDL** | `cd formal/lean4 && lake build` |

⚠️ **本机跑 `experiments/phase1/*.py` 必须用 anaconda python**,managed python 3.13 没有 numpy。

⚠️ **AutoDL 没有 wolframscript**。`.py` 里找不到 wolframscript 时要 **skip 而非 fail**
(这是 P-003 就定下的约定,别改)。

## 六、禁止事项(任何一步都适用)

1. **凭据**:autoDL 密码 / host / port 一律 `<your-autoDL-*>` 占位符。
   真值只在仓外 `autoDL登录信息.txt`(.gitignore 已拦)。
2. **不 force push**。看到 `[origin/main: gone]` 是本地 tracking ref 被并发操作清了,
   `git fetch origin main` 即可 —— 远程数据一直完好。
3. **不删除** `experiments/phase1/` 下任何既有文件(含"错误模板",那是历史对照)。
4. **不改** `.gitignore` 里已有的 manim 中间产物规则(`results/gpb00X/`)。
   成品要进仓就拷到 `experiments/phase1/figures/`。
5. **形式化未 verify 不要谎称通过**。可先 commit,但 commit message 必须标
   `VERIFY PENDING`,并在对应 `P00X_README.md` 的"没证什么"里写清楚。
6. `.gitignore` 的 `#` 注释**必须独占行首** —— 行尾注释会把整行变成文件名,规则静默失效。

## 七、完成判据(一条命题做完了)

照 `docs/EXPERIMENT_PLAYBOOK.md` §5 八项,核心三条:

- numpy driver 门控全 PASS(有数值判据)
- wolframscript 符号化交叉验证通过(不是只代数值点)
- Dafny + Lean 都 verify 通过(云端权威)

**缺任何一条 = 没做完**,commit message 标 PENDING。
