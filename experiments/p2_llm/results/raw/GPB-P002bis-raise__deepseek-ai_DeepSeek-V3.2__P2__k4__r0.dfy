// P2 · Iterative repair (verifier feedback)
// Theorem: In the 2D local raise step RaiseNbr, raising a 4-neighbor from an already-processed cell
// never decreases any cell elevation, and the neighbor is lifted at least to max(original neighbor, processed cell fill).

method RaiseNbrPreservesNonDecreasingAndLiftsToMax(
  processedElev: real, neighborElev: real, fillHeight: real
) returns (newNeighborElev: real)
  requires processedElev >= 0.0 && neighborElev >= 0.0 && fillHeight >= 0.0
  ensures newNeighborElev >= neighborElev  // never decreases any cell elevation
  ensures newNeighborElev >= max(neighborElev, max(processedElev, fillHeight))  // lifted at least to max(original neighbor, processed cell fill)
{
  // The raise step: new neighbor elevation is the maximum of its original elevation
  // and the processed cell's fill height (which itself is the maximum of processed cell's elevation and fillHeight).
  var processedFill := max(processedElev, fillHeight);
  newNeighborElev := max(neighborElev, processedFill);

  // Verification of postconditions:
  // 1. newNeighborElev >= neighborElev  (by definition of max)
  // 2. newNeighborElev >= max(neighborElev, processedFill)  (trivially true since newNeighborElev = max(neighborElev, processedFill))
  //    But we need newNeighborElev >= max(neighborElev, max(processedElev, fillHeight))
  //    Since processedFill = max(processedElev, fillHeight), this is equivalent to the above.
}
