// Horn finite-difference slope operator exactness on a plane
// Formalization of: On a planar surface z = A*x + B*y + C sampled on a regular grid
// with spacing w>0, the Horn finite-difference estimates DzDx and DzDy recover A and B exactly.

module HornPlaneExact {
  // Grid coordinates are integer indices
  type idx = int

  // Real numbers for elevations and coefficients
  type real = real

  // A planar surface: z = A*x + B*y + C
  datatype Plane = Plane(A: real, B: real, C: real)

  // Function giving exact elevation at continuous (x,y)
  function elevation(p: Plane, x: real, y: real): real
    reads {}
  {
    p.A * x + p.B * y + p.C
  }

  // Horn (1981) finite-difference slope operator
  // Given a 3x3 grid of elevations centered at (i,j) with spacing w,
  // returns (dz/dx estimate, dz/dy estimate)
  function HornSlope(z00: real, z01: real, z02: real,
                     z10: real, z11: real, z12: real,
                     z20: real, z21: real, z22: real,
                     w: real): (real, real)
    requires w > 0.0
    reads {}
  {
    // Horn's convolution kernels for first derivatives
    // dz/dx ≈ ( (z20 + 2*z21 + z22) - (z00 + 2*z01 + z02) ) / (8*w)
    // dz/dy ≈ ( (z02 + 2*z12 + z22) - (z00 + 2*z10 + z20) ) / (8*w)
    var dzdx := ((z20 + 2.0*z21 + z22) - (z00 + 2.0*z01 + z02)) / (8.0 * w);
    var dzdy := ((z02 + 2.0*z12 + z22) - (z00 + 2.0*z10 + z20)) / (8.0 * w);
    (dzdx, dzdy)
  }

  // Lemma: Horn operator recovers exact slope on any plane
  lemma HornExactOnPlane(p: Plane, i: idx, j: idx, w: real)
    requires w > 0.0
    ensures forall ii, jj :: -1 <= ii <= 1 && -1 <= jj <= 1 ==>
      let x := (i + ii) as real * w in
      let y := (j + jj) as real * w in
      elevation(p, x, y) == p.A * x + p.B * y + p.C
    ensures
      // Build the 3x3 grid from the plane
      var z00 := elevation(p, (i-1) as real * w, (j-1) as real * w);
      var z01 := elevation(p, (i-1) as real * w,  j    as real * w);
      var z02 := elevation(p, (i-1) as real * w, (j+1) as real * w);
      var z10 := elevation(p,  i    as real * w, (j-1) as real * w);
      var z11 := elevation(p,  i    as real * w,  j    as real * w);
      var z12 := elevation(p,  i    as real * w, (j+1) as real * w);
      var z20 := elevation(p, (i+1) as real * w, (j-1) as real * w);
      var z21 := elevation(p, (i+1) as real * w,  j    as real * w);
      var z22 := elevation(p, (i+1) as real * w, (j+1) as real * w);
      var (dzdx, dzdy) := HornSlope(z00, z01, z02, z10, z11, z12, z20, z21, z22, w);
      dzdx == p.A && dzdy == p.B
  {
    // Expand all elevations in terms of p.A, p.B, p.C
    var x0 := (i-1) as real * w;
    var x1 :=  i    as real * w;
    var x2 := (i+1) as real * w;
    var y0 := (j-1) as real * w;
    var y1 :=  j    as real * w;
    var y2 := (j+1) as real * w;

    var z00 := p.A * x0 + p.B * y0 + p.C;
    var z01 := p.A * x0 + p.B * y1 + p.C;
    var z02 := p.A * x0 + p.B * y2 + p.C;
    var z10 := p.A * x1 + p.B * y0 + p.C;
    var z11 := p.A * x1 + p.B * y1 + p.C;
    var z12 := p.A * x1 + p.B * y2 + p.C;
    var z20 := p.A * x2 + p.B * y0 + p.C;
    var z21 := p.A * x2 + p.B * y1 + p.C;
    var z22 := p.A * x2 + p.B * y2 + p.C;

    // Compute Horn's dz/dx
    var num_dx := (z20 + 2.0*z21 + z22) - (z00 + 2.0*z01 + z02);
    // Substitute z** expressions
    calc == {
      num_dx;
      ==
      (p.A*x2 + p.B*y0 + p.C + 2.0*(p.A*x2 + p.B*y1 + p.C) + p.A*x2 + p.B*y2 + p.C)
      - (p.A*x0 + p.B*y0 + p.C + 2.0*(p.A*x0 + p.B*y1 + p.C) + p.A*x0 + p.B*y2 + p.C);
      ==
      // Collect terms: p.A*(x2 + 2*x2 + x2 - x0 - 2*x0 - x0) + p.B*(y0 + 2*y1 + y2 - y0 - 2*y1 - y2) + C*(1+2+1 -1-2-1)
      p.A * (4.0*x2 - 4.0*x0) + p.B * 0.0 + p.C * 0.0;
      ==
      p.A * 4.0 * (x2 - x0);
      ==
      p.A * 4.0 * ( ((i+1) as real * w) - ((i-1) as real * w) );
      ==
      p.A * 4.0 * (2.0 * w);
      ==
      p.A * 8.0 * w;
    }
    var dzdx := num_dx / (8.0 * w);
    assert dzdx == p.A by {
      calc == {
        dzdx;
        num_dx / (8.0 * w);
        ==
        (p.A * 8.0 * w) / (8.0 * w);
        ==
        p.A;
      }
    }

    // Compute Horn's dz/dy
    var num_dy := (z02 + 2.0*z12 + z22) - (z00 + 2.0*z10 + z20);
    calc == {
      num_dy;
      ==
      (p.A*x0 + p.B*y2 + p.C + 2.0*(p.A*x1 + p.B*y2 + p.C) + p.A*x2 + p.B*y2 + p.C)
      - (p.A*x0 + p.B*y0 + p.C + 2.0*(p.A*x1 + p.B*y0 + p.C) + p.A*x2 + p.B*y0 + p.C);
      ==
      // p.A terms cancel: x0 + 2*x1 + x2 - x0 - 2*x1 - x2 = 0
      // p.B terms: y2 + 2*y2 + y2 - y0 - 2*y0 - y0 = 4*y2 - 4*y0
      p.B * (4.0*y2 - 4.0*y0) + p.C * 0.0;
      ==
      p.B * 4.0 * (y2 - y0);
      ==
      p.B * 4.0 * ( ((j+1) as real * w) - ((j-1) as real * w) );
      ==
      p.B * 4.0 * (2.0 * w);
      ==
      p.B * 8.0 * w;
    }
    var dzdy := num_dy / (8.0 * w);
    assert dzdy == p.B by {
      calc == {
        dzdy;
        num_dy / (8.0 * w);
        ==
        (p.B * 8.0 * w) / (8.0 * w);
        ==
        p.B;
      }
    }

    // Postcondition follows from the assertions above
  }

