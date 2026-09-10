// Deterministic flow iteration to outlet fixed point
// Theorem: from same start cell, any two finite iteration lengths reach the same outlet

method WatershedUniqueness<Cell>(successor: Cell -> Cell, start: Cell, n: nat, m: nat)
  returns (outlet1: Cell, outlet2: Cell)
  requires forall c :: successor(c) == c || successor(successor(c)) != successor(c) // deterministic step
  ensures outlet1 == outlet2
{
  var i := 0;
  var current1 := start;
  while i < n
    invariant 0 <= i <= n
    invariant current1 == iterate(successor, start, i)
    decreases n - i
  {
    current1 := successor(current1);
    i := i + 1;
  }
  outlet1 := current1;

  var j := 0;
  var current2 := start;
  while j < m
    invariant 0 <= j <= m
    invariant current2 == iterate(successor, start, j)
    decreases m - j
  {
    current2 := successor(current2);
    j := j + 1;
  }
  outlet2 := current2;

  // Key lemma: if we iterate beyond both n and m to a common larger bound,
  // both results equal the iterate at that bound
  var k := if n < m then m else n;
  var current := start;
  var idx := 0;
  while idx < k
    invariant 0 <= idx <= k
    invariant current == iterate(successor, start, idx)
    decreases k - idx
  {
    current := successor(current);
    idx := idx + 1;
  }
  // Now current == iterate(successor, start, k)
  // By deterministic property, iterate(successor, start, n) == iterate(successor, start, k)
  // and similarly for m, when n <= k and m <= k.
  // This follows from the functional definition of iterate.
  assert outlet1 == iterate(successor, start, n);
  assert outlet2 == iterate(successor, start, m);
  assert iterate(successor, start, n) == iterate(successor, iterate(successor, start, n), k - n);
  assert iterate(successor, start, m) == iterate(successor, iterate(successor, start, m), k - m);
  // Since iterate(successor, start, k) is uniquely defined, both equal it.
  assert iterate(successor, start, n) == iterate(successor, start, k);
  assert iterate(successor, start, m) == iterate(successor, start, k);
}

// Helper function for deterministic iteration
function iterate<Cell>(step: Cell -> Cell, start: Cell, steps: nat): Cell
  decreases steps
{
  if steps == 0 then start
  else step(iterate(step, start, steps - 1))
}
