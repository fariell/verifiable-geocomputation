datatype Matrix33 = Matrix33(
  z00: real, z01: real, z02: real,
  z10: real, z11: real, z12: real,
  z20: real, z21: real, z22: real
)

function HornSlopeSq(m: Matrix33, w: real): real
  requires w > 0.0
{
  var dzdx := (m.z02 + 2.0*m.z12 + m.z22 - m.z00 - 2.0*m.z10 - m.z20) / (8.0 * w);
  var dzdy := (m.z00 + 2.0*m.z01 + m.z02 - m.z20 - 2.0*m.z21 - m.z22) / (8.0 * w);
  dzdx*dzdx + dzdy*dzdy
}

lemma AllEqualImpliesZeroSlope(m: Matrix33, w: real)
  requires w > 0.0
  requires m.z00 == m.z01 && m.z00 == m.z02 &&
           m.z00 == m.z10 && m.z00 == m.z11 && m.z00 == m.z12 &&
           m.z00 == m.z20 && m.z00 == m.z21 && m.z00 == m.z22
  ensures HornSlopeSq(m, w) == 0.0
{
  var c := m.z00;
  assert dzdx_expression: (m.z02 + 2.0*m.z12 + m.z22 - m.z00 - 2.0*m.z10 - m.z20) 
    == (c + 2.0*c + c - c - 2.0*c - c) by {
      assert m.z02 == c; assert m.z12 == c; assert m.z22 == c;
      assert m.z00 == c; assert m.z10 == c; assert m.z20 == c;
    }
  assert dzdx_zero: (c + 2.0*c + c - c - 2.0*c - c) == 0.0;
  
  assert dzdy_expression: (m.z00 + 2.0*m.z01 + m.z02 - m.z20 - 2.0*m.z21 - m.z22) 
    == (c + 2.0*c + c - c - 2.0*c - c) by {
      assert m.z00 == c; assert m.z01 == c; assert m.z02 == c;
      assert m.z20 == c; assert m.z21 == c; assert m.z22 == c;
    }
  assert dzdy_zero: (c + 2.0*c + c - c - 2.0*c - c) == 0.0;
}
