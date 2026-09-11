type Cell
function f(c: Cell): Cell

predicate outlet(c: Cell) {
  f(c) == c
}

function stepN(s: Cell, n: nat): Cell
  decreases n
{
  if n == 0 then s else f(stepN(s, n-1))
}

lemma outletFixed(c: Cell, k: nat)
  requires outlet(c)
  ensures stepN(c, k) == c
  decreases k
{
  if k != 0 {
    outletFixed(c, k-1);
  }
}

lemma stepNAdd(s: Cell, n: nat, m: nat)
  ensures stepN(s, n+m) == stepN(stepN(s, n), m)
  decreases m
{
  if m != 0 {
    stepNAdd(s, n, m-1);
  }
}

theorem watershedUniqueness(s: Cell, n: nat, m: nat)
  requires outlet(stepN(s, n)) && outlet(stepN(s, m))
  ensures stepN(s, n) == stepN(s, m)
{
  if n <= m {
    var k: nat := m - n;
    stepNAdd(s, n, k);
    outletFixed(stepN(s, n), k);
  } else {
    var k: nat := n - m;
    stepNAdd(s, m, k);
    outletFixed(stepN(s, m), k);
  }
}
