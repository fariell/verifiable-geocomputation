// Horn slope magnitude is zero on a constant 3x3 elevation window
// Grid spacing w must be positive

// Define a 3x3 window of finite elevations
datatype Window = Window(
  z00: real, z01: real, z02: real,
  z10: real, z11: real, z12: real,
  z20: real, z21: real, z22: real
)

// Horn (1981) finite-difference slope components
function HornDzDx(w: Window, spacing: real): real
  requires spacing > 0.0
{
  ((w.z20 + 2.0*w.z21 + w.z22) - (w.z00 + 2.0*w.z01 + w.z02)) / (8.0 * spacing)
}

function HornDzDy(w: Window, spacing: real): real
  requires spacing > 0.0
{
  ((w.z02 + 2.0*w.z12 + w.z22) - (w.z00 + 2.0*w.z10 + w.z20)) / (8.0 * spacing)
}

// Slope magnitude squared (avoids sqrt for simpler verification)
function HornSlopeSq(w: Window, spacing: real): real
  requires spacing > 0.0
{
  HornDzDx(w, spacing)*HornDzDx(w, spacing) + HornDzDy(w, spacing)*HornDzDy(w, spacing)
}

// Main theorem: if all nine cells have the same elevation, HornSlopeSq is zero
theorem HornZeroOnConstantWindow(spacing: real)
  requires spacing > 0.0
  ensures forall c: real :: 
    let w := Window(c, c, c, c, c, c, c, c, c) in
    HornSlopeSq(w, spacing) == 0.0
{
  // For any constant c
  var c: real;
  var w := Window(c, c, c, c, c, c, c, c, c);
  
  // Compute DzDx
  var dzdx := HornDzDx(w, spacing);
  calc == {
    dzdx;
    ((c + 2.0*c + c) - (c + 2.0*c + c)) / (8.0 * spacing);
    ((4.0*c) - (4.0*c)) / (8.0 * spacing);
    0.0 / (8.0 * spacing);
    0.0;
  }
  
  // Compute DzDy
  var dzdy := HornDzDy(w, spacing);
  calc == {
    dzdy;
    ((c + 2.0*c + c) - (c + 2.0*c + c)) / (8.0 * spacing);
    ((4.0*c) - (4.0*c)) / (8.0 * spacing);
    0.0 / (8.0 * spacing);
    0.0;
  }
  
  // Slope squared is zero
  assert HornSlopeSq(w, spacing) == 0.0*0.0 + 0.0*0.0 == 0.0;
}
