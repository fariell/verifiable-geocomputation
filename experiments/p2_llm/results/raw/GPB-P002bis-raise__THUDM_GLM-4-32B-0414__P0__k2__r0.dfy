// Formal specification of the 2D local raise step RaiseNbr
module RaiseNbrSpec {
  // Represents a 2D grid of elevations
  type Grid = array<array<float>>

  // Represents a cell's coordinates in the grid
  type Cell = (int, int)

  // Represents the 4-neighbors of a cell
  type Neighbors = set<Cell>

  // Function to get the 4-neighbors of a cell
  function method GetNeighbors(p: Cell, rows: int, cols: int): Neighbors {
    var (r, c) := p;
    var neighbors := {};
    if r > 0 { neighbors := neighbors + {(r - 1, c)}; }
    if r < rows - 1 { neighbors := neighbors + {(r + 1, c)}; }
    if c > 0 { neighbors := neighbors + {(r, c - 1)}; }
    if c < cols - 1 { neighbors := neighbors + {(r, c + 1)}; }
    return neighbors;
  }

  // Function to raise a cell's elevation based on its 4-neighbors
  function method RaiseNbr(h: Grid, p: Cell, rows: int, cols: int): float {
    var (r, c) := p;
    var neighbors := GetNeighbors(p, rows, cols);
    var maxNeighbor := 0.0;
    for n in neighbors {
      var (nr, nc) := n;
      if h[nr][nc] > maxNeighbor {
        maxNeighbor := h[nr][nc];
      }
    }
    return max(h[r][c], maxNeighbor);
  }

  // Property to be proven: raising a 4-neighbor from an already-processed cell
  // never decreases any cell elevation, and the neighbor is lifted at least to
  // max(original neighbor, processed cell fill)
  lemma RaiseNbrProperty(h: Grid, p: Cell, rows: int, cols: int)
    requires 0 <= p.0 < rows && 0 <= p.1 < cols
    requires rows > 0 && cols > 0
    ensures RaiseNbr(h, p, rows, cols) >= h[p.0][p.1]
    ensures forall n :: n in GetNeighbors(p, rows, cols) ==> RaiseNbr(h, n, rows, cols) >= max(h[n.0][n.1], h[p.0][p.1])
  {
    var (r, c) := p;
    var neighbors := GetNeighbors(p, rows, cols);
    var maxNeighbor := 0.0;
    for n in neighbors {
      var (nr, nc) := n;
      if h[nr][nc] > maxNeighbor {
        maxNeighbor := h[nr][nc];
      }
    }
    assert RaiseNbr(h, p, rows, cols) >= h[r][c];
    for n in neighbors {
      var (nr, nc) := n;
      assert RaiseNbr(h, n, rows, cols) >= max(h[nr][nc], h[r][c]);
    }
  }
}
