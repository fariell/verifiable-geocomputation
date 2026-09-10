// Horn slope magnitude on a constant 3x3 window is zero
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

// Main theorem: constant elevation window yields zero slope magnitude
lemma HornConstantWindowZeroSlope(w: Window, spacing: real)
  requires spacing > 0.0
  requires w.z00 == w.z01 && w.z01 == w.z02 &&
           w.z02 == w.z10 && w.z10 == w.z11 &&
           w.z11 == w.z12 && w.z12 == w.z20 &&
           w.z20 == w.z21 && w.z21 == w.z22
  ensures HornSlopeSq(w, spacing) == 0.0
{
  // All elevations are equal
  var c := w.z00;
  assert forall i,j :: 
    i in {0,1,2} && j in {0,1,2} ==> 
    match (i,j) {
      case (0,0) => w.z00 == c
      case (0,1) => w.z01 == c
      case (0,2) => w.z02 == c
      case (1,0) => w.z10 == c
      case (1,1) => w.z11 == c
      case (1,2) => w.z12 == c
      case (2,0) => w.z20 == c
      case (2,1) => w.z21 == c
      case (2,2) => w.z22 == c
    };

  // Compute DzDx numerator
  var numDx := (w.z20 + 2.0*w.z21 + w.z22) - (w.z00 + 2.0*w.z01 + w.z02);
  calc {
    numDx;
    ==
    (c + 2.0*c + c) - (c + 2.0*c + c);
    ==
    4.0*c - 4.0*c;
    ==
    0.0;
  }
  assert HornDzDx(w, spacing) == 0.0;

  // Compute DzDy numerator
  var numDy := (w.z02 + 2.0*w.z12 + w.z22) - (w.z00 + 2.0*w.z10 + w.z20);
  calc {
    numDy;
    ==
    (c + 2.0*c + c) - (c + 2.0*c + c);
    ==
    4.0*c - 4.0*c;
    ==
    0.0;
  }
  assert HornDzDy(w, spacing) == 0.0;

  // Slope squared is sum of squares of zero components
  assert HornSlopeSq(w, spacing) == 0.0*0.0 + 0.0*0.0 == 0.0;
}
