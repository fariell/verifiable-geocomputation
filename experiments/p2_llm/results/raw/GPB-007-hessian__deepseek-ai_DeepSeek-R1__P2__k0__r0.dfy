lemma HessianExact(A: real, B: real, C: real, D: real, E: real, F: real, w: real, x0: real, y0: real)
  requires w > 0.0
  ensures 
    (z(x0+w, y0) - 2.0*z(x0, y0) + z(x0-w, y0)) / (w*w) == 2.0 * A &&
    (z(x0, y0+w) - 2.0*z(x0, y0) + z(x0, y0-w)) / (w*w) == 2.0 * B &&
    ( (z(x0+w, y0+w) - z(x0-w, y0+w)) - (z(x0+w, y0-w) - z(x0-w, y0-w)) ) / (4.0 * w * w) == C
{
  function z(x: real, y: real): real
  {
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }

  // Prove d²z/dx² = 2A
  calc {
    (z(x0+w, y0) - 2.0*z(x0, y0) + z(x0-w, y0)) / (w*w);
    ==
    // Expand z terms
    ( (A*(x0+w)*(x0+w) + B*y0*y0 + C*(x0+w)*y0 + D*(x0+w) + E*y0 + F) 
      - 2.0*(A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F)
      + (A*(x0-w)*(x0-w) + B*y0*y0 + C*(x0-w)*y0 + D*(x0-w) + E*y0 + F)
    ) / (w*w);
    ==
    // Expand squares and products
    ( (A*(x0*x0 + 2*x0*w + w*w) + B*y0*y0 + C*(x0*y0 + w*y0) + D*(x0+w) + E*y0 + F)
      - 2*A*x0*x0 - 2*B*y0*y0 - 2*C*x0*y0 - 2*D*x0 - 2*E*y0 - 2*F
      + (A*(x0*x0 - 2*x0*w + w*w) + B*y0*y0 + C*(x0*y0 - w*y0) + D*(x0-w) + E*y0 + F)
    ) / (w*w);
    ==
    // Combine like terms
    ( (A*x0*x0 + 2*A*x0*w + A*w*w + B*y0*y0 + C*x0*y0 + C*w*y0 + D*x0 + D*w + E*y0 + F)
      - 2*A*x0*x0 - 2*B*y0*y0 - 2*C*x0*y0 - 2*D*x0 - 2*E*y0 - 2*F
      + (A*x0*x0 - 2*A*x0*w + A*w*w + B*y0*y0 + C*x0*y0 - C*w*y0 + D*x0 - D*w + E*y0 + F)
    ) / (w*w);
    ==
    // Simplify coefficients
    ( (A*x0*x0 - 2*A*x0*x0 + A*x0*x0) 
      + (2*A*x0*w - 2*A*x0*w) 
      + (A*w*w + A*w*w)
      + (B*y0*y0 - 2*B*y0*y0 + B*y0*y0)
      + (C*x0*y0 - 2*C*x0*y0 + C*x0*y0)
      + (C*w*y0 - C*w*y0)
      + (D*x0 - 2*D*x0 + D*x0)
      + (D*w - D*w)
      + (E*y0 - 2*E*y0 + E*y0)
      + (F - 2*F + F)
      + 2*A*w*w
    ) / (w*w);
    ==
    // Final simplification
    (2.0 * A * w * w) / (w * w);
    ==
    2.0 * A;
  }

  // Prove d²z/dy² = 2B
  calc {
    (z(x0, y0+w) - 2.0*z(x0, y0) + z(x0, y0-w)) / (w*w);
    ==
    // Expand z terms
    ( (A*x0*x0 + B*(y0+w)*(y0+w) + C*x0*(y0+w) + D*x0 + E*(y0+w) + F)
      - 2.0*(A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F)
      + (A*x0*x0 + B*(y0-w)*(y0-w) + C*x0*(y0-w) + D*x0 + E*(y0-w) + F)
    ) / (w*w);
    ==
    // Expand squares and products
    ( (A*x0*x0 + B*(y0*y0 + 2*y0*w + w*w) + C*x0*y0 + C*x0*w + D*x0 + E*y0 + E*w + F)
      - 2*A*x0*x0 - 2*B*y0*y0 - 2*C*x0*y0 - 2*D*x0 - 2*E*y0 - 2*F
      + (A*x0*x0 + B*(y0*y0 - 2*y0*w + w*w) + C*x0*y0 - C*x0*w + D*x0 + E*y0 - E*w + F)
    ) / (w*w);
    ==
    // Combine like terms
    ( (A*x0*x0 - 2*A*x0*x0 + A*x0*x0)
      + (B*y0*y0 - 2*B*y0*y0 + B*y0*y0)
      + (2*B*y0*w - 2*B*y0*w)
      + (B*w*w + B*w*w)
      + (C*x0*y0 - 2*C*x0*y0 + C*x0*y0)
      + (C*x0*w - C*x0*w)
      + (D*x0 - 2*D*x0 + D*x0)
      + (E*y0 - 2*E*y0 + E*y0)
      + (E*w - E*w)
      + (F - 2*F + F)
      + 2*B*w*w
    ) / (w*w);
    ==
    // Final simplification
    (2.0 * B * w * w) / (w * w);
    ==
    2.0 * B;
  }

  // Prove d²z/dxdy = C
  calc {
    ( (z(x0+w, y0+w) - z(x0-w, y0+w)) - (z(x0+w, y0-w) - z(x0-w, y0-w)) ) / (4.0 * w * w);
    ==
    // Expand all z terms
    ( (A*(x0+w)*(x0+w) + B*(y0+w)*(y0+w) + C*(x0+w)*(y0+w) + D*(x0+w) + E*(y0+w) + F)
      - (A*(x0-w)*(x0-w) + B*(y0+w)*(y0+w) + C*(x0-w)*(y0+w) + D*(x0-w) + E*(y0+w) + F)
      - ( (A*(x0+w)*(x0+w) + B*(y0-w)*(y0-w) + C*(x0+w)*(y0-w) + D*(x0+w) + E*(y0-w) + F)
        - (A*(x0-w)*(x0-w) + B*(y0-w)*(y0-w) + C*(x0-w)*(y0-w) + D*(x0-w) + E*(y0-w) + F) )
    ) / (4.0 * w * w);
    ==
    // Simplify by canceling symmetric terms
    ( (A*((x0+w)*(x0+w) - (x0-w)*(x0+w)) 
        + C*((x0+w)*(y0+w) - (x0-w)*(y0+w))
        + D*((x0+w) - (x0-w))
      )
      - ( A*((x0+w)*(x0+w) - (x0-w)*(x0+w)) 
          + C*((x0+w)*(y0-w) - (x0-w)*(y0-w))
          + D*((x0+w) - (x0-w))
        )
    ) / (4.0 * w * w);
    ==
    // Expand differences
    ( (A*(4*x0*w) + C*(2*w*y0 + 2*w*w) + D*(2*w))
      - (A*(4*x0*w) + C*(2*w*y0 - 2*w*w) + D*(2*w))
    ) / (4.0 * w * w);
    ==
    // Simplify
    (4*x0*w*A + 2*w*y0*C + 2*w*w*C + 2*w*D 
      - 4*x0*w*A - 2*w*y0*C + 2*w*w*C - 2*w*D
    ) / (4.0 * w * w);
    ==
    (4*C*w*w) / (4.0 * w * w);
    ==
    C;
  }
}
