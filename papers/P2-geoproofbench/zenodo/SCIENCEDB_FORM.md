# ScienceDB 表单填写稿（GeoProofBench v0.1）

**已分配（2026-09-07）**

- DOI: https://doi.org/10.57760/sciencedb.011r9
- CSTR: https://cstr.cn/31253.11.sciencedb.011r9 （`31253.11.sciencedb.011r9`）
- 推荐引用：郭迎钢. 面向数字高程模型分析的机器可检验命题集 GeoProofBench v0.1[DS/OL]. V1. Science Data Bank, 2026[2026-09-07]. https://cstr.cn/31253.11.sciencedb.011r9. CSTR:31253.11.sciencedb.011r9.

以下为当时填写用的底稿，提交后不必改表单标题；只需把 DOI/CSTR 用于论文。

登录后：https://www.scidb.cn/ → **提交数据** → 创建数据集。  
上传文件用下面打好的 zip（路径见文末）。封面图用同目录 `cover.png`。

选 **中文** 时，标题/简介/关键词必须中英各填一份（文件本身不用双语）。下面每项都给好了，直接粘贴。

---

## 1. 数据集语言

**选：中文**（中英都要填；方便国内审核，英文给 Scientific Data 用）。

不要选「仅英文」——你在中文界面填，漏英文字段容易被退回。

---

## 2. 数据集描述信息

### 标题（≤ 建议完整、可检索）

**中文：**  
面向数字高程模型分析的机器可检验命题集 GeoProofBench v0.1

**英文：**  
GeoProofBench v0.1: a machine-checked proposition set for digital elevation model analysis

（ScienceDB 标题可以用冒号；投稿 *Scientific Data* 的论文标题另有「禁止冒号」规则，两边不必逐字相同。）

### 简介 / 摘要

**中文：**  
本数据集发布 GeoProofBench（GPB）v0.1：一套面向数字高程模型（DEM）算子的机器可检验命题，以及复现每条判定所需的全部工件。内容包括六个一阶算子（坡度符号、填洼、Zevenbergen–Thorne 剖面曲率、Horn 二阶拟合一致性、D8 流向、流域唯一性）、填洼后流域等组合记录、用于界定组合边界的反例网格、受控噪声与重采样试验。每条命题同时用 Dafny 与 Lean 4 陈述，并配有 Python 数值闸、Wolfram 符号检查与短动画。栅格包括 5×5 平面、256² 合成地形、公开瓦片不可用时的同尺寸合成占位，以及三套公开产品窗口（USGS 3DEP 1 m 激光雷达、阿拉斯加 IFSAR 5 m、Copernicus GLO-30）。数据许可 CC-BY-4.0，软件许可 MIT。拟作为 *Scientific Data* Data Descriptor 的关联数据；期刊接收前可限制下载，接收后改为公开。

**英文：**（与 `zenodo/metadata.json` 对齐，可直接贴）  
Digital elevation model (DEM) analysis underlies terrain-related work across geomorphology, hydrology, and civil engineering, yet published algorithms are rarely machine-checked. GeoProofBench (GPB) v0.1 is a proposition set of terrain-analysis claims expressed in Dafny and Lean 4, with a reproducible pipeline that compiles each proposition to a numerical witness, a Wolfram symbolic check, and a manim visualization, keyed to a GPB-N ENTRY: PASS verdict. This deposit contains six first-order operators, composition records (including fill-then-watershed), counter-example grids, five noise levels, four DEM stacks plus three public product windows (USGS 3DEP lidar, Alaska IFSAR, Copernicus GLO-30), Dafny/Lean sources, Python/Wolfram drivers, and mp4 animations. Data are licensed CC-BY-4.0; software is licensed MIT. Public file access is intended at journal acceptance; until then the record may be restricted.

### 关键词（中英各一套，逗号分隔）

**中文：**  
数字高程模型, 形式化验证, 地形分析, 水文学, 可重复基准, Dafny, Lean 4, 空间计算

**英文：**  
digital elevation model, formal verification, terrain analysis, hydrology, reproducible benchmark, Dafny, Lean 4, spatial computation

### 学科分类（国标 GB/T 13745）

优先勾（可多选）：

1. **地球科学 → 地理学 → 地图学与地理信息系统**（或「地理信息学 / 地图学」相近项）  
2. **计算机科学技术 → 计算机软件**（形式化验证 / 定理证明）

若有 AI 助手：把上面中文简介贴进去，选它给出的地理学 + 计算机软件两条即可。不要只标人工智能。

### 封面图

文件：`papers/P2-geoproofbench/zenodo/cover.png`  
（三套真实 DEM 窗口拼图，854×480。系统若要求更大，用同目录 `../scida/figures/fig4_realworld.png` 或自行导出。）

---

## 3. 作者信息

单作者，与 `AUTHOR.md` 一致，不要改单位英文。

| 字段 | 填 |
|---|---|
| 姓名（中文） | 郭迎钢 |
| 姓名（英文） | Yinggang Guo |
| 单位（中文） | 西北核技术研究所 |
| 单位（英文） | Northwest Institute of Nuclear Technology |
| 地址 | 西安 710024 / Xi'an 710024, China |
| 邮箱 | fariel_gyg@163.com |
| ORCID | 0000-0002-8207-9941 |
| 通讯作者 | **是** |
| 贡献 | conceptualization; methodology; software; validation; formal analysis; writing |

作者顺序：仅此一人。不要把实验室内部工具人写成作者。

---

## 4. 论文管理信息

