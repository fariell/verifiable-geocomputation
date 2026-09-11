// ===========================================================================
//  GeoProofBench · P-005
//  文件 : formal/dafny/P005_d8.dfy
//  算子 : D8 最陡下降法流向
//  覆盖 : GPB-010 (洼地无流向)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P005_d8.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  科学动机
//  ---------
//  水文分析中洼地(pit)是流向未定义的区域。本文件证明:在 D8 最陡下降法中，
//  当中心单元不存在严格下坡邻居时，流向必为 NoFlow。这是流向算法正确性的
//  基本引理，也是填洼算法(P-002)的前置条件。
//
//  注:本文件仅覆盖洼地条件(GPB-010)。平面流场的一致性(GPB-011)需额外
//  证明(见 separate P005_plane.dfy)。
//
// ===========================================================================

module D8Flow {

  // -------------------------------------------------------------------------
  // 流向类型定义 (8方向 + NoFlow)
  // -------------------------------------------------------------------------
  datatype Direction = 
    | E    // 东
    | SE   // 东南
    | S    // 南
    | SW   // 西南
    | W    // 西
    | NW   // 西北
    | N    // 北
    | NE   // 东北
    | NoFlow  // 无流向(洼地)

  // -------------------------------------------------------------------------
  // 3x3 窗口约定(行偏移 q 向下为正，符合栅格惯例)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // 注意:中心元 e 参与流向决策(与 Horn 坡度不同)
  // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
  // D8 最陡下降法核心逻辑
  // -------------------------------------------------------------------------
  function D8Flow(
    a: real, b: real, c: real,  // 上排
    d: real, e: real, f: real,  // 中排
    g: real, h: real, i: real   // 下排
  ): Direction
  {
    // 初始化:无流向，优先级为0
    var candidate := NoFlow;
    var max_priority := 0.0;

    // 检查东(E)方向: f(1,0)
    if e > f {
      var priority := (e - f) * (e - f) / 1.0;  // 距离平方=1
      if priority > max_priority {
        candidate := E;
        max_priority := priority;
      }
    }
    
    // 检查东南(SE)方向: i(1,1)
    if e > i {
      var priority := (e - i) * (e - i) / 2.0;  // 距离平方=2
      if priority > max_priority {
        candidate := SE;
        max_priority := priority;
      }
    }
    
    // 检查南(S)方向: h(0,1)
    if e > h {
      var priority := (e - h) * (e - h) / 1.0;
      if priority > max_priority {
        candidate := S;
        max_priority := priority;
      }
    }
    
    // 检查西南(SW)方向: g(-1,1)
    if e > g {
      var priority := (e - g) * (e - g) / 2.0;
      if priority > max_priority {
        candidate := SW;
        max_priority := priority;
      }
    }
    
    // 检查西(W)方向: d(-1,0)
    if e > d {
      var priority := (e - d) * (e - d) / 1.0;
      if priority > max_priority {
        candidate := W;
        max_priority := priority;
      }
    }
    
    // 检查西北(NW)方向: a(-1,-1)
    if e > a {
      var priority := (e - a) * (e - a) / 2.0;
      if priority > max_priority {
        candidate := NW;
        max_priority := priority;
      }
    }
    
    // 检查北(N)方向: b(0,-1)
    if e > b {
      var priority := (e - b) * (e - b) / 1.0;
      if priority > max_priority {
        candidate := N;
        max_priority := priority;
      }
    }
    
    // 检查东北(NE)方向: c(1,-1)
    if e > c {
      var priority := (e - c) * (e - c) / 2.0;
      if priority > max_priority {
        candidate := NE;
        max_priority := priority;
      }
    }
    
    candidate  // 返回最终流向
  }

  // ========================================================================
  // 洼地条件定理:若无严格下坡邻居，则流向必为 NoFlow
  // ========================================================================
  lemma PitCondition(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real
  )
    // 前置条件:所有邻居高程 ≥ 中心高程 (无严格下坡)
    requires a >= e && b >= e && c >= e
    requires d >= e && f >= e
    requires g >= e && h >= e && i >= e
    
    // 结论:流向必为 NoFlow
    ensures D8Flow(a, b, c, d, e, f, g, h, i) == NoFlow
  {
    // 由前置条件直接推导:所有方向 e > neighbor 均不成立
    // Dafny 自动验证所有分支条件失败，candidate 保持 NoFlow
  }
}

method Main() {
  print "GeoProofBench P-005 — D8 洼地条件 (GPB-010)\n";
  print "编译期验证: dafny verify P005_d8.dfy\n";
}
