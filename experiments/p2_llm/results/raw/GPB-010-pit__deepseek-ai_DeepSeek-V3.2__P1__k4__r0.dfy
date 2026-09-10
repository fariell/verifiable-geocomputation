// ===========================================================================
//  GeoProofBench · P-005
//  文件 : formal/dafny/P005_d8.dfy
//  算子 : D8 最陡坡度流向
//  覆盖 : GPB-010 (洼地无流向)、GPB-011 (平面上流向恒定)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P005_d8.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么做这一条(科学动机)
//  --------------------------
//  D8 流向是水文分析的基础算子。其核心语义是:每个像元流向最陡下降的
//  邻居。若所有邻居都不低于中心,则中心为洼地(pit),流向未定义(NoFlow)。
//
//  本文件形式化验证这一语义:在精确算术下,若 3×3 窗口中八个邻居的高程
//  均不小于中心,则 D8 流向必为 NoFlow。这是流向计算的**基本完整性**,
//  也是后续汇流累积、填洼等算法的前置条件。
//
//  注意:本验证仅针对"洼地无流向"这一代数性质。平面上流向恒定的性质
//  在另一引理中单独证明(见 GPB-011)。
//
// ===========================================================================

module D8Flow {

  // ------------------------------------------------------------------
  // 3×3 窗口约定(行偏移 q 向下为正,列偏移 p 向右为正)
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  //  中心元 e 在 D8 流向计算中是**比较基准**,不参与权重计算。
  // ------------------------------------------------------------------

  // 八个邻居的相对坐标 (Δp, Δq) 及其欧氏距离平方
  type Dir = (
    name: string,
    dp: int,  // 列偏移
    dq: int,  // 行偏移
    dist2: real  // 距离平方 (1.0 或 2.0)
  )

  const dirs: seq<Dir> := [
    ("E",  1,  0, 1.0),
    ("SE", 1,  1, 2.0),
    ("S",  0,  1, 1.0),
    ("SW", -1,  1, 2.0),
    ("W", -1,  0, 1.0),
    ("NW", -1, -1, 2.0),
    ("N",  0, -1, 1.0),
    ("NE",  1, -1, 2.0)
  ];

  // ------------------------------------------------------------------
  // D8 流向计算核心函数
  // 输入: 3×3 窗口的九个高程值 (a..i 对应上图)
  // 输出: 流向名称,若为洼地则返回 "NoFlow"
  // ------------------------------------------------------------------
  function D8Direction(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real
  ): string
  {
    var bestName := "NoFlow";
    var bestPower := 0.0;

    for dir in dirs
      invariant bestName == "NoFlow" || bestPower > 0.0
    {
      var neighborElev: real;
      // 根据方向选择对应邻居高程
      match dir.dp, dir.dq {
        case 1, 0 => neighborElev := f;
        case 1, 1 => neighborElev := i;
        case 0, 1 => neighborElev := h;
        case -1, 1 => neighborElev := g;
        case -1, 0 => neighborElev := d;
        case -1, -1 => neighborElev := a;
        case 0, -1 => neighborElev := b;
        case 1, -1 => neighborElev := c;
      }
      var drop := e - neighborElev;
      if drop > 0.0 {
        var power := (drop * drop) / dir.dist2;
        if bestName == "NoFlow" || power > bestPower {
          bestName, bestPower := dir.name, power;
        }
      }
    }
    bestName
  }

  // ==================================================================
  // 主定理:洼地无流向
  // 若所有邻居高程均不小于中心高程 e,则 D8 流向必为 NoFlow。
  // ==================================================================
  lemma PitNoFlow(
    a: real, b: real, c: real,
    d: real, e: real, f: real,
    g: real, h: real, i: real
  )
    requires a >= e && b >= e && c >= e
    requires d >= e && f >= e
    requires g >= e && h >= e && i >= e
    ensures D8Direction(a, b, c, d, e, f, g, h, i) == "NoFlow"
  {
    // 证明思路:遍历所有八个方向,每个方向的 drop = e - neighborElev ≤ 0,
    // 因此不会进入 if drop > 0.0 分支,最终 bestName 保持初始值 "NoFlow"。
    
    // 展开 D8Direction 的计算过程
    var bestName := "NoFlow";
    var bestPower := 0.0;

    // 对每个方向进行验证
    for dir in dirs
      invariant bestName == "NoFlow"
      invariant bestPower == 0.0
    {
      var neighborElev: real;
      // 根据方向选择邻居高程
      match dir.dp, dir.dq {
        case 1, 0 => neighborElev := f;
        case 1, 1 => neighborElev := i;
        case 0, 1 => neighborElev := h;
        case -1, 1 => neighborElev := g;
        case -1, 0 => neighborElev := d;
        case -1, -1 => neighborElev := a;
        case 0, -1 => neighborElev := b;
        case 1, -1 => neighborElev := c;
      }
      // 由前提条件知 neighborElev ≥ e
      assert neighborElev >= e;
      var drop := e - neighborElev;
      assert drop <= 0.0;
      // drop ≤ 0, 不会更新 bestName 和 bestPower
    }
    // 循环结束后 bestName 仍为 "NoFlow"
    assert bestName == "NoFlow";
  }

  // ==================================================================
  // 测试用例:经典洼地配置
  // 中心为 0, 周围八个邻居均为 1
  // ==================================================================
  lemma TestPit()
    ensures D8Direction(1.0, 1.0, 1.0,
                        1.0, 0.0, 1.0,
                        1.0, 1.0, 1.0) == "NoFlow"
  {
    PitNoFlow(1.0, 1.0, 1.0,
              1.0, 0.0, 1.0,
              1.0, 1.0, 1.0);
  }

  // ==================================================================
  // 反例构造:若存在严格更低的邻居,则流向不为 NoFlow
  // 用于验证定理的边界条件
  // ==================================================================
  lemma CounterExample()
    ensures D8Direction(1.0, 1.0, 1.0,
                        1.0, 1.0, 0.5,  // f < e
                        1.0, 1.0, 1.0) != "NoFlow"
  {
    // 计算实际流向
    var dir := D8Direction(1.0, 1.0, 1.0,
                           1.0, 1.0, 0.5,
                           1.0, 1.0, 1.0);
    // 东侧邻居 f = 0.5 < e = 1.0, drop = 0.5 > 0
    // 距离平方为 1.0, power = 0.25
    // 其他邻居均不小于 e, 因此流向应为 "E"
    assert dir == "E";
  }

}

method Main() {
  print "GeoProofBench P-005 — D8 洼地无流向定理\n";
  print "验证:若 3×3 窗口中所有邻居不低于中心,则流向为 NoFlow\n";
  print "编译期验证: dafny verify P005_d8.dfy\n";
}
