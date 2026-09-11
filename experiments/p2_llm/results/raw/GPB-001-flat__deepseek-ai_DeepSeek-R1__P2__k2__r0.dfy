function SlopeSq(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
  requires w > 0.0
{
  var dx_numerator := c + 2.0*f + i - a - 2.0*d - g;
  var dy_numerator := g + 2.0*h + i - a - 2.0*b - c;
  var dx := dx_numerator / (8.0 * w);
  var dy := dy_numerator / (8.0 * w);
  dx*dx + dy*dy
}

lemma ZeroSlopeWhenUniform(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real)
  requires w > 0.0
  requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
  ensures SlopeSq(a,b,c,d,e,f,g,h,i,w) == 0.0
{
  // Uniform elevation makes all numerator terms cancel
  assert dx_numerator := c + 2.0*f + i - a - 2.0*d - g == 0.0 by {
    assert a == b == c == d == e == f == g == h == i;
    calc {
      c + 2.0*f + i - a - 2.0*d - g;
      == { assert c == a; assert f == a; assert i == a; assert d == a; assert g == a; }
      a + 2.0*a + a - a - 2.0*a - a;
      == 
      0.0;
    }
  }
  assert dy_numerator := g + 2.0*h + i - a - 2.0*b - c == 0.0 by {
    assert a == b == c == d == e == f == g == h == i;
    calc {
      g + 2.0*h + i - a - 2.0*b - c;
      == { assert g == a; assert h == a; assert i == a; assert b == a; assert c == a; }
      a + 2.0*a + a - a - 2.0*a - a;
      == 
      0.0;
    }
  }
  // With zero numerators, slope components are zero
  assert dx == 0.0 && dy == 0.0;
}
