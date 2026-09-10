// Deterministic flow accumulation to outlet fixed point
// Theorem: from the same start cell, any two finite iteration lengths
// that reach a fixed point (outlet) yield the same outlet.

datatype Option<T> = None | Some(value: T)

function stepN<T>(step: T → Option<T>, start: T, n: nat): Option<T>
  decreases n
{
  if n == 0 then Some(start)
  else
    match stepN(step, start, n-1)
      case None => None
      case Some(x) => step(x)
}

predicate isFixedPoint<T(==)>(step: T → Option<T>, x: T) {
  step(x) == Some(x)
}

lemma WatershedUniqueness<T(==)>(step: T → Option<T>, start: T, n: nat, m: nat)
  requires forall x :: step(x) == None || step(x) == Some(x) || exists y :: step(x) == Some(y)
  requires stepN(step, start, n) as Some? && isFixedPoint(step, stepN(step, start, n).value)
  requires stepN(step, start, m) as Some? && isFixedPoint(step, stepN(step, start, m).value)
  ensures stepN(step, start, n).value == stepN(step, start, m).value
{
  // The deterministic step function ensures that from a given start,
  // the sequence is uniquely determined.
  // If both n and m reach a fixed point, they must be the same fixed point
  // because the step function is deterministic and a fixed point is stable.
  // We prove this by showing that the fixed point reached is independent of n and m.

  var fn := stepN(step, start, n).value;
  var fm := stepN(step, start, m).value;

  // Key observation: once you reach a fixed point, further steps stay there.
  // So if you iterate max(n,m) steps, you'll get the same fixed point from both.
  if n <= m {
    // Extend n to m steps
    var extended := stepN(step, start, m);
    assert extended == Some(fm);
    // But also, because fn is a fixed point, stepping from fn stays fn.
    // So the sequence from start after n steps is fn, and after m steps (m ≥ n)
    // it must still be fn if we follow deterministic steps.
    // However, we know after m steps we have fm, which is also a fixed point.
    // Since the step function is deterministic, the path is unique,
    // so fn == fm.
    // We prove by induction that stepN(step, start, k) == Some(fn) for all k ≥ n.
    // Base: k = n, true by definition.
    // Inductive step: assume for k, prove for k+1.
    // But Dafny needs more guidance.
    // Instead, we note: stepN(step, fn, m-n) == Some(fn) because fn is fixed.
    // And stepN(step, start, m) == stepN(step, fn, m-n) by deterministic unfolding.
    // Therefore fm == fn.
    calc {
      stepN(step, start, m);
      == // unfold stepN m-n times from n
      stepN(step, fn, m-n);
      == { FixedPointLemma(step, fn, m-n); }
      Some(fn);
    }
    assert fm == fn;
  } else {
    // symmetric case
    var extended := stepN(step, start, n);
    assert extended == Some(fn);
    calc {
      stepN(step, start, n);
      ==
      stepN(step, fm, n-m);
      == { FixedPointLemma(step, fm, n-m); }
      Some(fm);
    }
    assert fn == fm;
  }
}

lemma FixedPointLemma<T(==)>(step: T → Option<T>, x: T, k: nat)
  requires isFixedPoint(step, x)
  ensures stepN(step, x, k) == Some(x)
  decreases k
{
  if k == 0 {
    // stepN(step, x, 0) == Some(x) by definition
  } else {
    FixedPointLemma(step, x, k-1);
    // Now stepN(step, x, k-1) == Some(x)
    // Then step(x) == Some(x) because x is fixed point
    // So stepN(step, x, k) == step(stepN(step, x, k-1).value) == step(x) == Some(x)
  }
}
