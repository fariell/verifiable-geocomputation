// Horn slope magnitude on constant elevation window
// Proof that Horn slope magnitude is zero when all elevations are equal

function method SlopeSq(z: array2<real>, w: real): real
  requires z.Length0 == 3 && z.Length1 == 3
  requires w > 0.0
{
  // Horn (1981) finite-difference slope components
  var dzdx := (z[2,0] + 2*z[2,1] + z[2,2] - z[0,0] - 2*z[0,1] - z[0,2]) / (8.0 * w);
  var dzdy := (z[0,2] + 2*z[1,2] + z[2,2] - z[0,0] - 2*z[1,0] - z[2,0]) / (8.0 * w);
  dzdx*dzdx + dzdy*dzdy
}

lemma HornConstantWindow(z: array2<real>, w: real, c: real)
  requires z.Length0 == 3 && z.Length1 == 3
  requires w > 0.0
  requires forall i,j :: 0 <= i < 3 && 0 <= j < 3 ==> z[i,j] == c
  ensures SlopeSq(z, w) == 0.0
{
  // Numerator calculations for dzdx and dzdy
  var dx_num := z[2,0] + 2*z[2,1] + z[2,2] - z[0,0] - 2*z[0,1] - z[0,2];
  var dy_num := z[0,2] + 2*z[1,2] + z[2,2] - z[0,0] - 2*z[1,0] - z[2,0];

  // Substitute constant elevation value
  assert dx_num == c + 2*c + c - c - 2*c - c by {
    assert z[2,0] == c && z[2,1] == c && z[2,2] == c;
    assert z[0,0] == c && z[0,1] == c && z[0,2] == c;
  }
  assert dy_num == c + 2*c + c - c - 2*c - c by {
    assert z[0,2] == c && z[1,2] == c && z[2,2] == c;
    assert z[0,0] == c && z[1,0] == c && z[2,0] == c;
  }

  // Simplify to zero
  assert dx_num == 0.0;
  assert dy_num == 0.0;

  // Final slope magnitude squared
  assert SlopeSq(z, w) == (0.0/(8.0*w))*(0.0/(8.0*w)) + (0.0/(8.0*w))*(0.0/(8.0*w));
}
