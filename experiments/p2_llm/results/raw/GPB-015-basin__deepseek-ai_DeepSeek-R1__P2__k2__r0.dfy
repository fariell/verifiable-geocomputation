type Cell

function succ(c: Cell): Cell

function stepN(s: Cell, k: nat): Cell
  decreases k
{
  if k == 0 then s else succ(stepN(s, k-1))
}

predicate isOutlet(c: Cell) {
  succ(c) == c
}

lemma outletFixed(o: Cell, k: nat)
  requires isOutlet(o)
  ensures stepN(o, k) == o
  decreases k
{
  if k != 0 {
    outletFixed(o, k-1);
  }
}

lemma stepNAdd(s: Cell, n: nat, k: nat)
  ensures stepN(s, n+k) == stepN(stepN(s, n), k)
  decreases k
{
  if k == 0 {
  } else {
    stepNAdd(s, n, k-1);
  }
}

theorem watershedUniqueness(s: Cell, n: nat, m: nat)
  requires isOutlet(stepN(s, n))
  requires isOutlet(stepN(s, m))
  ensures stepN(s, n) == stepN(s, m)
{
  if n <= m {
    var diff: nat := m - n;
    stepNAdd(s, n, diff);
    outletFixed(stepN(s, n), diff);
  } else {
    var diff: nat := n - m;
    stepNAdd(s, m, diff);
    outletFixed(stepN(s, m), diff);
  }
}
