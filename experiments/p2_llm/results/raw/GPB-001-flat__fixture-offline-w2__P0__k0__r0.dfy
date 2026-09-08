// P2_AIMATH W2 offline fixture — NOT gold_formal, NOT a paper metric.
// Purpose: exercise harness generate→verify→score path when external LLM API is unreachable.
// Intentional gaps: definitions are stubs; lemma body empty → expected compile/verify fail or skip.
module HornSlopeSmokeFixture {
  function SlopeSq(a: real, b: real, c: real, d: real, f: real,
                   g: real, h: real, i: real, w: real): real
    requires w > 0.0
  {
    0.0  // stub: deliberately wrong / incomplete vs Horn formula
  }

  lemma FlatSlopeZero(C: real, w: real)
    requires w > 0.0
    ensures SlopeSq(C, C, C, C, C, C, C, C, w) == 0.0
  {
  }
}
