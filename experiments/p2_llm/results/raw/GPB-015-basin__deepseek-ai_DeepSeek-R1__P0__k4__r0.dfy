// P0 · Zero-shot auto-formalization: Watershed uniqueness
// Grid dimensions
const H: int, W: int
assume H > 0 && W > 0  // Non-empty grid

// Cell type
type Cell = (int, int)

// Valid grid cell predicate
predicate validCell(c: Cell) {
  0 <= c.0 < H && 0 <= c.1 < W
}

// Abstract deterministic successor function
function succ(c: Cell): Cell
  requires validCell(c)
  ensures validCell(succ(c))  // Successor remains in grid

// Outlet predicate (fixed point)
predicate isOutlet(c: Cell) {
  validCell(c) && succ(c) == c
}

// Bounded iteration of successor function
function stepN(c: Cell, n: nat): Cell
  requires validCell(c)
  decreases n
  ensures validCell(stepN(c, n))
{
  if n == 0 then c else stepN(succ(c), n-1)
}

// Fixed points remain fixed under iteration
lemma FixedPointStays(c: Cell, k: nat)
  requires validCell(c) && isOutlet(c)
  ensures stepN(c, k) == c
  decreases k
{
  if k != 0 {
    FixedPointStays(c, k-1);
  }
}

// Path composition lemma
lemma StepNAdd(c: Cell, n: nat, m: nat)
  requires validCell(c)
  ensures stepN(c, n+m) == stepN(stepN(c, n), m)
  decreases n
{
  if n != 0 {
    StepNAdd(succ(c), n-1, m);
  }
}

// Watershed uniqueness: common start ⇒ common outlet
lemma WatershedUniqueness(c0: Cell, n: nat, m: nat)
  requires validCell(c0)
  requires isOutlet(stepN(c0, n))
  requires isOutlet(stepN(c0, m))
  ensures stepN(c0, n) == stepN(c0, m)
{
  if n <= m {
    var diff: nat := m - n;
    StepNAdd(c0, n, diff);
    FixedPointStays(stepN(c0, n), diff);
  } else {
    var diff: nat := n - m;
    StepNAdd(c0, m, diff);
    FixedPointStays(stepN(c0, m), diff);
  }
}
