function z(i: int, j: int, w: real, A: real, B: real, C: real): real
{
  A * (i * w) + B * (j * w) + C
}

function DzDx(i: int, j: int, w: real, A: real, B: real, C: real): real
  requires w > 0.0
{
  (z(i+1, j, w, A, B, C) - z(i-1, j, w, A, B, C)) / (2.0 * w)
}

function DzDy(i: int, j: int, w: real, A: real, B: real, C: real): real
  requires w > 0.0
{
  (z(i, j+1, w, A, B, C) - z(i, j-1, w, A, B, C)) / (2.0 * w)
}

lemma Lemma(w: real, A: real, B: real, C: real)
  requires w > 0.0
  ensures forall i: int, j: int :: 
      DzDx(i, j, w, A, B, C) == A && DzDy(i, j, w, A, B, C) == B
{
  forall i: int, j: int {
    calc {
      DzDx(i, j, w, A, B, C);
      == 
      (z(i+1, j, w, A, B, C) - z(i-1, j, w, A, B, C)) / (2.0 * w);
      == 
      (A*(i+1)*w + B*j*w + C - (A*(i-1)*w + B*j*w + C)) / (2.0 * w);
      == 
      (A*w*(i+1 - (i-1))) / (2.0 * w);
      == 
      (A*w*2) / (2.0 * w);
      == 
      A;
    }
    calc {
      DzDy(i, j, w, A, B, C);
      ==
      (z(i, j+1, w, A, B, C) - z(i, j-1, w, A, B, C)) / (2.0 * w);
      ==
      (A*i*w + B*(j+1)*w + C - (A*i*w + B*(j-1)*w + C)) / (2.0 * w);
      ==
      (B*w*((j+1) - (j-1))) / (2.0 * w);
      ==
      (B*w*2) / (2.0 * w);
      ==
      B;
    }
  }
}
