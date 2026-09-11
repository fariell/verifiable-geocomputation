// Horn finite-difference exactness on planar surfaces
module HornExact {
  lemma ExactRecovery(w: real, A: real, B: real, x0: real, y0: real, C: real, i: int, j: int)
    requires w > 0.0
  {
    // Define planar elevation function
    function elevation(i: int, j: int): real
      reads 
    {
      A * (x0 + j*w) + B * (y0 + i*w) + C
    }

    // Horn finite-difference operators
    var dzdx := (elevation(i, j+1) - elevation(i, j-1)) / (2.0 * w);
    var dzdy := (elevation(i+1, j) - elevation(i-1, j)) / (2.0 * w);

    // Algebraic verification
    assert dzdx == A by {
      calc {
        dzdx;
        == // Expand elevation terms
        ( (A*(x0 + (j+1)*w) + B*(y0 + i*w) + C) - 
          (A*(x0 + (j-1)*w) + B*(y0 + i*w) + C) ) / (2.0 * w);
        == // Simplify by canceling B and C terms
        (A*(x0 + (j+1)*w - x0 - (j-1)*w)) / (2.0 * w);
        == // Simplify x-coordinate difference
        (A*(2*w)) / (2.0 * w);
        == // Cancel common factors
        A;
      }
    }

    assert dzdy == B by {
      calc {
        dzdy;
        == // Expand elevation terms
        ( (A*(x0 + j*w) + B*(y0 + (i+1)*w) + C) - 
          (A*(x0 + j*w) + B*(y0 + (i-1)*w) + C) ) / (2.0 * w);
        == // Simplify by canceling A and C terms
        (B*(y0 + (i+1)*w - y0 - (i-1)*w)) / (2.0 * w);
        == // Simplify y-coordinate difference
        (B*(2*w)) / (2.0 * w);
        == // Cancel common factors
        B;
      }
    }
  }
}
