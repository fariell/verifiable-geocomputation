# Scientific Data 首轮投稿包

依据：[Submission Guidelines](https://www.nature.com/sdata/submission-guidelines)

## SNAPP 这一栏要什么

书面指南仍写：首轮最简单是 **一个含图的 PDF**；修订轮再交独立 `.tex`。

你当前的 SNAPP 上传页要求：

> LaTeX documents with figures and tables compressed into a .zip format. We will compile these into a PDF for peer review.

**按 SNAPP 上传 zip。** 封面信仍是单独 PDF。

期刊不提供、不建议任何 LaTeX 模板。

## 实际上传文件（在上一级 `snapp_upload/`）

| SNAPP 栏 | 文件 |
|---|---|
| Article / Manuscript | `../snapp_upload/geoproofbench_latex.zip` |
| Covering letter | `../snapp_upload/covering_letter.pdf` |

本目录备份：`01_article.pdf`（本地编译预览，一般不必传）、`02_covering_letter.pdf`（与 covering_letter.pdf 相同）。

不要传：独立插图、Supplementary、`manuscript.md`、中文 Word。

## SNAPP 勾选

见 `../snapp_upload/SNAPP_FORM.md`。要点：

- Article type: **Data Descriptor**
- Title 与 PDF 一致（≤110 字符、无冒号、标题里无 GeoProofBench）
- Funding: none (institutional time; no grant number)
- Competing interests: No（不要写进 `.tex`）
- Author contributions: 单作者，只填系统
- Data availability：https://doi.org/10.57760/sciencedb.011r9
- 相关已发表：SAM-GFNet，DOI 10.3390/rs17223662，**does not share data**
- APC 减免：只在系统里答

## 封面信

指南规定封面信**不参与录用判断**，但系统必须传一个文件。数据下载说明**必须写在正文**。`02_covering_letter.pdf` 已按终稿：标题与文章一致、6+5+44 条目、Dafny 云端成员计数、Lean 2764 为工具链规模、ScienceDB 开放获取。审稿人看不到这封信。
