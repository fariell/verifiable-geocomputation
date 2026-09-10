method RaiseNbrPreservesElevation(
  elevations: array2<int>,
  processed: (int, int),
  neighbor: (int, int)
)
  requires elevations != null
  requires 0 <= processed.0 < elevations.Length0
  requires 0 <= processed.1 < elevations.Length1
  requires 0 <= neighbor.0 < elevations.Length0
  requires 0 <= neighbor.1 < elevations.Length1
  requires |processed.0 - neighbor.0| + |processed.1 - neighbor.1| == 1
  requires elevations[processed.0, processed.1] >= 0
  requires elevations[neighbor.0, neighbor.1] >= 0
  modifies elevations
  ensures elevations[processed.0, processed.1] >= old(elevations[processed.0, processed.1])
  ensures elevations[neighbor.0, neighbor.1] >= old(elevations[neighbor.0, neighbor.1])
  ensures elevations[neighbor.0, neighbor.1] >= old(elevations[processed.0, processed.1])
  ensures elevations[neighbor.0, neighbor.1] >= old(elevations[neighbor.0, neighbor.1])
{
  var oldProc := elevations[processed.0, processed.1];
  var oldNbr := elevations[neighbor.0, neighbor.1];
  var newNbr := if oldNbr >= oldProc then oldNbr else oldProc;
  elevations[neighbor.0, neighbor.1] := newNbr;
  assert elevations[neighbor.0, neighbor.1] >= oldNbr;
  assert elevations[neighbor.0, neighbor.1] >= oldProc;
}
