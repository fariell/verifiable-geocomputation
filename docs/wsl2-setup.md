# WSL2 + Ubuntu 22.04 统一开发环境搭建指南

> 适用:Windows 本机(RTX 3080 / 12 GB)。
> 目标:一套可复现的 Linux 开发环境,装好可验证空间计算所需的全部工具链。
> 配套脚本:[`scripts/wsl/install_wsl.ps1`](../scripts/wsl/install_wsl.ps1)(启用 WSL+装发行版)、[`scripts/wsl/provision.sh`](../scripts/wsl/provision.sh)(装工具链)。

---

## 0. 为什么是 WSL2 + Ubuntu 22.04

Lean 4、Dafny、GDAL、WhiteboxTools、RichDEM、vLLM 在原生 Windows 上要么装不上、要么行为不一致。**统一放进 WSL2(Ubuntu 22.04)** 后:

- 形式化(Lean/Dafny)与地理数据处理(GDAL/WhiteboxTools/RichDEM)在同一环境,避免两套工具链来回切。
- vLLM 不支持 Windows 原生,本地推理必须走 WSL2 或 API——而 Y2 本地 32B 评测依赖它(本机 12 GB 只能跑 7–13B,32B 走云 4090/24 GB)。
- 与云上 SeetaCloud/AutoDL 的 Ubuntu 环境一致,脚本可复用。

> **关于 agent 自动安装**:本仓库的 agent(WorkBuddy)运行在沙箱中,`wsl.exe` 被 Security Center 的"程序黑名单"硬拦截,**无法在本会话内自动安装 WSL2**。因此本指南由你在本机手动执行一条命令完成;脚本已写好,本质是一次"一键"。若你愿意把 `wsl.exe` 从黑名单移除,agent 也可在本会话内驱动安装与核对。

---

## 1. 一键启用 WSL2 + 安装 Ubuntu 22.04

**以管理员身份打开 PowerShell**(Win+X → Windows Terminal(管理员) 或 PowerShell(管理员))。

进入仓库目录(路径含空格,注意引号):

```powershell
cd "E:\AI for Math与DEM空间网格交叉研究\verifiable-geocomputation\scripts\wsl"
```

运行安装脚本:

```powershell
powershell -ExecutionPolicy Bypass -File .\install_wsl.ps1
```

脚本会:

1. 启用 `Microsoft-Windows-Subsystem-Linux` 与 `VirtualMachinePlatform` 功能
2. `wsl --set-default-version 2`
3. `wsl --install -d Ubuntu-22.04`

**若提示需要重启**:按提示重启后,**重新运行上面的脚本一次**,继续完成发行版安装。

> 若 `wsl --install` 弹出了 Ubuntu 窗口要求设置用户名/密码,按提示完成即可(这就是下一步)。

---

## 2. 首次启动 Ubuntu 并完成初始化

从**开始菜单**打开 **Ubuntu 22.04 LTS**,首次启动会让你设置:

- UNIX 用户名(小写,如 `guo`)
- 密码(输入时不显示,输完回车)

设置完成后,你就进到了 Ubuntu 的 shell。接下来装工具链。

---

## 3. 一键安装全部工具链(Lean4 / Dafny / GDAL / WhiteboxTools / RichDEM)

回到 **Windows 的 PowerShell**(不是 Ubuntu 窗口),执行下面这条命令(把路径改成你仓库里的真实路径):

```powershell
wsl -d Ubuntu-22.04 -- bash -c "sudo bash '/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/provision.sh'"
```

脚本会自动:

| 步骤 | 内容 | 预计耗时 |
| --- | --- | --- |
| 1/7 | 更新 apt、装基础编译工具 | 2–5 min |
| 2/7 | 安装 GDAL 3.4(`gdal-bin` + `libgdal-dev` + `python3-gdal`) | 1–3 min |
| 3/7 | 建 Python venv `~/verigis/venv`(继承系统 GDAL),装 numpy/scipy/whiteboxtools/richdem | 3–8 min |
| 4/7 | 装 Lean 4(elan)+ 拉取 mathlib、**首次构建 mathlib 30–60 min**(脚本不阻塞,超时记非致命) | 30–60 min |
| 5/7 | 装 Dafny 最新版(自包含,z3 内嵌)+ 验证一条小定理 | 1–3 min |
| 6/7 | 验证 WhiteboxTools / RichDEM / GDAL-Python 导入 | <1 min |
| 7/7 | 汇总各工具版本 | — |

