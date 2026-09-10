method pitFill_2d(h: array2<float>) returns (fill: array2<float>)
  requires h != null;
  requires h.Length0 > 0 && h.Length1 > 0;
  ensures fill != null;
  ensures fill.Length0 == h.Length0 && fill.Length1 == h.Length1;
  ensures forall r, c :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 ==> fill[r, c] >= h[r, c];
  ensures forall r, c :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 && (r == 0 || r == fill.Length0 - 1 || c == 0 || c == fill.Length1 - 1) ==> fill[r, c] == h[r, c];
  ensures forall r, c :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 && (0 < r < fill.Length0 - 1 && 0 < c < fill.Length1 - 1) ==> minNbr(fill, r, c) <= fill[r, c];
{
  var rows := h.Length0;
  var cols := h.Length1;
  fill := new float[rows, cols];
  var visited := new bool[rows, cols];

  method seed(r: int, c: int)
    requires 0 <= r < rows && 0 <= c < cols;
    modifies fill, visited;
  {
    if !visited[r, c] {
      fill[r, c] := h[r, c];
      visited[r, c] := true;
      var heap: seq<(float, int, int)> := [(fill[r, c], r, c)];
      while !heap.IsEmpty
        invariant forall r, c :: 0 <= r < rows && 0 <= c < cols && visited[r, c] ==> fill[r, c] >= h[r, c];
        invariant forall r, c :: 0 <= r < rows && 0 <= c < cols && (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) && visited[r, c] ==> fill[r, c] == h[r, c];
        invariant forall r, c :: 0 <= r < rows && 0 <= c < cols && (0 < r < rows - 1 && 0 < c < cols - 1) && visited[r, c] ==> minNbr(fill, r, c) <= fill[r, c];
      {
        var (value, r, c) := heap[0];
        heap := heap[1..];
        for dr, dc in NBR4
          var nr := r + dr;
          var nc := c + dc;
          if 0 <= nr < rows && 0 <= nc < cols && !visited[nr, nc] {
            var new_value := max(h[nr, nc], value);
            fill[nr, nc] := new_value;
            visited[nr, nc] := true;
            heap := heap + [(new_value, nr, nc)];
          }
        }
      }
  }

  for r in 0..rows {
    seed(r, 0);
    seed(r, cols - 1);
  }
  for c in 0..cols {
    seed(0, c);
    seed(rows - 1, c);
  }
}

function minNbr(fill: array2<float>, r: int, c: int): float
  requires 0 <= r < fill.Length0 && 0 <= c < fill.Length1;
  requires 0 < r < fill.Length0 - 1 && 0 < c < fill.Length1 - 1;
{
  var min_value := fill[r - 1, c];
  min_value := min(min_value, fill[r + 1, c]);
  min_value := min(min_value, fill[r, c - 1]);
  min_value := min(min_value, fill[r, c + 1]);
  min_value
}

const NBR4: seq<(int, int)> := [(-1, 0), (1, 0), (0, -1), (0, 1)];
