# Verifiable Geocomputation
# 把可验证性从数学定理证明搬到 DEM、地形分析与空间网格上。

本目录是研究计划的官网源码。技术栈:纯静态 HTML/CSS/JS,无构建步骤,部署到 GitHub Pages。

## 本地预览

任选一种:

### 方式 A:Python 内置服务器(最简单)
```bash
cd site
python -m http.server 8080
# 浏览器打开 http://localhost:8080
```

### 方式 B:Node 的 npx serve
```bash
npx serve site -p 8080
```

### 方式 C:VS Code Live Server 插件
打开 `site/index.html`,右键 → Open with Live Server。

## 文件结构

```
site/
├── index.html            # 首页(单页应用,所有 section 在这里)
├── assets/
│   ├── css/main.css      # 样式
│   ├── js/main.js        # 交互逻辑
│   └── images/           # logo/favicon/插图
└── blog/                 # 预留博客目录(暂空)
```

## 设计原则

- **零构建**:任何能跑 HTTP 的环境都能部署,无需 Node/Python 工具链
- **零依赖**:不引入 npm 包,JS 是原生 vanilla JS
- **响应式**:移动端可用,断点 900px 与 540px
- **可访问**:语义化 HTML,合理的 ARIA,键盘可达
- **打印友好**:科研工作者经常打印网页;主样式有 @media print 兜底

## 部署

详见上级目录的 `docs/this-week.md` 与 `docs/deployment.md`(即将添加)。

## 修改

颜色、字体、间距:改 `assets/css/main.css` 顶部的 `:root` 变量
新加 section:在 `index.html` 的相应位置粘贴;无需改 JS
新加页面:复制 `index.html`,删掉不用的 section,作为独立页面

## 已知 TODO

- [ ] 添加 RSS feed(博客上线时)
- [ ] 添加 sitemap.xml(SEO)
- [ ] 多语言切换(英文版)
- [ ] 暗色主题

---

_v0.1 · 2026-09-05_