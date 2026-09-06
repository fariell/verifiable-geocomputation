# AutoDL 作战手册 · Verifiable Geocomputation 云端工作流

> **决策(2026-09-06)**:本地 WSL 的 Lean/Dafny 链路装得通但太费劲,**主路径迁 AutoDL**。
> 本文档是这条主路径的入口。硬件与预算沿用 [`autodl-rental.md`](autodl-rental.md)
> (4090 + PyTorch 2.5.1/UB22.04,月 ¥60-120),不重复;本文档专讲**怎么用**。

## 〇、一句话

```bash
# 本机一行(密码在 ~/.autodl_pwd 私有文件,模式 600)
sshpass -f ~/.autodl_pwd ssh -p <your-autoDL-port> -o StrictHostKeyChecking=no \
    root@<your-autoDL-host> \
    'bash -s' < scripts/autodl/setup.sh       # 首次装机
sshpass -f ~/.autodl_pwd ssh -p <your-autoDL-port> -o StrictHostKeyChecking=no \
    root@<your-autoDL-host> \
    'bash -s' < scripts/autodl/verify_all.sh  # 日常跑
```

然后**在 autoDL 实例内**的工作目录里干活。本机只看拉回来的结果(`results_pull.sh`)。

---

## 一、前置:本地只准备一个密码文件(再也不手敲密码)

`autoDL登录信息.txt` 是**唯一可信源**,但明文密码不进任何脚本。

```bash
# 本机 PowerShell / Git Bash 都行,把密码写到用户私有文件
echo '<your-autoDL-password>' > ~/.autodl_pwd
chmod 600 ~/.autodl_pwd      # Git Bash: 也行;Windows 上 Git Bash 强制 600
# 验证
cat ~/.autodl_pwd            # 只回显自己看
```

**为什么不在脚本里硬编码密码?**
- 进 commit 即泄露(同事/审稿人/学生能看到)
- `autoDL登录信息.txt` 走 `.gitignore` 不进 git,但脚本里若也写一份就两处风险源
- 用 SSH_ASKPASS 每次还得手输,用密码文件 + sshpass 一行命令,**全部离线脚本可启动**

**前置依赖:装 sshpass**

```bash
# Git Bash
pacman -S sshpass          # 或 scoop install sshpass / choco install sshpass

# WSL(如果以后还要用)
sudo apt-get install sshpass

# macOS
brew install hudochenkov/sshpass/sshpass
```

---

## 二、首次装机:`setup.sh`(约 10-20 分钟)

`scripts/autodl/setup.sh` 在 autoDL 实例里**装 Lean + Dafny + GDAL/Python + clone 本仓 + 跑冒烟**。

为何不用 `provision.sh`:那是为本地 WSL 设计的,带 `./scripts/wsl/remedy.sh` 那套本地补救逻辑。autoDL 网络好(国际出口通畅),**直接走官方路径**:
- Lean: `curl https://elan.lean-lang.org/elan-init.sh | sh`(elan 反而在云端好装)
- Dafny: `wget https://github.com/dafny-lang/dafny/releases/download/v4.11.0/dafny-4.11.0-x64-ubuntu-22.04.zip`,自带 unzip

跑法:

```bash
# 本机 Git Bash
sshpass -f ~/.autodl_pwd ssh -p <your-autoDL-port> \
    -o StrictHostKeyChecking=no \
    root@<your-autoDL-host> \
    'bash -s' < scripts/autodl/setup.sh
```

实例里大约做这些事(脚本本身):
1. `apt update && apt install -y unzip git curl wget build-essential python3-venv python3-pip libgdal-dev gdal-bin zstd`
2. `curl https://elan.lean-lang.org/elan-init.sh | sh -s -- -y --default-toolchain lean-4.18.0`
3. 装 Dafny v4.11.0(.zip → /opt/dafny → 符号链)
4. `python3 -m venv --system-site-packages ~/verigis/venv` + pip 装 numpy/scipy/osgeo
5. `git clone https://github.com/fariell/verifiable-geocomputation.git ~/verigis/repo`
6. `dafny verify formal/dafny/SmokeAbs.dfy` 冒烟 + `lake build` 暖机(可选,首次 30-60 min)

**详细输出**会写到 `~/.workbuddy/setup_<时间戳>.log`。

---

## 三、日常跑批:`verify_all.sh`

`scripts/autodl/verify_all.sh` 在云端跑"今天该验的几件事":

1. **Dafny P-001**(已知 19 verified,作为锚点再验)
2. **Dafny P-002**(新命题,SMT 可能超时 → 收集 stderr)
3. **Lean P-001**:`lake build` 或单独 `lake env lean VeriGIS/HornSlope`(mathlib 已暖机后秒过)
4. **Lean P-002**:把 P-002 的 Lean 版本也跑了(完成 Lean/Dafny 双重证明)
5. **GPB-019** DEM 噪声实验入口(若 `experiments/phase1/` 里已经有 benchmark 脚本就跑)

每项跑完都把 stdout/stderr + 摘要 append 到 `~/.workbuddy/verify_<时间戳>.log`。
**关键**:脚本还把摘要 grep 出来写到 `~/.workbuddy/summary_<时间戳>.txt`,**方便本地拉**。

跑法(本机):

