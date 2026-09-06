#!/usr/bin/env bash
# fake_setup.sh — 给 jupyter_progress.py 冒烟测试用的 fake 长任务
set +e  # 自己保留非零
echo "AutoDL fake setup START @ $(date '+%H:%M:%S')"
echo "============================================================"
echo "==[0/3] 起点盘点 =="
sleep 1
echo "  ✅ fake_tool  /usr/local/bin/fake_tool"
echo "==[1/3] apt 阶段 =="
sleep 1
echo "  ℹ fake apt 完成"
sleep 1
echo "==[2/3] Dafny 验证(模拟慢)=:"
echo "  [dafny] P-001"
echo "  (接下来 sleep 8 模拟 Lake update 的网络 stall — 测试心跳)"
sleep 8
echo "Dafny program verifier finished with 19 verified, 0 errors"
echo "  [dafny] P-002"
sleep 2
echo "Dafny program verifier finished with 4 verified, 0 errors"
echo "==[3/3] 终态盘点 =="
sleep 1
echo "  ✅ fake_dafny  4.11.0"
echo "============================================================"
echo "fake setup END @ $(date '+%H:%M:%S')"
