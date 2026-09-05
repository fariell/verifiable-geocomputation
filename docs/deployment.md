# 部署与分享指南 · Deployment & Sharing

> 本文档讲两件事:
> 1. **把整套成果推到 GitHub**(代码、文档、论文草稿、站点源码——全部公开分享)
> 2. **把 `site/` 发布成可访问的网址**(GitHub Pages,无需域名)

**当前方案:不注册域名,用 GitHub 提供的免费默认地址。**

---

## 一、整套成果推到 GitHub

这一步会把 `verifiable-geocomputation/` 下的**所有内容**公开分享:
README、体系文档、静态站源码、基准占位、形式化规范、Python 包骨架、论文目录。

### 1. 在 GitHub 上创建空仓库

访问 https://github.com/new:
- **Repository name**:`verifiable-geocomputation`
- **Description**:`Verifiable Geocomputation · 可验证空间计算 — 把形式化验证带到 DEM 与空间网格分析`
- **Public**(公开分享必须选 Public)
- ⚠️ **不要勾选** "Add a README file"、"Add .gitignore"、"Choose a license"——我们本地已经有了,勾选会导致冲突

点击 **Create repository**。

### 2. 本地仓库已初始化好,直接推

> 本仓库的 `git init` + 首次 commit 已经完成,你只需要执行下面这段:

```bash
cd "E:/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation"

# 关联远程仓库(如果提示已存在,先 git remote remove origin)
git remote add origin https://github.com/fariell/verifiable-geocomputation.git

# 推送
git branch -M main
git push -u origin main
```

如果 GitHub 要求认证:
- 用户名:填 `fariell`
- 密码:**不能填登录密码**,要用 Personal Access Token(PAT)
  - 生成:https://github.com/settings/tokens → **Generate new token (classic)**
  - 勾选 `repo` 权限即可
  - 复制 token,粘贴到密码框

### 3. 验证

推送完成后访问 https://github.com/fariell/verifiable-geocomputation,应该能看到全部内容。

---

## 二、把 site/ 发布成网址(GitHub Pages,免费)

### 1. 启用 Pages

仓库页面 → **Settings** → 左侧 **Pages**:
- **Source**:选 `Deploy from a branch`
- **Branch**:选 `main`,目录选 `/site`
- 点击 **Save**

### 2. 等 1–3 分钟

页面顶部会出现提示:
```
Your site is live at https://fariell.github.io/verifiable-geocomputation/
```

**这就是你的公开网址,可以写进论文、简历、邮件签名。**

### 3. 更新仓库里的站点地址

拿到地址后,把下面三个文件里的 `YOUR-SITE-URL` 替换成真实地址:
- `README.md`(顶部徽章 + 联系方式)
- `site/robots.txt`(sitemap 行)
- `site/index.html`(footer 的主页链接)

然后:
```bash
git add .
git commit -m "docs: update site URL"
git push
```

---

## 三、以后想绑自定义域名(可选,现在不用做)

等方向做起来了、觉得需要独立域名时再加,10 分钟的事:

1. 注册域名(Cloudflare Registrar / Namecheap / 阿里云均可,`.org` 约 ¥90/年)
2. 在 `site/` 下新建 `CNAME` 文件(无后缀),内容只写域名,如 `verifiable-geocomputation.org`
3. 到域名 DNS 加 4 条 A 记录指向 GitHub:
   - `185.199.108.153`
   - `185.199.109.153`
   - `185.199.110.153`
   - `185.199.111.153`
4. GitHub Pages 设置里填 Custom domain,勾选 Enforce HTTPS

详见 [GitHub 官方文档](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)。

---

## 四、备选部署方案(如果 GitHub Pages 不顺)

### Cloudflare Pages(国内访问更快)
1. https://dash.cloudflare.com → Pages → Create a project → Connect to Git
2. 选 `verifiable-geocomputation` 仓库
3. 构建配置:Framework `None` / Build command 留空 / Output directory `site`
4. 部署即可,拿到 `xxx.pages.dev` 地址

### Vercel(最快,当天可看)
1. https://vercel.com → 用 GitHub 登录 → New Project
2. 选仓库,Framework 选 `Other`,Output Directory 填 `site`
3. Deploy,立刻拿到 `xxx.vercel.app`

### Netlify Drop(不登录,临时预览)
1. https://app.netlify.com/drop
2. 把 `site/` 文件夹整个拖进去,立刻拿到预览 URL

---

## 五、分享之后建议做的 3 件事

| # | 动作 | 为什么 |
|---|---|---|
| 1 | 在 repo **About** 里填上站点地址 + 勾选 Topics(`gis` `dem` `formal-verification` `lean` `geocomputation`) | 让别人能搜到你 |
| 2 | 发第一条 **Discussion**:`RFC: Defining verifiability metric for spatial operators` | 早期信号——有人回应就说明方向有人跟 |
| 3 | 把仓库地址写进 **ORCID / Google Scholar** 个人简介 | 学术身份与项目绑定 |

---

## 网络提示

如果 `git push` 报连接超时/被拒:
- 可能是本机网络限制(已确认本机直连 github.com 不通)
- 解决:换个网络环境(手机热点),或配置代理:
  ```bash
  git config --global http.proxy http://127.0.0.1:PORT
  git config --global https.proxy http://127.0.0.1:PORT
  ```
  用完记得取消:
  ```bash
  git config --global --unset http.proxy
  git config --global --unset https.proxy
  ```

---

_v0.2 · 2026-09-05 · 去掉域名环节,聚焦 GitHub 分享_