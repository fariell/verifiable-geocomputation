function succ(x: int): int

predicate isFixedPoint(s: int) {
  succ(s) == s
}

function stepN(s: int, n: nat): int
  decreases n;
{
  if n == 0 then s else succ(stepN(s, n-1))
}

lemma FixedPointAfter(s0: int, n: nat, m: nat)
  requires n <= m
  requires isFixedPoint(stepN(s0, n))
  ensures stepN(s0, m) == stepN(s0, n)
  decreases m - n;
{
  if m == n {
    // Base case: same step count
  } else {
    // Induction on decreasing m-n
    FixedPointAfter(s0, n, m-1);
    // Unfold stepN definition for m
    // stepN(s0, m) = succ(stepN(s0, m-1))
    // By induction: stepN(s0, m-1) = stepN(s0, n)
    // Thus: succ(stepN(s0, n)) = stepN(s0, n)  [by fixed point property]
  }
}

lemma WatershedUniqueness(s0: int, n: nat, m: nat)
  requires isFixedPoint(stepN(s0, n))
  requires isFixedPoint(stepN(s0, m))
  ensures stepN(s0, n) == stepN(s0, m)
{
  if n <= m {
    FixedPointAfter(s0, n, m);
  } else {
    FixedPointAfter(s0, m, n);
  }
}
