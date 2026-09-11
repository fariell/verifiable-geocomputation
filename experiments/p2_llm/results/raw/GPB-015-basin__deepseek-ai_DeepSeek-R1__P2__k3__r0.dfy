type Cell
function succ(c: Cell): Cell

predicate isOutlet(c: Cell) {
  succ(c) == c
}

function stepN(s: Cell, n: nat): Cell {
  if n == 0 then s else succ(stepN(s, n-1))
}

lemma OutletFixed(c: Cell, k: nat)
  requires isOutlet(c)
  ensures stepN(c, k) == c
  decreases k
{
  if k != 0 {
    OutletFixed(c, k-1);
  }
}

lemma StepNAdd(s: Cell, a: nat, b: nat)
  ensures stepN(s, a+b) == stepN(stepN(s, a), b)
  decreases b
{
  if b == 0 {
  } else {
    StepNAdd(s, a, b-1);
  }
}

lemma WatershedUniqueness(s: Cell, n: nat, m: nat)
  requires isOutlet(stepN(s, n))
  requires isOutlet(stepN(s, m))
  ensures stepN(s, n) == stepN(s, m)
{
  if n <= m {
    var d: nat := m - n;
    StepNAdd(s, n, d);
    OutletFixed(stepN(s, n), d);
  } else {
    var d: nat := n - m;
    StepNAdd(s, m, d);
    OutletFixed(stepN(s, m), d);
  }
}
