datatype Direction = E | SE | S | SW | W | NW | N | NE | NoFlow

function indexToDir(i: int): Direction
  requires 0 <= i < 8
{
  if i == 0 then E else
  if i == 1 then SE else
  if i == 2 then S else
  if i == 3 then SW else
  if i == 4 then W else
  if i == 5 then NW else
  if i == 6 then N else
  NE
}

function method D8(center: real, neighbors: seq<real>): Direction
  requires |neighbors| == 8
{
  var bestDir: Direction := NoFlow;
  var bestPriority: real := 0.0;
  var dists := [1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0];
  var i: int := 0;
  while i < 8
    invariant 0 <= i <= 8
    invariant bestDir == NoFlow
    invariant bestPriority == 0.0
    decreases 8 - i
  {
    var drop: real := center - neighbors[i];
    if drop > 0.0 {
      var priority := (drop * drop) / dists[i];
      if bestDir == NoFlow || priority > bestPriority {
        bestDir := indexToDir(i);
        bestPriority := priority;
      }
    }
    i := i + 1;
  }
  bestDir
}

lemma Lemma_D8_Pit(center: real, neighbors: seq<real>)
  requires |neighbors| == 8
  requires forall i :: 0 <= i < 8 ==> neighbors[i] >= center
  ensures D8(center, neighbors) == NoFlow
{
}
