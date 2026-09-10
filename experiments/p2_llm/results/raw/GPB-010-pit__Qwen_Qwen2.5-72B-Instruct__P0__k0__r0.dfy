method D8SteepestDescent(h: array2<int>, r: int, c: int) returns (flowDirection: string)
  requires h != null
  requires 0 <= r < h.Height
  requires 0 <= c < h.Width
  ensures (flowDirection == "NoFlow" || flowDirection == "E" || flowDirection == "SE" || flowDirection == "S" || flowDirection == "SW" || flowDirection == "W" || flowDirection == "NW" || flowDirection == "N" || flowDirection == "NE")
{
  var e := h[r, c];
  var best: string := "NoFlow";
  var best_p: real := 0.0;

  for name, dp, dq, dist2 in [
    ("E", 1, 0, 1.0),
    ("SE", 1, 1, 2.0),
    ("S", 0, 1, 1.0),
    ("SW", -1, 1, 2.0),
    ("W", -1, 0, 1.0),
    ("NW", -1, -1, 2.0),
    ("N", 0, -1, 1.0),
    ("NE", 1, -1, 2.0)
  ] {
    var rr := r + dq;
    var cc := c + dp;
    if 0 <= rr < h.Height && 0 <= cc < h.Width {
      var drop := e - h[rr, cc];
      if drop > 0 {
        var p := (drop * drop) / dist2;
        if best == "NoFlow" || p > best_p {
          best := name;
          best_p := p;
        }
      }
    }
  }

  flowDirection := best;
}

lemma D8NoFlowOnPit(h: array2<int>, r: int, c: int)
  requires h != null
  requires 0 <= r < h.Height
  requires 0 <= c < h.Width
  requires forall i, j :: 0 <= i < h.Height && 0 <= j < h.Width && (i != r || j != c) ==> h[i, j] >= h[r, c]
  ensures D8SteepestDescent(h, r, c) == "NoFlow"
{
  var e := h[r, c];
  var best: string := "NoFlow";
  var best_p: real := 0.0;

  for name, dp, dq, dist2 in [
    ("E", 1, 0, 1.0),
    ("SE", 1, 1, 2.0),
    ("S", 0, 1, 1.0),
    ("SW", -1, 1, 2.0),
    ("W", -1, 0, 1.0),
    ("NW", -1, -1, 2.0),
    ("N", 0, -1, 1.0),
    ("NE", 1, -1, 2.0)
  ] {
    var rr := r + dq;
    var cc := c + dp;
    if 0 <= rr < h.Height && 0 <= cc < h.Width {
      assert h[rr, cc] >= h[r, c]; // By the pit condition
      var drop := e - h[rr, cc];
      assert drop <= 0; // Since h[rr, cc] >= h[r, c]
      if drop > 0 {
        assert false; // This should never happen
      }
    }
  }

  assert best == "NoFlow"; // No neighbor is strictly lower, so best remains "NoFlow"
}
