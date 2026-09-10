// Formalization of RaiseNbr property from W&L pit-filling algorithm
// The property: raising a 4-neighbor from an already-processed cell never decreases
// any cell elevation, and the neighbor is lifted at least to max(original neighbor,
// processed cell fill).

module PCOMP1_RaiseNbr {
  // Grid dimensions
  const rows: int
  const cols: int
  ghost predicate ValidGrid() {
    rows > 0 && cols > 0
  }

  // Elevation type (real numbers for DEM)
  type Elevation = real

  // Grid coordinates
  type Coord = (int, int)
  predicate InGrid(r: int, c: int) {
    0 <= r < rows && 0 <= c < cols
  }

  // 4-neighbor offsets
  const NBR4: seq<Coord> := [(-1, 0), (1, 0), (0, -1), (0, 1)]
  predicate Is4Neighbor(p: Coord, q: Coord) {
    exists dir | 0 <= dir < |NBR4| ::
      q.0 == p.0 + NBR4[dir].0 && q.1 == p.1 + NBR4[dir].1
  }

  // Original DEM elevations (immutable)
  const original: array2<Elevation>
  ghost predicate ValidOriginal() {
    original.Length0 == rows && original.Length1 == cols
  }

  // Fill elevations (mutable during algorithm)
  var fill: array2<Elevation>
  ghost predicate ValidFill() {
    fill.Length0 == rows && fill.Length1 == cols
  }

  // Processed flag
  var processed: array2<bool>
  ghost predicate ValidProcessed() {
    processed.Length0 == rows && processed.Length1 == cols
  }

  // State invariant
  predicate StateInvariant() {
    ValidGrid() &&
    ValidOriginal() &&
    ValidFill() &&
    ValidProcessed() &&
    (forall r, c | InGrid(r, c) :: 
      fill[r, c] >= original[r, c])  // Fill never lower than original
  }

  // The RaiseNbr operation
  method RaiseNbr(p_r: int, p_c: int, n_r: int, n_c: int)
    requires StateInvariant()
    requires InGrid(p_r, p_c) && InGrid(n_r, n_c)
    requires Is4Neighbor((p_r, p_c), (n_r, n_c))
    requires processed[p_r, p_c] == true  // p is already processed
    modifies fill
    ensures StateInvariant()
    ensures fill[n_r, n_c] >= old(fill[n_r, n_c])  // Never decreases neighbor
    ensures fill[n_r, n_c] >= original[n_r, n_c]   // Preserves original lower bound
    ensures fill[n_r, n_c] >= max(original[n_r, n_c], old(fill[p_r, p_c]))
    // Additional property: no other cell changes
    ensures forall r, c | InGrid(r, c) && (r != n_r || c != n_c) ::
      fill[r, c] == old(fill[r, c])
  {
    // Implementation of the W&L rule: max(original[n], fill[p])
    var newElev := max(original[n_r, n_c], fill[p_r, p_c]);
    
    // Update only if it raises the neighbor
    if newElev > fill[n_r, n_c] {
      fill[n_r, n_c] := newElev;
    }
    
    // Proof of properties
    assert fill[n_r, n_c] >= old(fill[n_r, n_c]) by {
      // Case 1: we updated to newElev, which is >= old(fill[p_r, p_c]) >= ?
      // Actually simpler: newElev >= original[n_r, n_c] >= old(fill[n_r, n_c]) 
      // by StateInvariant? Wait, StateInvariant says fill >= original, not original >= fill.
      // Let's do case analysis:
      if newElev > old(fill[n_r, n_c]) {
        // We updated
        assert fill[n_r, n_c] == newElev;
        // newElev >= original[n_r, n_c] by definition of max
        // old(fill[n_r, n_c]) >= original[n_r, n_c] by StateInvariant
        // So newElev >= original[n_r, n_c] <= old(fill[n_r, n_c]) doesn't give ordering.
        // Actually: newElev = max(original[n_r, n_c], old(fill[p_r, p_c]))
        // So newElev >= original[n_r, n_c] AND newElev >= old(fill[p_r, p_c])
        // But we need newElev >= old(fill[n_r, n_c]).
        // This doesn't necessarily hold! Counterexample: 
        // original[n] = 5, fill[p] = 6, old(fill[n]) = 10.
        // Then newElev = max(5, 6) = 6, which is < 10.
        // But the algorithm says "if newElev > fill[n_r, n_c]" then update.
        // So in this case we wouldn't update, and fill[n] stays at 10.
        // So the property holds because we only update when raising.
      } else {
        // We didn't update
        assert fill[n_r, n_c] == old(fill[n_r, n_c]);
      }
    }
    
    assert fill[n_r, n_c] >= original[n_r, n_c] by {
      if newElev > old(fill[n_r, n_c]) {
        assert fill[n_r, n_c] == newElev;
        assert newElev >= original[n_r, n_c] by {
          // max(x, y) >= x
        }
      } else {
        assert fill[n_r, n_c] == old(fill[n_r, n_c]);
        assert old(fill[n_r, n_c]) >= original[n_r, n_c] by StateInvariant();
      }
    }
    
    assert fill[n_r, n_c] >= max(original[n_r, n_c], old(fill[p_r, p_c])) by {
      if newElev > old(fill[n_r, n_c]) {
        assert fill[n_r, n_c] == newElev;
        assert newElev == max(original[n_r, n_c], old(fill[p_r, p_c]));
      } else {
        assert fill[n_r, n_c] == old(fill[n_r, n_c]);
        // Since we didn't update, old(fill[n_r, n_c]) >= newElev
        assert old(fill[n_r, n_c]) >= newElev;
        assert newElev == max(original[n_r, n_c], old(fill[p_r, p_c]));
      }
    }
  }

  // Helper lemma about max
  lemma MaxProperty(a: Elevation, b: Elevation)
    ensures max(a, b) >= a
    ensures max(a, b) >= b
  {
    // Built-in property of max
  }
}
