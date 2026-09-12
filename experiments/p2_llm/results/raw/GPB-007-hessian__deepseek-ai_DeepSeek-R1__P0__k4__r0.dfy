To solve this problem, we need to formalize the property that the Zevenbergen-Thorne discrete Hessian recovers the exact second-order derivatives of a quadratic surface when sampled on a 3x3 grid with spacing `w > 0`. The quadratic surface is defined as \( z = A x^2 + B y^2 + C xy + D x + E y + F \), and the discrete Hessian should recover \((2A, 2B, C)\) exactly.

### Approach
1. **Problem Analysis**: The problem involves proving that the discrete Hessian computed from a 3x3 grid sampling of a quadratic surface matches the continuous second-order derivatives \((2A, 2B, C)\). The grid points are centered at \((x0, y0)\) with spacing \(w\) in both directions.
2. **Discrete Hessian Definition**: The discrete Hessian components are defined as:
   - \(hxx = (d - 2e + f) / w^2\)
   - \(hyy = (b - 2e + h) / w^2\)
   - \(hxy = (-a + c + g - i) / (4w^2)\)
   Here, \(a, b, c, d, e, f, g, h, i\) are the function values at the grid points.
3. **Symbolic Computation**: We symbolically compute the function values at each grid point using the quadratic function. By expanding these expressions and simplifying, we show that the discrete Hessian components equal \(2A\), \(2B\), and \(C\) respectively.
4. **Verification**: Using Dafny's real arithmetic, we verify the exact equality of the discrete Hessian components to the continuous derivatives.

