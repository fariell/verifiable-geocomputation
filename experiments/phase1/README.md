# Phase 1 实验 — Verifiable DEM Terrain Operator Baseline

本目录是「可验证空间计算」研究体系 **Y0 第一阶段实验** 的代码与脚本。

## 目标

在算子层（三层资产结构的最底层）建立第一个可验证基线：

1. **算子可复现性**：用「解析真值」验证数值地形算子（坡度/坡向/曲率）的正确性。
   生成一张「高斯叠加 + 线性倾斜」合成 DEM，其 1/2 阶导有闭式解；再用有限差分
   数值计算同一组导数，对比得到 MAE / RMSE / 最大误差 / 相关系数。
2. **命题素材库种子集**：生成 GeoProofBench v0.1 的 20 条候选命题（M3 子集），
   作为后续 Lean 4 / Dafny 形式化的原料。
3. **形式化工具链冒烟测试**：确认 Lean 4（elan）能在远程环境编译构建。

## 文件

| 文件 | 作用 |
|---|---|
| `experiment.py`  | 合成 DEM + 数值/解析对比实验，输出 `results/phase1_metrics.json` 与对比图 |
| `gpb019_consistency.py` | **GPB-019 入口**:扫网格间距 w + 高程噪声,Horn 坡度 vs 曲率对照 |
| `run_benchmark.sh` | AutoDL / `verify_all.sh` 调用的 GPB-019 驱动 |
| `p003_curvature.py` | **P-003 入口**:正确 ZT Hessian vs Phase 1 错误模板;可选 wolframscript / Manim |
| `p003_taylor.wl` | ZT Hxx 的 Taylor 余项(由 Python `subprocess` 调 wolframscript) |
| `p003_manim.py` | 3×3 模板与 `1/w²` 放大的 Manim 场景 |
| `run_p003.sh` | AutoDL / `verify_all.sh` 调用的 P-003 驱动 |
| `propositions.py` | 生成 20 条 GeoProofBench 候选命题（json/csv/md） |
| `run_experiment.sh` | 实验驱动（激活 venv 后运行上述两个 py） |
| `bootstrap.sh` | 远程一键装机：装系统依赖 → 建 venv → 装包 → 跑实验 → 装 Lean → 构建 |
| `lean4_proj/` | Lean 4 骨架工程（Phase 1 仅做冒烟测试，未引入 mathlib） |
| `deploy.py` | 本机部署器：读登录信息 → SFTP 上传 → 后台启动 bootstrap |

## GPB-019(只在 AutoDL 跑)

```bash
source ~/verigis/venv/bin/activate
bash /root/verigis/repo/experiments/phase1/run_benchmark.sh
```

通过标准写在脚本末尾 `GPB-019 ENTRY: PASS`:`dx=1` 坡度 corr≥0.999;细网格 RMSE 低于粗网格;曲率 corr 仍 <0.5(对照,不是 Horn 的失败)。
产出:`experiments/phase1/results/gpb019/` 与 `~/.workbuddy/gpb019/`。

**实跑(AutoDL 2026-09-06 10:41)**:`GPB-019 ENTRY: PASS`,rc=0。dx=1 slope_r=0.999936;dx=0.5 RMSE < dx=4;曲率 corr(dx=1)=0.1566。日志 `~/.workbuddy/jobs/20260906_104126.log`。

## P-003 / GPB-003(本机写,AutoDL 验)

正确 ZT 模板:`hxx = (d-2e+f)/w²`。Phase 1 `experiment.py` 的 `d2zdx2 = (a-2d+g)/dx²` 在二次面上精确恢复的是 **hyy**,这是 0.157 的一部分来源,文件保持不动(历史对照)。

```bash
bash /root/verigis/repo/experiments/phase1/run_p003.sh
```

门控:抛物面 `|hxx+2k|<1e-10`;正确 hxx corr(dx=1)≥0.90 且高于错误模板;旧模板剖面曲率 corr<0.5;正确 ZT 剖面曲率在 dx=1 仍 <0.5(GPB-020 不是模板写反就能过)。
Wolfram / Manim 缺席不挡 PASS。本机渲染:`P003_MANIM=1 python experiments/phase1/p003_curvature.py`。

## 本地部署（需要能 SSH 到远程的环境）

```bash
# 在本机（能联网到云实例的机器）执行：
python experiments/phase1/deploy.py
# 监控(host/port 用环境变量,不要把实例地址写进仓库):
ssh -p "$AUTODL_SSH_PORT" "$AUTODL_SSH_HOST" "tail -f /root/verigis/logs/progress.log"
```

## 设计判断

- **用合成 DEM 而非真实 DEM**：因为合成地形有闭式导数真值，能直接「验证」数值算子，
  这正是本方向的核心卖点（可验证性）。真实 DEM 没有真值，只能做交叉验证。
- **实验脚本只用 numpy + 可选 matplotlib**：即使 rasterio/whiteboxtools/richdem
  安装失败，Phase 1 主体仍能跑完，保证产出不依赖脆弱的依赖链。
- **Lean 仅做冒烟测试**：真正的地形算子形式化需要 mathlib 的实分析，留到后续 sprint，
  本阶段只确认工具链可用。

## 合规

仅使用合成数据与公开方法，不涉及任何内部/涉密数据，符合依托单位数据合规要求。