**日志同时写入 WSL 内的 `~/wsl_provision.log`**,卡住时可 `wsl -d Ubuntu-22.04 -- tail -n 50 ~/wsl_provision.log` 查看。

> 这一步通常 40–70 分钟(mathlib 构建是大头)。可放心让它跑完。

---

## 4. 验证安装结果

在 PowerShell 执行:

```powershell
wsl -d Ubuntu-22.04 -- bash -c "source ~/verigis/venv/bin/activate; gdalinfo --version; lake --version; dafny --version; python -c 'import whiteboxtools, richdem; print(\"whiteboxtools+richdem OK\")'"
```

应看到类似输出:

```
GDAL 3.4.1, released 2021/12/27
Lean (version 4.x, ...)
Dafny program verifier version 4.x
whiteboxtools+richdem OK
```

如果哪一项是 `Command 'xxx' not found` 或 `No such file or directory`,**别重跑 provision.sh**——直接跳到 §6 跑 `remedy.sh`,它只补缺失项,5–30 min 内搞定。

---

## 5. 日常使用

- 打开开发环境:开始菜单 → Ubuntu 22.04 LTS(或 PowerShell 里 `wsl -d Ubuntu-22.04`)。
- 激活 Python 环境:`source ~/verigis/venv/bin/activate`
- Windows 的 `E:` 盘在 WSL 内为 `/mnt/e/`,仓库路径:`/mnt/e/AI\ for\ Math与DEM空间网格交叉研究/verifiable-geocomputation/`
- 推荐把常用命令写进 `~/.bashrc`(如 `alias vact='source ~/verigis/venv/bin/activate'`)。
- elan 装好后脚本会自动把 `~/.elan/bin` 写进 `~/.bashrc`,`lake` 在新会话也直接可用。

---

## 6. 出问题怎么办(诊断与补装)

`provision.sh` 在历史上有过两个常见坑(都源于 GitHub release 链路与重定向):

1. **elan 官方源 `elan.lean-lang.org` 被墙或被劫持** → `curl` 静默挂起,后面全跳;
2. **Dafny 走 `api.github.com/repos/.../latest` 触发 60 次/h 限流** → 拿不到版本号,后续下载也链断开。

新版 `provision.sh` 已经修了这两点(`-L` 跟随重定向、Lean 双源 fallback、`.deb` 直装不查 API、最后硬校验),但**早期或网络不好的环境还是可能漏一项**。同目录准备了一个 `remedy.sh` 专门补缺:

```bash
# 在 WSL 内,从仓库根目录跑
bash scripts/wsl/remedy.sh
```

或在 PowerShell:

```powershell
wsl -d Ubuntu-22.04 -- bash -c "bash '/mnt/e/AI for Math与DEM空间网格交叉研究/verifiable-geocomputation/scripts/wsl/remedy.sh'"
```

`remedy.sh` 行为:

1. 先**漏装检查**——只装缺的那几样,几秒钟判定。
2. **Python venv**:从 `python3 -m venv --system-site-packages` 重建,装 numpy/scipy/whiteboxtools/richdem。
3. **Lean 4**:同 provision.sh(elan 主源 + raw.githubusercontent.com 备用),自动把 `~/.elan/bin` 写进 `~/.bashrc`。
4. **Dafny**:直接下固定 `v4.8.1 .deb`,装完跑一条 `Abs` 小定理验证。
5. **mathlib scaffold**:在 `~/verigis/lean4_proj` 准备好项目(不阻塞,首次 `lake build` 30–60 min)。
6. 最终打印 `OK/FAIL` 表格,失败打 `FATAL` 并退非零——没有任何"假装成功"。

