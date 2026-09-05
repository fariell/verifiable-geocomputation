# 本周执行清单 · This Week (2026-09-05 起 1 周)

> Sprint 0 目标:跑通"agent 闭环"的最小实证 + 建立对外可见的研究门面。
> **方案:不注册域名,直接用 GitHub 免费地址分享整套成果。**
> 完整作战手册见 [`../AI4Math_DEM_Solo_Execution.md`](../AI4Math_DEM_Solo_Execution.md)。

---

## 你(PI)要做的 · 约 30 分钟

### □ 1. 在 GitHub 建空仓库(3 分钟)

访问 https://github.com/new:
- Repository name:`verifiable-geocomputation`
- Description:`Verifiable Geocomputation · 可验证空间计算`
- 选 **Public**
- ⚠️ **不要勾选** README / .gitignore / license(本地已有,勾选会冲突)

点 Create repository。

### □ 2. 推送(2 分钟,复制即可)

本地 `git init` 和首次 commit **已经完成**,你只需:

```bash
cd "E:/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation"
git remote add origin https://github.com/fariell/verifiable-geocomputation.git
git branch -M main
git push -u origin main
```

认证时:用户名 `fariell`,密码用 **Personal Access Token**(不是登录密码)。
生成:https://github.com/settings/tokens → Generate new token (classic) → 勾 `repo`

### □ 3. 启用 GitHub Pages(2 分钟)

仓库 → **Settings** → **Pages**:
- Source:`Deploy from a branch`
- Branch:`main` + 目录 `/site`
- Save

等 1–3 分钟,你会拿到:
```
https://fariell.github.io/verifiable-geocomputation/
```
**这就是你的公开网址**,可写进论文、简历、邮件签名。

### □ 4. 启用 Discussions 并开第一个 RFC(10 分钟)

- Settings → General → Features → 勾选 **Discussions**
- 新建 Discussion(Ideas 分类):
  `RFC: Defining verifiability metric for spatial operators`
- 把 D2 课题的初步想法贴出来,征求反馈

> 这是 Y0 最重要的早期信号——**有人回应就说明方向有人跟**。

### □ 5. 补上 About 与 Topics(3 分钟)

- repo 首页右上角 ⚙️ → 填 Description + 站点地址
- Topics 加:`gis` `dem` `formal-verification` `lean` `geocomputation` `spatial-analysis` `verifiable-computing` `ai-for-math`
- 个人主页 <https://github.com/fariell> 的 Bio 建议写:
  `Verifiable spatial computing · DEM terrain analysis · AI for Math · D0116 Geographic Big Data & Spatial Intelligence`

---

## 我和你一起做的

### □ 6. 核对并锁定作者信息(3 分钟)

打开 [`../AUTHOR.md`](../AUTHOR.md),逐项核对:

- [ ] 姓名拼写:`Yinggang Guo` / 郭迎钢
- [ ] 单位:`Northwest Institute of Nuclear Technology, Xi'an 710024, China`
- [ ] 邮箱:`fariel_gyg@163.com`(通讯作者)
- [ ] ORCID:`0000-0002-8207-9941`
- [ ] 学科口:`D0116 地理大数据与空间智能`(地球科学部 · 地球科学一处)

**确认后,该文件就是唯一权威署名源**——今后所有投稿、简历、CITATION.cff 一律从这里复制,不再凭记忆写。

站点地址已按 GitHub Pages 默认地址写死(`https://fariell.github.io/verifiable-geocomputation/`),无需再替换。

### □ 7. 攒 GeoProofBench 50 命题(agent 主跑)

- **输入**:从经典 DEM 文献抽出的性质(我先列候选,你 5 分钟抽审一次)
- **输出**:`benchmark/problems/v0.1.md`,50 条命题的表格
- 这是 P2 论文的弹药库,**这周就开始攒**

### □ 8. 初始化 Lean 4 项目(agent 主跑)

```bash
cd formal/lean4
lake new verigis
cd verigis && lake update
```
确认编译通过,提交。

### ✅ 9. 第一阶段实验已自动跑完(2026-09-05)

- 在 SeetaCloud 实例(128 核/1TiB/无 GPU)上自动装机 + 跑通 `experiments/phase1`:
  - 合成 DEM 算子可复现性实验:一阶算子(坡度/梯度)vs 解析真值 corr > 0.9999;二阶曲率 corr 仅 0.157(即"粗网格下曲率不可验证",本方向要解决的真实缺口)。
  - 生成 GeoProofBench v0.1 的 20 条候选命题(json/csv/md)。
  - 产出与日志已拉回本地 `experiments/phase1/results/`,报告见 [`experiments/phase1/REPORT.md`](../experiments/phase1/REPORT.md)。
- Lean 4 因 elan 在 github 发布页重定向上挂起,已超时跳过(非必需);`bootstrap.sh` 已加固为固定版本 + 超时,下次可直接重跑。
- ⚠️ 该实例 `nvidia-smi` 缺失,未挂载 GPU;Phase 1 纯 CPU 无影响,但 Y2 本地大模型评测前需确认显卡可见。

---

## 周末验收 · 三件事

1. **网址可访问**:`https://fariell.github.io/verifiable-geocomputation/` 能打开
2. **50 条命题**:是否经得起你 5 分钟抽查?
3. **下次接续**:MEMORY.md 标注能否让你零成本接续?

**全达标** → 按 2 周/sprint 推第一档 6 个 M 题
**不达标** → 调协作模式(更细的 PI 介入点 / 更小任务),再放大

---

## 不在本周做

- ❌ 青C 相关准备(按你的要求延后)
- ❌ P0–P4 论文动笔
- ❌ 域名注册(已决定不做)
- ❌ 对外宣传(门面先立住)

---

## 一个判断

> **本周最重要的产出不是代码,是"对外可见的研究门面"。**
> repo 立住了、Pages 能访问了、Discussions 有人来了,后续所有工作才有"挂在墙上"的地方。
> 立不住,你做的所有东西都只是散落在硬盘里的文件。

---

_v0.2 · 2026-09-05 · 去掉域名环节,聚焦 GitHub 分享_