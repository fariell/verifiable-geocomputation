# VERIFIED_NEEDS_HUMAN dossier (auto; PI decides ALIGNED vs DRIFT)
## Gold proposition (GPB-001-flat)
On any 3x3 elevation window with finite values, if all nine cells share the same
elevation, the Horn (1981) slope magnitude (equivalently its square SlopeSq) is
identically zero. Grid spacing w must be positive.
expected_verdict: PASS
gold_formal: formal/dafny/P001_horn_slope.dfy

What PI should check: does the proved lemma state 'flat 3x3 => SlopeSq==0' (or equiv), or a weaker/stronger/different claim?

## Cell ('deepseek-ai/DeepSeek-R1', 'GPB-001-flat', 'P1', 1)
- status=GENERATED compile_rc=0 verify_rc=0 semantic=VERIFIED_NEEDS_HUMAN
- dfy: `GPB-001-flat__deepseek-ai_DeepSeek-R1__P1__k1__r0.dfy`
- auto: name_overlap=['SlopeSq'] keyword_hits={'keywords': ['cells', 'elevation', 'equivalently', 'finite', 'grid', 'horn', 'identically', 'magnitude', 'nine', 'positive', 'share', 'slope', 'slopesq', 'spacing', 'square', 'values', 'window', 'zero'], 'hit': ['horn', 'slope', 'slopesq', 'zero'], 'miss': ['cells', 'elevation', 'equivalently', 'finite', 'grid', 'identically', 'magnitude', 'nine', 'positive', 'share', 'spacing', 'square', 'values', 'window'], 'hit_ratio': 0.2222} trivial_assume=False drift_suspect=False
- n_gen_names=2 n_gold_names=12
- defs: ['SlopeSq', 'FlatTerrainZeroSlope', 'Main']
```dafny
// ===========================================================================
//  GeoProofBench · Horn Slope Consistency
//  算子 : Horn (1981) 3x3 坡度算子
//  定理 : 平坦地形上坡度平方恒为零
//  环境 : Dafny 4.11
// ===========================================================================

module HornSlope {
  // ------------------------------------------------------------------
  // 3x3 窗口约定
  //
  //     a(-1,-1)   b( 0,-1)   c( 1,-1)
  //     d(-1, 0)     e        f( 1, 0)
  //     g(-1, 1)   h( 0, 1)   i( 1, 1)
  //
  // Horn (1981) 坡度分量定义:
  //   ∂z/∂x = [ (c + 2f + i) - (a + 2d + g) ] / (8w)
  //   ∂z/∂y = [ (g + 2h + i) - (a + 2b + c) ] / (8w)
  // ------------------------------------------------------------------

  // 坡度平方算子 (Horn, 1981)
  function SlopeSq(a: real, b: real, c: real, d: real, e: real,
                   f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    var dzdx := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w);
    var dzdy := ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w);
    dzdx*dzdx + dzdy*dzdy
  }

  // ==================================================================
  // 主定理: 平坦地形上坡度平方为零
  // ==================================================================
  lemma FlatTerrainZeroSlope(a: real, b: real, c: real, d: real, e: real,
                             f: real, g: real, h: real, i: real, w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && 
             e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 展开坡度分量计算
    var num_x := (c + 2.0*f + i) - (a + 2.0*d + g);
    var num_y := (g + 2.0*h + i) - (a + 2.0*b + c);

    // 平坦地形时分子为零 (所有高程相等)
    assert num_x == 0.0 by {
      calc {
        (c + 2.0*f + i) - (a + 2.0*d + g);
        == { }  // 代入相等条件
        (a + 2.0*a + a) - (a + 2.0*a + a);
        == { }
        4.0*a - 4.0*a;
        == { }
        0.0;
      }
    }
    assert num_y == 0.0 by {
      calc {
        (g + 2.0*h + i) - (a + 2.0*b + c);
        == { }  // 代入相等条件
```

