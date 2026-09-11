// P006_watershed.dfy
// Formalization of watershed uniqueness under deterministic D8.

module Watershed {
  // Define the grid and cell types
  type Grid = array2d<int>
  type Cell = (int, int)

  // Define the successor function (d8_at from p005_d8)
  function method d8_at(h: Grid, r: int, c: int): string {
    // Implementation of d8_at would go here
    // For now, we'll use a placeholder
    "NoFlow"
  }

  // Define the delta function to get direction offsets
  function method _delta(name: string): (int, int) {
    // Implementation of _delta would go here
    // For now, we'll use a placeholder
    (0, 0)
  }

  // Define the bounded iterate function (stepN)
  function method stepN(h: Grid, start: Cell, n: int): Cell {
    if n == 0 then start
    else {
      var r, c := start;
      var d := d8_at(h, r, c);
      if d == "NoFlow" then start
      else {
        var dp, dq := _delta(d);
        var nr, nc := r + dq, c + dp;
        if not (0 <= nr < h.Length1 && 0 <= nc < h.Length2) then start
        else stepN(h, (nr, nc), n - 1)
      }
    }
  }

  // Define the fixed point function (follow_d8)
  function method follow_d8(h: Grid, r: int, c: int, max_steps: int): (bool, Cell, list<Cell>) {
    var path := list<Cell>[(r, c)];
    var i := 0;
    while i < max_steps
      invariant path.Length <= i + 1
      invariant forall j :: 0 <= j < i ==> path[j] != path[j + 1]
    {
      var d := d8_at(h, r, c);
      if d == "NoFlow" then return (true, (r, c), path)
      var dp, dq := _delta(d);
      var nr, nc := r + dq, c + dp;
      if not (0 <= nr < h.Length1 && 0 <= nc < h.Length2) then return (true, (r, c), path)
      r, c := nr, nc;
      path := path + list<Cell>[(r, c)];
      i := i + 1;
    }
    return (false, (r, c), path)
  }

  // The main theorem: watershed uniqueness
  lemma WatershedUniqueness(h: Grid, start: Cell, n1: int, n2: int)
    requires 0 <= n1 <= h.Length1 * h.Length2
    requires 0 <= n2 <= h.Length1 * h.Length2
    requires n1 < h.Length1 * h.Length2 || n2 < h.Length1 * h.Length2
    ensures stepN(h, start, n1) == stepN(h, start, n2)
  {
    // Base case: if n1 == n2, the result is trivial
    if n1 == n2 then return;
    
    // Inductive case: assume the property holds for all k < n1 and k < n2
    // and prove it for n1 and n2
    
    // We'll use the fact that the successor function is deterministic
    // and that the grid is finite to show that the outlets must be equal
    
    // First, compute the outlets for n1 and n2
    var outlet1 := stepN(h, start, n1);
    var outlet2 := stepN(h, start, n2);
    
    // Now, we need to show that outlet1 == outlet2
    
    // If n1 == n2, we're done
    if n1 == n2 then return;
    
    // Otherwise, we'll use the fact that the successor function is deterministic
    // and that the grid is finite to show that the outlets must be equal
    
    // We'll use induction on the number of steps
    
    // Base case: if n1 == 0 or n2 == 0, then the outlet is the start cell
    if n1 == 0 || n2 == 0 then {
      if n1 == 0 then {
        assert outlet1 == start;
        assert outlet2 == start;
        return;
      } else {
        assert outlet1 == start;
        assert outlet2 == start;
        return;
      }
    }
    
    // Inductive case: assume the property holds for n1 - 1 and n2 - 1
    // and prove it for n1 and n2
    
    // Compute the outlets for n1 - 1 and n2 - 1
    var outlet1_prev := stepN(h, start, n1 - 1);
    var outlet2_prev := stepN(h, start, n2 - 1);
    
    // By the induction hypothesis, outlet1_prev == outlet2_prev
    // So, the next step from outlet1_prev and outlet2_prev must be the same
    // because the successor function is deterministic
    
    // Compute the next step from outlet1_prev and outlet2_prev
    var d1 := d8_at(h, outlet1_prev._0, outlet1_prev._1);
    var d2 := d8_at(h, outlet2_prev._0, outlet2_prev._1);
    
    // Since the successor function is deterministic, d1 == d2
    assert d1 == d2;
    
    // Compute the next cell from outlet1_prev and outlet2_prev
    var dp, dq := _delta(d1);
    var nr1, nc1 := outlet1_prev._0 + dq, outlet1_prev._1 + dp;
    var nr2, nc2 := outlet2_prev._0 + dq, outlet2_prev._1 + dp;
    
    // If the next cell is out of bounds, then the outlet is the current cell
    if not (0 <= nr1 < h.Length1 && 0 <= nc1 < h.Length2) then {
      assert outlet1 == outlet1_prev;
      assert outlet2 == outlet2_prev;
      return;
    }
    if not (0 <= nr2 < h.Length2 && 0 <= nc2 < h.Length2) then {
      assert outlet1 == outlet1_prev;
      assert outlet2 == outlet2_prev;
      return;
    }
    
    // Otherwise, the next cell is the outlet
    assert outlet1 == (nr1, nc1);
    assert outlet2 == (nr2, nc2);
    
    // Since outlet1_prev == outlet2_prev and the successor function is deterministic,
    // the next cell must be the same
    assert (nr1, nc1) == (nr2, nc2);
    
    // Therefore, outlet1 == outlet2
    return;
  }
}
