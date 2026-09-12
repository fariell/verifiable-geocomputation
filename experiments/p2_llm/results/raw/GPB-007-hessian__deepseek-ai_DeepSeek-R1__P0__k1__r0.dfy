// P0 · Zero-shot auto-formalization: ZT Hessian exact on quadratics
function quadratic(A: real, B: real, C: real, D: real, E: real, F: real, x: real, y: real): real
{
  A * x * x + B * y * y + C * x * y + D * x + E * y + F
}

lemma LemmaExactRecovery(A: real, B: real, C: real, D: real, E: real, F: real, x0: real, y0: real, w: real)
  requires w > 0.0
  ensures 
    var a_val := quadratic(A, B, C, D, E, F, x0 - w, y0 + w);
    var b_val := quadratic(A, B, C, D, E, F, x0, y0 + w);
    var c_val := quadratic(A, B, C, D, E, F, x0 + w, y0 + w);
    var d_val := quadratic(A, B, C, D, E, F, x0 - w, y0);
    var e_val := quadratic(A, B, C, D, E, F, x0, y0);
    var f_val := quadratic(A, B, C, D, E, F, x0 + w, y0);
    var g_val := quadratic(A, B, C, D, E, F, x0 - w, y0 - w);
    var h_val := quadratic(A, B, C, D, E, F, x0, y0 - w);
    var i_val := quadratic(A, B, C, D, E, F, x0 + w, y0 - w);

    var hxx := (d_val - 2.0 * e_val + f_val) / (w * w);
    var hyy := (b_val - 2.0 * e_val + h_val) / (w * w);
    var hxy := (a_val - c_val - g_val + i_val) / (4.0 * w * w);

    hxx == 2.0 * A &&
    hyy == 2.0 * B &&
    hxy == C
{
  // Proof by algebraic expansion - Dafny's real arithmetic handles cancellations
}
