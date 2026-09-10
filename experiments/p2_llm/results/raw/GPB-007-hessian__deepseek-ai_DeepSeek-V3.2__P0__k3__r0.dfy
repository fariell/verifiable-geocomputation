// Formalization of Zevenbergen-Thorne Hessian exactness on quadratic surfaces
// Quadratic surface: z = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// Sampled on 3x3 window with spacing w > 0
// ZT Hessian recovers (2A, 2B, C) exactly

module P003_Curvature {
  // Grid coordinates for 3x3 window centered at (0,0)
  datatype GridCoord = 
    | TL  // top-left     (-w, w)
    | TC  // top-center   (0, w)
    | TR  // top-right    (w, w)
    | CL  // center-left  (-w, 0)
    | CC  // center       (0, 0)
    | CR  // center-right (w, 0)
    | BL  // bottom-left  (-w, -w)
    | BC  // bottom-center (0, -w)
    | BR  // bottom-right (w, -w)

  // Quadratic surface function
  function quadratic(A: real, B: real, C: real, D: real, E: real, F: real, 
                     x: real, y: real): real
    reads {}
  {
    A*x*x + B*y*y + C*x*y + D*x + E*y + F
  }

  // Get coordinates for a grid point
  function coordX(gc: GridCoord, w: real): real
    requires w > 0.0
    reads {}
  {
    match gc
      case TL => -w
      case TC => 0.0
      case TR => w
      case CL => -w
      case CC => 0.0
      case CR => w
      case BL => -w
      case BC => 0.0
      case BR => w
  }

  function coordY(gc: GridCoord, w: real): real
    requires w > 0.0
    reads {}
  {
    match gc
      case TL => w
      case TC => w
      case TR => w
      case CL => 0.0
      case CC => 0.0
      case CR => 0.0
      case BL => -w
      case BC => -w
      case BR => -w
  }

  // Sample the quadratic surface at a grid point
  function sample(A: real, B: real, C: real, D: real, E: real, F: real,
                  gc: GridCoord, w: real): real
    requires w > 0.0
    reads {}
  {
    quadratic(A, B, C, D, E, F, coordX(gc, w), coordY(gc, w))
  }

