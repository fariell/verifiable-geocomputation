// Formalization of RaiseNbr step properties
predicate N4(p_i: int, p_j: int, q_i: int, q_j: int)
{
  (q_i == p_i && q_j == p_j - 1) ||
  (q_i == p_i && q_j == p_j + 1) ||
  (q_i == p_i - 1 && q_j == p_j) ||
  (q_i == p_i + 1 && q_j == p_j)
}

lemma RaiseNbrStep(h: array2<real>, fill: array2<real>, p_i: int, p_j: int, n_i: int, n_j: int)
  requires h != null && fill != null
  requires h.Length0 == fill.Length0 && h.Length1 == fill.Length1
  requires 0 <= p_i < h.Length0 && 0 <= p_j < h.Length1
  requires 0 <= n_i < h.Length0 && 0 <= n_j < h.Length1
  requires N4(p_i, p_j, n_i, n_j)
  ensures 
    var new_fill := fill[n_i, n_j := max(h[n_i, n_j], fill[p_i, p_j])];
    // Elevation never decreases
    new_fill[n_i, n_j] >= h[n_i, n_j] &&
    // Neighbor lifted to at least max(original, processed cell)
    new_fill[n_i, n_j] >= max(h[n_i, n_j], fill[p_i, p_j])
{
  // Verification follows directly from assignment semantics
}
