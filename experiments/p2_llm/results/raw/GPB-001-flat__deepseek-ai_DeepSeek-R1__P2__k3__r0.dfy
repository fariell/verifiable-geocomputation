function HornSlopeSq(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
  requires w > 0.0
{
  var dx := ((c + 2.0*f + i) - (a + 2.0*d + g)) / (8.0 * w);
  var dy := ((g + 2.0*h + i) - (a + 2.0*b + c)) / (8.0 * w);
  dx*dx + dy*dy
}

lemma Theorem(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real)
  requires w > 0.0
  requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
  ensures HornSlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
{
  // All values are equal to a
  assert (c + 2.0*f + i) == a + 2.0*a + a by {}
  assert (a + 2.0*d + g) == a + 2.0*a + a by {}
  assert ((c + 2.0*f + i) - (a + 2.0*d + g)) == 0.0 by {}

  assert (g + 2.0*h + i) == a + 2.0*a + a by {}
  assert (a + 2.0*b + c) == a + 2.0*a + a by {}
  assert ((g + 2.0*h + i) - (a + 2.0*b + c)) == 0.0 by {}

  // Both dx and dy numerators are zero
  assert HornSlopeSq(a, b, c, d, e, f, g, h, i, w) == (0.0/(8.0*w))*(0.0/(8.0*w)) + (0.0/(8.0*w))*(0.0/(8.0*w)) by {}
  assert HornSlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0 by {}
}
