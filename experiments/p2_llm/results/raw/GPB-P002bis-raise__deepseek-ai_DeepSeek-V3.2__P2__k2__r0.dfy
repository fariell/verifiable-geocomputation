// Formalization of 2D local raise step RaiseNbr
// Theorem: Raising a 4-neighbor from an already-processed cell never decreases
// any cell elevation, and the neighbor is lifted at least to
// max(original neighbor, processed cell fill).

datatype Point = Point(x: int, y: int)

function Max(a: real, b: real): real {
  if a >= b then a else b
}

// Grid elevations: map from Point to real elevation
type Grid = map<Point, real>

// 4-neighbor offsets
const neighborOffsets: seq<Point> :=
  [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];

// Predicate: point is inside bounds [0, N) x [0, N)
predicate InBounds(p: Point, N: int) {
  0 <= p.x < N && 0 <= p.y < N
}

// The RaiseNbr operation: raise neighbor q of processed cell p
// Precondition: p and q are 4-neighbors, p has been processed (filled to some level),
// and we are raising q's elevation.
// Postcondition: elevations never decrease, and q is raised to at least
// max(original q elevation, processed cell p's fill level).

method RaiseNbr(grid: Grid, p: Point, q: Point, N: int, fill_p: real) returns (grid': Grid)
  requires InBounds(p, N) && InBounds(q, N)
  requires exists off :: off in neighborOffsets && q == Point(p.x + off.x, p.y + off.y)
  requires grid[p] <= fill_p  // p already processed to at least its original elevation
  ensures grid' == grid[q := Max(grid[q], fill_p)]
  ensures forall r: Point :: InBounds(r, N) ==> grid'[r] >= grid[r]
  ensures grid'[q] >= Max(grid[q], fill_p)
{
  // Implementation: raise q to max of its current elevation and fill_p
  grid' := grid[q := Max(grid[q], fill_p)];

  // Verify postconditions
  // 1. grid' is exactly grid with q updated
  assert grid' == grid[q := Max(grid[q], fill_p)];

  // 2. No cell decreases
  forall r: Point | InBounds(r, N)
    ensures grid'[r] >= grid[r]
  {
    if r == q {
      assert grid'[r] == Max(grid[q], fill_p) >= grid[q] == grid[r];
    } else {
      assert grid'[r] == grid[r];
    }
  }

  // 3. q is lifted at least to max(original neighbor, processed cell fill)
  assert grid'[q] == Max(grid[q], fill_p);
  assert grid'[q] >= Max(grid[q], fill_p);
}
