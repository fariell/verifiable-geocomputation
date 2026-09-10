// Horn slope exactness on quadratic surfaces
// DzDx and DzDy recover true planar gradient coefficients (A,B) identically.
// On z = G x^3, DzDx remainder at origin equals G w^2 (order O(w^2)).

method QuadraticExactness(A: real, B: real, C: real, w: real) 
  returns (DzDx: real, DzDy: real)
  requires w != 0.0
{
  // Quadratic surface: z = A x + B y + C
  // Central differences over a square grid of spacing w
  var z00 := C;                     // (0,0)
  var z10 := A * w + B * 0.0 + C;   // (w,0)
  var z01 := A * 0.0 + B * w + C;   // (0,w)
  var zm10 := A * (-w) + B * 0.0 + C; // (-w,0)
  var z0m1 := A * 0.0 + B * (-w) + C; // (0,-w)

  // Horn's finite-difference slope operators
  DzDx := (z10 - zm10) / (2.0 * w);
  DzDy := (z01 - z0m1) / (2.0 * w);

  // Exact recovery of coefficients
  assert DzDx == A by {
    calc {
      DzDx;
      == (z10 - zm10) / (2.0 * w);
      == ((A * w + C) - (A * (-w) + C)) / (2.0 * w);
      == (A * w + C + A * w - C) / (2.0 * w);
      == (2.0 * A * w) / (2.0 * w);
      == A;
    }
  }
  assert DzDy == B by {
    calc {
      DzDy;
      == (z01 - z0m1) / (2.0 * w);
      == ((B * w + C) - (B * (-w) + C)) / (2.0 * w);
      == (B * w + C + B * w - C) / (2.0 * w);
      == (2.0 * B * w) / (2.0 * w);
      == B;
    }
  }
}

method CubicRemainder(G: real, w: real) 
  returns (remainder: real)
  requires w != 0.0
{
  // Surface: z = G * x^3
  var z00 := 0.0;           // (0,0)
  var z10 := G * w * w * w; // (w,0)
  var zm10 := G * (-w) * (-w) * (-w); // (-w,0) = -G w^3

  // Horn's DzDx operator
  var DzDx := (z10 - zm10) / (2.0 * w);

  // True derivative at origin is 0 (since d/dx (G x^3) = 3 G x^2, at x=0 gives 0)
  var trueDerivative := 0.0;

  // Remainder = computed - true
  remainder := DzDx - trueDerivative;

  // Show remainder equals G w^2
  assert remainder == G * w * w by {
    calc {
      DzDx;
      == (G * w * w * w - (-G * w * w * w)) / (2.0 * w);
      == (G * w * w * w + G * w * w * w) / (2.0 * w);
      == (2.0 * G * w * w * w) / (2.0 * w);
      == G * w * w;
    }
    remainder == DzDx - 0.0;
    == G * w * w;
  }
}
