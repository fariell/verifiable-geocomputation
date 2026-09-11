function f(x: real, y: real, A: real, B: real, C: real, D: real, E: real, F: real): real
{
  A * x * x + B * y * y + C * x * y + D * x + E * y + F
}

lemma ZT_Hessian(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
  requires w > 0.0
  ensures (f(w, 0.0, A, B, C, D, E, F) - 2.0 * f(0.0, 0.0, A, B, C, D, E, F) + f(-w, 0.0, A, B, C, D, E, F)) / (w * w) == 2.0 * A
  ensures (f(0.0, w, A, B, C, D, E, F) - 2.0 * f(0.0, 0.0, A, B, C, D, E, F) + f(0.0, -w, A, B, C, D, E, F)) / (w * w) == 2.0 * B
  ensures (f(w, w, A, B, C, D, E, F) + f(-w, -w, A, B, C, D, E, F) - f(w, -w, A, B, C, D, E, F) - f(-w, w, A, B, C, D, E, F)) / (4.0 * w * w) == C
{
}