```bash
# 同 sshpass 包装,一行
sshpass -f ~/.autodl_pwd ssh -p <your-autoDL-port> \
    -o StrictHostKeyChecking=no \
    root@<your-autoDL-host> \
    'bash -s' < scripts/autodl/verify_all.sh
```

---

## 四、回传结果:`results_pull.sh`(本机跑)

把今天云端跑出来的所有产物拉到 `experiments/phase1/`,统一管理:

```bash
# 本机
bash scripts/autodl/results_pull.sh
```

脚本做的事:
1. `scp -P <your-autoDL-port>` 拉 `~/.workbuddy/summary_*.txt` 到 `experiments/phase1/logs/`(名字按日期)
2. 拉 `~/.workbuddy/dafny_*.log` + `~/.workbuddy/lake_*.log` 原始档(若有)
3. 在 `experiments/phase1/STATUS.md` 里 append 一行 "<日期> \| P-001 pass=P P-002 pass=?"

**幂等**:重复跑不会丢档(同名就 `.bak`)。
**零凭据风险**:密码从 `~/.autodl_pwd` 读,不进 git。

---

## 五、本地 WSL 还用得上吗?(降级规则)

迁不意味着弃。**本地 WSL 保留,但用途收窄**:

| 任务 | 主场 |
| --- | --- |
| Lean/Dafny 跑通链路 | **autoDL** ✓ |
| Lake build / mathlib 编译 | **autoDL** ✓ |
| 长实验(GPB-019 / GPB-005 / 大数据集) | **autoDL** ✓ |
| 本地 LLM 评测 32B-Q4 | autoDL(日后) |
| **小改 .dfy 后的快速 lint** | WSL(已装 dafny,改完即可验) |
| **写论文/码代码** | 本机(在 Git Bash 里) |
| **没有网时应急** | 备用 |

WSL 不再试图装"完整工具链"——**已装好的不删**(dafny 还在),
**不再追装** GDAL/Lean toolchain(那两件事的边际收益是负的)。

---

## 六、当前任务清单(谁来都按这个推)

| # | 任务 | 跑在哪 | 预估时间 | 状态 |
| --- | --- | --- | --- | --- |
| 1 | 首次 `setup.sh` 把工具链装好 | autoDL | 10–20 min | ⏳ 待启动 |
| 2 | `lake build` 暖通 mathlib | autoDL | 30–60 min | ⏳ 待启动 |
| 3 | Dafny P-001 + P-002 重跑(云端一致性锚) | autoDL | 2 min | ⏳ |
| 4 | Lean P-001 verify(`VeriGIS/HornSlope.lean`,222 行) | autoDL(暖机后) | 1 min | ⏳ |
| 5 | GPB-019 DEM 噪声实验入口脚本 | autoDL + 本仓 | 30 min | ⏳ |

---

## 七、安全护栏

| 红线 | 处置 |
| --- | --- |
| 密码写进任何 .sh / .py / commit message | 严禁。`~/.autodl_pwd` 是唯一可读来源 |
| 跑超过 2 小时 GPU(¥4+) | 改无卡模式装,GPU 只在跑实际评测时开 |
| 无 git push 用例外的强行推送 | 没有。即便开了 vLLM/SGlang 模型,也走 `/root/autodl-tmp/` 不进系统盘 |
| `git push` 进 autoDL 实例仓库 | 不,实例 repo 是只读工作区,**同步用 rebase from upstream**,不要 push 走 autoDL 出网 |
| 烧钱到月初没规划 | 设消费上限 ¥300/月(账户里改,不要靠脚本监控) |

---

## 八、故障排查(快速索引)

| 现象 | 解 |
| --- | --- |
| `sshpass: command not found` | 装 sshpass(见 §一) |
| `Connection refused on port <your-autoDL-port>` | 实例已关机;进 autoDL 网页控制台 → 实例 → "开机" |
| `dafny verify` 在云端报 unzip 类错 | autoDL 镜像几乎一定有 unzip;若报缺,Setup 已带 `apt install -y unzip` |
| `lake build` 首次 30-60 min 不动 | **正常**,mathlib 大;开 `tail -f ~/.workbuddy/setup_*.log` 看进度 |
| `verification timeout` SMT | `lake build` 加 `--timeout 120` 或把 .dfy 拆 |
| 拉回的结果发现 `summary_*.txt` 空 | 查 `~/.workbuddy/verify_*.log` 原文,看哪一步 hang |

---

## 九、为什么不是本地(2026-09-06 的反思)

迁 autoDL 不是因为本地"装不上",而是因为**装这件事不该再花一晚**:

| 因素 | 本地 WSL | autoDL |
| --- | --- | --- |
| Lean toolchain 318 MB | 反复断,3 次 270M 卡 | 一次性秒下 |
| Dafny .zip 63 MB | apt-cache 0 结果,只能 ZIP | wget 30 秒 |
| GitHub release 限流 | 60 req/h | 不限 |
| mathlib 编译 | 30–60 min 卡本机 CPU | 不卡本机,可睡前开 |
| 重启/休眠对链路的影响 | Windows 重启 = 工具链可能丢 | 实例状态独立 |
| 本机 CPU 占用 | 影响写代码体验 | 零 |

唯一不能迁的是**写代码**——依然在本机,在 VS Code 里改 `.dfy` / `.lean`,
然后 `bash scripts/autodl/results_pull.sh` 一条龙验证。

---

_创建日期:2026-09-06 · 主路径决策记录,洛书整理_
