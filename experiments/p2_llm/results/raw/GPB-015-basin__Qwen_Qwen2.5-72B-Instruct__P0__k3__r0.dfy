predicate IsInBounds(h: array2<int>, r: int, c: int) {
    0 <= r < h.Rows && 0 <= c < h.Cols
}

function method D8At(h: array2<int>, r: int, c: int): (dir: string, dp: int, dq: int) {
    if h[r, c] == -1 {
        ("NoFlow", 0, 0)
    } else {
        var minDelta := 1000000;
        var minDir := "NoFlow";
        var minDp := 0;
        var minDq := 0;
        for i in 0..7 {
            var (dp, dq) := DIRS[i];
            var nr := r + dp;
            var nc := c + dq;
            if IsInBounds(h, nr, nc) && h[nr, nc] < h[r, c] && h[nr, nc] - h[r, c] < minDelta {
                minDelta := h[nr, nc] - h[r, c];
                minDir := DIRS[i][0];
                minDp := dp;
                minDq := dq;
            }
        }
        (minDir, minDp, minDq)
    }
}

predicate IsUniqueOutlet(h: array2<int>, r: int, c: int, maxSteps: int) {
    var (dir, dp, dq) := D8At(h, r, c);
    if dir == "NoFlow" || !IsInBounds(h, r + dp, c + dq) {
        true
    } else {
        var path: seq<(int, int)> := [ (r, c) ];
        var currentR := r;
        var currentC := c;
        var steps := 0;
        while steps < maxSteps
            invariant 0 <= steps <= maxSteps
            invariant IsInBounds(h, currentR, currentC)
            invariant |path| == steps + 1
            invariant forall i, j :: 0 <= i < j < |path| ==> path[i] != path[j]
        {
            (dir, dp, dq) := D8At(h, currentR, currentC);
            if dir == "NoFlow" || !IsInBounds(h, currentR + dp, currentC + dq) {
                break;
            }
            currentR := currentR + dp;
            currentC := currentC + dq;
            path := path + [ (currentR, currentC) ];
            steps := steps + 1;
        }
        var outlet := (currentR, currentC);
        forall r1, c1, r2, c2 :: 0 <= r1 < h.Rows && 0 <= c1 < h.Cols && 0 <= r2 < h.Rows && 0 <= c2 < h.Cols && (r1, c1) == (r2, c2) ==> (followD8(h, r1, c1, maxSteps).1 == followD8(h, r2, c2, maxSteps).1)
    }
}

method followD8(h: array2<int>, r: int, c: int, maxSteps: int) returns (terminated: bool, outlet: (int, int), path: seq<(int, int)>) {
    requires IsInBounds(h, r, c);
    requires maxSteps >= 0;
    ensures terminated ==> IsUniqueOutlet(h, r, c, maxSteps);
    ensures !terminated ==> |path| == maxSteps + 1;
    ensures IsInBounds(h, outlet.0, outlet.1);
    ensures path[0] == (r, c);
    ensures forall i :: 0 < i < |path| ==> path[i] == (path[i-1].0 + D8At(h, path[i-1].0, path[i-1].1).1, path[i-1].1 + D8At(h, path[i-1].0, path[i-1].1).2);
    ensures forall i, j :: 0 <= i < j < |path| ==> path[i] != path[j];
    ensures terminated ==> (forall i :: 0 <= i < |path| - 1 ==> D8At(h, path[i].0, path[i].1).0 != "NoFlow" && IsInBounds(h, path[i].0 + D8At(h, path[i].0, path[i].1).1, path[i].1 + D8At(h, path[i].0, path[i].1).2));
    ensures terminated ==> (D8At(h, outlet.0, outlet.1).0 == "NoFlow" || !IsInBounds(h, outlet.0 + D8At(h, outlet.0, outlet.1).1, outlet.1 + D8At(h, outlet.0, outlet.1).2));
    var path: seq<(int, int)> := [ (r, c) ];
    var currentR := r;
    var currentC := c;
    var steps := 0;
    while steps < maxSteps
        invariant 0 <= steps <= maxSteps
        invariant IsInBounds(h, currentR, currentC)
        invariant |path| == steps + 1
        invariant forall i, j :: 0 <= i < j < |path| ==> path[i] != path[j]
    {
        var (dir, dp, dq) := D8At(h, currentR, currentC);
        if dir == "NoFlow" || !IsInBounds(h, currentR + dp, currentC + dq) {
            terminated := true;
            outlet := (currentR, currentC);
            return;
        }
        currentR := currentR + dp;
        currentC := currentC + dq;
        path := path + [ (currentR, currentC) ];
        steps := steps + 1;
    }
    terminated := false;
    outlet := (currentR, currentC);
    path := path;
}

lemma LayerAWatershedUniqueness(h: array2<int>, r: int, c: int, maxSteps: int) {
    requires IsInBounds(h, r, c);
    requires maxSteps >= 0;
    ensures IsUniqueOutlet(h, r, c, maxSteps);
    var (terminated, outlet, path) := followD8(h, r, c, maxSteps);
    if terminated {
        assert IsUniqueOutlet(h, r, c, maxSteps);
    } else {
        assert !IsUniqueOutlet(h, r, c, maxSteps);
    }
}

const DIRS: array<(string, int, int)> := [ ("N", -1, 0), ("NE", -1, 1), ("E", 0, 1), ("SE", 1, 1), ("S", 1, 0), ("SW", 1, -1), ("W", 0, -1), ("NW", -1, -1) ];
