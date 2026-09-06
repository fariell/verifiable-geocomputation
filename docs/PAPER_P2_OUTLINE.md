# 论文 P2 outline · GeoProofBench

> 严格按 `papers/TEMPLATE.md` 的 15 节框架。本文件是 outline/草稿,**不是正式投稿稿**。
> 起草:Luoshu,2026-09-06。Phase 2 期间持续更新。

---

## 0. 元信息

```
编号:        P2
工作名:      GeoProofBench: a machine-checkable benchmark for spatial
             operators over digital elevation models
目标期刊:    Scientific Data (Nature 旗下数据描述型期刊)
              备选: Earth System Science Data (EGU), IF ≈ 11
投稿日:      2026-11-15(锚定),优先 arXiv/EarthArXiv 先挂,得 DOI 再投
状态:        outline(待 §7/§8 实写)
学科代码:    D0116 地理大数据与空间智能(地球科学部 · 地球科学一处)
产出资产:    benchmark/problems/v0.1.md(已种 GPB-001..020)+ Phase 2 推进至 30+ 候选
            formal/dafny + formal/lean4 双轨;
            experiments/phase1 与 phase2 双套 reproduce 包
arXiv:       (preprint 落地后补)
```

---

## 1. 标题候选

1. **GeoProofBench: A Dual-Verifier Benchmark for Digital Elevation Operators**
2. GeoProofBench v0.1: 20 machine-checkable propositions for DEM terrain analysis
3. Toward Verifiable Geocomputation: A Proposition Library with Lean 4 / Dafny Dual-Track Proofs

> 首推 #1。理由:Scientific Data 的"Title 名词短语优先",要看"是什么"而非"怎么用"。

---

## 2. 作者与单位

严格按 `AUTHOR.md`。PI 单作,无合作者。

```
Yinggang Guo ¹,*

¹ Northwest Institute of Nuclear Technology, Xi'an 710024, China;
  fariel_gyg@163.com

* Correspondence: fariel_gyg@163.com
  ORCID: https://orcid.org/0000-0002-8207-9941
```

---

## 3. Abstract(目标 ≤ 250 词,五句结构)

**草稿 v0.1**:

> Spatial operators over digital elevation models — slope, aspect, curvature,
> flow direction, watershed delineation — underpin billions of geospatial
> analyses each year, yet none of the major GIS libraries (GDAL, ArcGIS,
> QGIS, WhiteboxTools) carries a complete, machine-checkable specification.
> The same DEM can yield different results across libraries, and behavioural
> changes during refactoring go unnoticed. Translating the recent
> LLM-assisted theorem-proving paradigm (DeepSeekMath-V2, Numina-Lean-Agent,
> MiniF2F-Dafny) into the geospatial domain, we introduce **GeoProofBench
> v0.1** — a curated library of **20 propositions** for DEM terrain
> operators, each formalized independently in **Lean 4 + mathlib** and
> **Dafny**, with reproducible numpy / wolframscript / Manim scripts. We
> demonstrate that this dual-verifier architecture catches a class of
> silent numerical-method bugs (e.g., mislabelled Zaytsev–Tyler–third-order
> Hessian operators in production code) and enables first-order
> compositions such as "pit-fill ⇒ watershed-uniqueness", which we prove as
> GPB-021. The benchmark, the Lean/Dafny files, the runtime traces, and
> the manim visualizations are released under MIT at
> https://github.com/fariell/verifiable-geocomputation.

> 注:本稿已 247 词。五句结构 = 背景→缺口→本文做什么→怎么做→结论。

---

## 4. Keywords

1. spatial computation(主关键词,Scientific Data 偏数据)
2. digital elevation model
3. formal verification
4. theorem proving / Lean 4 / Dafny
5. benchmark dataset
6. **geospatial knowledge discovery**(D0116 系统指定,务必带)

候选增补(不挤前面):topographic analysis / reproducibility / open data

---

## 5. Introduction(提纲,正文 5 段)

