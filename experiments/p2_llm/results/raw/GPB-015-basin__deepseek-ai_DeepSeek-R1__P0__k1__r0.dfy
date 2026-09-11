type Cell

function next(cell: Cell): Cell

predicate isOutlet(cell: Cell) {
  next(cell) == cell
}

function stepN(cell: Cell, n: nat): Cell
  decreases n
{
  if n == 0 then cell
  else if isOutlet(cell) then cell
  else stepN(next(cell), n-1)
}

lemma WatershedUniqueness(s: Cell, n: nat, m: nat)
  requires isOutlet(stepN(s, n))
  requires isOutlet(stepN(s, m))
  ensures stepN(s, n) == stepN(s, m)
  decreases n + m
{
  if n == 0 {
    // Base case: n=0 implies outlet is start cell
  } else if m == 0 {
    // Base case: m=0 implies outlet is start cell
  } else {
    if isOutlet(s) {
      // Start cell is already outlet
    } else {
      // Both paths reduce by one step
      WatershedUniqueness(next(s), n-1, m-1);
    }
  }
}
