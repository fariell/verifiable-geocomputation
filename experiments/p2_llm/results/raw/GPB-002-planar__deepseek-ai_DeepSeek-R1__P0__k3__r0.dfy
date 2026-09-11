module PlanarHorn {
  // Grid elevation function for plane z = A*x + B*y + C
  function grid(w: real, A: real, B: real, C: real, x0: real, y0: real, i: int, j: int): real
  {
    A*(x0 + i*w) + B*(y0 + j*w) + C
  }

  // Horn finite-difference for dz/dx
  function HornDzDx(w: real, A: real, B: real, C: real, x0: real, y0: real, i: int, j: int): real
    requires w > 0.0
  {
    (grid(w, A, B, C, x0, y0, i+1, j) - grid(w, A, B, C, x0, y0, i-1, j)) / (2.0 * w)
  }

  // Horn finite-difference for dz/dy
  function HornDzDy(w: real, A: real, B: real, C: real, x0: real, y0: real, i: int, j: int): real
    requires w > 0.0
  {
    (grid(w, A, B, C, x0, y0, i, j+1) - grid(w, A, B, C, x0, y0, i, j-1)) / (2.0 * w)
  }

  lemma LemmaHornExactOnPlane(w: real, A: real, B: real, C: real, x0: real, y0: real, i: int, j: int)
    requires w > 0.0
    ensures HornDzDx(w, A, B, C, x0, y0, i, j) == A
    ensures HornDzDy(w, A, B, C, x0, y0, i, j) == B
  {
    // Proof for dz/dx
    calc {
      HornDzDx(w, A, B, C, x0, y0, i, j);
      ==
      (grid(w, A, B, C, x0, y0, i+1, j) - grid(w, A, B, C, x0, y0, i-1, j)) / (2.0 * w);
      == {
        assert grid(w, A, B, C, x0, y0, i+1, j) == A*(x0 + (i+1)*w) + B*(y0 + j*w) + C;
        assert grid(w, A, B, C, x0, y0, i-1, j) == A*(x0 + (i-1)*w) + B*(y0 + j*w) + C;
      }
      (A*(x0 + (i+1)*w) + B*(y0 + j*w) + C - (A*(x0 + (i-1)*w) + B*(y0 + j*w) + C)) / (2.0 * w);
      ==
      (A*(x0 + (i+1)*w - x0 - (i-1)*w)) / (2.0 * w);
      ==
      (A*((i+1)*w - (i-1)*w)) / (2.0 * w);
      ==
      (A*(2*w)) / (2.0 * w);
      ==
      A;
    }
    // Proof for dz/dy
    calc {
      HornDzDy(w, A, B, C, x0, y0, i, j);
      ==
      (grid(w, A, B, C, x0, y0, i, j+1) - grid(w, A, B, C, x0, y0, i, j-1)) / (2.0 * w);
      == {
        assert grid(w, A, B, C, x0, y0, i, j+1) == A*(x0 + i*w) + B*(y0 + (j+1)*w) + C;
        assert grid(w, A, B, C, x0, y0, i, j-1) == A*(x0 + i*w) + B*(y0 + (j-1)*w) + C;
      }
      (A*(x0 + i*w) + B*(y0 + (j+1)*w) + C - (A*(x0 + i*w) + B*(y0 + (j-1)*w) + C)) / (2.0 * w);
      ==
      (B*((j+1)*w - (j-1)*w)) / (2.0 * w);
      ==
      (B*(2*w)) / (2.0 * w);
      ==
      B;
    }
  }
}
