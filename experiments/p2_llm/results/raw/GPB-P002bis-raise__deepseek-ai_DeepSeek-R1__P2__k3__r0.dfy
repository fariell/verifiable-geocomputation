function max(a: int, b: int): int {
  if a >= b then a else b
}

predicate ValidStep(
  old_elev: array2<int>,
  i: int, j: int,
  fill: int,
  ni: int, nj: int,
  new_elev: array2<int>
)
  requires 0 <= i < old_elev.Length0
  requires 0 <= j < old_elev.Length1
  requires 0 <= ni < old_elev.Length0
  requires 0 <= nj < old_elev.Length1
  requires old_elev[i, j] == fill
{
  // (ni, nj) must be a 4-neighbor of (i, j)
  (ni == i - 1 && nj == j) ||
  (ni == i + 1 && nj == j) ||
  (ni == i && nj == j - 1) ||
  (ni == i && nj == j + 1)
  &&
  // Grid dimensions unchanged
  new_elev.Length0 == old_elev.Length0 &&
  new_elev.Length1 == old_elev.Length1
  &&
  // Neighbor raised sufficiently
  new_elev[ni, nj] >= max(old_elev[ni, nj], fill)
  &&
  // All other cells unchanged
  (forall r, c ::
    0 <= r < new_elev.Length0 &&
    0 <= c < new_elev.Length1 &&
    (r != ni || c != nj) ==>
      new_elev[r, c] == old_elev[r, c]
  )
}

lemma Theorem(
  old_elev: array2<int>,
  i: int, j: int,
  fill: int,
  ni: int, nj: int,
  new_elev: array2<int>
)
  requires ValidStep(old_elev, i, j, fill, ni, nj, new_elev)
  ensures forall r, c ::
    0 <= r < old_elev.Length0 &&
    0 <= c < old_elev.Length1 ==>
      new_elev[r, c] >= old_elev[r, c]
  ensures new_elev[ni, nj] >= max(old_elev[ni, nj], fill)
{
  // Second ensures follows directly from ValidStep
  // First ensures: show non-decreasing for every cell
  forall r, c | 0 <= r < old_elev.Length0 && 0 <= c < old_elev.Length1
    ensures new_elev[r, c] >= old_elev[r, c]
  {
    if r == ni && c == nj {
      // Raised neighbor: new value >= max(old, fill) >= old value
      assert new_elev[ni, nj] >= max(old_elev[ni, nj], fill);
      assert max(old_elev[ni, nj], fill) >= old_elev[ni, nj];
    } else {
      // Unchanged cell: equality holds
      assert new_elev[r, c] == old_elev[r, c];
    }
  }
}
