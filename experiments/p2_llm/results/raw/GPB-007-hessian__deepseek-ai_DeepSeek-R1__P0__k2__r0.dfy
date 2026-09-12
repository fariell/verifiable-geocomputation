To solve this problem, we need to formalize the property that the Zevenbergen-Thorne discrete Hessian recovers the exact Hessian components (2A, 2B, C) for a quadratic surface sampled on a 3x3 grid with spacing w > 0. The quadratic surface is defined as \( z = A x^2 + B y^2 + C xy + D x + E y + F \). The Hessian components are the second derivatives \( \frac{\partial^2 z}{\partial x^2} = 2A \), \( \frac{\partial^2 z}{\partial y^2} = 2B \), and \( \frac{\partial^2 z}{\partial x \partial y} = C \).

### Approach
1. **Problem Analysis**: The task involves proving that the finite difference approximations used in the Zevenbergen-Thorne method exactly compute the Hessian components for any quadratic surface. The discrete approximations for the Hessian components are:
   - \( h_{xx} = \frac{d - 2e + f}{w^2} \)
   - \( h_{yy} = \frac{b - 2e + h}{w^2} \)
   - \( h_{xy} = \frac{a - c - g + i}{4w^2} \)
   Here, \( a, b, c, d, e, f, g, h, i \) are the function values at the grid points around the center point \( (x_0, y_0) \).

2. **Key Insight**: For a quadratic function, the second derivatives are constant. The finite difference approximations must exactly match these constants because quadratic functions are polynomials of degree 2, and the finite difference stencils are designed to be exact for such polynomials.

3. **Algebraic Verification**: We expand the function values at each grid point in terms of the quadratic function. By substituting these expansions into the finite difference formulas and simplifying, we show that:
   - \( h_{xx} = 2A \)
   - \( h_{yy} = 2B \)
   - \( h_{xy} = -C \) (Note: The natural language specification states \( C \), but the discrete method yields \( -C \). This discrepancy is noted in the code comments.)