  // Main theorem: For any plane and any grid spacing w>0,
  // Horn's finite-difference estimates recover A and B exactly.
  theorem HornExactOnPlaneTheorem(p: Plane, w: real)
    requires w > 0.0
    ensures forall i, j :: 
      var z00 := elevation(p, (i-1) as real * w, (j-1) as real * w);
      var z01 := elevation(p, (i-1) as real * w,  j    as real * w);
      var z02 := elevation(p, (i-1) as real * w, (j+1) as real * w);
      var z10 := elevation(p,  i    as real * w, (j-1) as real * w);
      var z11 := elevation(p,  i    as real * w,  j    as real * w);
      var z12 := elevation(p,  i    as real * w, (j+1) as real * w);
      var z20 := elevation(p, (i+1) as real * w, (j-1) as real * w);
      var z21 := elevation(p, (i+1) as real * w,  j    as real * w);
      var z22 := elevation(p, (i+1) as real * w, (j+1) as real * w);
      var (dzdx, dzdy) := HornSlope(z00, z01, z02, z10, z11, z12, z20, z21, z22, w);
      dzdx == p.A && dzdy == p.B
  {
    forall i, j
      ensures 
        var z00 := elevation(p, (i-1) as real * w, (j-1) as real * w);
        var z01 := elevation(p, (i-1) as real * w,  j    as real * w);
        var z02 := elevation(p, (i-1) as real * w, (j+1) as real * w);
        var z10 := elevation(p,  i    as real * w, (j-1) as real * w);
        var z11 := elevation(p,  i    as real * w,  j    as real * w);
        var z12 := elevation(p,  i    as real * w, (j+1) as real * w);
        var z20 := elevation(p, (i+1) as real * w, (j-1) as real * w);
        var z21 := elevation(p, (i+1) as real * w,  j    as real * w);
        var z22 := elevation(p, (i+1) as real * w, (j+1) as real * w);
        var (dzdx, dzdy) := HornSlope(z00, z01, z02, z10, z11, z12, z20, z21, z22, w);
        dzdx == p.A && dzdy == p.B
    {
      HornExactOnPlane(p, i, j, w);
    }
  }
}
