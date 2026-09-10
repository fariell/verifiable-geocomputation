// Deterministic successor function on a finite grid
module WatershedUniqueness {
  // Grid dimensions
  const w: int
  const h: int
  predicate validCell(r: int, c: int) {
    0 <= r < h && 0 <= c < w
  }

  // Deterministic successor function (D8 flow direction)
  function succ(r: int, c: int): (nr: int, nc: int)
    requires validCell(r, c)
    ensures validCell(nr, nc)

  // Fixed point predicate (outlet cell)
  predicate isOutlet(r: int, c: int) {
    validCell(r, c) && succ(r, c) == (r, c)
  }

  // Bounded iteration: stepN(s, n) = succ applied n times to start s
  function stepN(r: int, c: int, n: nat): (nr: int, nc: int)
    requires validCell(r, c)
    ensures validCell(nr, nc)
    decreases n
  {
    if n == 0 then (r, c) else
      var (pr, pc) := stepN(r, c, n-1);
      succ(pr, pc)
  }

  // Main theorem: if from the same start we reach a fixed point in two
  // different finite step counts, those fixed points are equal.
  theorem WatershedUniqueness(r: int, c: int, m: nat, n: nat)
    requires validCell(r, c)
    requires m != n
    requires isOutlet(stepN(r, c, m).0, stepN(r, c, m).1)
    requires isOutlet(stepN(r, c, n).0, stepN(r, c, n).1)
    ensures stepN(r, c, m) == stepN(r, c, n)
  {
    // Without loss of generality, assume m < n
    if m < n {
      // Let k = n - m
      var k: nat := n - m;
      // Define the intermediate cell after m steps
      var (rm, cm) := stepN(r, c, m);
      // Since (rm, cm) is an outlet, succ(rm, cm) == (rm, cm)
      assert succ(rm, cm) == (rm, cm);
      // Then stepN(rm, cm, k) = (rm, cm) for any k
      // Prove by induction on k
      var (rn, cn) := stepN(r, c, n);
      calc {
        stepN(r, c, n);
        == // definition of n = m + k
        stepN(rm, cm, k);
        == { LemmaOutletFixed(rm, cm, k); }
        (rm, cm);
        ==
        stepN(r, c, m);
      }
    } else {
      // Symmetric case when n < m
      WatershedUniqueness(r, c, n, m);
    }
  }

  // Helper lemma: once at an outlet, further steps stay there
  lemma LemmaOutletFixed(r: int, c: int, k: nat)
    requires validCell(r, c)
    requires isOutlet(r, c)
    ensures stepN(r, c, k) == (r, c)
    decreases k
  {
    if k == 0 {
      // base case
    } else {
      // inductive step
      var (r1, c1) := stepN(r, c, k-1);
      LemmaOutletFixed(r, c, k-1);
      assert (r1, c1) == (r, c);
      assert succ(r1, c1) == (r, c);
    }
  }
}
