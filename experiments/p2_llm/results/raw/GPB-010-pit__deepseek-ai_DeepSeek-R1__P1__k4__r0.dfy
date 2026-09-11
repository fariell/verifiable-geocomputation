// ===========================================================================
//  GeoProofBench · P-005
//  算子 : D8 最陡坡度流向
//  覆盖 : GPB-010 (洼地无流向)、GPB-011 (平面流向一致性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P005_d8.dfy
// ===========================================================================
//
//  科学动机
//  ---------
//  D8 流向算法是水文分析的基础算子。本文件证明其核心性质：
//      当中心点不高于任何邻点时（洼地条件），流向应为 NoFlow。
//
//  该性质是填洼算法（P-002）和流量累积（P-006）的前置条件，
//  确保水文网络在洼地处终止。
//
//  注：本证明仅关注洼地条件，平面流向一致性见 GPB-011 的独立证明。
// ===========================================================================

module D8Flow {

  // ------------------------------------------------------------------
  // 3x3 窗口约定（行偏移向下为正，符合栅格惯例）
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  // ------------------------------------------------------------------

  // 流向枚举（含 NoFlow 状态）
  datatype Direction = 
    | E   // 东
    | SE  // 东南
    | S   // 南
    | SW  // 西南
    | W   // 西
    | NW  // 西北
    | N   // 北
    | NE  // 东北
    | NoFlow

  // D8 流向计算核心函数
  function method FlowDirection(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real
  ): Direction
  {
    // 初始化最佳优先级和方向
    var bestDir := NoFlow;
    var bestPriority := 0.0;

    // 东向 (E) - 邻点 f
    var drop := e - f;
    if drop > 0.0 {
      var priority := drop * drop / 1.0;  // 距离因子=1.0
      if priority > bestPriority {
        bestDir, bestPriority := E, priority;
      }
    }

    // 东南 (SE) - 邻点 i
    drop := e - i;
    if drop > 0.0 {
      var priority := drop * drop / 2.0;  // 距离因子=2.0
      if priority > bestPriority {
        bestDir, bestPriority := SE, priority;
      }
    }

    // 南 (S) - 邻点 h
    drop := e - h;
    if drop > 0.0 {
      var priority := drop * drop / 1.0;
      if priority > bestPriority {
        bestDir, bestPriority := S, priority;
      }
    }

    // 西南 (SW) - 邻点 g
    drop := e - g;
    if drop > 0.0 {
      var priority := drop * drop / 2.0;
      if priority > bestPriority {
        bestDir, bestPriority := SW, priority;
      }
    }

    // 西 (W) - 邻点 d
    drop := e - d;
    if drop > 0.0 {
      var priority := drop * drop / 1.0;
      if priority > bestPriority {
        bestDir, bestPriority := W, priority;
      }
    }

    // 西北 (NW) - 邻点 a
    drop := e - a;
    if drop > 0.0 {
      var priority := drop * drop / 2.0;
      if priority > bestPriority {
        bestDir, bestPriority := NW, priority;
      }
    }

    // 北 (N) - 邻点 b
    drop := e - b;
    if drop > 0.0 {
      var priority := drop * drop / 1.0;
      if priority > bestPriority {
        bestDir, bestPriority := N, priority;
      }
    }

    // 东北 (NE) - 邻点 c
    drop := e - c;
    if drop > 0.0 {
      var priority := drop * drop / 2.0;
      if priority > bestPriority {
        bestDir, bestPriority := NE, priority;
      }
    }

    bestDir  // 返回最终流向
  }

  // ==================================================================
  // 洼地引理：若中心点不高于任何邻点，则流向为 NoFlow
  // ==================================================================
  lemma PitCondition(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real
  )
    // 前置条件：所有邻点高程 ≥ 中心点
    requires a >= e && b >= e && c >= e
    requires d >= e && f >= e
    requires g >= e && h >= e && i >= e
    // 后置条件：流向必为 NoFlow
    ensures FlowDirection(a,b,c,d,e,f,g,h,i) == NoFlow
  {
    // 证明策略：所有邻点下降值 ≤ 0 → 无正优先级更新
    assert e - a <= 0.0;  // 西北
    assert e - b <= 0.0;  // 北
    assert e - c <= 0.0;  // 东北
    assert e - d <= 0.0;  // 西
    assert e - f <= 0.0;  // 东
    assert e - g <= 0.0;  // 西南
    assert e - h <= 0.0;  // 南
    assert e - i <= 0.0;  // 东南
    // 由函数逻辑：所有 if(drop>0) 分支均跳过 → bestDir 保持 NoFlow
  }

  method Main() {
    print "GeoProofBench P-005 — D8 洼地无流向定理\n";
    print "编译期验证: dafny verify P005_d8.dfy\n";
  }
}
