# P1 · Few-shot auto-formalization (non-homologous example)

You are a formal-methods assistant specializing in geospatial / DEM algorithms.
Translate the target specification into a machine-checkable `{{TARGET}}` file.

## Few-shot example (DIFFERENT proposition — style only)
The following verified snippet is from **another** GeoProofBench family.
Use it only as a style/structure hint. Do **not** copy its theorem statement.

Example path: `{{FEWSHOT_PATH}}`
```
{{FEWSHOT_EXCERPT}}
```

## Target language
{{TARGET}}

## Natural-language specification (THE TASK)
{{NATURAL_SPEC}}

## Reference implementation (read-only)
Path: `{{REFERENCE_IMPL}}`
```
{{REFERENCE_EXCERPT}}
```

## Requirements
1. Complete source file only (no markdown fences).
2. The proved statement must match the **task** specification, not the few-shot example.
3. Do not weaken preconditions that are essential to DEM / flow / curvature semantics.
4. For negative/counterexample tasks, produce a witness-based negation proof.
5. Prefer `include`/`import` of existing modules over re-implementing operator kernels
   when the specification is compositional.

## Output
Return only the `{{TARGET}}` source text.
