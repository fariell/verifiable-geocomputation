function z(A: real, B: real, C: real, w: real, i: int, j: int): real
{
  A * (i * w) + B * (j * w) + C
}

function DzDx(A: real, B: real, C: real, w: real, i: int, j: int): real
  requires w > 0.0
{
  (z(A, B, C, w, i+1, j) - z(A, B, C, w, i-1, j)) / (2.0 * w)
}

function DzDy(A: real, B: real, C: real, w: real, i: int, j: int): real
  requires w > 0.0
{
  (z(A, B, C, w, i, j+1) - z(A, B, C, w, i, j-1)) / (2.0 * w)
}

lemma Theorem(A: real, B: real, C: real, w: real)
  requires w > 0.0
  ensures forall i: int, j: int :: 
      DzDx(A, B, C, w, i, j) == A && DzDy(A, B, C, w, i, j) == B
{
  forall i: int, j: int)
    ensures DzDx(A, B, C, w, i, j) == A && DzDy(A, B, C, w, i, j) == B
  {
    calc {
      DzDx(A, B, C, w, i, j);
    ==
      (z(A, B, C, w, i+1, j) - z(A, B, C, w, i-1, j)) / (2.0 * w);
    ==
      ( (A * ( (i+1) * w ) + B * (j * w) + C) - (A * ( (i-1) * w ) + B * (j * w) + C) ) / (2.0 * w);
    ==
      (A * (i+1) * w - A * (i-1) * w) / (2.0 * w);
    ==
      A * w * ( (i+1) - (i-1) ) / (2.0 * w);
    ==
      A * w * 2 / (2.0 * w);
    ==
      A;
    }
    calc {
      DzDy(A, B, C, w, i, j);
    ==
      (z(A, B, C, w, i, j+1) - z(A, B, C, w, i, j-1)) / (2.0 * w);
    ==
      ( (A * (i * w) + B * ((j+1) * w) + C) - (A * (i * w) + B * ((j-1) * w) + C) ) / (2.0 * w);
    ==
      (B * (j+1) * w - B * (j-1) * w) / (2.0 * w);
    ==
      B * w * ( (j+1) - (j-1) ) / (2.0 * w);
    ==
      B * w * 2 / (2.0 * w);
    ==
      B;
    }
  }
}
