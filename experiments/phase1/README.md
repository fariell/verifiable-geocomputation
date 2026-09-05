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
| `propositions.py` | 生成 20 条 GeoProofBench 候选命题（json/csv/md） |
| `run_experiment.sh` | 实验驱动（激活 venv 后运行上述两个 py） |
| `bootstrap.sh` | 远程一键装机：装系统依赖 → 建 venv → 装包 → 跑实验 → 装 Lean → 构建 |
| `lean4_proj/` | Lean 4 骨架工程（Phase 1 仅做冒烟测试，未引入 mathlib） |
| `deploy.py` | 本机部署器：读登录信息 → SFTP 上传 → 后台启动 bootstrap |

## 本地部署（需要能 SSH 到远程的环境）

```bash
# 在本机（能联网到 SeetaCloud 的机器）执行：
python experiments/phase1/deploy.py
# 监控：
ssh -p <your-autoDL-port> root@<your-autoDL-host> "tail -f /root/verigis/logs/progress.log"
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