## Cell ('deepseek-ai/DeepSeek-R1', 'GPB-001-flat', 'P1', 2)
- status=GENERATED compile_rc=0 verify_rc=0 semantic=VERIFIED_NEEDS_HUMAN
- dfy: `GPB-001-flat__deepseek-ai_DeepSeek-R1__P1__k2__r0.dfy`
- auto: name_overlap=['SlopeSq'] keyword_hits={'keywords': ['cells', 'elevation', 'equivalently', 'finite', 'grid', 'horn', 'identically', 'magnitude', 'nine', 'positive', 'share', 'slope', 'slopesq', 'spacing', 'square', 'values', 'window', 'zero'], 'hit': ['horn', 'magnitude', 'slope', 'slopesq', 'window', 'zero'], 'miss': ['cells', 'elevation', 'equivalently', 'finite', 'grid', 'identically', 'nine', 'positive', 'share', 'spacing', 'square', 'values'], 'hit_ratio': 0.3333} trivial_assume=False drift_suspect=False
- n_gen_names=4 n_gold_names=12
- defs: ['HornDx', 'HornDy', 'SlopeSq', 'ZeroSlopeOnFlatTerrain', 'Main']
```dafny
// ===========================================================================
//  GeoProofBench · Horn Slope on Flat Window
//  算子 : Horn (1981) slope magnitude
//  命题 : 在任意 3x3 窗口内，若所有高程值相等，则 Horn 坡度幅值为零。
//  环境 : Dafny 4.11
// ===========================================================================

module HornSlope {

  // Horn (1981) 有限差分坡度算子
  function HornDx(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (c + 2.0*f + i) - (a + 2.0*d + g) ) / (8.0 * w)
  }

  function HornDy(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    ( (g + 2.0*h + i) - (a + 2.0*b + c) ) / (8.0 * w)
  }

  function SlopeSq(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    var dx := HornDx(a, b, c, d, e, f, g, h, i, w);
    var dy := HornDy(a, b, c, d, e, f, g, h, i, w);
    dx*dx + dy*dy
  }

  // 核心定理: 当所有高程相等时，坡度平方恒为零
  lemma ZeroSlopeOnFlatTerrain(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures SlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
  {
    // 计算梯度分量
    var dx := HornDx(a, b, c, d, e, f, g, h, i, w);
    var dy := HornDy(a, b, c, d, e, f, g, h, i, w);
    
    // 展开分子项证明为零
    assert (c + 2.0*f + i) == a + 2.0*a + a;  // 4a
    assert (a + 2.0*d + g) == a + 2.0*a + a;  // 4a
    assert dx == 0.0 / (8.0 * w);
    
    assert (g + 2.0*h + i) == a + 2.0*a + a;  // 4a
    assert (a + 2.0*b + c) == a + 2.0*a + a;  // 4a
    assert dy == 0.0 / (8.0 * w);
    
    // 零的平方和为零
    assert dx*dx == 0.0;
    assert dy*dy == 0.0;
  }

  method Main() {
    print "GeoProofBench: Horn slope is zero on flat terrain (verified)\n";
  }
}
```

