// Formal specification of the 2D local raise step RaiseNbr
module RaiseNbr {
  // Represents a 2D grid of elevations
  type Grid = array<array<float>>

  // 4-neighbors of a cell (up, down, left, right)
  const NBR4: (int, int)[] = [(-1, 0), (1, 0), (0, -1), (0, 1)]

  // Raises a 4-neighbor from an already-processed cell
  method RaiseNbr(h: Grid, p: (int, int), n: (int, int)) returns (h': Grid)
    requires 0 <= p.0 < h.Length && 0 <= p.1 < h[p.0].Length
    requires 0 <= n.0 < h.Length && 0 <= n.1 < h[n.0].Length
    requires (n.0 == p.0 + 1 || n.0 == p.0 - 1 || n.0 == p.0) && (n.1 == p.1 + 1 || n.1 == p.1 - 1 || n.1 == p.1)
    requires h[p.0][p.1] == float.PositiveInfinity // Already processed cell
    ensures h'.Length == h.Length
    ensures forall i :: 0 <= i < h.Length ==> h'[i].Length == h[i].Length
    ensures forall i, j :: 0 <= i < h.Length && 0 <= j < h[i].Length && (i, j) != n ==> h'[i][j] == h[i][j]
    ensures h'[n.0][n.1] >= h[n.0][n.1] // Never decreases any cell elevation
    ensures h'[n.0][n.1] >= max(h[n.0][n.1], h[p.0][p.1]) // Lifted at least to max(original neighbor, processed cell fill)
  {
    var h' := h;
    h'[n.0][n.1] := max(h[n.0][n.1], h[p.0][p.1]);
    return h';
  }

  // Helper function to compute the maximum of two values
  function method max(a: float, b: float): float
    ensures max(a, b) >= a
    ensures max(a, b) >= b
  {
    if a >= b then a else b
  }

  // Verification of the property
  lemma RaiseNbrProperty()
  {
    var h: Grid := new array<array<float>>(3, 3);
    h[0][0] := 1.0;
    h[0][1] := 2.0;
    h[0][2] := 3.0;
    h[1][0] := 4.0;
    h[1][1] := float.PositiveInfinity; // Already processed cell
    h[1][2] := 6.0;
    h[2][0] := 7.0;
    h[2][1] := 8.0;
    h[2][2] := 9.0;

    var p := (1, 1);
    var n := (1, 0);

    var h' := RaiseNbr(h, p, n);

    assert h'[n.0][n.1] >= h[n.0][n.1]; // Never decreases any cell elevation
    assert h'[n.0][n.1] >= max(h[n.0][n.1], h[p.0][p.1]); // Lifted at least to max(original neighbor, processed cell fill)
  }
}
