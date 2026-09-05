# Verifiable Geocomputation

> **Bringing formal verification to spatial computing.**  
> 把可验证性从数学定理证明,搬到 DEM、地形分析与空间网格上。

![License](https://img.shields.io/badge/license-MIT-blue.svg)

![Status](https://img.shields.io/badge/status-Y0%20·%20founding-yellow.svg)

![Site](https://img.shields.io/badge/site-fariell.github.io%2Fverifiable--geocomputation-orange)

![Repo](https://img.shields.io/badge/github-fariell%2Fverifiable--geocomputation-blue?logo=github)

![ORCID](https://img.shields.io/badge/ORCID-0000--0002--8207--9941-A6CE39?logo=orcid)

![Field](https://img.shields.io/badge/NSFC-D0116%20地理大数据与空间智能-blueviolet)

**Verifiable Geocomputation** (可验证空间计算) 是一个把 AI 形式化数学推理能力迁移到地理空间分析场景的开源研究计划:让地形分析、空间算子、变化检测的每一步推理都可被机器证明。

## 负责人

| | |
| --- | --- |
| **姓名** | 郭迎钢 / Yinggang Guo |
| **单位** | 西北核技术研究所(Northwest Institute of Nuclear Technology),Xi'an 710024, China |
| **邮箱** | `fariel_gyg@163.com` |
| **ORCID** | [0000-0002-8207-9941](https://orcid.org/0000-0002-8207-9941) |
| **GitHub** | [@fariell](https://github.com/fariell) |
| **学科口** | 地球科学部 · 地球科学一处 · **D01 地理科学 / D0116 地理大数据与空间智能** |

> 论文署名、单位写法、基金学科代码、代表作 BibTeX 全部以 [`AUTHOR.md`](AUTHOR.md) 为唯一权威源,投稿前必查。

## 我们在做什么(一句话版)

> 空间计算结果的可验证性,能否被**形式化地定义、证明与机器检验**?

## 三层资产结构

| 层          | 内容                                   | 作用           |
| ---------- | ------------------------------------ | ------------ |
| **L1 流量层** | 论文                                   | 可见度与考核       |
| **L2 壁垒层** | 开源库 VeriGIS、基准 GeoProofBench、命题库、排行榜 | 别人引用你的真正原因   |
| **L3 复利层** | Special Issue、Workshop、标准提案、研究生梯队    | 从"做研究"到"立方向" |

只做 L1 → 高级论文工人;只做 L2/L3 → 在现行考核里活不到成型。**三线并行,让 L1 从 L2/L3 自然产生**。

## 仓库结构

```
verifiable-geocomputation/
├── docs/          # 体系文档(愿景、路线图、贡献指南)
├── benchmark/     # GeoProofBench 形式化命题基准
├── formal/        # Lean 4 / Dafny 形式化规范
│   ├── lean4/
│   └── dafny/
├── library/       # VeriGIS Python 开源库(算子实现 + 形式化绑定)
│   ├── src/verigis/
│   └── tests/
├── papers/        # 论文草稿(P0–P4 + 支线)
└── site/          # 静态网站(本仓库的对外门面)
```

## 立即可做

- [x] 建立 GitHub 仓库 `verifiable-geocomputation`(Public)
- [ ] 推送本仓库到 GitHub
- [ ] 启用 GitHub Pages(branch `main`,目录 `/site`)
- [ ] 启用 Discussions 并开第一个 RFC
- [ ] 初始化 Lean 4 项目与 VeriGIS Python 包骨架
- [ ] 攒 GeoProofBench 前 50 条命题

详细执行清单见 [`docs/this-week.md`](docs/this-week.md),部署细节见 [`docs/deployment.md`](docs/deployment.md)。

## 路线图

完整 10 年路线见 [`docs/roadmap.md`](docs/roadmap.md)。简版:

- **Y0 立纲**(2026.09–2027.06):研究纲领 + 基准 + 第一笔钱(青C)
- **Y1 地基**:VeriGIS v0.1 开源发布,4 类核心算子形式化
- **Y2 闭环**:GeoMath-Agent 超零样本基线,可验证性度量定型
- **Y3 成型**:GeoProofBench v2 跨域,组织 Special Issue / Workshop
- **Y4–Y7 扩张**:从 DEM 扩到矢量/点云/时空,OGC/ISO 标准提案

## 贡献

我们目前处于早期,**欢迎一切形式的贡献**:提 issue、提交 PR、加 discussion、转发论文。

详见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

## 引用本项目

仓库提供 [`CITATION.cff`](CITATION.cff),GitHub 会自动生成引用信息。BibTeX:

```bibtex
@software{guo2026verifiable,
  author  = {Guo, Yinggang},
  title   = {Verifiable Geocomputation: Formal Specification, Machine-Checked
             Proofs and Autonomous Reasoning for DEM Terrain Analysis},
  year    = {2026},
  url     = {https://github.com/fariell/verifiable-geocomputation},
  license = {MIT}
}
```

## 联系方式

- 主页:<https://fariell.github.io/verifiable-geocomputation/>
- 仓库:<https://github.com/fariell/verifiable-geocomputation>
- 讨论:GitHub Discussions
- 邮件:`fariel_gyg@163.com`(郭迎钢)

---

> v0.3 · 2026-09-05 · 本周启动 · 不绑域名,用 GitHub Pages 默认地址
