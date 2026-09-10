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
    ] do
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

lemma D8NoFlowOnPit(h: array2<int>, r: int, c: int)
    requires h != null
    requires 0 <= r < h.Height
    requires 0 <= c < h.Width
    requires forall i, j :: 0 <= i < h.Height && 0 <= j < h.Width && (i != r || j != c) ==> h[i, j] >= h[r, c]
    ensures D8At(h, r, c) == "NoFlow"
{
    var e := h[r, c];
    var best_p := 0.0;
    var best := "NoFlow";

    for name, dp, dq, dist2 in [
        ("E", 1, 0, 1.0),
        ("SE", 1, 1, 2.0),
        ("S", 0, 1, 1.0),
        ("SW", -1, 1, 2.0),
        ("W", -1, 0, 1.0),
        ("NW", -1, -1, 2.0),
        ("N", 0, -1, 1.0),
        ("NE", 1, -1, 2.0)
    ] do
        var rr := r + dq;
        var cc := c + dp;
        if 0 <= rr < h.Height && 0 <= cc < h.Width {
            var drop := e - h[rr, cc];
            assert drop <= 0; // By the pit condition, no neighbor is strictly lower
            if drop > 0 {
                var p := (drop * drop) / dist2;
                if best == "NoFlow" || p > best_p {
                    best := name;
                    best_p := p;
                }
            }
        }

    assert best == "NoFlow"; // No neighbor is strictly lower, so best remains "NoFlow"
}
