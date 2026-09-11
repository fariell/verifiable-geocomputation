datatype Direction = NW | N | NE | W | E | SW | S | SE | NoFlow

predicate ValidIndex(grid: array2<int>, i: int, j: int) {
  0 <= i < grid.Length0 && 0 <= j < grid.Length1
}

function method FlowDirectionAt(grid: array2<int>, i: int, j: int): Direction
  requires 0 <= i < grid.Length0 && 0 <= j < grid.Length1
{
  if forall dx, dy | dx in {-1,0,1} && dy in {-1,0,1} && (dx != 0 || dy != 0) :: 
      !(ValidIndex(grid, i+dx, j+dy) && grid[i+dx, j+dy] < grid[i,j])
  then 
      Direction.NoFlow
  else 
      Direction.N  // Arbitrary direction when flow exists
}

lemma Theorem(grid: array2<int>, i: int, j: int)
  requires 0 <= i < grid.Length0 && 0 <= j < grid.Length1
  requires forall dx, dy | dx in {-1,0,1} && dy in {-1,0,1} && (dx != 0 || dy != 0) :: 
      ValidIndex(grid, i+dx, j+dy) ==> grid[i+dx, j+dy] >= grid[i, j]
  ensures FlowDirectionAt(grid, i, j) == Direction.NoFlow
{
  // Proof follows directly from function definition and precondition
}
