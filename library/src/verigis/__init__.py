"""
VeriGIS · 可验证空间计算 Python 库

把 GDAL / WhiteboxTools / RichDEM 等成熟空间库的算子接口,
暴露为可形式化规范的形式:每个函数都附带 Lean/Dafny 形式规约、
属性测试、与参考实现的差分验证。
"""

__version__ = "0.1.0-dev"
__author__ = "Verifiable Geocomputation Contributors"

# 占位:本周 sprint 0 完成骨架,下周接入第一个算子(坡度)