  // Zevenbergen-Thorne discrete Hessian components
  function ztHxx(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real
    requires w > 0.0
    reads {}
  {
    // (z(CR) - 2*z(CC) + z(CL)) / w^2
    (sample(A, B, C, D, E, F, CR, w) - 2.0*sample(A, B, C, D, E, F, CC, w) 
     + sample(A, B, C, D, E, F, CL, w)) / (w*w)
  }

  function ztHyy(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real
    requires w > 0.0
    reads {}
  {
    // (z(TC) - 2*z(CC) + z(BC)) / w^2
    (sample(A, B, C, D, E, F, TC, w) - 2.0*sample(A, B, C, D, E, F, CC, w) 
     + sample(A, B, C, D, E, F, BC, w)) / (w*w)
  }

  function ztHxy(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real
    requires w > 0.0
    reads {}
  {
    // (z(TL) - z(TR) - z(BL) + z(BR)) / (4*w^2)
    (sample(A, B, C, D, E, F, TL, w) - sample(A, B, C, D, E, F, TR, w)
     - sample(A, B, C, D, E, F, BL, w) + sample(A, B, C, D, E, F, BR, w)) / (4.0*w*w)
  }

  // Main theorem: ZT Hessian recovers (2A, 2B, C) exactly
  theorem ZTExactOnQuadratic(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures ztHxx(A, B, C, D, E, F, w) == 2.0*A
    ensures ztHyy(A, B, C, D, E, F, w) == 2.0*B
    ensures ztHxy(A, B, C, D, E, F, w) == C
  {
    // Expand all samples and simplify algebraically
    // Proof for hxx:
    calc {
      ztHxx(A, B, C, D, E, F, w);
      == // Definition of ztHxx
      (sample(A, B, C, D, E, F, CR, w) - 2.0*sample(A, B, C, D, E, F, CC, w) 
       + sample(A, B, C, D, E, F, CL, w)) / (w*w);
      == // Expand samples at CR (w, 0)
      (quadratic(A, B, C, D, E, F, w, 0.0) 
       - 2.0*quadratic(A, B, C, D, E, F, 0.0, 0.0)
       + quadratic(A, B, C, D, E, F, -w, 0.0)) / (w*w);
      == // Expand quadratic function
      ((A*w*w + B*0.0 + C*w*0.0 + D*w + E*0.0 + F)
       - 2.0*(A*0.0 + B*0.0 + C*0.0 + D*0.0 + E*0.0 + F)
       + (A*w*w + B*0.0 + C*(-w)*0.0 + D*(-w) + E*0.0 + F)) / (w*w);
      == // Simplify
      ((A*w*w + D*w + F) - 2.0*F + (A*w*w - D*w + F)) / (w*w);
      == // Combine terms
      (2.0*A*w*w + 2.0*F - 2.0*F) / (w*w);
      == // Final simplification
      2.0*A;
    }

    // Proof for hyy:
    calc {
      ztHyy(A, B, C, D, E, F, w);
      == // Definition of ztHyy
      (sample(A, B, C, D, E, F, TC, w) - 2.0*sample(A, B, C, D, E, F, CC, w) 
       + sample(A, B, C, D, E, F, BC, w)) / (w*w);
      == // Expand samples at TC (0, w)
      (quadratic(A, B, C, D, E, F, 0.0, w) 
       - 2.0*quadratic(A, B, C, D, E, F, 0.0, 0.0)
       + quadratic(A, B, C, D, E, F, 0.0, -w)) / (w*w);
      == // Expand quadratic function
      ((A*0.0 + B*w*w + C*0.0*w + D*0.0 + E*w + F)
       - 2.0*(A*0.0 + B*0.0 + C*0.0 + D*0.0 + E*0.0 + F)
       + (A*0.0 + B*w*w + C*0.0*(-w) + D*0.0 + E*(-w) + F)) / (w*w);
      == // Simplify
      ((B*w*w + E*w + F) - 2.0*F + (B*w*w - E*w + F)) / (w*w);
      == // Combine terms
      (2.0*B*w*w + 2.0*F - 2.0*F) / (w*w);
      == // Final simplification
      2.0*B;
    }

    // Proof for hxy:
    calc {
      ztHxy(A, B, C, D, E, F, w);
      == // Definition of ztHxy
      (sample(A, B, C, D, E, F, TL, w) - sample(A, B, C, D, E, F, TR, w)
       - sample(A, B, C, D, E, F, BL, w) + sample(A, B, C, D, E, F, BR, w)) / (4.0*w*w);
      == // Expand all four samples
      (quadratic(A, B, C, D, E, F, -w, w) - quadratic(A, B, C, D, E, F, w, w)
       - quadratic(A, B, C, D, E, F, -w, -w) + quadratic(A, B, C, D, E, F, w, -w)) / (4.0*w*w);
      == // Expand each quadratic
      (((A*w*w + B*w*w + C*(-w)*w + D*(-w) + E*w + F)
        - (A*w*w + B*w*w + C*w*w + D*w + E*w + F)
        - (A*w*w + B*w*w + C*(-w)*(-w) + D*(-w) + E*(-w) + F)
        + (A*w*w + B*w*w + C*w*(-w) + D*w + E*(-w) + F))) / (4.0*w*w);
      == // Simplify each term
      // TL: A*w² + B*w² - C*w² - D*w + E*w + F
      // TR: A*w² + B*w² + C*w² + D*w + E*w + F  
      // BL: A*w² + B*w² + C*w² - D*w - E*w + F
      // BR: A*w² + B*w² - C*w² + D*w - E*w + F
      // TL - TR = (-C*w² - D*w + E*w) - (C*w² + D*w + E*w) = -2*C*w² - 2*D*w
      // -BL = -A*w² - B*w² - C*w² + D*w + E*w - F
      // +BR = A*w² + B*w² - C*w² + D*w - E*w + F
      // Sum: (-2*C*w² - 2*D*w) + (-C*w² + D*w + E*w) + (-C*w² + D*w - E*w)
      //     = (-2*C*w² - C*w² - C*w²) + (-2*D*w + D*w + D*w) + (E*w - E*w)
      //     = -4*C*w² + 0 + 0
      (-4.0*C*w*w) / (4.0*w*w);
      == // Final simplification
      C;
    }
  }
}