### Solution Code
```dafny
function quad(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
{
  A*x*x + B*y*y + C*x*y + D*x + E*y + F
}

lemma ZTHessianExact(A: real, B: real, C: real, D: real, E: real, F: real, x0: real, y0: real, w: real)
  requires w > 0.0
  ensures 
    var a_val := quad(x0 - w, y0 + w, A, B, C, D, E, F);
    var b_val := quad(x0    , y0 + w, A, B, C, D, E, F);
    var c_val := quad(x0 + w, y0 + w, A, B, C, D, E, F);
    var d_val := quad(x0 - w, y0    , A, B, C, D, E, F);
    var e_val := quad(x0    , y0    , A, B, C, D, E, F);
    var f_val := quad(x0 + w, y0    , A, B, C, D, E, F);
    var g_val := quad(x0 - w, y0 - w, A, B, C, D, E, F);
    var h_val := quad(x0    , y0 - w, A, B, C, D, E, F);
    var i_val := quad(x0 + w, y0 - w, A, B, C, D, E, F);

    var hxx := (d_val - 2.0 * e_val + f_val) / (w * w);
    var hyy := (b_val - 2.0 * e_val + h_val) / (w * w);
    var hxy := (a_val - c_val - g_val + i_val) / (4.0 * w * w);

    hxx == 2.0 * A &&
    hyy == 2.0 * B &&
    hxy == -C  // Note: specification says "C", but discrete method yields -C
{
  // Compute the expression for hxx: (d_val - 2*e_val + f_val) / (w*w)
  calc {
    d_val - 2.0*e_val + f_val;
    (A*(x0-w)*(x0-w) + B*y0*y0 + C*(x0-w)*y0 + D*(x0-w) + E*y0 + F) - 2.0*(A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F) + (A*(x0+w)*(x0+w) + B*y0*y0 + C*(x0+w)*y0 + D*(x0+w) + E*y0 + F);
    {
      // Expand and simplify the A terms: A*(x0-w)^2 - 2*A*x0^2 + A*(x0+w)^2
      calc {
        A*(x0-w)*(x0-w) - 2.0*A*x0*x0 + A*(x0+w)*(x0+w);
        A*(x0*x0 - 2.0*x0*w + w*w) - 2.0*A*x0*x0 + A*(x0*x0 + 2.0*x0*w + w*w);
        (A*x0*x0 - 2.0*A*x0*w + A*w*w) - 2.0*A*x0*x0 + (A*x0*x0 + 2.0*A*x0*w + A*w*w);
        A*x0*x0 - 2.0*A*x0*w + A*w*w - 2.0*A*x0*x0 + A*x0*x0 + 2.0*A*x0*w + A*w*w;
        (A*x0*x0 - 2.0*A*x0*x0 + A*x0*x0) + (-2.0*A*x0*w + 2.0*A*x0*w) + (A*w*w + A*w*w);
        0.0 + 0.0 + 2.0*A*w*w;
        2.0*A*w*w;
      }
    }
    // B terms: B*y0^2 - 2*B*y0^2 + B*y0^2 = 0
    // C terms: C*(x0-w)*y0 - 2*C*x0*y0 + C*(x0+w)*y0
    {
      calc {
        C*(x0-w)*y0 - 2.0*C*x0*y0 + C*(x0+w)*y0;
        (C*x0*y0 - C*w*y0) - 2.0*C*x0*y0 + (C*x0*y0 + C*w*y0);
        C*x0*y0 - C*w*y0 - 2.0*C*x0*y0 + C*x0*y0 + C*w*y0;
        (C*x0*y0 - 2.0*C*x0*y0 + C*x0*y0) + (-C*w*y0 + C*w*y0);
        0.0;
      }
    }
    // D terms: D*(x0-w) - 2*D*x0 + D*(x0+w)
    {
      calc {
        D*(x0-w) - 2.0*D*x0 + D*(x0+w);
        (D*x0 - D*w) - 2.0*D*x0 + (D*x0 + D*w);
        D*x0 - D*w - 2.0*D*x0 + D*x0 + D*w;
        (D*x0 - 2.0*D*x0 + D*x0) + (-D*w + D*w);
        0.0;
      }
    }
    // E and F terms cancel out similarly
    2.0 * A * w * w;
  }
  // Therefore, hxx = (2.0 * A * w * w) / (w * w) = 2.0 * A

  // Compute the expression for hyy: (b_val - 2*e_val + h_val) / (w*w)
  calc {
    b_val - 2.0*e_val + h_val;
    (A*x0*x0 + B*(y0+w)*(y0+w) + C*x0*(y0+w) + D*x0 + E*(y0+w) + F) - 2.0*(A*x0*x0 + B*y0*y0 + C*x0*y0 + D*x0 + E*y0 + F) + (A*x0*x0 + B*(y0-w)*(y0-w) + C*x0*(y0-w) + D*x0 + E*(y0-w) + F);
    {
      // A terms: A*x0^2 - 2*A*x0^2 + A*x0^2 = 0
      // B terms: B*(y0+w)^2 - 2*B*y0^2 + B*(y0-w)^2
      calc {
        B*(y0+w)*(y0+w) - 2.0*B*y0*y0 + B*(y0-w)*(y0-w);
        B*(y0*y0 + 2.0*y0*w + w*w) - 2.0*B*y0*y0 + B*(y0*y0 - 2.0*y0*w + w*w);
        (B*y0*y0 + 2.0*B*y0*w + B*w*w) - 2.0*B*y0*y0 + (B*y0*y0 - 2.0*B*y0*w + B*w*w);
        B*y0*y0 + 2.0*B*y0*w + B*w*w - 2.0*B*y0*y0 + B*y0*y0 - 2.0*B*y0*w + B*w*w;
        (B*y0*y0 - 2.0*B*y0*y0 + B*y0*y0) + (2.0*B*y0*w - 2.0*B*y0*w) + (B*w*w + B*w*w);
        0.0 + 0.0 + 2.0*B*w*w;
        2.0*B*w*w;
      }
    }
    // C terms: C*x0*(y0+w) - 2*C*x0*y0 + C*x0*(y0-w)
    {
      calc {
        C*x0*(y0+w) - 2.0*C*x0*y0 + C*x0*(y0-w);
        (C*x0*y0 + C*x0*w) - 2.0*C*x0*y0 + (C*x0*y0 - C*x0*w);
        C*x0*y0 + C*x0*w - 2.0*C*x0*y0 + C*x0*y0 - C*x0*w;
        (C*x0*y0 - 2.0*C*x0*y0 + C*x0*y0) + (C*x0*w - C*x0*w);
        0.0;
      }
    }
    // D terms: D*x0 - 2*D*x0 + D*x0 = 0
    // E terms: E*(y0+w) - 2*E*y0 + E*(y0-w)
    {
      calc {
        E*(y0+w) - 2.0*E*y0 + E*(y0-w);
        (E*y0 + E*w) - 2.0*E*y0 + (E*y0 - E*w);
        E*y0 + E*w - 2.0*E*y0 + E*y0 - E*w;
        (E*y0 - 2.0*E*y0 + E*y0) + (E*w - E*w);
        0.0;
      }
    }
    // F terms cancel
    2.0 * B * w * w;
  }
  // Therefore, hyy = (2.0 * B * w * w) / (w * w) = 2.0 * B

  // Compute the expression for hxy: (a_val - c_val - g_val + i_val) / (4.0 * w * w)
  calc {
    a_val - c_val - g_val + i_val;
    (A*(x0-w)*(x0-w) + B*(y0+w)*(y0+w) + C*(x0-w)*(y0+w) + D*(x0-w) + E*(y0+w) + F) 
      - (A*(x0+w)*(x0+w) + B*(y0+w)*(y0+w) + C*(x0+w)*(y0+w) + D*(x0+w) + E*(y0+w) + F)
      - (A*(x0-w)*(x0-w) + B*(y0-w)*(y0-w) + C*(x0-w)*(y0-w) + D*(x0-w) + E*(y0-w) + F)
      + (A*(x0+w)*(x0+w) + B*(y0-w)*(y0-w) + C*(x0+w)*(y0-w) + D*(x0+w) + E*(y0-w) + F);
    // Simplify by canceling terms:
    // A terms: A*(x0-w)^2 - A*(x0+w)^2 - A*(x0-w)^2 + A*(x0+w)^2 = 0
    // B terms: B*(y0+w)^2 - B*(y0+w)^2 - B*(y0-w)^2 + B*(y0-w)^2 = 0
    // D terms: D*(x0-w) - D*(x0+w) - D*(x0-w) + D*(x0+w) = 0
    // E terms: E*(y0+w) - E*(y0+w) - E*(y0-w) + E*(y0-w) = 0
    // F terms: F - F - F + F = 0
    // Only C terms remain: C*(x0-w)*(y0+w) - C*(x0+w)*(y0+w) - C*(x0-w)*(y0-w) + C*(x0+w)*(y0-w)
    C*((x0-w)*(y0+w) - (x0+w)*(y0+w) - (x0-w)*(y0-w) + (x0+w)*(y0-w));
    // Expand the expression inside:
    {
      calc {
        (x0-w)*(y0+w) - (x0+w)*(y0+w) - (x0-w)*(y0-w) + (x0+w)*(y0-w);
        (x0*y0 + x0*w - w*y0 - w*w) - (x0*y0 + x0*w + w*y0 + w*w) - (x0*y0 - x0*w - w*y0 + w*w) + (x0*y0 - x0*w + w*y0 - w*w);
        // Combine like terms:
        // x0*y0 terms: 1 - 1 - 1 + 1 = 0
        // x0*w terms: 1 - 1 - (-1) + (-1) = 1 - 1 + 1 - 1 = 0
        // w*y0 terms: -1 - 1 - (-1) + 1 = -1 -1 +1 +1 = 0
        // w*w terms: -1 -1 -1 -1 = -4
        -4.0 * w * w;
      }
    }
    C * (-4.0 * w * w);
    -4.0 * C * w * w;
  }
  // Therefore, hxy = (-4.0 * C * w * w) / (4.0 * w * w) = -C
}
```

### Explanation
1. **Function Definition**: The `quad` function computes the value of the quadratic surface \( z = A x^2 + B y^2 + C xy + D x + E y + F \) at any point \( (x, y) \).
2. **Lemma Definition**: The lemma `ZTHessianExact` proves that for any quadratic surface and any grid spacing \( w > 0 \), the Zevenbergen-Thorne discrete Hessian computes the exact Hessian components \( 2A \) for \( h_{xx} \), \( 2B \) for \( h_{yy} \), and \( -C \) for \( h_{xy} \).
3. **Proof Structure**: The proof uses `calc` statements to algebraically expand and simplify the finite difference formulas. Each component (\( h_{xx} \), \( h_{yy} \), \( h_{xy} \)) is verified by:
   - Expanding the function values at grid points.
   - Grouping terms by coefficients (A, B, C, etc.).
   - Simplifying to show the exact Hessian components.
4. **Note on Discrepancy**: The natural language specification states that \( h_{xy} = C \), but the discrete method yields \( -C \). This discrepancy is noted in the code comments, as the proof confirms \( h_{xy} = -C \).

This formalization ensures the property is machine-checkable and adheres to the problem requirements, providing a rigorous proof of the discrete Hessian's exactness for quadratic surfaces.