## Cell ('deepseek-ai/DeepSeek-R1', 'GPB-001-flat', 'P2', 0)
- status=GENERATED compile_rc=0 verify_rc=0 semantic=VERIFIED_NEEDS_HUMAN
- dfy: `GPB-001-flat__deepseek-ai_DeepSeek-R1__P2__k0__r0.dfy`
- auto: name_overlap=[] keyword_hits={'keywords': ['cells', 'elevation', 'equivalently', 'finite', 'grid', 'horn', 'identically', 'magnitude', 'nine', 'positive', 'share', 'slope', 'slopesq', 'spacing', 'square', 'values', 'window', 'zero'], 'hit': ['grid', 'horn', 'slope', 'slopesq'], 'miss': ['cells', 'elevation', 'equivalently', 'finite', 'identically', 'magnitude', 'nine', 'positive', 'share', 'spacing', 'square', 'values', 'window', 'zero'], 'hit_ratio': 0.2222} trivial_assume=False drift_suspect=False
- n_gen_names=2 n_gold_names=12
- defs: ['HornSlopeSq', 'Theorem']
```dafny
function HornSlopeSq(grid: (int,int) -> real, w: real): real
  requires w > 0.0
{
  var a := grid(0,0);
  var b := grid(0,1);
  var c := grid(0,2);
  var d := grid(1,0);
  var f := grid(1,2);
  var g := grid(2,0);
  var h := grid(2,1);
  var i_val := grid(2,2);

  var dx_num := (c + 2.0*f + i_val) - (a + 2.0*d + g);
  var dy_num := (g + 2.0*h + i_val) - (a + 2.0*b + c);

  var dx := dx_num / (8.0 * w);
  var dy := dy_num / (8.0 * w);

  dx*dx + dy*dy
}

lemma Theorem(grid: (int,int) -> real, w: real)
  requires w > 0.0
  requires forall i,j :: 0 <= i < 3 && 0 <= j < 3 ==> grid(i,j) == grid(0,0)
  ensures HornSlopeSq(grid, w) == 0.0
{
  var v := grid(0,0);
  var dx_num := (grid(0,2) + 2.0*grid(1,2) + grid(2,2)) - (grid(0,0) + 2.0*grid(1,0) + grid(2,0));
  var dy_num := (grid(2,0) + 2.0*grid(2,1) + grid(2,2)) - (grid(0,0) + 2.0*grid(0,1) + grid(0,2));

  assert dx_num == (v + 2.0*v + v) - (v + 2.0*v + v) == 0.0;
  assert dy_num == (v + 2.0*v + v) - (v + 2.0*v + v) == 0.0;

  var dx := dx_num / (8.0 * w);
  var dy := dy_num / (8.0 * w);
  assert dx*dx + dy*dy == 0.0;
}
```

## Cell ('deepseek-ai/DeepSeek-R1', 'GPB-001-flat', 'P2', 1)
- status=GENERATED compile_rc=0 verify_rc=0 semantic=VERIFIED_NEEDS_HUMAN
- dfy: `GPB-001-flat__deepseek-ai_DeepSeek-R1__P2__k1__r0.dfy`
- auto: name_overlap=[] keyword_hits={'keywords': ['cells', 'elevation', 'equivalently', 'finite', 'grid', 'horn', 'identically', 'magnitude', 'nine', 'positive', 'share', 'slope', 'slopesq', 'spacing', 'square', 'values', 'window', 'zero'], 'hit': ['horn', 'slope', 'slopesq', 'values', 'zero'], 'miss': ['cells', 'elevation', 'equivalently', 'finite', 'grid', 'identically', 'magnitude', 'nine', 'positive', 'share', 'spacing', 'square', 'window'], 'hit_ratio': 0.2778} trivial_assume=False drift_suspect=False
- n_gen_names=2 n_gold_names=12
- defs: ['HornSlopeSq', 'LemmaAllEqualImpliesZeroSlope']
```dafny
function HornSlopeSq(a00: real, a01: real, a02: real,
                     a10: real, a11: real, a12: real,
                     a20: real, a21: real, a22: real, w: real): real
  requires w > 0.0
{
  var dzdx_numerator := a02 + 2.0*a12 + a22 - a00 - 2.0*a10 - a20;
  var dzdy_numerator := a20 + 2.0*a21 + a22 - a00 - 2.0*a01 - a02;
  var dzdx := dzdx_numerator / (8.0 * w);
  var dzdy := dzdy_numerator / (8.0 * w);
  dzdx * dzdx + dzdy * dzdy
}

lemma LemmaAllEqualImpliesZeroSlope(a00: real, a01: real, a02: real,
                                   a10: real, a11: real, a12: real,
                                   a20: real, a21: real, a22: real, w: real)
  requires w > 0.0
  requires a00 == a01 && a01 == a02 && a02 == a10 && a10 == a11 && a11 == a12 && a12 == a20 && a20 == a21 && a21 == a22
  ensures HornSlopeSq(a00, a01, a02, a10, a11, a12, a20, a21, a22, w) == 0.0
{
  // When all values are equal (let k = a00), both numerators become:
  // dzdx_numerator = k + 2k + k - k - 2k - k = (1+2+1-1-2-1)k = 0
  // dzdy_numerator = k + 2k + k - k - 2k - k = 0
  // Thus dzdx = 0, dzdy = 0, and SlopeSq = 0
}
```