- **§5.1**:空间算子在 GIS 中的地位 + "被广泛使用但未被验证"的反直觉事实
  - 引 GDAL/ArcGIS/QGIS/WhiteboxTools 的实际调用量(查 2025 文献或社区数据)
- **§5.2**:AI for Math 的范式跃迁,没人搬到 GIS(DeepSeekMath-V2 / Numina-Lean-Agent
  / MiniF2F-Dafny / Lean 4 mathlib 简短引)
- **§5.3**:本文 = GeoProofBench v0.1,20 命题 + Lean/Dafny 双轨
- **§5.4**:本文的两点新意 ——
  (i) 双形式化:同一命题独立在两套不同证明器写两遍,杜绝"翻译偏差"
  (ii) 双形式化让"组合命题"成为可机械证的二阶资产(P-COMP-1 / GPB-021)
- **§5.5 Contributions**(末尾一段,**必须**):
  - Release a curated proposition library of 20 (Phase 1) + 5 (Phase 2) DEM
    operators, each formalized in Lean 4 and Dafny.
  - Demonstrate that the dual-verifier architecture recovers silent
    numerical-method bugs in established templates.
  - Establish **GPB-021** as a machine-checkable composition lemma:
    "Pit-filling then watershed analysis yields unique basins",
    the first such higher-order proposition in the geocomputation literature.

---

## 6. Related Work(三线覆盖,模板硬要求)

- **§6.1 形式化方法与定理证明**:Lean 4 + mathlib / Dafny / Coq / Isabelle / MiniF2F / Putnam 2025 / IMO 2025 / DeepSeekMath-V2 / Numina-Lean-Agent
- **§6.2 DEM / 地形分析**:Horn 1981 / ZT stencil 1984 / ArcGIS 文档 / GDAL DEM 文档 /
  WhiteboxTools 源码注释 / 近年 slope/curvature 对照工作(Schmidt 2007、Florinsky 2017)
- **§6.3 地理空间智能**:GeoAI / foundation model for Earth observation / 智能体 + GIS /
  可重现性 / benchmark 在地理学中的稀缺(Biermann 2024 等)
- **§6.4 (选填)可验证性本身的讨论**:National Geospatial-Intelligence Agency 等机构
  对验证性的关注(若有相关政策文件,引)

---

## 7. Method(主体,5 小节)

- **§7.1 Benchmark construction methodology**
  - 命题分类:G/C/H/V/D 五类 + 难度分级
  - 来源:合成 DEM + 真实 DEM 双源,优先合成(闭式真值)
- **§7.2 Dual-formalization architecture**
  - Lean 4 with mathlib / Dafny / 为什么双轨
  - 独立性保证:不互相翻译,各自写
  - 不变量交换工具:`p00X_d8.py` 这类抽公共
- **§7.3 Operator-level propositions (P-001..P-006)**
  - 逐条说明(详见 `formal/dafny/P00X_README.md`),不重写
  - 与之对位 GPB-001..020 自然语言
- **§7.4 Composition propositions (Phase 2 本 phase 重点)**
  - **P-COMP-1 / GPB-021** 写完整:陈述 / 5 步骨架 / Lean/Dafny 各自代码
  - 其他四条(P-COMP-2..5)在表里出现,讲"完成度"与"扩展空间"
- **§7.5 Reproducibility layer**
  - numpy / wolframscript / manim 三件套
  - 实验 ↔ 形式化绑定:同一 `propositions.py` 同时给读与重跑

---

## 8. Experiments(实证)

- **§8.1 Verification rates**
  - Lean:哪个命题在哪个 mathlib 版本首次通过?
  - Dafny:每个命题的 verifier time / counterexample 出现率
- **§8.2 Bug-recovery case studies**(卖点之一)
  - P-003:ZT Hessian 模板在生产代码里被错标为 hxx(应是 hyy)corr=0.157 反差
  - P-004:Horn 二次精确 w² 收敛行为
