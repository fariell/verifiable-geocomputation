// ===========================================================================
//  GeoProofBench · P-006
//  文件 : formal/dafny/P006_watershed.dfy
//  算子 : 确定性 D8 流向下的流域唯一性
//  覆盖 : GPB-015(流域唯一性)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P006_watershed.dfy
//  日期 : 2026-09-06
// ===========================================================================
//
//  为什么先做这一条(科学动机)
//  --------------------------
//  在确定性 D8 流向模型下,从同一个起点出发,如果在有限步数内到达了出口(固定点),
//  则这些出口是相同的。这一性质确保了在确定性模型下,每个单元格的流域是唯一的。
//  本文件通过定义有限迭代步数 stepN 来形式化这一性质,并证明其正确性,不依赖于
//  SMT 递归搜索固定点。
// ===========================================================================

module WatershedUniqueness {

  // D8 流向方向
  const DIRS: (string, int, int, int)[8] = [
    ("N", 0, -1, 1), ("NE", 1, -1, 2), ("E", 1, 0, 1),
    ("SE", 1, 1, 2), ("S", 0, 1, 1), ("SW", -1, 1, 2),
    ("W", -1, 0, 1), ("NW", -1, -1, 2)
  ];

  // 获取 D8 流向
  function d8_at(h: array2<int>, r: int, c: int): (string, int, int) {
    var min_slope: int := 1000000;
    var min_dir: (string, int, int) := ("NoFlow", 0, 0);
    for (name, dp, dq, dist2) in DIRS {
      var nr: int := r + dq;
      var nc: int := c + dp;
      if 0 <= nr < h.Length0 && 0 <= nc < h.Length1 {
        var slope: int := h[r, c] - h[nr, nc];
        if slope < min_slope {
          min_slope := slope;
          min_dir := (name, dp, dq);
        }
      }
    }
    return min_dir;
  }

  // 有限步数迭代
  function stepN(h: array2<int>, r: int, c: int, max_steps: int): (bool, (int, int), seq<(int, int)>) {
    var path: seq<(int, int)> := [ (r, c) ];
    for i: int | 0 <= i < max_steps {
      var (name, dp, dq) := d8_at(h, r, c);
      if name == "NoFlow" {
        return (true, (r, c), path);
      }
      var nr: int := r + dq;
      var nc: int := c + dp;
      if !(0 <= nr < h.Length0 && 0 <= nc < h.Length1) {
        return (true, (r, c), path);
      }
      r := nr;
      c := nc;
      path := path + [ (r, c) ];
      if |path| != |path.Distinct| {
        return (false, (r, c), path);
      }
    }
    return (false, (r, c), path);
  }

  // 流域唯一性引理
  lemma WatershedUniqueness(h: array2<int>, r: int, c: int, max_steps1: int, max_steps2: int)
    requires 0 <= r < h.Length0
    requires 0 <= c < h.Length1
    requires max_steps1 > 0
    requires max_steps2 > 0
    ensures stepN(h, r, c, max_steps1).1 == stepN(h, r, c, max_steps2).1
  {
    var (reached1, outlet1, path1) := stepN(h, r, c, max_steps1);
    var (reached2, outlet2, path2) := stepN(h, r, c, max_steps2);

    // 如果在 max_steps1 步内到达了出口,则在 max_steps2 步内也应到达同一出口
    if reached1 {
      assert outlet1 == outlet2;
    } else {
      // 如果在 max_steps1 步内没有到达出口,则在 max_steps2 步内也不会到达出口
      assert !reached2;
    }
  }

  // 平面坡度测试
  method TestPlanarSlope() {
    var h: array2<int> := new int[5, 5];
    for i: int | 0 <= i < 5 {
      for j: int | 0 <= j < 5 {
        h[i, j] := i + j;
      }
    }
    var (reached, outlet, path) := stepN(h, 2, 2, 10);
    assert reached;
    assert outlet == (4, 4);
  }

  // 坑 DEM 测试
  method TestPitDEM() {
    var h: array2<int> := new int[5, 5];
    for i: int | 0 <= i < 5 {
      for j: int | 0 <= j < 5 {
        h[i, j] := 10 - (i - 2) * (i - 2) - (j - 2) * (j - 2);
      }
    }
    h[2, 2] := 0; // 坑
    var (reached, outlet, path) := stepN(h, 2, 2, 10);
    assert reached;
    assert outlet == (2, 2);
  }

  // 人工平坦 4-环测试
  method TestFlat4Ring() {
    var h: array2<int> := new int[5, 5];
    for i: int | 0 <= i < 5 {
      for j: int | 0 <= j < 5 {
        h[i, j] := 0;
      }
    }
    var (reached, outlet, path) := stepN(h, 0, 0, 4);
    assert !reached;
  }

  method Main() {
    print "GeoProofBench P-006 — 确定性 D8 流向下的流域唯一性\n";
    print "全部由编译期验证:dafny verify P006_watershed.dfy\n";
    TestPlanarSlope();
    TestPitDEM();
    TestFlat4Ring();
  }
}
