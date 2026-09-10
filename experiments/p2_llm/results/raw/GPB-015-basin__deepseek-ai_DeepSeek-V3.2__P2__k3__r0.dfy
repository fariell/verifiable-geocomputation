// Deterministic flow iteration to outlet fixed point
// Theorem: from the same start cell, any two finite iteration lengths
// that reach a fixed point (outlet) yield the same outlet.

predicate IsFixedPoint(successor: (int) -> int, cell: int)
  requires forall c :: successor(c) >= 0
{
  successor(cell) == cell
}

function stepN(successor: (int) -> int, start: int, n: nat): int
  requires forall c :: successor(c) >= 0
  decreases n
{
  if n == 0 then start
  else successor(stepN(successor, start, n-1))
}

lemma WatershedUniqueness(successor: (int) -> int, start: int, m: nat, n: nat)
  requires forall c :: successor(c) >= 0
  requires IsFixedPoint(successor, stepN(successor, start, m))
  requires IsFixedPoint(successor, stepN(successor, start, n))
  ensures stepN(successor, start, m) == stepN(successor, start, n)
{
  // The key insight: once a fixed point is reached, further iterations stay there.
  // We prove that the later fixed point equals the earlier one.
  if m <= n {
    var outlet_m := stepN(successor, start, m);
    // Show that from step m onward, the value stays at outlet_m
    assert forall k: nat | k <= n - m :: stepN(successor, start, m + k) == outlet_m
      by {
        var k: nat | k <= n - m;
        calc {
          stepN(successor, start, m + k);
          == // unfold stepN k times
          stepN(successor, outlet_m, k);
          == { LemmaFixedPointStable(successor, outlet_m, k); }
          outlet_m;
        }
      }
    // In particular, for k = n - m
    assert stepN(successor, start, n) == outlet_m;
  } else {
    // Symmetric case
    var outlet_n := stepN(successor, start, n);
    assert forall k: nat | k <= m - n :: stepN(successor, start, n + k) == outlet_n
      by {
        var k: nat | k <= m - n;
        calc {
          stepN(successor, start, n + k);
          ==
          stepN(successor, outlet_n, k);
          == { LemmaFixedPointStable(successor, outlet_n, k); }
          outlet_n;
        }
      }
    assert stepN(successor, start, m) == outlet_n;
  }
}

// Helper lemma: once at a fixed point, stepN stays there for any further steps.
lemma LemmaFixedPointStable(successor: (int) -> int, cell: int, k: nat)
  requires forall c :: successor(c) >= 0
  requires IsFixedPoint(successor, cell)
  ensures stepN(successor, cell, k) == cell
  decreases k
{
  if k == 0 {
    // base case: stepN(successor, cell, 0) == cell by definition
  } else {
    // inductive step
    LemmaFixedPointStable(successor, cell, k-1);
    // stepN(successor, cell, k) = successor(stepN(successor, cell, k-1))
    // = successor(cell) because of induction hypothesis
    // = cell because cell is a fixed point
  }
}
