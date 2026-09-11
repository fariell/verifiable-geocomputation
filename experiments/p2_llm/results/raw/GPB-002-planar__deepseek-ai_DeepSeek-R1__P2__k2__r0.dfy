lemma Theorem(A: real, B: real, C: real, w: real, x0: real, y0: real, i: int, j: int)
  requires w > 0.0
{
  // Grid coordinates for point (i,j)
  var x := x0 + i * w;
  var y := y0 + j * w;

  // Linear surface function
  function z(xx: real, yy: real): real
  {
    A * xx + B * yy + C
  }

  // Compute neighboring values
  var z_right := z(x + w, y);
  var z_left := z(x - w, y);
  var z_top := z(x, y + w);
  var z_bottom := z(x, y - w);

  // Horn central difference approximations
  var DzDx := (z_right - z_left) / (2.0 * w);
  var DzDy := (z_top - z_bottom) / (2.0 * w);

  // Verify exact recovery of A and B
  assert DzDx == A by {
    calc {
      DzDx;
      == (z(x + w, y) - z(x - w, y)) / (2.0 * w);
      == ((A*(x + w) + B*y + C) - (A*(x - w) + B*y + C)) / (2.0 * w);
      == (A*x + A*w + B*y + C - A*x + A*w - B*y - C) / (2.0 * w);
      == (2.0 * A * w) / (2.0 * w);
      == A;
    }
  }
  assert DzDy == B by {
    calc {
      DzDy;
      == (z(x, y + w) - z(x, y - w)) / (2.0 * w);
      == ((A*x + B*(y + w) + C) - (A*x + B*(y - w) + C)) / (2.0 * w);
      == (A*x + B*y + B*w + C - A*x - B*y + B*w - C) / (2.0 * w);
      == (2.0 * B * w) / (2.0 * w);
      == B;
    }
  }
}
