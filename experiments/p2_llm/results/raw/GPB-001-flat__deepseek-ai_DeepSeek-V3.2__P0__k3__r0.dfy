// Horn slope magnitude on a flat 3×3 window is zero
// Formalization of: On any 3x3 elevation window with finite values,
// if all nine cells share the same elevation, the Horn (1981) slope magnitude
// (equivalently its square SlopeSq) is identically zero.
// Grid spacing w must be positive.

// Horn (1981) finite-difference slope components
// Given a 3×3 window with elevations z₀..z₈ arranged as:
//   z₀ z₁ z₂
//   z₃ z₄ z₅
//   z₆ z₇ z₈
// and grid spacing w (cell size) in both x and y directions,
// the slope components are:
//   dz/dx = (z₂ + 2*z₅ + z₈ - z₀ - 2*z₃ - z₆) / (8*w)
//   dz/dy = (z₆ + 2*z₇ + z₈ - z₀ - 2*z₁ - z₂) / (8*w)
// Slope magnitude squared = (dz/dx)² + (dz/dy)²

// We prove that if all z_i are equal, then dz/dx = dz/dy = 0, so slope² = 0.

// Real numbers with usual arithmetic
datatype Real = Real(value: real)

function HornSlopeSq(z0: Real, z1: Real, z2: Real,
                     z3: Real, z4: Real, z5: Real,
                     z6: Real, z7: Real, z8: Real, w: Real): Real
  requires w.value > 0.0  // positive grid spacing
{
  // Compute dz/dx numerator
  var numX := Real(z2.value + 2.0*z5.value + z8.value - z0.value - 2.0*z3.value - z6.value);
  // Compute dz/dy numerator
  var numY := Real(z6.value + 2.0*z7.value + z8.value - z0.value - 2.0*z1.value - z2.value);
  // Common denominator 8*w
  var denom := Real(8.0 * w.value);
  // Slope components
  var dzdx := Real(numX.value / denom.value);
  var dzdy := Real(numY.value / denom.value);
  // Slope magnitude squared
  Real(dzdx.value*dzdx.value + dzdy.value*dzdy.value)
}

// Main theorem: if all elevations are equal, HornSlopeSq = 0
lemma FlatWindowZeroSlope(z: Real, w: Real)
  requires w.value > 0.0
  ensures HornSlopeSq(z, z, z, z, z, z, z, z, z, w).value == 0.0
{
  // Expand HornSlopeSq with all arguments equal to z
  var numX := Real(z.value + 2.0*z.value + z.value - z.value - 2.0*z.value - z.value);
  // numX = (z + 2z + z) - (z + 2z + z) = 4z - 4z = 0
  assert numX.value == 0.0;

  var numY := Real(z.value + 2.0*z.value + z.value - z.value - 2.0*z.value - z.value);
  // numY = (z + 2z + z) - (z + 2z + z) = 4z - 4z = 0
  assert numY.value == 0.0;

  var denom := Real(8.0 * w.value);
  // dzdx = 0 / (8w) = 0
  var dzdx := Real(numX.value / denom.value);
  assert dzdx.value == 0.0;
  // dzdy = 0 / (8w) = 0
  var dzdy := Real(numY.value / denom.value);
  assert dzdy.value == 0.0;

  // SlopeSq = 0² + 0² = 0
  assert dzdx.value*dzdx.value + dzdy.value*dzdy.value == 0.0;
}
