module HornSlope {
  // Horn (1981) finite-difference slope operators
  // DzDx = (f - d) / (2w)  (centered difference in x)
  // DzDy = (h - b) / (2w)  (centered difference in y)
  
  method DzDx(d: real, f: real, w: real) returns (slope_x: real)
    requires w > 0.0
    ensures slope_x == (f - d) / (2.0 * w)
  {
    return (f - d) / (2.0 * w);
  }
  
  method DzDy(b: real, h: real, w: real) returns (slope_y: real)
    requires w > 0.0
    ensures slope_y == (h - b) / (2.0 * w)
  {
    return (h - b) / (2.0 * w);
  }
  
  // Planar surface z = A*x + B*y + C
  // Sampled at grid points with spacing w
  function Q(A: real, B: real, C: real, x: real, y: real) : real
    ensures Q(A, B, C, x, y) == A * x + B * y + C
  {
    return A * x + B * y + C;
  }
  
  // Grid points for Horn's 3x3 stencil
  // Centered at (0,0) with spacing w
  function Qd(A: real, B: real, C: real, w: real) : real
    ensures Qd(A, B, C, w) == Q(A, B, C, -w, 0.0)
  {
    return A * (-w) + B * 0.0 + C;
  }
  
  function Qf(A: real, B: real, C: real, w: real) : real
    ensures Qf(A, B, C, w) == Q(A, B, C, w, 0.0)
  {
    return A * w + B * 0.0 + C;
  }
  
  function Qb(A: real, B: real, C: real, w: real) : real
    ensures Qb(A, B, C, w) == Q(A, B, C, 0.0, -w)
  {
    return A * 0.0 + B * (-w) + C;
  }
  
  function Qh(A: real, B: real, C: real, w: real) : real
    ensures Qh(A, B, C, w) == Q(A, B, C, 0.0, w)
  {
    return A * 0.0 + B * w + C;
  }
  
  // Theorem: Horn's finite-difference operators recover A and B exactly on planes
  lemma PlanarExact(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures DzDx(Qd(A, B, C, w), Qf(A, B, C, w), w) == A
    ensures DzDy(Qb(A, B, C, w), Qh(A, B, C, w), w) == B
  {
    // Compute DzDx
    var slope_x := DzDx(Qd(A, B, C, w), Qf(A, B, C, w), w);
    assert slope_x == (Qf(A, B, C, w) - Qd(A, B, C, w)) / (2.0 * w);
    assert Qf(A, B, C, w) - Qd(A, B, C, w) == (A * w + B * 0.0 + C) - (A * (-w) + B * 0.0 + C);
    assert Qf(A, B, C, w) - Qd(A, B, C, w) == 2.0 * A * w;
    assert slope_x == (2.0 * A * w) / (2.0 * w);
    assert slope_x == A;
    
    // Compute DzDy
    var slope_y := DzDy(Qb(A, B, C, w), Qh(A, B, C, w), w);
    assert slope_y == (Qh(A, B, C, w) - Qb(A, B, C, w)) / (2.0 * w);
    assert Qh(A, B, C, w) - Qb(A, B, C, w) == (A * 0.0 + B * w + C) - (A * 0.0 + B * (-w) + C);
    assert Qh(A, B, C, w) - Qb(A, B, C, w) == 2.0 * B * w;
    assert slope_y == (2.0 * B * w) / (2.0 * w);
    assert slope_y == B;
  }
}

method Main() {
  print "GeoProofBench GPB-019 — Horn slope exactness on planes\n";
  print "全部由编译期验证:dafny verify HornSlope.dfy\n";
}
