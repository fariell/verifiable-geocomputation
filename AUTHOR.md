# Author & Affiliation

> 本文件是**唯一权威署名源**。所有论文投稿、仓库引用、网站署名一律以此为准,不要凭记忆另写一份。

**Canonical author record · 版本 v1.0 · 2026-09-05**

---

## 1. 英文署名块(投稿系统 / LaTeX / Word 直接复制)

```
Yinggang Guo ¹,*

¹ Northwest Institute of Nuclear Technology, Xi'an 710024, China;
  fariel_gyg@163.com

* Correspondence: fariel_gyg@163.com
  ORCID: https://orcid.org/0000-0002-8207-9941
```

多作者时按贡献排序,其余作者沿用各自单位编号,通讯作者标记 `*` 保持不变。

**LaTeX 版**

```latex
\author{Yinggang Guo\orcidlink{0000-0002-8207-9941}}
\affil{Northwest Institute of Nuclear Technology, Xi'an 710024, China}
\email{fariel_gyg@163.com}
```

**MDPI / Elsevier 通讯作者脚注版**

```
¹ Northwest Institute of Nuclear Technology, Xi'an 710024, China
* Correspondence: fariel_gyg@163.com;
  ORCID: https://orcid.org/0000-0002-8207-9941
```

---

## 2. 中文署名块

```
郭迎钢(通讯作者)
西北核技术研究所,西安 710024,中国
邮箱:fariel_gyg@163.com
ORCID:0000-0002-8207-9941
```

单位英文写法固定为 **Northwest Institute of Nuclear Technology**,不要写成 `Northwest Institute of Nuclear Technology of China` 等变体——单位名不一致会导致 ORCID / Scopus 归并失败。

---

## 3. 关键标识(一处改动,处处改动)

| 项 | 值 |
| --- | --- |
| 中文名 | 郭迎钢 |
| 英文名 | Yinggang Guo |
| 单位 | Northwest Institute of Nuclear Technology |
| 单位中文 | 西北核技术研究所 |
| 地址 | Xi'an 710024, China(西安) |
| 邮箱 | `fariel_gyg@163.com` |
| ORCID | `0000-0002-8207-9941`(<https://orcid.org/0000-0002-8207-9941>) |
| GitHub | <https://github.com/fariell> |
| 项目主页 | <https://fariell.github.io/verifiable-geocomputation/> |

---

## 4. 基金申报学科口

| 项 | 值 |
| --- | --- |
| 学部 | 地球科学部 |
| 科学处 | 地球科学一处(地理科学) |
| 一级代码 | **D01 地理科学** / Science of Geography |
| 二级代码 | **D0116 地理大数据与空间智能** / Geographic Big Data and Spatial Intelligence |
| 所属分支 | 信息地理学(D0113 遥感科学 / D0114 地理信息学 / D0115 测量与地图学 / D0116 地理大数据与空间智能) |
| 科学处电话 | 010-62327161 |

**D0116 官方内涵要点**(写本子时逐条对位):

1. 人工智能与地理问题相结合的**地理智能理论、方法与技术**
2. 以多源实时对地观测数据与社会感知大数据作为地理现象的观察介入
3. **数据驱动的地理知识与规律的自动提取和发现**
4. **地理事件与现象的可解释性因果分析**
5. 构建**时空大数据分析科学范式和技术体系**

### 本方向(D0116 下)的落位

本项目不是把 AI 方法搬到地理数据上跑一遍,而是回答 D0116 尚未被回答的一个基础问题:

> **地理空间计算的结果,能否被形式化地定义、证明与机器检验?**

对应 D0116 内涵的第 3 条(知识与规律的自动提取与发现)与第 4 条(可解释性因果分析)——**把"可解释"从定性描述推进到"可机器检验"**。这是 D0116 内部的理论增量,而非方法学平移。

**推荐关键词**(系统指定词优先,不足部分用自定义词):
空间智能、地理大数据、时空数据挖掘、机器学习、可解释性、DEM 地形分析、形式化验证、地理知识发现。

---

## 5. 代表作(研究基础引用格式)

```bibtex
@article{guo2025samgfnet,
  title   = {SAM-GFNet: Generalized Feature Fusion with Hierarchical Network
             for Hyperspectral Image Semantic Segmentation},
  author  = {Guo, Yinggang and Liu, Xu and Rong, Jinhong and Shi, Fengmiao and Tang, Chao},
  journal = {Remote Sensing},
  volume  = {17},
  number  = {22},
  pages   = {3662},
  year    = {2025},
  doi     = {10.3390/rs17223662}
}
```

```
Guo, Y.; Liu, X.; Rong, J.; Shi, F.; Tang, C. SAM-GFNet: Generalized Feature
Fusion with Hierarchical Network for Hyperspectral Image Semantic Segmentation.
Remote Sensing 2025, 17(22), 3662. https://doi.org/10.3390/rs17223662
```

研究基础段落可这样写(证明"能做出 AI + 遥感的系统性工作"):

> 申请人前期围绕视觉基础模型与遥感影像解译开展研究,提出层次化特征融合网络 SAM-GFNet,在 WHU-OHS 与 WHU-H2SR 基准上分别取得 79.60% 与 86.92% 的总体精度(Remote Sensing, 2025, 17(22): 3662)。该工作验证了"基础模型通用特征 + 任务专用特征"的融合范式,但同时也暴露出关键不足:**模型输出的结果可信,推理过程不可验证**。本项目正是针对这一不足,将形式化验证引入地理空间计算。

---

## 6. 使用规则

- **投稿前必查本文档**,不要用记忆里的单位/邮箱/ORCID。
- 合作者加入时,在本文档追加其完整信息后再写入论文,避免版本分叉。
- ORCID 记录建议同步补入本仓库的 `CITATION.cff` 与每次 release。

---

## 7. 申报状态与资源(2026-09-05 确认)

| 项 | 状态 |
| --- | --- |
| 青C 申报年份 | **2027**(基金委集中接收截止约 2027-03-20) |
| 年龄资格 | ✅ 已自查符合 |
| 依托单位校内报送截止 | ⚠️ 待确认(预计 2027-02 下旬,**这是真正的死线**) |
| 学科口 | D0116 地理大数据与空间智能 |
| 本机算力 | RTX 3080 |
| 云算力 | AutoDL(经费充足) |

**写作提示**:项目**申报中不等于可致谢**。论文 Funding 段在获批前一律写 `This research received no external funding.`(与 SAM-GFNet 一致),获批后再按批准号补写。研究基础段落用 §5 的话术,不提"拟申请"。

资源配置的详细判断见 [`docs/resources.md`](docs/resources.md)——核心结论:**本方向的瓶颈是人工核验时间与 API 预算,不是 GPU**。

---

> 若单位、邮箱或 ORCID 变更,**先改本文件,再全局替换**,不要只在论文里改。
