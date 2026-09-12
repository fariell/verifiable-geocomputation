module Watershed {
  const H: int, W: int
  assume H > 0 && W > 0

  type Cell = (int, int)
  predicate inGrid(c: Cell) {
    0 <= c.0 < H && 0 <= c.1 < W
  }

  function succ(c: Cell): Cell
    requires inGrid(c)
    ensures inGrid(result)

  predicate isOutlet(c: Cell)
    requires inGrid(c)
  {
    succ(c) == c
  }

  function stepN(n: nat, c: Cell): Cell
    requires inGrid(c)
    ensures inGrid(result)
    decreases n
  {
    if n == 0 then c
    else stepN(n-1, succ(c))
  }

  lemma FixedPointStays(c: Cell, k: nat)
    requires inGrid(c) && isOutlet(c)
    ensures stepN(k, c) == c
    decreases k
  {
    if k != 0 {
      FixedPointStays(c, k-1);
    }
  }

  lemma StepNAdd(n: nat, m: nat, c: Cell)
    requires inGrid(c)
    ensures stepN(n+m, c) == stepN(m, stepN(n, c))
    decreases n
  {
    if n != 0 {
      StepNAdd(n-1, m, succ(c));
    }
  }

  lemma WatershedUniqueness(r: int, c: int, n: nat, m: nat)
    requires inGrid((r,c))
    requires isOutlet(stepN(n, (r,c)))
    requires isOutlet(stepN(m, (r,c)))
    ensures stepN(n, (r,c)) == stepN(m, (r,c))
  {
    if n <= m {
      var diff: nat := m - n;
      StepNAdd(n, diff, (r,c));
      FixedPointStays(stepN(n, (r,c)), diff);
    } else {
      var diff: nat := n - m;
      StepNAdd(m, diff, (r,c));
      FixedPointStays(stepN(m, (r,c)), diff);
    }
  }
}
