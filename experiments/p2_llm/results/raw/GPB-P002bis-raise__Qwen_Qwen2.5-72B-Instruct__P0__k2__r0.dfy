predicate Is4Neighbor(grid: array2<float>, r: int, c: int, nr: int, nc: int)
  requires 0 <= r < grid.Height && 0 <= c < grid.Width
  requires 0 <= nr < grid.Height && 0 <= nc < grid.Width
{
  (r == nr && (c == nc + 1 || c == nc - 1)) || (c == nc && (r == nr + 1 || r == nr - 1))
}

method RaiseNbr(grid: array2<float>, r: int, c: int, fill: array2<float>)
  requires 0 <= r < grid.Height && 0 <= c < grid.Width
  requires fill.Length0 == grid.Length0 && fill.Length1 == grid.Length1
  modifies fill
{
  var originalElevation := grid[r, c];
  var processedElevation := fill[r, c];
  for dr, dc in NBR4 do
    var nr := r + dr;
    var nc := c + dc;
    if 0 <= nr < grid.Height && 0 <= nc < grid.Width then
      fill[nr, nc] := max(fill[nr, nc], processedElevation);
}

lemma RaiseNbrPreservesElevation(grid: array2<float>, r: int, c: int, fill: array2<float>)
  requires 0 <= r < grid.Height && 0 <= c < grid.Width
  requires fill.Length0 == grid.Length0 && fill.Length1 == grid.Width
  ensures forall nr, nc :: 0 <= nr < grid.Height && 0 <= nc < grid.Width ==> fill[nr, nc] >= grid[nr, nc]
{
  var originalFill := fill;
  RaiseNbr(grid, r, c, fill);
  assert forall nr, nc :: 0 <= nr < grid.Height && 0 <= nc < grid.Width ==> fill[nr, nc] >= originalFill[nr, nc];
  assert forall nr, nc :: 0 <= nr < grid.Height && 0 <= nc < grid.Width ==> originalFill[nr, nc] >= grid[nr, nc];
}

lemma RaiseNbrLiftsNeighbor(grid: array2<float>, r: int, c: int, fill: array2<float>)
  requires 0 <= r < grid.Height && 0 <= c < grid.Width
  requires fill.Length0 == grid.Length0 && fill.Length1 == grid.Width
  ensures forall nr, nc :: Is4Neighbor(grid, r, c, nr, nc) ==> fill[nr, nc] >= max(grid[nr, nc], fill[r, c])
{
  var originalFill := fill;
  RaiseNbr(grid, r, c, fill);
  assert forall nr, nc :: Is4Neighbor(grid, r, c, nr, nc) ==> fill[nr, nc] >= max(originalFill[nr, nc], fill[r, c]);
  assert forall nr, nc :: Is4Neighbor(grid, r, c, nr, nc) ==> originalFill[nr, nc] >= grid[nr, nc];
}

const NBR4: set<(int, int)> := { (-1, 0), (1, 0), (0, -1), (0, 1) };

method main() {
  var grid: array2<float> := new float[5, 5];
  var fill: array2<float> := new float[5, 5];
  for r := 0 to 4 do
    for c := 0 to 4 do
      grid[r, c] := 0.0;
      fill[r, c] := 0.0;
  fill[2, 2] := 1.0;
  RaiseNbr(grid, 2, 2, fill);
  assert forall nr, nc :: Is4Neighbor(grid, 2, 2, nr, nc) ==> fill[nr, nc] >= max(grid[nr, nc], fill[2, 2]);
}
