// ElevationGrid.dfy
// Proof of the RaiseNbr step property in 2D pit filling algorithm

function method Max(a: real, b: real): real
{
  if a >= b then a else b
}

predicate ValidGrid<T>(g: array2d<T>)
{
  g != null
}

predicate Nbr4(p0: int, p1: int, n0: int, n1: int)
{
  (p0 == n0 && (p1 == n1 - 1 || p1 == n1 + 1)) ||
  (p1 == n1 && (p0 == n0 - 1 || p0 == n0 + 1))
}

predicate Invariant(orig: array2d<real>, fill: array2d<real>, visited: array2d<bool>)
  requires ValidGrid(orig) && ValidGrid(fill) && ValidGrid(visited)
  requires orig.Length0 == fill.Length0 && orig.Length1 == fill.Length1
  requires orig.Length0 == visited.Length0 && orig.Length1 == visited.Length1
  reads orig, fill, visited
{
  forall i, j :: 
    0 <= i < orig.Length0 && 0 <= j < orig.Length1 && visited[i,j] == true ==>
    fill[i,j] >= orig[i,j]
}

lemma RaiseNbrStepPreserves(
  p0: int, p1: int, 
  n0: int, n1: int,
  orig: array2d<real>,
  fill: array2d<real>,
  visited: array2d<bool>
)
  requires ValidGrid(orig) && ValidGrid(fill) && ValidGrid(visited)
  requires orig.Length0 == fill.Length0 && orig.Length1 == fill.Length1
  requires orig.Length0 == visited.Length0 && orig.Length1 == visited.Length1
  requires 0 <= p0 < orig.Length0 && 0 <= p1 < orig.Length1
  requires 0 <= n0 < orig.Length0 && 0 <= n1 < orig.Length1
  requires Nbr4(p0, p1, n0, n1)
  requires visited[p0, p1] && !visited[n0, n1]
  requires Invariant(orig, fill, visited)
  ensures 
    var fill_new := fill[ n0, n1 := Max(orig[n0, n1], fill[p0, p1]) ];
    var visited_new := visited[ n0, n1 := true ];
    fill_new[n0, n1] == Max(orig[n0, n1], fill[p0, p1]) &&
    fill_new[n0, n1] >= orig[n0, n1] &&
    fill_new[n0, n1] >= fill[p0, p1] &&
    Invariant(orig, fill_new, visited_new)
{
  // Updated cell properties
  assert fill_new[n0, n1] == Max(orig[n0, n1], fill[p0, p1]);
  assert Max(orig[n0, n1], fill[p0, p1]) >= orig[n0, n1];
  assert Max(orig[n0, n1], fill[p0, p1]) >= fill[p0, p1];

  // Invariant preservation
  forall i, j | 0 <= i < orig.Length0 && 0 <= j < orig.Length1 && visited_new[i,j]
    ensures fill_new[i,j] >= orig[i,j]
  {
    if i == n0 && j == n1 {
      assert fill_new[i,j] == Max(orig[i,j], fill[p0,p1]) >= orig[i,j];
    } else {
      assert visited_new[i,j] ==> (i == n0 && j == n1) || visited[i,j];
      if i != n0 || j != n1 {
        assert visited[i,j];
        assert fill_new[i,j] == fill[i,j];
        assert fill[i,j] >= orig[i,j] by Invariant(orig, fill, visited);
      }
    }
  }
}
