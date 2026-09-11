lemma HornExactOnPlane(A: real, B: real, w: real)
  requires w > 0.0
  ensures forall i: int, j: int, C: real :: 
    // Horn x-derivative estimate
    ( (A * ((i+1) * w) + B * (j * w) + C) - 
      (A * ((i-1) * w) + B * (j * w) + C) ) / (2.0 * w) == A
    &&
    // Horn y-derivative estimate
    ( (A * (i * w) + B * ((j+1) * w) + C) - 
      (A * (i * w) + B * ((j-1) * w) + C) ) / (2.0 * w) == B
{
  forall i: int, j: int, C: real
    ensures ( (A * ((i+1) * w) + B * (j * w) + C) - 
              (A * ((i-1) * w) + B * (j * w) + C) ) / (2.0 * w) == A
    ensures ( (A * (i * w) + B * ((j+1) * w) + C) - 
              (A * (i * w) + B * ((j-1) * w) + C) ) / (2.0 * w) == B
  {
    // Proof for x-derivative
    calc {
      ( (A * ((i+1) * w) + B * (j * w) + C) - 
        (A * ((i-1) * w) + B * (j * w) + C) ) / (2.0 * w);
      ==
      (A * (i+1)*w - A*(i-1)*w) / (2.0 * w);
      ==
      A * w * ((i+1) - (i-1)) / (2.0 * w);
      ==
      A * w * 2 / (2.0 * w);
      ==
      A;
    }
    // Proof for y-derivative
    calc {
      ( (A * (i * w) + B * ((j+1) * w) + C) - 
        (A * (i * w) + B * ((j-1) * w) + C) ) / (2.0 * w);
      ==
      (B * (j+1)*w - B*(j-1)*w) / (2.0 * w);
      ==
      B * w * ((j+1) - (j-1)) / (2.0 * w);
      ==
      B * w * 2 / (2.0 * w);
      ==
      B;
    }
  }
}
