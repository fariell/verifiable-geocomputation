// Deterministic flow iteration to outlet fixed point
// Theorem: from the same start cell, any two finite iteration lengths
// that reach a fixed point (outlet) yield the same outlet cell.

datatype Cell = Cell(x: int, y: int)

function step(c: Cell): Cell
  // deterministic successor; for concreteness, a simple example:
  decreases 0
{
  if c.x == 0 && c.y == 0 then c // outlet at origin
  else if c.x > 0 then Cell(c.x - 1, c.y)
  else if c.y > 0 then Cell(c.x, c.y - 1)
  else Cell(0, 0) // default fallback
}

function stepN(c: Cell, n: nat): Cell
  decreases n
{
  if n == 0 then c
  else stepN(step(c), n - 1)
}

predicate isFixedPoint(c: Cell) {
  step(c) == c
}

lemma WatershedUniqueness(start: Cell, m: nat, n: nat)
  requires isFixedPoint(stepN(start, m))
  requires isFixedPoint(stepN(start, n))
  ensures stepN(start, m) == stepN(start, n)
{
  // The key observation: once a fixed point is reached,
  // further iterations stay at that fixed point.
  // So both stepN(start, m) and stepN(start, n) are fixed points
  // reachable from start. We show they are equal by considering
  // the longer iteration length.

  var p := stepN(start, m);
  var q := stepN(start, n);

  if m <= n {
    // Since p is a fixed point, iterating further from p stays at p.
    // But stepN(start, n) = stepN(p, n - m) = p.
    // So q = p.
    FixedPointIteration(start, m, n);
  } else {
    // Symmetric case
    FixedPointIteration(start, n, m);
    // Now we know stepN(start, m) = stepN(start, n) from the symmetric call.
  }
}

lemma FixedPointIteration(start: Cell, k: nat, l: nat)
  requires k <= l
  requires isFixedPoint(stepN(start, k))
  ensures stepN(start, l) == stepN(start, k)
  decreases l - k
{
  if k == l {
    // trivial
  } else {
    // stepN(start, k) is a fixed point, so step(stepN(start, k)) = stepN(start, k)
    // Therefore stepN(start, k+1) = stepN(start, k).
    // By induction, stepN(start, l) = stepN(start, k).
    calc {
      stepN(start, k + 1);
      stepN(step(start), k);
      { assert step(start) == stepN(start, 1); }
      stepN(stepN(start, 1), k);
      { lemma_stepN_commutes(start, 1, k); }
      stepN(start, 1 + k);
      { assert 1 + k == k + 1; }
      stepN(start, k + 1);
    }
    // Actually simpler: direct unfolding
    assert stepN(start, k+1) == stepN(step(stepN(start, k)), 0) by {
      reveal stepN();
    }
    assert stepN(start, k+1) == step(stepN(start, k));
    assert stepN(start, k+1) == stepN(start, k) because isFixedPoint(stepN(start, k));

    // Now apply induction
    FixedPointIteration(start, k+1, l);
  }
}

lemma lemma_stepN_commutes(c: Cell, a: nat, b: nat)
  ensures stepN(stepN(c, a), b) == stepN(c, a + b)
  decreases b
{
  if b == 0 {
  } else {
    lemma_stepN_commutes(c, a, b-1);
  }
}
