// Horn slope magnitude on a 3×3 constant‑elevation window
// Formalization of: "On any 3x3 elevation window with finite values,
// if all nine cells share the same elevation, the Horn (1981) slope magnitude
// (equivalently its square SlopeSq) is identically zero. Grid spacing w must be positive."

module HornSlopeConstantWindow {
  // A 3×3 window of finite elevations
  type Window = array3<int, 3, 3>

  // Horn (1981) finite‑difference slope components
  // Notation: window indices (row, col) with (0,0) at top‑left.
  // The central cell is (1,1).
  function HornSlopeX(w: Window, spacing: real): real
    requires spacing > 0.0
  {
    // ∂z/∂x ≈ ( (z(0,2)+2*z(1,2)+z(2,2)) - (z(0,0)+2*z(1,0)+z(2,0)) ) / (8 * spacing)
    let numerator :=
      (w[0,2] + 2 * w[1,2] + w[2,2]) -
      (w[0,0] + 2 * w[1,0] + w[2,0]);
    numerator as real / (8.0 * spacing)
  }

  function HornSlopeY(w: Window, spacing: real): real
    requires spacing > 0.0
  {
    // ∂z/∂y ≈ ( (z(2,0)+2*z(2,1)+z(2,2)) - (z(0,0)+2*z(0,1)+z(0,2)) ) / (8 * spacing)
    let numerator :=
      (w[2,0] + 2 * w[2,1] + w[2,2]) -
      (w[0,0] + 2 * w[0,1] + w[0,2]);
    numerator as real / (8.0 * spacing)
  }

  // Square of the slope magnitude (to avoid square‑root)
  function HornSlopeSq(w: Window, spacing: real): real
    requires spacing > 0.0
  {
    let sx := HornSlopeX(w, spacing);
    let sy := HornSlopeY(w, spacing);
    sx * sx + sy * sy
  }

  // Predicate: all nine cells have the same finite elevation value
  predicate ConstantWindow(w: Window)
  {
    forall i, j :: 0 <= i < 3 && 0 <= j < 3 ==> w[i,j] == w[0,0]
  }

  // Main theorem: on a constant window, the Horn slope magnitude is zero.
  theorem HornSlopeZeroOnConstant(w: Window, spacing: real)
    requires spacing > 0.0
    requires ConstantWindow(w)
    ensures HornSlopeSq(w, spacing) == 0.0
  {
    // Because all cells are equal, each numerator in HornSlopeX and HornSlopeY is zero.
    calc {
      HornSlopeX(w, spacing);
    ==
      // Expand numerator
      ((w[0,2] + 2 * w[1,2] + w[2,2]) - (w[0,0] + 2 * w[1,0] + w[2,0])) as real / (8.0 * spacing);
    ==
      // Since w[i,j] == w[0,0] for all i,j
      ((w[0,0] + 2 * w[0,0] + w[0,0]) - (w[0,0] + 2 * w[0,0] + w[0,0])) as real / (8.0 * spacing);
    ==
      0.0 / (8.0 * spacing);
    ==
      0.0;
    }

    calc {
      HornSlopeY(w, spacing);
    ==
      ((w[2,0] + 2 * w[2,1] + w[2,2]) - (w[0,0] + 2 * w[0,1] + w[0,2])) as real / (8.0 * spacing);
    ==
      ((w[0,0] + 2 * w[0,0] + w[0,0]) - (w[0,0] + 2 * w[0,0] + w[0,0])) as real / (8.0 * spacing);
    ==
      0.0 / (8.0 * spacing);
    ==
      0.0;
    }

    // Therefore the squared magnitude is zero.
    assert HornSlopeSq(w, spacing) == 0.0 * 0.0 + 0.0 * 0.0 == 0.0;
  }
}
