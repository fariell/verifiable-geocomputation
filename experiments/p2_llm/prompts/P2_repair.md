# P2 · Iterative repair (verifier feedback)

You previously produced a `{{TARGET}}` formalization that failed the toolchain.
Repair it using the verifier/compiler feedback. Do not change the intended theorem
into a different proposition.

## Original specification
{{NATURAL_SPEC}}

## Previous attempt
```
{{PREVIOUS_SOURCE}}
```

## Toolchain feedback (round {{REPAIR_ROUND}} of ≤3)
```
{{VERIFIER_STDERR}}
```

## Repair rules
1. Fix syntax/type errors first if present.
2. If verification fails, strengthen invariants / decreases / preconditions **only**
   when justified by the specification—never vacuously restrict to a trivial fragment
   unless the task is explicitly about that fragment.
3. Do not delete the main claim or replace a NEG/counterexample task with a positive tautology.
4. Keep geospatial meaning (grid, flow, termination, tolerances) intact.
5. Output a complete revised source file only.

## Output
Return only the repaired `{{TARGET}}` source text.
