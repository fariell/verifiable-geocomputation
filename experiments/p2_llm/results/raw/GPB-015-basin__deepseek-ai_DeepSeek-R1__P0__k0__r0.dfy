type Point

function succ(p: Point): Point

predicate IsOutlet(p: Point) {
  succ(p) == p
}

function stepN(p: Point, n: nat): Point
  decreases n;
{
  if n == 0 then p else succ(stepN(p, n-1))
}

lemma StepNAdd(p: Point, n: nat, m: nat)
  ensures stepN(p, n+m) == stepN(stepN(p, n), m)
  decreases n;
{
  if n == 0 {
  } else {
    StepNAdd(p, n-1, m);
  }
}

lemma OutletStays(q: Point, m: nat)
  requires IsOutlet(q)
  ensures stepN(q, m) == q
  decreases m;
{
  if m == 0 {
  } else {
    OutletStays(q, m-1);
  }
}

lemma WatershedUniqueness(p0: Point, n1: nat, n2: nat)
  requires IsOutlet(stepN(p0, n1))
  requires IsOutlet(stepN(p0, n2))
  ensures stepN(p0, n1) == stepN(p0, n2)
{
  if n1 <= n2 {
    var diff: nat := n2 - n1;
    StepNAdd(p0, n1, diff);
    OutletStays(stepN(p0, n1), diff);
  } else {
    var diff: nat := n1 - n2;
    StepNAdd(p0, n2, diff);
    OutletStays(stepN(p0, n2), diff);
  }
}
