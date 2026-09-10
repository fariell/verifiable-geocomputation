method pitFill2D(h: array2<float>) returns (fill: array2<float>)
  requires h != null && h.Length0 > 0 && h.Length1 > 0
  ensures fill != null && fill.Length0 == h.Length0 && fill.Length1 == h.Length1
  ensures forall r: int, c: int :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 ==> fill[r, c] >= h[r, c]
  ensures forall r: int, c: int :: 0 < r < fill.Length0 - 1 && 0 < c < fill.Length1 - 1 ==> 
    (minNbr4(fill, r, c) <= fill[r, c])
{
  var rows := h.Length0;
  var cols := h.Length1;
  fill := new float(rows, cols);
  var visited := new bool(rows, cols);

  method seed(r: int, c: int)
    requires 0 <= r < rows && 0 <= c < cols
    modifies fill, visited
    ensures fill[r, c] == h[r, c]
    ensures visited[r, c]
  {
    if !visited[r, c] {
      fill[r, c] := h[r, c];
      visited[r, c] := true;
    }
  }

  var heap: seq<(float, int, int)> := [];
  for r := 0 to rows - 1 {
    seed(r, 0);
    seed(r, cols - 1);
  }
  for c := 0 to cols - 1 {
    seed(0, c);
    seed(rows - 1, c);
  }

  while heap != [] {
    var (elevation, r, c) := heap[0];
    heap := heap[1..];
    for dr, dc in NBR4 {
      var nr := r + dr;
      var nc := c + dc;
      if 0 <= nr < rows && 0 <= nc < cols && !visited[nr, nc] {
        var newElevation := max(h[nr, nc], fill[r, c]);
        fill[nr, nc] := newElevation;
        visited[nr, nc] := true;
        heap := heap + [(newElevation, nr, nc)];
      }
    }
  }
}

function minNbr4(fill: array2<float>, r: int, c: int): float
  requires 0 < r < fill.Length0 - 1 && 0 < c < fill.Length1 - 1
{
  var minElevation := fill[r - 1, c];
  minElevation := min(minElevation, fill[r + 1, c]);
  minElevation := min(minElevation, fill[r, c - 1]);
  minElevation := min(minElevation, fill[r, c + 1]);
  return minElevation;
}

lemma pitFill2DProperties(h: array2<float>)
  requires h != null && h.Length0 > 0 && h.Length1 > 0
  ensures forall r: int, c: int :: 0 <= r < h.Length0 && 0 <= c < h.Length1 ==> 
    (pitFill2D(h)[r, c] >= h[r, c])
  ensures forall r: int, c: int :: 0 < r < h.Length0 - 1 && 0 < c < h.Length1 - 1 ==> 
    (minNbr4(pitFill2D(h), r, c) <= pitFill2D(h)[r, c])
{
  var fill := pitFill2D(h);
  var rows := h.Length0;
  var cols := h.Length1;

  // Prove that each cell in the filled grid is at least as high as the original
  forall r, c | 0 <= r < rows && 0 <= c < cols
    ensures fill[r, c] >= h[r, c]
  {
    if r == 0 || r == rows - 1 || c == 0 || c == cols - 1 {
      assert fill[r, c] == h[r, c]; // Boundary cells are seeded with their original values
    } else {
      // Interior cells are filled with the maximum of their original value and the value of a filled neighbor
      var minElevation := minNbr4(fill, r, c);
      assert fill[r, c] >= minElevation;
      assert minElevation >= h[r, c];
      assert fill[r, c] >= h[r, c];
    }
  }

  // Prove that each cell with a 4-neighbour has min(nbr) ≤ cell
  forall r, c | 0 < r < rows - 1 && 0 < c < cols - 1
    ensures minNbr4(fill, r, c) <= fill[r, c]
  {
    var minElevation := minNbr4(fill, r, c);
    assert minElevation <= fill[r, c];
  }
}
