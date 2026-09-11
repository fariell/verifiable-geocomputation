module PlaneExactness {
  function z(A: real, B: real, w: real, i: int, j: int): real
  {
    A * (i * w) + B * (j * w)  // Constant C omitted (cancels in differences)
  }

  function HornDzDx(A: real, B: real, w: real, i: int, j: int): real
    requires w > 0.0
  {
    (z(A, B, w, i+1, j-1) + 2.0 * z(A, B, w, i+1, j) + z(A, B, w, i+1, j+1) 
     - z(A, B, w, i-1, j-1) - 2.0 * z(A, B, w, i-1, j) - z(A, B, w, i-1, j+1)) 
    / (8.0 * w)
  }

  function HornDzDy(A: real, B: real, w: real, i: int, j: int): real
    requires w > 0.0
  {
    (z(A, B, w, i-1, j+1) + 2.0 * z(A, B, w, i, j+1) + z(A, B, w, i+1, j+1) 
     - z(A, B, w, i-1, j-1) - 2.0 * z(A, B, w, i, j-1) - z(A, B, w, i+1, j-1)) 
    / (8.0 * w)
  }

  lemma ExactRecovery(A: real, B: real, w: real, i: int, j: int)
    requires w > 0.0
    ensures HornDzDx(A, B, w, i, j) == A
    ensures HornDzDy(A, B, w, i, j) == B
  {
    // Proof for DzDx
    calc {
      HornDzDx(A, B, w, i, j);
      ==
      (z(A, B, w, i+1, j-1) + 2.0 * z(A, B, w, i+1, j) + z(A, B, w, i+1, j+1) 
       - z(A, B, w, i-1, j-1) - 2.0 * z(A, B, w, i-1, j) - z(A, B, w, i-1, j+1)) 
       / (8.0 * w);
      ==
      (A*w*( (i+1) + 2*(i+1) + (i+1) - (i-1) - 2*(i-1) - (i-1) ) 
       + B*w*( (j-1) + 2*j + (j+1) - (j-1) - 2*j - (j+1) )) 
       / (8.0 * w);
      ==
      (A*w*(4*(i+1) - 4*(i-1)) + B*w*0) / (8.0 * w);
      ==
      (A*w*(4*i + 4 - 4*i + 4)) / (8.0 * w);
      ==
      (A*w*8) / (8.0 * w);
      ==
      A;
    }
    // Proof for DzDy
    calc {
      HornDzDy(A, B, w, i, j);
      ==
      (z(A, B, w, i-1, j+1) + 2.0 * z(A, B, w, i, j+1) + z(A, B, w, i+1, j+1) 
       - z(A, B, w, i-1, j-1) - 2.0 * z(A, B, w, i, j-1) - z(A, B, w, i+1, j-1)) 
       / (8.0 * w);
      ==
      (A*w*( (i-1) + 2*i + (i+1) - (i-1) - 2*i - (i+1) ) 
       + B*w*( (j+1) + 2*(j+1) + (j+1) - (j-1) - 2*(j-1) - (j-1) )) 
       / (8.0 * w);
      ==
      (A*w*0 + B*w*(4*(j+1) - 4*(j-1))) / (8.0 * w);
      ==
      (B*w*(4*j + 4 - 4*j + 4)) / (8.0 * w);
      ==
      (B*w*8) / (8.0 * w);
      ==
      B;
    }
  }
}
