# SNAPP 首轮上传（Scientific Data）

依据：<https://www.nature.com/sdata/submission-guidelines>
本目录是 **SNAPP 网页当前这一栏** 要交的文件（LaTeX zip + 封面信 PDF）。

书面指南写“首轮最简单是一个含图的 PDF”；你这边 SNAPP 明确要求：

> LaTeX documents with figures and tables compressed into a .zip format. We will compile these into a PDF for peer review.

**以 SNAPP 这一栏为准。**

---

## 上传这两个文件

| SNAPP 栏 | 文件 | 不要放进去的东西 |
|---|---|---|
| **Article / Manuscript** | `geoproofbench_latex.zip` | 封面信、PNG、`.py`、中文 Word、`.aux/.log`、旧图 `fig3_zt_horn` / `fig4_realworld` |
| **Covering letter** | `covering_letter.pdf` | 不要打进 zip（审稿人看不到封面信；数据 URL 必须在正文 Data Availability） |

Zip 根目录内容（已隔离编译通过）：

```
geoproofbench.tex
figures/fig1_fill_watershed.pdf
figures/fig2_multires.pdf
figures/fig3_realworld.pdf
figures/fig4_zt_horn.pdf
```

本地预览 PDF（不必上传，除非 SNAPP 另要 PDF）：`../geoproofbench.pdf` 与 `../first_round/01_article.pdf`（16 页）。

---

## 网页表单请粘贴

见同目录 `SNAPP_FORM.md`。

必须勾选：

- Article type = **Data Descriptor**
- Competing interests = **No**
- Funding = none（无基金号；与正文 Funding 一致）
- Data availability URL = `https://doi.org/10.57760/sciencedb.011r9`
- 相关已发表：SAM-GFNet，DOI `10.3390/rs17223662`，**does not share data**
- APC 减免只在系统答，不要写进封面信
- Author contributions（单作者也要填；**不要**写进 `.tex`，SNAPP 会覆盖）

---

## 不要上传

- `papers/P2/manuscript.md` 或 `papers/P2-geoproofbench/manuscript.md`（实验室笔记，不是 Data Descriptor）
- 期刊 LaTeX 模板、独立 `.bib`
- Supplementary（能放正文已放正文）
- ScienceDB zip 本身（数据已在仓储；正文给 DOI）
