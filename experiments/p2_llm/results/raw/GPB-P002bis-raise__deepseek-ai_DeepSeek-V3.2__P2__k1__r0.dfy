// P2 · Iterative repair (verifier feedback)
// Formalization of the 2D local raise step RaiseNbr property.

method RaiseNbrPreservesNonDecreasingAndLifts(
  elevations: array2<int>,
  processedRow: int, processedCol: int,
  neighborRow: int, neighborCol: int,
  fillHeight: int
)
  requires elevations != null
  requires 0 <= processedRow < elevations.Length0
  requires 0 <= processedCol < elevations.Length1
  requires 0 <= neighborRow < elevations.Length0
  requires 0 <= neighborCol < elevations.Length1
  requires (neighborRow == processedRow && (neighborCol == processedCol + 1 || neighborCol == processedCol - 1)) ||
           (neighborCol == processedCol && (neighborRow == processedRow + 1 || neighborRow == processedRow - 1))
  requires fillHeight >= elevations[processedRow, processedCol]
  // Precondition: neighbor has not been processed yet (its elevation may be lower)
  requires elevations[neighborRow, neighborCol] <= elevations[processedRow, processedCol] + 1 // optional bound for realism
  modifies elevations
  ensures elevations[neighborRow, neighborCol] >= old(elevations[neighborRow, neighborCol])
  ensures elevations[neighborRow, neighborCol] >= max(old(elevations[neighborRow, neighborCol]), fillHeight)
  ensures forall i, j :: 0 <= i < elevations.Length0 && 0 <= j < elevations.Length1 ==>
             elevations[i, j] >= old(elevations[i, j])
{
  // Store old values for postcondition
  ghost var oldElevations := elevations[.., ..];

  // The RaiseNbr operation: if neighbor is lower than fillHeight, raise it to fillHeight.
  if elevations[neighborRow, neighborCol] < fillHeight {
    elevations[neighborRow, neighborCol] := fillHeight;
  }

  // Postconditions are checked automatically by Dafny.
  // The first postcondition (non‑decrease) is satisfied because we only increase or leave unchanged.
  // The second postcondition (lift to at least max(original neighbor, processed cell fill)) holds because:
  //   - If original neighbor >= fillHeight, we do nothing, and new = original >= max(original, fillHeight).
  //   - If original neighbor < fillHeight, we set to fillHeight, so new = fillHeight >= max(original, fillHeight).
  // The third postcondition (global non‑decrease) holds because we only modified one cell and increased it.
}