### Solution Code
```dafny
lemma HessianExact(A: real, B: real, C: real, D: real, E: real, F: real, x0: real, y0: real, w: real)
   requires w > 0.0
   ensures
      // Define the quadratic function
      var a := A*(x0 - w)*(x0 - w) + B*(y0 + w)*(y0 + w) + C*(x0 - w)*(y0 + w) + D*(x0 - w) + E*(y0 + w) + F;
      var b := A*x0*x0 + B*(y0 + w)*(y0 + w) + C*x0*(y0 + w) + D*x0 + E*(y0 + w) + F;
      var c := A*(x0 + w)*(x0 + w) + B*(y0 + w)*(y0 + w) + C*(x0 + w)*(y0 + w) + D*(x0 + w) + E*(y0 + w) + F;
      var d := A*(x0 - w)*(x0 - w) + B*y0*y0 + C*(x0 - w)*y0 + D*(x0 - w) + E*y0 + F;
      var e := A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F;
      var f := A*(x0 + w)*(x0 + w) + B*y0*y0 + C*(x0 + w)*y0 + D*(x0 + w) + E*y0 + F;
      var g := A*(x0 - w)*(x0 - w) + B*(y0 - w)*(y0 - w) + C*(x0 - w)*(y0 - w) + D*(x0 - w) + E*(y0 - w) + F;
      var h_val := A*x0*x0 + B*(y0 - w)*(y0 - w) + C*x0*(y0 - w) + D*x0 + E*(y0 - w) + F;
      var i_val := A*(x0 + w)*(x0 + w) + B*(y0 - w)*(y0 - w) + C*(x0 + w)*(y0 - w) + D*(x0 + w) + E*(y0 - w) + F;
      // Discrete Hessian
      var hxx := (d - 2.0*e + f) / (w*w);
      var hyy := (b - 2.0*e + h_val) / (w*w);
      var hxy := (-a + c + g - i_val) / (4.0*w*w);
      // Properties
      hxx == 2.0 * A &&
      hyy == 2.0 * B &&
      hxy == C
{
   // Expansion and simplification for hxx
   calc {
      (d - 2.0*e + f);
      ==
      (A*(x0 - w)*(x0 - w) + B*y0*y0 + C*(x0 - w)*y0 + D*(x0 - w) + E*y0 + F)
      - 2.0*(A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F)
      + (A*(x0 + w)*(x0 + w) + B*y0*y0 + C*(x0 + w)*y0 + D*(x0 + w) + E*y0 + F);
      ==
      // Expand A terms
      A*(x0*x0 - 2.0*x0*w + w*w) - 2.0*A*x0*x0 + A*(x0*x0 + 2.0*x0*w + w*w)
      // B terms cancel: B*y0*y0 - 2*B*y0*y0 + B*y0*y0 = 0
      // Expand C terms
      + (C*(x0*y0 - w*y0) - 2.0*C*x0*y0 + C*(x0*y0 + w*y0))
      // Expand D terms
      + (D*(x0 - w) - 2.0*D*x0 + D*(x0 + w))
      // E terms: E*y0 - 2*E*y0 + E*y0 = 0
      // F terms: F - 2*F + F = 0
      ;
      ==
      // Simplify A: (x0^2 - 2x0w + w^2) - 2x0^2 + (x0^2 + 2x0w + w^2) = (x0^2 - 2x0^2 + x0^2) + (-2x0w + 2x0w) + (w^2 + w^2) = 0 + 0 + 2w^2
      2.0*A*w*w
      // Simplify C: (x0y0 - w y0) - 2x0y0 + (x0y0 + w y0) = (x0y0 - 2x0y0 + x0y0) + (-w y0 + w y0) = 0
      // Simplify D: (x0 - w) - 2x0 + (x0 + w) = (x0 - 2x0 + x0) + (-w + w) = 0
      ;
   }
   assert d - 2.0*e + f == 2.0*A*w*w;
   assert hxx == 2.0*A;

   // Expansion and simplification for hyy
   calc {
      (b - 2.0*e + h_val);
      ==
      (A*x0*x0 + B*(y0 + w)*(y0 + w) + C*x0*(y0 + w) + D*x0 + E*(y0 + w) + F)
      - 2.0*(A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F)
      + (A*x0*x0 + B*(y0 - w)*(y0 - w) + C*x0*(y0 - w) + D*x0 + E*(y0 - w) + F);
      ==
      // A terms: A*x0^2 - 2*A*x0^2 + A*x0^2 = 0
      // Expand B terms
      B*(y0*y0 + 2.0*y0*w + w*w) - 2.0*B*y0*y0 + B*(y0*y0 - 2.0*y0*w + w*w)
      // Expand C terms
      + (C*(x0*y0 + x0*w) - 2.0*C*x0*y0 + C*(x0*y0 - x0*w))
      // Expand E terms
      + (E*(y0 + w) - 2.0*E*y0 + E*(y0 - w))
      // D terms: D*x0 - 2*D*x0 + D*x0 = 0
      // F terms: F - 2*F + F = 0
      ;
      ==
      // Simplify B: (y0^2 + 2y0w + w^2) - 2y0^2 + (y0^2 - 2y0w + w^2) = (y0^2 - 2y0^2 + y0^2) + (2y0w - 2y0w) + (w^2 + w^2) = 0 + 0 + 2w^2
      2.0*B*w*w
      // Simplify C: (x0y0 + x0w) - 2x0y0 + (x0y0 - x0w) = (x0y0 - 2x0y0 + x0y0) + (x0w - x0w) = 0
      // Simplify E: (y0 + w) - 2y0 + (y0 - w) = (y0 - 2y0 + y0) + (w - w) = 0
      ;
   }
   assert b - 2.0*e + h_val == 2.0*B*w*w;
   assert hyy == 2.0*B;

   // Expansion and simplification for hxy
   calc {
      (-a + c + g - i_val);
      ==
      - (A*(x0 - w)*(x0 - w) + B*(y0 + w)*(y0 + w) + C*(x0 - w)*(y0 + w) + D*(x0 - w) + E*(y0 + w) + F)
      + (A*(x0 + w)*(x0 + w) + B*(y0 + w)*(y0 + w) + C*(x0 + w)*(y0 + w) + D*(x0 + w) + E*(y0 + w) + F)
      + (A*(x0 - w)*(x0 - w) + B*(y0 - w)*(y0 - w) + C*(x0 - w)*(y0 - w) + D*(x0 - w) + E*(y0 - w) + F)
      - (A*(x0 + w)*(x0 + w) + B*(y0 - w)*(y0 - w) + C*(x0 + w)*(y0 - w) + D*(x0 + w) + E*(y0 - w) + F);
      ==
      // A terms: -A*(x0-w)^2 + A*(x0+w)^2 + A*(x0-w)^2 - A*(x0+w)^2 = 0
      // B terms: -B*(y0+w)^2 + B*(y0+w)^2 + B*(y0-w)^2 - B*(y0-w)^2 = 0
      // Expand C terms
      - C*((x0 - w)*(y0 + w)) + C*((x0 + w)*(y0 + w)) + C*((x0 - w)*(y0 - w)) - C*((x0 + w)*(y0 - w))
      // D terms: -D*(x0-w) + D*(x0+w) + D*(x0-w) - D*(x0+w) = 0
      // E terms: -E*(y0+w) + E*(y0+w) + E*(y0-w) - E*(y0-w) = 0
      // F terms: -F + F + F - F = 0
      ;
      ==
      // Expand each C term:
      // - [x0 y0 + x0 w - w y0 - w^2] + [x0 y0 + x0 w + w y0 + w^2] + [x0 y0 - x0 w - w y0 + w^2] - [x0 y0 - x0 w + w y0 - w^2]
      // = -x0 y0 - x0 w + w y0 + w^2 + x0 y0 + x0 w + w y0 + w^2 + x0 y0 - x0 w - w y0 + w^2 - x0 y0 + x0 w - w y0 - w^2
      // Group x0 y0: -1 + 1 + 1 - 1 = 0
      // Group x0 w: -1 + 1 -1 +1 = 0
      // Group w y0: 1 + 1 -1 -1 = 0
      // Group w^2: 1 + 1 + 1 -1 = 2
      // But wait, let's count w^2 terms:
      //   - [ - w^2 ] = + w^2
      //   + [ + w^2 ] = + w^2
      //   + [ + w^2 ] = + w^2
      //   - [ - w^2 ] = + w^2
      // Total: 4 w^2
      // However, from expansion:
      //   - ( ... - w^2) = + w^2
      //   + ( ... + w^2) = + w^2
      //   + ( ... + w^2) = + w^2
      //   - ( ... - w^2) = + w^2
      // So total: 4 w^2
      4.0 * C * w * w;
   }
   assert -a + c + g - i_val == 4.0 * C * w * w;
   assert hxy == (4.0 * C * w * w) / (4.0 * w * w) == C;
}
```

### Explanation
1. **Quadratic Function**: The quadratic surface \( z = A x^2 + B y^2 + C xy + D x + E y + F \) is defined, and its values at the 9 grid points around \((x0, y0)\) are computed.
2. **Discrete Hessian Calculation**: The discrete Hessian components \(hxx\), \(hyy\), and \(hxy\) are calculated using the grid values and the given formulas.
3. **Symbolic Verification**: Through symbolic expansion and simplification, we show that:
   - \(hxx = (d - 2e + f) / w^2 = 2A\)
   - \(hyy = (b - 2e + h) / w^2 = 2B\)
   - \(hxy = (-a + c + g - i) / (4w^2) = C\)
4. **Proof**: The Dafny lemma `HessianExact` uses real arithmetic to verify these equalities, ensuring the discrete Hessian matches the continuous derivatives exactly for any quadratic surface sampled on a 3x3 grid with spacing \(w > 0\).
