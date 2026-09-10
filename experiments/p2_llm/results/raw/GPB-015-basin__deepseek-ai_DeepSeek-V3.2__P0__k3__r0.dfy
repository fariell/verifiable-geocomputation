// Formalization of watershed uniqueness under deterministic successor function
// Property: If a deterministic successor function reaches an outlet (fixed point)
// from the same start cell in any two finite step counts, those outlets are equal.

module P006_Watershed {
  // Grid dimensions
  const w: int
  const h: int
  predicate validGrid() { w > 0 && h > 0 }
  
  // Cell coordinates
  type Cell = (int, int)
  predicate validCell(c: Cell) {
    validGrid() &&
    0 <= c.0 && c.0 < h &&
    0 <= c.1 && c.1 < w
  }
  
  // Deterministic successor function (D8 flow direction)
  function succ(c: Cell): Cell
    requires validCell(c)
    ensures validCell(succ(c))
  
  // Fixed point definition: cell is an outlet if it maps to itself
  predicate isOutlet(c: Cell) {
    validCell(c) && succ(c) == c
  }
  
  // Bounded iteration without searching for fixed points
  function stepN(c: Cell, n: nat): Cell
    requires validCell(c)
    ensures validCell(stepN(c, n))
    decreases n
  {
    if n == 0 then c
    else stepN(succ(c), n-1)
  }
  
  // Main theorem: if we reach an outlet in two different step counts,
  // the outlets must be the same
  theorem WatershedUniqueness(c: Cell, m: nat, n: nat)
    requires validCell(c)
    requires m != n
    requires isOutlet(stepN(c, m))
    requires isOutlet(stepN(c, n))
    ensures stepN(c, m) == stepN(c, n)
  {
    // Without loss of generality, assume m < n
    if m < n {
      WatershedUniquenessHelper(c, m, n);
    } else {
      WatershedUniquenessHelper(c, n, m);
    }
  }
  
  // Helper lemma for the case where m < n
  lemma WatershedUniquenessHelper(c: Cell, m: nat, n: nat)
    requires validCell(c)
    requires m < n
    requires isOutlet(stepN(c, m))
    requires isOutlet(stepN(c, n))
    ensures stepN(c, m) == stepN(c, n)
    decreases n - m
  {
    // Let a = stepN(c, m) and b = stepN(c, n)
    var a := stepN(c, m);
    var b := stepN(c, n);
    
    // Since a is an outlet, succ(a) = a
    assert succ(a) == a;
    
    // Show that stepN(a, k) = a for any k
    assert forall k: nat :: stepN(a, k) == a by {
      FixedPointIteration(a, k);
    }
    
    // Express b in terms of a
    // b = stepN(c, n) = stepN(stepN(c, m), n - m) = stepN(a, n - m)
    calc {
      stepN(c, n);
      == // by definition of stepN
      stepN(stepN(c, m), n - m);
      == // a = stepN(c, m)
      stepN(a, n - m);
      == // from the lemma above
      a;
    }
    
    // Therefore b = a
    assert b == a;
  }
  
  // Lemma: Once at a fixed point, further iterations stay at the fixed point
  lemma FixedPointIteration(c: Cell, n: nat)
    requires validCell(c)
    requires isOutlet(c)
    ensures stepN(c, n) == c
    decreases n
  {
    if n == 0 {
      // base case
    } else {
      // Inductive step
      FixedPointIteration(c, n-1);
      // stepN(c, n) = stepN(succ(c), n-1) = stepN(c, n-1) = c
    }
  }
  
  // Additional property: if we reach an outlet at step m,
  // then for all n >= m, stepN(c, n) equals that outlet
  theorem OutletStability(c: Cell, m: nat, n: nat)
    requires validCell(c)
    requires m <= n
    requires isOutlet(stepN(c, m))
    ensures stepN(c, n) == stepN(c, m)
  {
    // Express stepN(c, n) as stepN(stepN(c, m), n - m)
    // Then apply FixedPointIteration
    FixedPointIteration(stepN(c, m), n - m);
  }
}
