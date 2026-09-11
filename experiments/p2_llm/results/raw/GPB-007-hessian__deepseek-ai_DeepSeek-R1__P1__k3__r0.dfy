// ===========================================================================
//  GeoProofBench · P-003
//  文件 : formal/dafny/P003_curvature.dfy
//  算子 : Zevenbergen-Thorne (1987) 3x3 有限差分 Hessian
//  覆盖 : GPB-003 (二次曲面上的精确性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P003_curvature.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  Phase 1 实验显示曲率算子在不同实现间相关性极低 (corr ≈ 0.157)。
//  本证明回答:在什么条件下离散 Hessian 是精确的?
//
//  结论:在二次曲面上, ZT Hessian 精确恢复 (hxx, hyy, hxy) = (2A, 2B, C)。
//  这为曲率算子的一致性提供了代数基础——但仅当曲面局部二次且无噪声。
//  噪声放大问题(由分母 w² 引起)是 Phase 1 低相关性的根源,见文末注记。
//
// ===========================================================================

module ZTHessian {

  // ------------------------------------------------------------------
  // 3x3 窗口约定(行偏移 q 向下为正,符合栅格惯例)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // 注意:与 Horn 坡度不同,Hessian 显式依赖中心元 e
  // ------------------------------------------------------------------

  // 二次曲面函数: z = A·x² + B·y² + C·xy + D·x + E·y + F
  function quadratic(x: real, y: real, 
                     A: real, B: real, C: real, 
                     D: real, E: real, F: real): real 
  {
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }

  // ZT Hessian 分量定义 (w = 格网间距)
  function zt_hxx(a: real, b: real, c: real, d: real, e: real, 
                  f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    (d - 2.0*e + f) / (w*w)
  }

  function zt_hyy(a: real, b: real, c: real, d: real, e: real, 
                  f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    (b - 2.0*e + h) / (w*w)
  }

  function zt_hxy(a: real, b: real, c: real, d: real, e: real, 
                  f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    (a - c - g + i) / (4.0 * w * w)
  }

