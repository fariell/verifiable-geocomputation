/-
  VeriGIS 根模块。`lake build` 只编译被根模块 import 的文件;
  没有本文件时 HornSlope.lean 不会进入构建图。
-/
import VeriGIS.HornSlope
import VeriGIS.PitFilling
import VeriGIS.PitFilling2D
import VeriGIS.Curvature
import VeriGIS.Consistency
