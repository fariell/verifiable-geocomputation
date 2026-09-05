# 贡献指南 · Contributing to Verifiable Geocomputation

感谢你对这个方向的兴趣。我们目前处于 Y0 立纲期,**欢迎任何形式的贡献**——提 issue、写文档、提交 PR、转发论文、在 Discussions 提 RFC,都算。

## 我们现在最需要什么

按优先级排序:

1. **GeoProofBench 命题素材**:你熟悉的某条 DEM 几何/水文性质——只要能写成"对所有满足 X 的 DEM,输出 Y 满足 Z"的形式,就是我们的素材。<a href="https://github.com/fariell/verifiable-geocomputation/issues/new">提 issue</a> 即可,模板:
   ```
   **命题**: 一句话陈述
   **前置条件**: 对 DEM 的要求(连续可微?无洼地?分辨率?)
   **结论**: 输出必须满足的性质
   **来源**: 教科书章节/论文/你的经验
   **难度**: ★(易)/★★(中)/★★★(需 Lean 功底)
   ```

2. **VeriGIS 库代码**:Python 算子绑定、单元测试、文档。会 Python 就能起步。

3. **形式化规范**:Lean 4 / Dafny 双形式化。会其中一种就能贡献。我们会带你过门槛。

4. **文档与翻译**:README、教程、roadmap 翻译、API 文档。

5. **审稿与批评**:看到我们写得不对的地方,直接提 issue。我们会更正。

## 提 PR 流程

1. Fork → 新建分支(命名:`feat/xxx` / `fix/xxx` / `docs/xxx` / `formal/xxx`)
2. 写完代码/文档
3. 跑 CI(本地 `pytest` / `lake build`)
4. 提 PR,标题格式:`[scope] 简短描述`,例如 `[library] add slope operator wrapper`
5. 等 review,通常 1–3 天内响应

## 提交规范

- **Commit message**: `<scope>: <imperative summary>`,scope 取自上面的分支前缀
- **代码风格**:Python 用 ruff/Black;Lean 4 用 mathlib 风格;Dafny 用微软官方风格
- **测试**:任何算子代码必须配至少一个属性测试(property-based test)+ 一个差分测试(对比参考实现)

## 行为准则

- 学术讨论:就事论事,观点碰撞但不针对人
- 引文规范:一切非显然结论必须给文献出处
- 不接受的:AI 生成内容未声明、未核实外部事实、营销性文案

## 联系方式

- Bug 与功能请求:GitHub Issues
- 方向讨论:GitHub Discussions
- 敏感问题(版权、署名、合作):邮件(见 README)

## 许可证

贡献的代码采用 MIT 许可证。形式化规范采用 Apache 2.0(允许商业使用、专利授权)。贡献即视为同意。

---

_最后更新:2026-09-05_