method D8FlowDirection(h: array2<int>, r: int, c: int) returns (flowDirection: string)
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

method D8PitNoFlow(h: array2<int>, r: int, c: int) returns (isPit: bool)
  requires h != null
  requires 0 <= r < h.Height
  requires 0 <= c < h.Width
  ensures isPit == (D8FlowDirection(h, r, c) == "NoFlow")
{
  var e := h[r, c];
  var isPit := true;

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
        isPit := false;
        break;
      }
    }
  }

  return isPit;
}

lemma D8PitNoFlowLemma(h: array2<int>, r: int, c: int)
  requires h != null
  requires 0 <= r < h.Height
  requires 0 <= c < h.Width
  ensures D8PitNoFlow(h, r, c) == (D8FlowDirection(h, r, c) == "NoFlow")
{
  if D8PitNoFlow(h, r, c) {
    assert D8FlowDirection(h, r, c) == "NoFlow";
  } else {
    assert D8FlowDirection(h, r, c) != "NoFlow";
  }
}
