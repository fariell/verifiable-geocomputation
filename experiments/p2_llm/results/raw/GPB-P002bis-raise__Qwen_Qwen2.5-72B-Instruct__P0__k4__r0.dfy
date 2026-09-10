predicate Is4Neighbor((r1: int, c1: int), (r2: int, c2: int), rows: int, cols: int)
  requires 0 <= r1 < rows
  requires 0 <= c1 < cols
  requires 0 <= r2 < rows
  requires 0 <= c2 < cols
{
  (r1 == r2 && (c1 == c2 - 1 || c1 == c2 + 1)) || (c1 == c2 && (r1 == r2 - 1 || r1 == r2 + 1))
}

method RaiseNbr(h: array2<float>, fill: array2<float>, r: int, c: int)
  requires h != null
  requires fill != null
  requires h.Rows == fill.Rows
  requires h.Cols == fill.Cols
  requires 0 <= r < h.Rows
  requires 0 <= c < h.Cols
  modifies fill
{
  var originalElevation := h[r, c];
  var processedElevation := fill[r, c];
  fill[r, c] := max(originalElevation, processedElevation);
}

lemma RaiseNbrPreservesElevation(h: array2<float>, fill: array2<float>, r: int, c: int)
  requires h != null
  requires fill != null
  requires h.Rows == fill.Rows
  requires h.Cols == fill.Cols
  requires 0 <= r < h.Rows
  requires 0 <= c < h.Cols
  ensures forall r2, c2 :: 0 <= r2 < h.Rows && 0 <= c2 < h.Cols ==> fill[r2, c2] >= h[r2, c2]
{
  var originalElevation := h[r, c];
  var processedElevation := fill[r, c];
  var newElevation := max(originalElevation, processedElevation);

  assert newElevation >= originalElevation;
  assert newElevation >= processedElevation;

  // Prove that the elevation of the neighbor is lifted at least to max(original neighbor, processed cell fill)
  assert forall r2, c2 :: 0 <= r2 < h.Rows && 0 <= c2 < h.Cols && Is4Neighbor((r2, c2), (r, c), h.Rows, h.Cols) ==> fill[r2, c2] >= max(h[r2, c2], fill[r, c]);

  // Prove that raising a 4-neighbor never decreases any cell elevation
  assert forall r2, c2 :: 0 <= r2 < h.Rows && 0 <= c2 < h.Cols ==> fill[r2, c2] >= h[r2, c2];
}

method PitFill2D(h: array2<float>) returns (fill: array2<float>)
  requires h != null
  ensures fill != null
  ensures fill.Rows == h.Rows
  ensures fill.Cols == h.Cols
  ensures forall r, c :: 0 <= r < h.Rows && 0 <= c < h.Cols ==> fill[r, c] >= h[r, c]
{
  var rows := h.Rows;
  var cols := h.Cols;
  fill := new float[rows, cols];

  // Initialize fill with infinity
  for r := 0 to rows - 1 do
    for c := 0 to cols - 1 do
      fill[r, c] := infinity;

  // Seed the boundary cells
  for r := 0 to rows - 1 do
  {
    RaiseNbr(h, fill, r, 0);
    RaiseNbr(h, fill, r, cols - 1);
  }

  for c := 0 to cols - 1 do
  {
    RaiseNbr(h, fill, 0, c);
    RaiseNbr(h, fill, rows - 1, c);
  }

  // Process the interior cells
  var heap: seq<(float, int, int)> := [];
  for r := 0 to rows - 1 do
  {
    for c := 0 to cols - 1 do
    {
      if fill[r, c] < infinity
      {
        heap := heap + [(fill[r, c], r, c)];
      }
    }
  }

  while |heap| > 0
  {
    var (elevation, r, c) := heap[0];
    heap := heap[1..];

    for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]
    {
      var r2 := r + dr;
      var c2 := c + dc;

      if 0 <= r2 < rows && 0 <= c2 < cols && fill[r2, c2] == infinity
      {
        RaiseNbr(h, fill, r2, c2);
        heap := heap + [(fill[r2, c2], r2, c2)];
      }
    }
  }

  // Ensure the property holds for all cells
  assert forall r, c :: 0 <= r < h.Rows && 0 <= c < h.Cols ==> fill[r, c] >= h[r, c];
}

lemma PitFill2DPreservesElevation(h: array2<float>, fill: array2<float>)
  requires h != null
  requires fill != null
  requires h.Rows == fill.Rows
  requires h.Cols == fill.Cols
  ensures forall r, c :: 0 <= r < h.Rows && 0 <= c < h.Cols ==> fill[r, c] >= h[r, c]
{
  // Prove the property for all cells
  assert forall r, c :: 0 <= r < h.Rows && 0 <= c < h.Cols ==> fill[r, c] >= h[r, c];
}
