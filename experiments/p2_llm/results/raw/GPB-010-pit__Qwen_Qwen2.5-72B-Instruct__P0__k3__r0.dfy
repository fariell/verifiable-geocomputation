method D8At(h: array2<int>, r: int, c: int) returns (best: string)
  requires h != null
  requires 0 <= r < h.Height
  requires 0 <= c < h.Width
  ensures (best == "NoFlow" || best == "E" || best == "SE" || best == "S" || best == "SW" || best == "W" || best == "NW" || best == "N" || best == "NE")
{
  var e := h[r, c];
  var best_p := 0.0;
  best := "NoFlow";

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
}

method PitFlow(h: array2<int>, r: int, c: int) returns (flow: string)
  requires h != null
  requires 0 <= r < h.Height
  requires 0 <= c < h.Width
  ensures (flow == "NoFlow" || flow == "E" || flow == "SE" || flow == "S" || flow == "SW" || flow == "W" || flow == "NW" || flow == "N" || flow == "NE")
{
  var e := h[r, c];
  var all_neighbors_lower := true;

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
      if h[rr, cc] < e {
        all_neighbors_lower := false;
        break;
      }
    }
  }

  if all_neighbors_lower {
    flow := "NoFlow";
  } else {
    flow := D8At(h, r, c);
  }
}

lemma D8PitNoFlow(h: array2<int>, r: int, c: int)
  requires h != null
  requires 0 <= r < h.Height
  requires 0 <= c < h.Width
  requires forall name, dp, dq, dist2 :: (name, dp, dq, dist2) in [
    ("E", 1, 0, 1.0),
    ("SE", 1, 1, 2.0),
    ("S", 0, 1, 1.0),
    ("SW", -1, 1, 2.0),
    ("W", -1, 0, 1.0),
    ("NW", -1, -1, 2.0),
    ("N", 0, -1, 1.0),
    ("NE", 1, -1, 2.0)
  ] && 0 <= r + dq < h.Height && 0 <= c + dp < h.Width ==> h[r + dq, c + dp] >= h[r, c]
  ensures PitFlow(h, r, c) == "NoFlow"
{
  var e := h[r, c];
  var all_neighbors_lower := true;

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
      assert h[rr, cc] >= e;  // By the precondition
      all_neighbors_lower := false;
    }
  }

  assert all_neighbors_lower;  // All neighbors are not strictly lower
  assert PitFlow(h, r, c) == "NoFlow";  // By the definition of PitFlow
}
