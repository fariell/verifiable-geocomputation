# 论文草稿模板

> 新论文从这里复制。署名块一律引用 [`../AUTHOR.md`](../AUTHOR.md),不要手写。

命名规则:`papers/<编号>-<短名>/`,例如 `papers/P2-geoproofbench/`。

---

## 0. 元信息(起草时先填,用于排期与投稿追踪)

```
编号:        P2
工作名:      GeoProofBench
目标期刊:    Scientific Data
投稿日:      2026-11-15
状态:        draft / submitted / under review / major revision / accepted / published
学科代码:    D0116 地理大数据与空间智能(地球科学部 · 地球科学一处)
产出资产:    benchmark/problems/v0.1.md + 排行榜
arXiv:       (待挂)
```

---

## 1. 标题

(Title: 名词短语优先,不加"基于 XX 的 YY 方法研究"式套话)

## 2. 作者与单位

```
Yinggang Guo ¹,*

¹ Northwest Institute of Nuclear Technology, Xi'an 710024, China;
  fariel_gyg@163.com

* Correspondence: fariel_gyg@163.com
  ORCID: https://orcid.org/0000-0002-8207-9941
```

## 3. Abstract

(250 词内。五句结构:背景 → 缺口 → 本文做什么 → 怎么做 → 结论与意义)

## 4. Keywords

空间智能;地理大数据;形式化验证;DEM 地形分析;可解释性;地理知识发现

(前 2–3 个务必是 D0116 系统指定关键词)

## 5. Introduction

(最后一段固定写 Contributions,3–4 条,每条一句话,动词开头)

## 6. Related Work

(必须覆盖三条线:① 形式化方法与定理证明;② DEM/地形分析;③ 地理空间智能。
缺任何一条都会被审稿人挑)

## 7. Method

## 8. Experiments

## 9. Discussion

(必须有一小节回答:"So what?"——地理学贡献在哪,不只是 AI 方法平移)

## 10. Conclusion

## 11. Data / Code Availability

```
The GeoProofBench proposition set, Lean 4 / Dafny specifications, and
reproduction scripts are publicly available at
https://github.com/fariell/verifiable-geocomputation
under the MIT License.
```

## 12. Author Contributions

```
Conceptualization, Y.G.; methodology, Y.G.; software, Y.G.;
validation, Y.G.; formal analysis, Y.G.; writing—original draft
preparation, Y.G.; writing—review and editing, Y.G.
```

## 13. Funding

```
This research received no external funding.
```

(获批青C 后改为:

```
This work was supported by the National Natural Science Foundation of
China (Grant No. XXXXXXXX).
```

)

## 14. Acknowledgments

## 15. Conflicts of Interest

```
The author declares no conflict of interest.
```

---

## 写作纪律(一人科研尤其重要)

1. **先写 §7 方法与 §8 实验,再回头写 §5 引言。** 引言最后写才不会撒谎。
2. **Discussion 的 "So what?" 小节不写完,不许投稿。** 这是"AI-heavy but geospatially thin"退稿的唯一解药。
3. **每完成一稿即挂 arXiv/EarthArXiv**,取得 DOI 与时间戳,再投期刊。
4. 投稿后立刻回本目录更新 §0 状态,不要靠记忆追踪。