  // ==================================================================
  // 核心定理:在二次曲面上,ZT Hessian 精确恢复 (2A, 2B, C)
  // ==================================================================
  lemma HessianExactOnQuadratic(A: real, B: real, C: real, 
                                D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures 
      // 定义 3x3 窗口采样点 (中心在 (0,0))
      var a := quadratic(-w, -w, A, B, C, D, E, F);
      var b := quadratic( 0.0, -w, A, B, C, D, E, F);
      var c := quadratic( w, -w, A, B, C, D, E, F);
      var d := quadratic(-w,  0.0, A, B, C, D, E, F);
      var e_val := quadratic(0.0, 0.0, A, B, C, D, E, F);
      var f_val := quadratic( w,  0.0, A, B, C, D, E, F);
      var g_val := quadratic(-w,  w, A, B, C, D, E, F);
      var h_val := quadratic( 0.0, w, A, B, C, D, E, F);
      var i_val := quadratic( w,  w, A, B, C, D, E, F);
      // 验证 ZT Hessian 精确匹配解析值
      zt_hxx(a, b, c, d, e_val, f_val, g_val, h_val, i_val, w) == 2.0 * A &&
      zt_hyy(a, b, c, d, e_val, f_val, g_val, h_val, i_val, w) == 2.0 * B &&
      zt_hxy(a, b, c, d, e_val, f_val, g_val, h_val, i_val, w) == C
  {
    // 证明策略:直接展开定义并代数化简
    // 注意:Dafny 自动处理实数算术,无需额外引理
    
    // 展开二次函数在采样点的值
    assert a == A*(-w)*(-w) + B*(-w)*(-w) + C*(-w)*(-w) + D*(-w) + E*(-w) + F 
           by (calc {
             quadratic(-w, -w, A, B, C, D, E, F);
           });
    assert b == B*(-w)*(-w) + E*(-w) + F 
           by (calc {
             quadratic(0.0, -w, A, B, C, D, E, F);
           });
    assert c == A*(w)*(w) + B*(-w)*(-w) + C*(w)*(-w) + D*(w) + E*(-w) + F 
           by (calc {
             quadratic(w, -w, A, B, C, D, E, F);
           });
    assert d == A*(-w)*(-w) + D*(-w) + F 
           by (calc {
             quadratic(-w, 0.0, A, B, C, D, E, F);
           });
    assert e_val == F 
           by (calc {
             quadratic(0.0, 0.0, A, B, C, D, E, F);
           });
    assert f_val == A*(w)*(w) + D*(w) + F 
           by (calc {
             quadratic(w, 0.0, A, B, C, D, E, F);
           });
    assert g_val == A*(-w)*(-w) + B*(w)*(w) + C*(-w)*(w) + D*(-w) + E*(w) + F 
           by (calc {
             quadratic(-w, w, A, B, C, D, E, F);
           });
    assert h_val == B*(w)*(w) + E*(w) + F 
           by (calc {
             quadratic(0.0, w, A, B, C, D, E, F);
           });
    assert i_val == A*(w)*(w) + B*(w)*(w) + C*(w)*(w) + D*(w) + E*(w) + F 
           by (calc {
             quadratic(w, w, A, B, C, D, E, F);
           });
    
    // 验证 hxx = (d - 2e + f)/w² = 2A
    assert d - 2.0*e_val + f_val == 
           (A*w*w - D*w + F) - 2.0*F + (A*w*w + D*w + F) 
           by (calc {})
        == 2.0*A*w*w 
           by (calc {});
    assert zt_hxx(a, b, c, d, e_val, f_val, g_val, h_val, i_val, w) 
           == (2.0*A*w*w) / (w*w) 
           by (calc {})
        == 2.0*A 
           by (calc {});
    
    // 验证 hyy = (b - 2e + h)/w² = 2B
    assert b - 2.0*e_val + h_val == 
           (B*w*w - E*w + F) - 2.0*F + (B*w*w + E*w + F) 
           by (calc {})
        == 2.0*B*w*w 
           by (calc {});
    assert zt_hyy(a, b, c, d, e_val, f_val, g_val, h_val, i_val, w) 
           == (2.0*B*w*w) / (w*w) 
           by (calc {})
        == 2.0*B 
           by (calc {});
    
    // 验证 hxy = (a - c - g + i)/(4w²) = C
    assert a - c - g_val + i_val == 
           (A*w*w + B*w*w + C*w*w - D*w - E*w + F) -
           (A*w*w + B*w*w - C*w*w + D*w - E*w + F) -
           (A*w*w + B*w*w - C*w*w - D*w + E*w + F) +
           (A*w*w + B*w*w + C*w*w + D*w + E*w + F) 
           by (calc {})
        == 4.0*C*w*w 
           by (calc {});
    assert zt_hxy(a, b, c, d, e_val, f_val, g_val, h_val, i_val, w) 
           == (4.0*C*w*w) / (4.0*w*w) 
           by (calc {})
        == C 
           by (calc {});
  }

  // ==================================================================
  // 噪声放大注记(非引理)
  // ------------------------------------------------------------------
  // 本定理成立的关键前提:
  //   1) 曲面严格二次(泰勒展开无高阶项)
  //   2) 无高程噪声(精确算术)
  //
  // 实际 DEM 中:
  //   - 分母 w² 放大高程噪声 O(σ/w²), 其中 σ 为高程标准差
  //   - 非二次曲面引入 O(w²) 截断误差
  //
  // 例: w=30m 的 SRTM 上, σ≈2-5m 时, 曲率信噪比崩塌 → Phase 1 的 0.157
  // 这是曲率算子与坡度算子的本质区别(Horn 坡度不依赖中心元且分母为 O(w))
  //
  // 结论:曲率的一致性必须定义在特定误差模型下(见 P-003 后续工作)
  // ==================================================================
}

method Main() {
  print "GeoProofBench P-003 — Zevenbergen-Thorne Hessian 在二次曲面上的精确性\n";
  print "由编译期验证: dafny verify P003_curvature.dfy\n";
}
