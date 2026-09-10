predicate IsInBounds(h: array2<int>, r: int, c: int) {
    0 <= r < h.Rows && 0 <= c < h.Cols
}

function method D8At(h: array2<int>, r: int, c: int): (dir: string, dp: int, dq: int) {
    if h[r, c] == -1 {
        ("NoFlow", 0, 0)
    } else {
        var minDir: string := "NoFlow";
        var minDelta: int := 1000000;
        for (dr, dc) in DIRS {
            if IsInBounds(h, r + dr, c + dc) && h[r + dr, c + dc] < h[r, c] {
                var delta: int := h[r, c] - h[r + dr, c + dc];
                if delta < minDelta {
                    minDir := dr.ToString() + dc.ToString();
                    minDelta := delta;
                }
            }
        }
        (minDir, minDelta / 10, minDelta % 10)
    }
}

predicate IsUniqueOutlet(h: array2<int>, r: int, c: int, maxSteps: int) {
    var (dir, dp, dq) := D8At(h, r, c);
    if dir == "NoFlow" || !IsInBounds(h, r + dp, c + dq) {
        true
    } else {
        var path: seq<(int, int)> := [ (r, c) ];
        var currentR: int := r;
        var currentC: int := c;
        var steps: int := 0;
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
        var outlet: (int, int) := (currentR, currentC);
        forall r2, c2 :: 0 <= r2 < h.Rows && 0 <= c2 < h.Cols && (r2, c2) == (r, c) ==>
            var (dir2, dp2, dq2) := D8At(h, r2, c2);
            if dir2 == "NoFlow" || !IsInBounds(h, r2 + dp2, c2 + dq2) {
                (r2, c2) == outlet
            } else {
                var path2: seq<(int, int)> := [ (r2, c2) ];
                var currentR2: int := r2;
                var currentC2: int := c2;
                var steps2: int := 0;
                while steps2 < maxSteps
                    invariant 0 <= steps2 <= maxSteps
                    invariant IsInBounds(h, currentR2, currentC2)
                    invariant |path2| == steps2 + 1
                    invariant forall i, j :: 0 <= i < j < |path2| ==> path2[i] != path2[j]
                {
                    (dir2, dp2, dq2) := D8At(h, currentR2, currentC2);
                    if dir2 == "NoFlow" || !IsInBounds(h, currentR2 + dp2, currentC2 + dq2) {
                        break;
                    }
                    currentR2 := currentR2 + dp2;
                    currentC2 := currentC2 + dq2;
                    path2 := path2 + [ (currentR2, currentC2) ];
                    steps2 := steps2 + 1;
                }
                (currentR2, currentC2) == outlet
            }
    }
}

lemma WatershedUniqueness(h: array2<int>, r: int, c: int, maxSteps: int)
    requires IsInBounds(h, r, c)
    requires maxSteps > 0
    ensures IsUniqueOutlet(h, r, c, maxSteps)
{
    var (dir, dp, dq) := D8At(h, r, c);
    if dir == "NoFlow" || !IsInBounds(h, r + dp, c + dq) {
        // If the first step is a NoFlow or out of bounds, the outlet is the start cell.
        assert IsUniqueOutlet(h, r, c, maxSteps);
    } else {
        var path: seq<(int, int)> := [ (r, c) ];
        var currentR: int := r;
        var currentC: int := c;
        var steps: int := 0;
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
        var outlet: (int, int) := (currentR, currentC);

        // Prove that any other path starting from the same cell (r, c) reaches the same outlet.
        forall r2, c2 :: 0 <= r2 < h.Rows && 0 <= c2 < h.Cols && (r2, c2) == (r, c) ==>
            var (dir2, dp2, dq2) := D8At(h, r2, c2);
            if dir2 == "NoFlow" || !IsInBounds(h, r2 + dp2, c2 + dq2) {
                // If the first step is a NoFlow or out of bounds, the outlet is the start cell.
                assert (r2, c2) == outlet;
            } else {
                var path2: seq<(int, int)> := [ (r2, c2) ];
                var currentR2: int := r2;
                var currentC2: int := c2;
                var steps2: int := 0;
                while steps2 < maxSteps
                    invariant 0 <= steps2 <= maxSteps
                    invariant IsInBounds(h, currentR2, currentC2)
                    invariant |path2| == steps2 + 1
                    invariant forall i, j :: 0 <= i < j < |path2| ==> path2[i] != path2[j]
                {
                    (dir2, dp2, dq2) := D8At(h, currentR2, currentC2);
                    if dir2 == "NoFlow" || !IsInBounds(h, currentR2 + dp2, currentC2 + dq2) {
                        break;
                    }
                    currentR2 := currentR2 + dp2;
                    currentC2 := currentC2 + dq2;
                    path2 := path2 + [ (currentR2, currentC2) ];
                    steps2 := steps2 + 1;
                }
                assert (currentR2, currentC2) == outlet;
            }
    }
}

const DIRS: set<(int, int)> := { (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (1, -1) };