| 字段 | 建议 |
|---|---|
| 是否关联论文 | **是** |
| 论文类型 | 期刊论文 |
| 发表状态 | **拟投稿** 或 **准备投稿**（尚未在 SNAPP 提交就不要选「审稿中」） |
| 期刊 | Scientific Data |
| 出版社 | Springer Nature / Nature Portfolio |
| ISSN | 2052-4463 |
| 论文标题（英文） | A machine-checked proposition set for digital elevation model analysis |
| 论文标题（中文，可选） | 面向数字高程模型分析的机器可检验命题集 |
| 作者 | Yinggang Guo |
| DOI（论文） | **空着**（文章还没有 DOI） |
| 数据社区 | 不要选某个中科院期刊社区；走 ScienceDB **通用提交**。Scientific Data 没有绑定 ScienceDB 社区。 |
| 基金 | **无**。填「本工作未获得外部基金资助 / This research received no external funding。」申报中的基金不能写。 |

相关已发表论文（若有「参考文献 / 相关成果」栏）：  
Guo, Y.; Liu, X.; Rong, J.; Shi, F.; Tang, C. SAM-GFNet... *Remote Sensing* 2025, 17(22), 3662. https://doi.org/10.3390/rs17223662  
并注明：**不共享数据**，仅声明无重复发表。

---

## 5. 数据相关信息

| 字段 | 建议 |
|---|---|
| 数据类型 | **数据集** + **代码** + **多媒体**（若只能选一个：数据集） |
| 数据格式 | ZIP；内含 Python (.py)、Dafny (.dfy)、Lean (.lean)、JSON、Markdown、MP4、PNG、PDF |
| 数据量级 | 以 zip 实际大小为准（打包后看控制台 MB） |
| 时间范围 | 2026-09（数据生产） |
| 空间范围 | 合成网格无地理范围；产品窗口：美国洛杉矶 Griffith Park（约 34.14°N, 118.30°W）、阿拉斯加 Fairbanks 附近（约 64.90°N, 147.80°W）、Copernicus 瓦片 N32E110（32–33°N, 110–111°E） |
| 坐标系 / 分辨率 | 窗口分别为约 1 m、5 m、30 m；合成平面 5 m |
| 生产软件 | Python 3.12, Dafny 4.11, Lean 4.18.0, GDAL, manim 0.21 |
| 打开方式 | 解压 zip。数值闸：Python。证明：`dafny verify`、`lake build`。动画：任意播放器打开 mp4。 |

---

## 6. 数据合规信息

全部选 **否 / 不涉及**（与 cover letter 伦理段一致）：

| 问题 | 填 |
|---|---|
| 人类遗传资源 / 人类受试 | **否** |
| 实验动物 | **否** |
| 濒危物种 / 保护地敏感位置精确到可伤害程度 | **否**（公开 DEM 产品窗口，非未公开测线） |
| 国家秘密、工作秘密、内部敏感 | **否** |
| 个人信息 / 可识别人脸 | **否** |
| 伦理审查批件 | **不需要** |
| 第三方版权 | 形式化与合成数据为作者产出；USGS 3DEP / Copernicus GLO-30 为公开产品窗口，论文中已标明来源与获取方式。**不要把整幅商业 DEM 装进包。** |
| 是否已在其他仓储发布 | **否**（Zenodo 未铸 DOI；GitHub 未公开） |

---

## 7. 数据共享方式（关键）

Scientific Data **首轮**要求审稿人能匿名下载；**接收前**你们又不希望全世界立刻公开。ScienceDB 上这样选：

**推荐：限制性获取（restricted / 审批后下载）**

- 元数据可公开（标题、简介、作者），**文件需申请或凭链接下载**。  
- 提交成功后系统会 **预分配 DOI 和 CSTR**（此时还没真正「公开发布文件」）。  
- 把预分配 DOI + 审稿说明发给 Scientific Data：正文 Data Availability 写 DOI；若平台生成「私有下载链接 / 审稿访问」，把该 URL 也写进正文（**不要只写在 cover letter**，审稿人看不到信）。

**不要**现在选「完全公开立即发布」——与实验室「接收后一次性公开」冲突。

**期刊接收后：** 在 ScienceDB 把共享改为 **公开**，许可保持 **CC-BY 4.0**。软件在简介里写清 **MIT**（若许可下拉只能选一个，选 CC-BY 4.0，在简介声明代码 MIT）。

**许可协议：**

- 数据：**CC-BY 4.0**  
- 若另有软件许可栏：**MIT**  
- 不要选 CC-BY-NC（Scientific Data 要可复用）  
- 不要选 CC0（你们要署名）

保护期/延期公开：若有「保护期至某日」，可填 **2027-06-01** 或「期刊接收之日」；有限制性获取就不必再叠一层保护期，免得审稿人下不了。

---

## 8. 数据集实体文件

**只上传这一个 zip**（不要把 `_staging` 或仓库根目录拖上去）：

```
E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\papers\P2-geoproofbench\zenodo\GeoProofBench-v0.1-deposit.zip
```

封面另外传：

```
E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\papers\P2-geoproofbench\zenodo\cover.png
```

zip 内已含：`formal/`、`benchmark/`、`experiments/phase1|phase2` 的 figures+results、`papers/P2-geoproofbench` 文稿与 SciDA PDF、本表单。  
**不含** Lean `.lake` 缓存、manim `partial_movie_files`。  
**不含** `data/cache/` 里的 USGS/Copernicus 窗口 GeoTIFF（需按论文方法重新拉取）。

文件名不要改成中文。若系统限制单文件大小，保持一个 zip，不要拆成碎文件。

---

## 9. 提交后你要抄下来发给 Cursor 的三行

1. 预分配 **DOI**（形如 `10.57760/sciencedb.xxxxxx`）  
2. **CSTR**（形如 `31253.11.sciencedb.xxxxxx`）  
3. 审稿人下载 URL（若有）

有这三行就可以改论文 Data Availability，不必等完全公开。