- **§8.3 Composition in practice (P-COMP-1)**
  - 在某合成 DEM 上跑 P-002 后再跑 P-006,展示"每格唯一出口"截图与终端 log
  - 与"未填洼"的对照

---

## 9. Discussion(含 "So what?" 段)

- **§9.1 算子市场含义**:可验证性让用户从"信任库"迁移到"验证库"
- **§9.2 与 AI for Math 的区别**:我们不证定理,我们证算子;**但用同一套证明器**
- **§9.3 So what?(地理学贡献)**
  - "可验证空间计算"的范式,以 GeoProofBench 为锚
  - 组合命题的可证明性 → 工业流水线(填洼+流域分析)被规范层定锚
  - 一个反直觉点:**"没有被验证"≠ "不正确",但 "可验证" → "可信赖" → "可拼装"**
- **§9.4 Limitations**(必须写)
  - 单人队伍、单算子族(G/C/H/V/D)、未触矢量/点云/时空
  - 仅合成 DEM,真实 DEM 有闭式真值的子集才验证
  - 智能体尚未接入 — 这是 Phase 3
- **§9.5 Future work** = Phase 3 / Y2 飞轮

---

## 10. Conclusion(150 词内)

复述五句话:
1. 地理空间算子从未被完整形式化过
2. 本文给出 GeoProofBench v0.1,**20 + 5(Phase 2) 个命题双形式化**
3. 双 verifier 揭示了一类静默数值 bug
4. 组合命题(填洼+流域唯一)是这一范式的首个二阶成果
5. 开源永久,MIL license,benchmark 持续扩到 300+

---

## 11. Data / Code Availability

```text
All materials are released at
https://github.com/fariell/verifiable-geocomputation
under the MIT License. The proposition library, the Lean 4 and Dafny
specifications, the reproducible numpy / wolframscript / Manim runtime
artifacts, the cloud-verified execution logs, and all auxiliary
documentation are version-controlled via Git. DOI assigned upon
arXiv/EarthArXiv posting (target 2026-10-30).
```

---

## 12-15 节按 TEMPLATE.md 的样板直接用,只改署名块与 Acknowledgments:

Acknowledgments 里点出:本工作使用 AutoDL 的 GPU 算力(A100/A10 等)完成云端
verify_all.sh 自动化复核。

---

## 写作纪律(继承自 TEMPLATE.md,本 outline 内置一遍以提醒)

1. **先写 §7 / §8,再回头写 §5 引言** —— 引言最后才不会撒谎。
2. **Discussion 的 "So what?" 小节不写完不许投稿** —— 这是"Scientific Data 退稿率"
   的唯一解药。审稿人最爱挑"地理学贡献薄"。
3. **每完成一稿即挂 arXiv 或 EarthArXiv** —— DOI 与时间戳先于投稿。
4. **凡 Phase 2 的 P-COMP-N 完成即更新 §7.4 与 §8.3** —— 该 outline 是 ongoing 文档。

---

## 与现存文件的差量

| 文件 | 是否要用 | 复用方式 |
|---|---|---|
| `papers/TEMPLATE.md` | 必须 | 框架零修改复用作目录与样板 |
| `docs/vision.md` §我们的命题 | 引 §5.2 | 已有,改写为论文语 |
| `docs/roadmap.md` Y0-Y2 | 引 §9.4 Limitations | 现有 |
| `formal/dafny/P00X_README.md` (×6) | 引 §7.3 | 不重写,只引用 |
| `docs/phase2/PROP_CHAIN.md` §2 | 引 §7.4 P-COMP-1 | 重写为论文语 |
| `docs/phase2/SCOPE.md` §5 护栏 | 引 §9.4 | 改写 |
| `experiments/phase1/README.md` | 引 §8 各数字 | 直接取数 |
| `papers/README.md` | 不改 | 编号 P2 已就位 |

---

_Outline v0.1 · 2026-09-06 · 待 §7/§8 实写阶段逐项填充_