日志写在 `~/wsl_remedy.log`,全程同步 stdout/stderr 到屏幕。

---

## 7. 常见问题(排错)

**Q1. `wsl.exe` 被拦截 / 不是内部或外部命令**
- 确认以**管理员**打开 PowerShell;
- 若来自 WorkBuddy agent:这是 agent 沙箱的程序黑名单,需在 Security Center → Command Security → Program Blacklist 移除 `wsl.exe`,或在本机手动执行本指南。

**Q2. 首次 `wsl --install` 后没弹出初始化窗口、且 `wsl -d Ubuntu-22.04` 报错**
- 可能功能启用后未重启。重启电脑再运行一次 `install_wsl.ps1`。

**Q3. mathlib 构建卡很久 / 超时**
- 属正常:首次构建本就 30–60 min。脚本不阻塞,失败记为非致命。稍后可手动:`cd ~/verigis/lean4_proj && lake build`。

**Q4. `pip install richdem` 编译失败**
- 需 `python3-dev` 与 `g++`(脚本第 1 步已装)。若仍失败,确认 venv 用了 `--system-site-packages`(继承系统 GDAL)。仍不行可改 `pip install richdem --no-build-isolation`。

**Q5. Dafny / elan 下载超时(`curl: (28) ... Connection timed out`)**
- 2026-09 国内/受限网络访问 `github.com` 必 134s 超时。`remedy.sh` / `provision.sh` 现在自动三源 fallback:原 URL → `gh-proxy.com` → `mirror.ghproxy.com`。
- **elan 特别坑**:`elan-init.sh` 内部还会再 curl 拉 tarball,卡两次。新版脚本**改直装 tarball**,跳过 init 流程。
- 三源都失败还有最后一手——手机热点 / VPN,或在能上 GitHub 的设备拉一份 `elan-x86_64-unknown-linux-gnu.tar.gz` / `dafny-4.8.1-x64-ubuntu-22.04.deb`,拷到 WSL 的 `/tmp/`,再跑一次 `bash scripts/wsl/remedy.sh`(脚本发现文件就在 /tmp 会优先用它)。

**Q5b. `whiteboxtools` `pip install` 报 "No matching distribution found"**
- 2026 年 PyPI 上 `whiteboxtools` 包装器把 Python 限制在 `<3.10`,但 Ubuntu 22.04 系统 Python 是 3.10.6。
- 修复:`pip install whitebox`(维护者 giswqs 迁的新名,Python 3.10+ OK)。脚本 fallback:`pip install --ignore-requires-python whiteboxtools==1.10.0`。
- DEM 算子在脚本里用哪个都行,核心是**至少一个能 import**。

**Q6. Windows 与 WSL 文件互访**
- WSL 内访问 Windows:`/mnt/c/`、`/mnt/e/`;Windows 访问 WSL 文件:资源管理器地址栏输入 `\\wsl$\Ubuntu-22.04\`。

**Q7. provision.sh 跑完看不到 lake/dafny**
- **新会话没自动加载 elan 环境**。手动:`export PATH="$HOME/.elan/bin:$PATH"`,或重开终端。
- 真没装上 → §6 跑 remedy.sh。

**Q8. `curl` 在 GitHub release 链接上挂死**
- 历史经验:`-sSf` 不带 `-L`,重定向后等不到响应。加 `-L --max-time`。新版 provision.sh / remedy.sh 已修。

---

## 8. 与云实例的分工(见 `docs/resources.md`)

| 场景 | 环境 |
| --- | --- |
| Lean 4 / mathlib 构建与证明检查、日常编码、7–13B 本地对照 | **本机 WSL2** |
| 多模型批量评测、全球尺度 DEM 批处理、模型微调(Y3+) | **云(SeetaCloud/AutoDL)** |

---

_最后更新:2026-09-05 v2 — 新增 `remedy.sh` 补装路径,Lean/Dafny 安装链路硬化(防 curl 挂起、API 限流)。_

