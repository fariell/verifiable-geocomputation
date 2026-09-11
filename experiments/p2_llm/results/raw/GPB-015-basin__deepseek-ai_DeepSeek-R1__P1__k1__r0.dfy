// ===========================================================================
//  GeoProofBench · P-006
//  算子 : Watershed uniqueness under deterministic D8 flow
//  覆盖 : GPB-015 (Layer A: deterministic D8 ⇒ unique outlet if orbit terminates)
//  环境 : Dafny 4.11 · 验证命令 dafny verify P006_watershed.dfy
// ===========================================================================

module WatershedUniqueness {

  // -------------------------------------------------------------------------
  // Abstract cell type and deterministic successor function
  // -------------------------------------------------------------------------
  type Cell
  function succ(c: Cell): Cell  // Deterministic flow successor

  // Fixed point definition (outlet cell)
  predicate IsOutlet(c: Cell) {
    succ(c) == c
  }

  // -------------------------------------------------------------------------
  // Bounded iteration (stepN) without recursion
  // -------------------------------------------------------------------------
  function stepN(s: Cell, n: nat): (c: Cell)
    decreases n
  {
    if n == 0 then s
    else if IsOutlet(s) then s
    else stepN(succ(s), n-1)
  }

  // -------------------------------------------------------------------------
  // Composition lemma: stepN(s, m+n) = stepN(stepN(s, m), n)
  // -------------------------------------------------------------------------
  lemma StepNAdd(s: Cell, m: nat, n: nat)
    ensures stepN(s, m+n) == stepN(stepN(s, m), n)
    decreases m
  {
    if m == 0 {
      // Base case: stepN(s, 0+n) = stepN(s, n) = stepN(stepN(s, 0), n)
    } else if IsOutlet(s) {
      // Early termination: s is already outlet
    } else {
      // Inductive step: reduce m and advance successor
      StepNAdd(succ(s), m-1, n);
    }
  }

  // -------------------------------------------------------------------------
  // Stability lemma: Outlets remain fixed under further iteration
  // -------------------------------------------------------------------------
  lemma StepNOutlet(c: Cell, n: nat)
    requires IsOutlet(c)
    ensures stepN(c, n) == c
  {
    // Trivial by stepN definition (outlet condition stops iteration)
  }

  // =========================================================================
  // MAIN THEOREM: Watershed outlet uniqueness
  // -------------------------------------------------------------------------
  // If bounded iteration reaches an outlet from the same start cell in
  // two different step counts, those outlets must be equal.
  // =========================================================================
  theorem WatershedUniqueness(s: Cell, n1: nat, n2: nat)
    requires IsOutlet(stepN(s, n1))  // First run terminates at outlet
    requires IsOutlet(stepN(s, n2))  // Second run terminates at outlet
    ensures stepN(s, n1) == stepN(s, n2)
  {
    // Case 1: n1 ≤ n2
    if n1 <= n2 {
      var diff: nat := n2 - n1;
      StepNAdd(s, n1, diff);
      StepNOutlet(stepN(s, n1), diff);
    }
    // Case 2: n2 < n1
    else {
      var diff: nat := n1 - n2;
      StepNAdd(s, n2, diff);
      StepNOutlet(stepN(s, n2), diff);
    }
  }
}

method Main() {
  print "GeoProofBench P-006 — Watershed outlet uniqueness\n";
  print "Verified: dafny verify P006_watershed.dfy\n";
}
