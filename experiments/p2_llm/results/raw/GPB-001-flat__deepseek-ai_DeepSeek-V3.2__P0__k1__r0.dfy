// Horn slope magnitude on a 3×3 constant‑elevation window
// Formalization of: "On any 3x3 elevation window with finite values,
// if all nine cells share the same elevation, the Horn (1981) slope magnitude
// (equivalently its square SlopeSq) is identically zero.
// Grid spacing w must be positive."

module HornSlopeConstantWindow {
  // A 3×3 window of finite elevations
  type Window = array3<int, 3, 3, real>

  // Horn (1981) finite‑difference slope components
  // Notation: window indices (r,c) with r,c ∈ {0,1,2}
  // Central cell is (1,1)
  function HornSlopeX(w: Window, spacing: real): real
    requires spacing > 0.0
  {
    // ∂z/∂x ≈ ( (z(2,0)+2*z(2,1)+z(2,2)) - (z(0,0)+2*z(0,1)+z(0,2)) ) / (8 * spacing)
    ((w[2,0] + 2.0*w[2,1] + w[2,2]) - (w[0,0] + 2.0*w[0,1] + w[0,2])) / (8.0 * spacing)
  }

  function HornSlopeY(w: Window, spacing: real): real
    requires spacing > 0.0
  {
    // ∂z/∂y ≈ ( (z(0,2)+2*z(1,2)+z(2,2)) - (z(0,0)+2*z(1,0)+z(2,0)) ) / (8 * spacing)
    ((w[0,2] + 2.0*w[1,2] + w[2,2]) - (w[0,0] + 2.0*w[1,0] + w[2,0])) / (8.0 * spacing)
  }

  // Slope magnitude squared (avoids sqrt for simplicity)
  function HornSlopeSq(w: Window, spacing: real): real
    requires spacing > 0.0
  {
    HornSlopeX(w, spacing) * HornSlopeX(w, spacing) +
    HornSlopeY(w, spacing) * HornSlopeY(w, spacing)
  }

  // Predicate: all nine cells have the same elevation
  predicate ConstantWindow(w: Window)
    reads w
  {
    forall r,c :: 0 <= r < 3 && 0 <= c < 3 ==> w[r,c] == w[0,0]
  }

  // Main theorem: on a constant window, Horn slope magnitude is zero
  theorem HornSlopeZeroOnConstant(w: Window, spacing: real)
    requires spacing > 0.0
    requires ConstantWindow(w)
    ensures HornSlopeSq(w, spacing) == 0.0
  {
    // Because all cells equal w[0,0], each sum in HornSlopeX reduces to:
    // (w[0,0] + 2*w[0,0] + w[0,0]) = 4*w[0,0]
    calc {
      HornSlopeX(w, spacing);
      ==
      ((w[2,0] + 2.0*w[2,1] + w[2,2]) - (w[0,0] + 2.0*w[0,1] + w[0,2])) / (8.0 * spacing);
      ==  // replace each w[r,c] with w[0,0]
      ((w[0,0] + 2.0*w[0,0] + w[0,0]) - (w[0,0] + 2.0*w[0,0] + w[0,0])) / (8.0 * spacing);
      ==
      (4.0*w[0,0] - 4.0*w[0,0]) / (8.0 * spacing);
      ==
      0.0 / (8.0 * spacing);
      ==
      0.0;
    }
    // Similarly for HornSlopeY
    calc {
      HornSlopeY(w, spacing);
      ==
      ((w[0,2] + 2.0*w[1,2] + w[2,2]) - (w[0,0] + 2.0*w[1,0] + w[2,0])) / (8.0 * spacing);
      ==  // replace each w[r,c] with w[0,0]
      ((w[0,0] + 2.0*w[0,0] + w[0,0]) - (w[0,0] + 2.0*w[0,0] + w[0,0])) / (8.0 * spacing);
      ==
      (4.0*w[0,0] - 4.0*w[0,0]) / (8.0 * spacing);
      ==
      0.0 / (8.0 * spacing);
      ==
      0.0;
    }
    // Therefore the squared magnitude is zero
    assert HornSlopeX(w, spacing) == 0.0 && HornSlopeY(w, spacing) == 0.0;
    assert HornSlopeSq(w, spacing) == 0.0 * 0.0 + 0.0 * 0.0 == 0.0;
  }
}
