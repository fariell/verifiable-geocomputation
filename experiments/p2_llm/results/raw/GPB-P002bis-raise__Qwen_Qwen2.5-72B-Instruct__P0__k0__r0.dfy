predicate Is4Neighbor((r1: int, c1: int), (r2: int, c2: int))
  requires 0 <= r1 < rows
  requires 0 <= c1 < cols
  requires 0 <= r2 < rows
  requires 0 <= c2 < cols
{
  (r1 == r2 + 1 && c1 == c2) ||
  (r1 == r2 - 1 && c1 == c2) ||
  (r1 == r2 && c1 == c2 + 1) ||
  (r1 == r2 && c1 == c2 - 1)
}

predicate IsBoundary(r: int, c: int)
  requires 0 <= r < rows
  requires 0 <= c < cols
{
  r == 0 || r == rows - 1 || c == 0 || c == cols - 1
}

predicate IsInterior(r: int, c: int)
  requires 0 <= r < rows
  requires 0 <= c < cols
{
  0 < r < rows - 1 && 0 < c < cols - 1
}

function method Max(a: real, b: real): real
{
  if a > b then a else b
}

predicate IsPitFilled(h: array2<real>, fill: array2<real>)
  requires h != null
  requires fill != null
  requires h.Dim0 == fill.Dim0
  requires h.Dim1 == fill.Dim1
{
  forall r, c | 0 <= r < h.Dim0 && 0 <= c < h.Dim1 :: 
    (IsBoundary(r, c) ==> fill[r, c] == h[r, c]) &&
    (IsInterior(r, c) ==> 
      forall r2, c2 | Is4Neighbor((r, c), (r2, c2)) :: 
        fill[r2, c2] <= fill[r, c] && fill[r, c] >= Max(h[r, c], fill[r2, c2])
    )
}

method RaiseNbr(h: array2<real>, fill: array2<real>, r: int, c: int)
  modifies fill
  requires h != null
  requires fill != null
  requires h.Dim0 == fill.Dim0
  requires h.Dim1 == fill.Dim1
  requires 0 <= r < h.Dim0
  requires 0 <= c < h.Dim1
  requires IsInterior(r, c)
  requires IsPitFilled(h, fill)
  ensures IsPitFilled(h, fill)
  ensures forall r2, c2 | Is4Neighbor((r, c), (r2, c2)) :: fill[r2, c2] >= fill[r2, c2]@pre
  ensures fill[r, c] >= Max(h[r, c], fill[r, c]@pre)
{
  var originalElevation := h[r, c];
  var processedCellFill := fill[r, c];
  var newElevation := Max(originalElevation, processedCellFill);

  fill[r, c] := newElevation;

  // Ensure that the neighbor is lifted at least to max(original neighbor, processed cell fill)
  forall r2, c2 | Is4Neighbor((r, c), (r2, c2)) {
    fill[r2, c2] := Max(fill[r2, c2], newElevation);
  }
}

method PitFill2D(h: array2<real>) returns (fill: array2<real>)
  requires h != null
  ensures IsPitFilled(h, fill)
{
  var rows := h.Dim0;
  var cols := h.Dim1;
  fill := new real[rows, cols];

  // Initialize fill with infinity
  for r := 0 to rows - 1 {
    for c := 0 to cols - 1 {
      fill[r, c] := infinity;
    }
  }

  // Seed the boundary cells
  for r := 0 to rows - 1 {
    if IsBoundary(r, 0) {
      fill[r, 0] := h[r, 0];
    }
    if IsBoundary(r, cols - 1) {
      fill[r, cols - 1] := h[r, cols - 1];
    }
  }
  for c := 0 to cols - 1 {
    if IsBoundary(0, c) {
      fill[0, c] := h[0, c];
    }
    if IsBoundary(rows - 1, c) {
      fill[rows - 1, c] := h[rows - 1, c];
    }
  }

  // Use a priority queue to process cells
  var heap := new Heap<(real, int, int)>();
  for r := 0 to rows - 1 {
    for c := 0 to cols - 1 {
      if IsBoundary(r, c) {
        heap.Add((fill[r, c], r, c));
      }
    }
  }

  while !heap.IsEmpty {
    var (elevation, r, c) := heap.RemoveMin();
    for (dr, dc) in NBR4 {
      var r2 := r + dr;
      var c2 := c + dc;
      if 0 <= r2 < rows && 0 <= c2 < cols && fill[r2, c2] == infinity {
        fill[r2, c2] := Max(h[r2, c2], elevation);
        heap.Add((fill[r2, c2], r2, c2));
      }
    }
  }
}

const NBR4: set<(int, int)> := { (-1, 0), (1, 0), (0, -1), (0, 1) };
const infinity: real := 1000000000000.0; // A large number representing infinity

lemma PitFill2DPreservesElevation(h: array2<real>, fill: array2<real>, r: int, c: int)
  requires h != null
  requires fill != null
  requires h.Dim0 == fill.Dim0
  requires h.Dim1 == fill.Dim1
  requires 0 <= r < h.Dim0
  requires 0 <= c < h.Dim1
  requires IsInterior(r, c)
  requires IsPitFilled(h, fill)
{
  var originalElevation := h[r, c];
  var processedCellFill := fill[r, c];
  var newElevation := Max(originalElevation, processedCellFill);

  // Ensure that the neighbor is lifted at least to max(original neighbor, processed cell fill)
  forall r2, c2 | Is4Neighbor((r, c), (r2, c2)) {
    assert fill[r2, c2] >= fill[r2, c2]@pre;
    assert fill[r2, c2] >= Max(h[r2, c2], fill[r, c]@pre);
  }

  // Ensure that the processed cell fill is not decreased
  assert fill[r, c] >= processedCellFill;
  assert fill[r, c] >= Max(h[r, c], fill[r, c]@pre);
}
