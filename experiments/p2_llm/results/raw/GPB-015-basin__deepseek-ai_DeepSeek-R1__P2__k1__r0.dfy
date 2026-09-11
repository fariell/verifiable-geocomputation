type Cell
function succ(c: Cell): Cell

predicate outlet(c: Cell) {
  c == succ(c)
}

function stepN(s: Cell, n: nat): Cell {
  if n == 0 then s else succ(stepN(s, n-1))
}

lemma LemmaOutletStable(c: Cell, k: nat)
  requires outlet(c)
  ensures stepN(c, k) == c
  decreases k
{
  if k != 0 {
    LemmaOutletStable(c, k-1);
  }
}

lemma LemmaStepAdditive(s: Cell, n: nat, k: nat)
  ensures stepN(s, n + k) == stepN(stepN(s, n), k)
  decreases k
{
  if k != 0 {
    LemmaStepAdditive(s, n, k-1);
  }
}

theorem WatershedUniqueness(s: Cell, n: nat, m: nat)
  requires outlet(stepN(s, n))
  requires outlet(stepN(s, m))
  ensures stepN(s, n) == stepN(s, m)
{
  if n <= m {
    var d: nat := m - n;
    calc {
      stepN(s, m);
      == { LemmaStepAdditive(s, n, d); }
      stepN(stepN(s, n), d);
      == { LemmaOutletStable(stepN(s, n), d); }
      stepN(s, n);
    }
  } else {
    var d: nat := n - m;
    calc {
      stepN(s, n);
      == { LemmaStepAdditive(s, m, d); }
      stepN(stepN(s, m), d);
      == { LemmaOutletStable(stepN(s, m), d); }
      stepN(s, m);
    }
  }
}
