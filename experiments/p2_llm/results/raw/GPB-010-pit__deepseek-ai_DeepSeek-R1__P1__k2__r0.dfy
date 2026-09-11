// ===========================================================================
//  GeoProofBench · P-005
//  文件 : formal/dafny/P005_d8.dfy
//  算子 : D8 最陡坡度流路算法
//  覆盖 : GPB-010 (洼地无流)、GPB-011 (平面流向一致性) 的洼地部分
//  环境 : Dafny 4.11 · 验证命令 dafny verify P005_d8.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  Phase 1 实验显示 D8 算法在平坦区域和洼地的行为是关键的误差源。
//  本文件证明:在严格洼地(无更低邻域)中,D8 算法正确返回无流(NoFlow)。
//
//  注:本文件仅覆盖洼地条件(GPB-010)。平面上的流向一致性(GPB-011)在另一个引理中。
//
// ===========================================================================

module D8Flow {

  // ------------------------------------------------------------------
  // 3×3 窗口约定(行偏移 q 向下为正,符合栅格惯例)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // 注意:中心元 e 在 D8 算法中为核心比较点
  // ------------------------------------------------------------------

  // 流向结果类型(包含 8 个方向 + 无流)
  datatype Direction = 
    E | SE | S | SW | W | NW | N | NE | NoFlow

  // D8 流路计算核心
  function method FlowDirection(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real
  ): Direction
  {
    // 初始化最佳流向为无流
    var bestDir := NoFlow;
    var bestPriority := 0.0;

    // 检查东向(E)邻居 f(1,0)
    if f < e {
      var drop := e - f;
      var priority := drop * drop / 1.0;  // 距离因子=1.0
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := E, priority;
      }
    }
    // 检查东南(SE)邻居 i(1,1)
    if i < e {
      var drop := e - i;
      var priority := drop * drop / 2.0;  // 距离因子=2.0
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := SE, priority;
      }
    }
    // 检查南向(S)邻居 h(0,1)
    if h < e {
      var drop := e - h;
      var priority := drop * drop / 1.0;
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := S, priority;
      }
    }
    // 检查西南(SW)邻居 g(-1,1)
    if g < e {
      var drop := e - g;
      var priority := drop * drop / 2.0;
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := SW, priority;
      }
    }
    // 检查西向(W)邻居 d(-1,0)
    if d < e {
      var drop := e - d;
      var priority := drop * drop / 1.0;
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := W, priority;
      }
    }
    // 检查西北(NW)邻居 a(-1,-1)
    if a < e {
      var drop := e - a;
      var priority := drop * drop / 2.0;
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := NW, priority;
      }
    }
    // 检查北向(N)邻居 b(0,-1)
    if b < e {
      var drop := e - b;
      var priority := drop * drop / 1.0;
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := N, priority;
      }
    }
    // 检查东北(NE)邻居 c(1,-1)
    if c < e {
      var drop := e - c;
      var priority := drop * drop / 2.0;
      if bestDir == NoFlow || priority > bestPriority {
        bestDir, bestPriority := NE, priority;
      }
    }

    bestDir  // 返回最终确定的流向
  }

  // ==================================================================
  // 洼地无流定理 · GPB-010
  // 核心性质:若所有邻居高程 ≥ 中心,则必为无流(NoFlow)
  // ==================================================================
  lemma PitNoFlow(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real
  )
    requires a >= e && b >= e && c >= e
    requires d >= e && f >= e
    requires g >= e && h >= e && i >= e
    ensures FlowDirection(a, b, c, d, e, f, g, h, i) == NoFlow
  {
    // 证明策略:所有流向判断条件 f<e, i<e,... 均为假
    // 由前置条件直接推出,无需额外计算
  }

  // ==================================================================
  // 算法结构注记
  // ------------------------------------------------------------------
  // 证明成立的关键结构特征:
  //   1) 流向计算严格依赖邻居<中心的下降条件
  //   2) 洼地条件(∀邻居≥中心)使所有下降条件失效
  //   3) 无流(NoFlow)是初始状态和默认返回值
  //
  // 此性质不依赖具体优先级计算方式(平方/线性/对数),
  // 仅依赖下降条件判断的严格不等关系.
  // ==================================================================

  method Main() {
    print "GeoProofBench P-005 — D8 洼地无流定理 (GPB-010)\n";
    print "编译验证: dafny verify P005_d8.dfy\n";
  }
}
