// P0 · Zero-shot auto-formalization: Watershed uniqueness
type Cell

function succ(c: Cell): Cell

predicate IsOutlet(c: Cell) {
  succ(c) == c
}

function stepN(s: Cell, n: nat): Cell
  decreases n
{
  if n == 0 then s else stepN(succ(s), n-1)
}

lemma StepNAdd(s: Cell, n: nat, m: nat)
  ensures stepN(s, n+m) == stepN(stepN(s, n), m)
  decreases n
{
  if n == 0 {
  } else {
    StepNAdd(succ(s), n-1, m);
  }
}

lemma OutletStable(o: Cell, k: nat)
  requires IsOutlet(o)
  ensures stepN(o, k) == o
  decreases k
{
  if k != 0 {
    OutletStable(o, k-1);
  }
}

lemma AfterOutlet(s: Cell, n: nat, k: nat)
  requires IsOutlet(stepN(s, n))
  requires k >= n
  ensures stepN(s, k) == stepN(s, n)
  decreases k - n
{
  if k == n {
  } else {
    AfterOutlet(s, n, k-1);
    StepNAdd(s, k-1, 1);
    assert stepN(s, k) == stepN(stepN(s, k-1), 1);
    var o := stepN(s, n);
    OutletStable(o, 1);
  }
}

lemma WatershedUniqueness(s: Cell, n: nat, m: nat)
  requires IsOutlet(stepN(s, n))
  requires IsOutlet(stepN(s, m))
  ensures stepN(s, n) == stepN(s, m)
{
  if n <= m {
    AfterOutlet(s, n, m);
  } else {
    AfterOutlet(s, m, n);
  }
}
