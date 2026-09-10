// P006_watershed.dfy
// Layer A watershed uniqueness: if a deterministic successor function reaches an outlet
// (fixed point) from the same start cell in any two finite step counts, those outlets are
// equal. Formalize via bounded iterate stepN without searching for fixed points by SMT
// recursion.

module WatershedUniqueness {

  // Directions for D8 flow
  const DIRS: set<(string, int, int)> := { ("NoFlow", 0, 0), ("N", 0, -1), ("NE", 1, -1), ("E", 1, 0), ("SE", 1, 1), ("S", 0, 1), ("SW", -1, 1), ("W", -1, 0), ("NW", -1, -1) };

  // Function to get the D8 direction at a given cell
  function d8_at(h: array2<int>, r: int, c: int): (string, int, int) {
    if h[r, c] == 0 { return ("NoFlow", 0, 0); }
    var min_slope := 1000000;
    var min_dir := ("NoFlow", 0, 0);
    for (name, dp, dq) in DIRS {
      if name == "NoFlow" { continue; }
      var nr := r + dp;
      var nc := c + dq;
      if 0 <= nr < h.Length0 && 0 <= nc < h.Length1 {
        var slope := h[r, c] - h[nr, nc];
        if slope < min_slope {
          min_slope := slope;
          min_dir := (name, dp, dq);
        }
      }
    }
    return min_dir;
  }

  // Function to follow the D8 flow from a given cell for a maximum number of steps
  function follow_d8(h: array2<int>, r: int, c: int, max_steps: int): (bool, (int, int), seq<(int, int)>) {
    var path: seq<(int, int)> := [ (r, c) ];
    var steps := 0;
    while steps < max_steps && (r, c) != (0, 0) {
      var (name, dp, dq) := d8_at(h, r, c);
      if name == "NoFlow" { return (true, (r, c), path); }
      var nr := r + dp;
      var nc := c + dq;
      if !(0 <= nr < h.Length0 && 0 <= nc < h.Length1) { return (true, (r, c), path); }
      r := nr;
      c := nc;
      path := path + [ (r, c) ];
      steps := steps + 1;
      if |path| != |path.Distinct| { return (false, (r, c), path); }
    }
    return (true, (r, c), path);
  }

  // Property: If a deterministic successor function reaches an outlet from the same start cell
  // in any two finite step counts, those outlets are equal.
  lemma WatershedUniqueness(h: array2<int>, r: int, c: int, max_steps1: int, max_steps2: int)
    requires 0 <= r < h.Length0;
    requires 0 <= c < h.Length1;
    requires max_steps1 >= 0;
    requires max_steps2 >= 0;
  {
    var (reached1, outlet1, path1) := follow_d8(h, r, c, max_steps1);
    var (reached2, outlet2, path2) := follow_d8(h, r, c, max_steps2);

    if reached1 && reached2 {
      assert outlet1 == outlet2;
    }
  }

  // Helper function to check if a cell is an outlet
  function isOutlet(h: array2<int>, r: int, c: int): bool {
    return d8_at(h, r, c).0 == "NoFlow" || !(0 <= r + d8_at(h, r, c).1 < h.Length0 && 0 <= c + d8_at(h, r, c).2 < h.Length1);
  }

  // Main function to test the lemma
  method TestWatershedUniqueness(h: array2<int>, r: int, c: int, max_steps1: int, max_steps2: int) {
    requires 0 <= r < h.Length0;
    requires 0 <= c < h.Length1;
    requires max_steps1 >= 0;
    requires max_steps2 >= 0;

    var (reached1, outlet1, path1) := follow_d8(h, r, c, max_steps1);
    var (reached2, outlet2, path2) := follow_d8(h, r, c, max_steps2);

    if reached1 && reached2 {
      assert outlet1 == outlet2;
    }
  }
}
