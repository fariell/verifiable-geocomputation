method pitFill_2D(h: array2<float>) returns (fill: array2<float>)
  requires h != null;
  requires h.Length0 > 0 && h.Length1 > 0;
  ensures fill != null;
  ensures fill.Length0 == h.Length0 && fill.Length1 == h.Length1;
  ensures forall r: int, c: int :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 ==> fill[r, c] >= h[r, c];
  ensures forall r: int, c: int :: 0 < r < fill.Length0 - 1 && 0 < c < fill.Length1 - 1 ==> 
    (forall dr: int, dc: int :: (dr, dc) in NBR4 ==> fill[r + dr, c + dc] <= fill[r, c]);
{
  var rows := h.Length0;
  var cols := h.Length1;
  fill := new float[rows, cols];
  var visited := new bool[rows, cols];

  method seed(r: int, c: int)
    requires 0 <= r < rows && 0 <= c < cols;
    modifies fill, visited;
    ensures fill[r, c] == h[r, c];
    ensures visited[r, c];
  {
    if !visited[r, c] {
      fill[r, c] := h[r, c];
      visited[r, c] := true;
      var heap: seq<(float, int, int)> := [];
      heap := heap + (fill[r, c], r, c);
      while heap != []
        invariant forall r: int, c: int :: 0 <= r < rows && 0 <= c < cols && visited[r, c] ==> fill[r, c] >= h[r, c];
        decreases heap.Length;
      {
        var (value, r, c) := heap[0];
        heap := heap[1..];
        for dr, dc in NBR4 {
          var nr := r + dr;
          var nc := c + dc;
          if 0 <= nr < rows && 0 <= nc < cols && !visited[nr, nc] {
            fill[nr, nc] := max(h[nr, nc], value);
            visited[nr, nc] := true;
            heap := heap + (fill[nr, nc], nr, nc);
          }
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

  // Ensure the fill is non-decreasing
  for r in 0..rows {
    for c in 0..cols {
      if 0 < r < rows - 1 && 0 < c < cols - 1 {
        for dr, dc in NBR4 {
          assert fill[r + dr, c + dc] <= fill[r, c];
        }
      }
    }
  }
}

lemma NBR4_is_4_connected()
  ensures forall dr: int, dc: int :: (dr, dc) in NBR4 ==> -1 <= dr <= 1 && -1 <= dc <= 1 && (dr != 0 || dc != 0);
{
  assert NBR4 == [(-1, 0), (1, 0), (0, -1), (0, 1)];
}

lemma pitFill_2D_non_decreasing(h: array2<float>, fill: array2<float>)
  requires h != null && fill != null;
  requires h.Length0 == fill.Length0 && h.Length1 == fill.Length1;
  requires forall r: int, c: int :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 ==> fill[r, c] >= h[r, c];
  requires forall r: int, c: int :: 0 < r < fill.Length0 - 1 && 0 < c < fill.Length1 - 1 ==> 
    (forall dr: int, dc: int :: (dr, dc) in NBR4 ==> fill[r + dr, c + dc] <= fill[r, c]);
  ensures forall r: int, c: int :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 ==> 
    (forall dr: int, dc: int :: (dr, dc) in NBR4 ==> fill[r + dr, c + dc] <= fill[r, c]);
{
  var rows := h.Length0;
  var cols := h.Length1;

  // Prove the boundary conditions
  for r in 0..rows {
    for c in 0..cols {
      if r == 0 || r == rows - 1 || c == 0 || c == cols - 1 {
        for dr, dc in NBR4 {
          var nr := r + dr;
          var nc := c + dc;
          if 0 <= nr < rows && 0 <= nc < cols {
            assert fill[nr, nc] >= h[nr, nc];
            assert fill[r, c] == h[r, c];
            assert fill[nr, nc] >= h[nr, nc] && h[nr, nc] <= fill[r, c];
            assert fill[nr, nc] <= fill[r, c];
          }
        }
      }
    }
  }

  // Prove the interior conditions
  for r in 1..rows - 1 {
    for c in 1..cols - 1 {
      for dr, dc in NBR4 {
        var nr := r + dr;
        var nc := c + dc;
        if 0 <= nr < rows && 0 <= nc < cols {
          assert fill[nr, nc] >= h[nr, nc];
          assert fill[r, c] >= h[r, c];
          assert fill[nr, nc] <= fill[r, c];
        }
      }
    }
  }
}

const NBR4: seq<(int, int)> := [(-1, 0), (1, 0), (0, -1), (0, 1)];

method main() {
  var h: array2<float> := new float[5, 5];
  for r in 0..5 {
    for c in 0..5 {
      h[r, c] := 0.0;
    }
  }
  h[2, 2] := 1.0;

  var fill: array2<float> := pitFill_2D(h);

  // Print the original and filled DEM
  print "Original DEM:\n";
  for r in 0..5 {
    for c in 0..5 {
      print h[r, c], " ";
    }
    print "\n";
  }

  print "Filled DEM:\n";
  for r in 0..5 {
    for c in 0..5 {
      print fill[r, c], " ";
    }
    print "\n";
  }

  // Verify the properties
  assert forall r: int, c: int :: 0 <= r < fill.Length0 && 0 <= c < fill.Length1 ==> fill[r, c] >= h[r, c];
  assert forall r: int, c: int :: 0 < r < fill.Length0 - 1 && 0 < c < fill.Length1 - 1 ==> 
    (forall dr: int, dc: int :: (dr, dc) in NBR4 ==> fill[r + dr, c + dc] <= fill[r, c]);
}
