# Scientific Data 投稿对照清单（Data Descriptor）

依据：<https://www.nature.com/sdata/submission-guidelines>
（2026-09-08 对照现行网页）。期刊**不提供、也不建议**用任何 LaTeX 模板；强制的是第 1 节的小标题。

书面指南写“首轮最简单是一个含图的 PDF”。**当前 SNAPP 栏要求** LaTeX + 图/表打成 zip、由系统编译。以 SNAPP 为准。

**上传这两个文件**（`snapp_upload/`）：

| SNAPP 栏 | 文件 |
|---|---|
| Article | `snapp_upload/geoproofbench_latex.zip` |
| Covering letter | `snapp_upload/covering_letter.pdf` |

Zip 仅含 `geoproofbench.tex` + `figures/fig{1–4}_*.pdf`。封面信、PNG、脚本、中文 Word **不要**打进 zip。

本地预览：`geoproofbench.pdf`（与 `first_round/01_article.pdf` 相同，16 页）。源文件：`geoproofbench.tex`。无独立 `.bib`。

本地编译：`pdflatex geoproofbench.tex` 两次。重新打包：`python _pack_snapp.py`。

表单粘贴：`snapp_upload/SNAPP_FORM.md`。

---

## A. 不补就很难过编辑部初检

1. **审稿人可下载的数据包 URL**  
   Science Data Bank V1：https://doi.org/10.57760/sciencedb.011r9 （CSTR https://cstr.cn/31253.11.sciencedb.011r9），下载不受限制，CC-BY-4.0。GitHub 开发树 https://github.com/fariell/verifiable-geocomputation 已公开。正文 Data Availability 与此一致。

2. **不要把 `manuscript.md` 当投稿文件**  
   实验室 IMRaD 笔记不是 Data Descriptor。投 zip 里的 `geoproofbench.tex`。

3. **SNAPP 网页表单（和 zip 同等重要）**  
   - Article type = **Data Descriptor**  
   - 作者、单位、通讯邮箱、ORCID  
   - Funding（无外部经费也要勾；正文已有 Funding 节）  
   - Competing interests = No（**不要**写进 `.tex`）  
   - Author contributions（单作者也要填系统；**不要**写进 `.tex`）  
   - Data / Code 访问说明（填 DOI）  
   - APC / 减免（不要写在 cover letter）  
   - 相关已发表工作：SAM-GFNet（不共享数据）

---

## B. 指南条款核对（2026-09-08）

| 条款 | 指南要求 | 本稿 |
|---|---|---|
| Article type | Data Descriptor | 封面信 + 表单；不是 Article |
| 标题 | ≤110 字符；禁止冒号/括号；不要品牌名、novel/first/open 等广告词 | 70 字符；无冒号括号；GeoProofBench 不在标题里 |
| Abstract | ≤170 词；描述数据与用途；不写新发现；不放下载 URL；不分小节 | 168 词；无 URL |
| 作者单位 | 机构+国家，通讯邮箱 | NINT, Xi'an, China；`fariel_gyg@163.com`；ORCID |
| 强制小标题 | Background & Summary → Methods → Data Records → Data Overview（可选）→ Technical Validation → Usage Notes（可选）→ Data Availability → Code Availability → References；Funding 必须在正文 | 已对齐。Ethics 在 Methods 小节。Author Contributions / Competing Interests **已从正文删除**（SNAPP 表单） |
| Data Overview | 可选；**1 段文字 + 1–2 图或表**；不要写成结果节 | 1 段 + Fig 2 + Fig 3（2 图）。窗口表已移到 Data Records |
| 不要结论/分析结果 | Data Descriptor 不发 Discussion/Conclusion | 无 |
| 数据已可下 | 首轮任意可匿名下载 URL；推荐正式仓储 | ScienceDB 已开放 |
| Data Records | 文件、格式、目录、字段；数据集用数据引用格式 | 有；ScienceDB 条目为 Guo 2026 |
| Data Availability | 短段重复仓储/DOI（允许与 Data Records 重复） | 有 DOI + CSTR |
| Code Availability | 自定义代码如何获取；放在参考文献**正前** | Funding 之后、thebibliography 之前 |
| Funding | **必须写在论文里**（系统经费栏不发表） | 无外部经费 / 无基金号 |
| 参考文献 | 正文顺序编号；嵌在同一个 `.tex`；尽量 DOI 的 URL | `thebibliography`；DOI 均 `\url{}` |
| 内部链接 | 不要 `\cref` 等可点内部链接；写 Fig. 1 | `\ref*`（hyperref 不生成内部链）；DOI 仍可点 |
| 图/表 | 建议 ≤8 图、≤10 表；图注 ≤350 词；图按出现顺序 | 4 图 8 表；图注均 <150 词 |
| 首轮文件 | 书面：含图 PDF；**本 SNAPP：tex+图 zip** | `geoproofbench_latex.zip` |
| 封面信 | 系统必传；不作录用判断；**不要把数据下载只写在信里** | 独立 PDF；DOI 在正文 |
| 无模板 | 不要用 Overleaf/他刊模板 | `article` 类 |
| 字体 | 建议 Computer Modern | Latin Modern（`lmodern`，CM 后继，避免位图字） |
| SI | 能放正文就放正文 | 无 Supplementary |

实验室 `manuscript.md` 仍是 FORM LOCK，**不要**改那两份 md。

---

## C. 已处理的不符合项（相对改稿前）

- Data Overview 曾为两段 + 两图 + 一表（超出 1 段 / 1–2 件）。现为一段 + 两图；`tab:real` 改到 Data Records。
- Author Contributions / Competing Interests 已从 `.tex` 删除（SNAPP 会覆盖）。
- Methods 增加 Ethics 小节（无人体/动物）。
- 去掉主观 “No previous paper has published…” 句（指南：不要主观 novelty）。
- 图/表交叉引用改为 `\ref*`，避免内部超链。

仍须人工做的只有 **SNAPP 网页勾选**（上表 A.3）。语言润色仍可选、自费、不保证送审。

---

## D. 上传勾选

- [ ] Article：`snapp_upload/geoproofbench_latex.zip`
- [ ] Covering letter：`snapp_upload/covering_letter.pdf`
- [ ] 系统 Data Availability 填 ScienceDB DOI（审稿人看不到封面信）
- [ ] Competing interests = No；Author contributions 填系统
- [ ] 相关工作 SAM-GFNet + does not share data
- [ ] APC 只在系统答

不要上传：独立 PNG、中文送审稿、`manuscript.md`、ScienceDB 数据包 zip、Supplementary。

修订轮若编辑改口只要单个 `.tex`：同一 `geoproofbench.tex` 仍无 `.bib` 依赖；图按当时说明另传。

---

## E. 明确不必做

- 不要用 Springer Nature / Overleaf 旧 SciDA 模板。  
- 不要另附 `.bib` / `.bbl`。  
- 不要把 lake 缓存打进数据包。  
- 不要把数据下载步骤只写在 cover letter。  
- 不要把 GitHub 私有仓当作唯一仓储。  
- 不要为“书面指南说首轮 PDF”而改回只交 PDF——以你看到的 SNAPP 栏为准。
