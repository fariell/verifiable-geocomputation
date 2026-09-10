predicate IsInBounds(h: array2<int>, r: int, c: int) {
    0 <= r < h.Rows && 0 <= c < h.Cols
}

function method D8At(h: array2<int>, r: int, c: int): (dir: string, dp: int, dq: int) {
    if h[r, c] == -1 {
        ("NoFlow", 0, 0)
    } else {
        var minDir: string := "NoFlow";
        var minDelta: int := 1000000;
        var dp: int := 0;
        var dq: int := 0;
        for d in ["N", "NE", "E", "SE", "S", "SW", "W", "NW"] {
            var (dp', dq', dist2) := _Delta(d);
            var nr := r + dp';
            var nc := c + dq';
            if IsInBounds(h, nr, nc) && h[nr, nc] < h[r, c] + minDelta {
                minDir := d;
                minDelta := h[r, c] - h[nr, nc];
                dp := dp';
                dq := dq';
            }
        }
        (minDir, dp, dq)
    }
}

function method _Delta(d: string): (string, int, int) {
    match d {
        case "N" => ("N", -1, 0)
        case "NE" => ("NE", -1, 1)
        case "E" => ("E", 0, 1)
        case "SE" => ("SE", 1, 1)
        case "S" => ("S", 1, 0)
        case "SW" => ("SW", 1, -1)
        case "W" => ("W", 0, -1)
        case "NW" => ("NW", -1, -1)
        case _ => ("NoFlow", 0, 0)
    }
}

method FollowD8(h: array2<int>, r: int, c: int, maxSteps: int) returns (terminated: bool, outlet: (int, int), path: seq<(int, int)>) {
    requires IsInBounds(h, r, c);
    requires maxSteps >= 0;
    ensures terminated ==> (outlet in path);
    ensures !terminated ==> (|path| == maxSteps + 1);
    ensures path[0] == (r, c);
    ensures forall i :: 0 <= i < |path| - 1 ==> path[i+1] == (path[i][0] + _Delta(D8At(h, path[i][0], path[i][1]).0).1, path[i][1] + _Delta(D8At(h, path[i][0], path[i][1]).0).2);
    ensures forall i, j :: 0 <= i < j < |path| ==> path[i] != path[j];
    var path := [ (r, c) ];
    var currentR := r;
    var currentC := c;
    for i := 0 to maxSteps {
        var (dir, dp, dq) := D8At(h, currentR, currentC);
        if dir == "NoFlow" || !IsInBounds(h, currentR + dp, currentC + dq) {
            terminated := true;
            outlet := (currentR, currentC);
            return;
        }
        currentR := currentR + dp;
        currentC := currentC + dq;
        path := path + [ (currentR, currentC) ];
        if |path| != |path.Distinct| {
            terminated := false;
            outlet := (currentR, currentC);
            return;
        }
    }
    terminated := false;
    outlet := (currentR, currentC);
}

lemma WatershedUniqueness(h: array2<int>, r: int, c: int, maxSteps: int)
    requires IsInBounds(h, r, c);
    requires maxSteps >= 0;
    ensures forall n1, n2 :: 0 <= n1 <= maxSteps && 0 <= n2 <= maxSteps && FollowD8(h, r, c, n1).0 && FollowD8(h, r, c, n2).0 ==> FollowD8(h, r, c, n1).1 == FollowD8(h, r, c, n2).1;
{
    var (terminated1, outlet1, path1) := FollowD8(h, r, c, maxSteps);
    var (terminated2, outlet2, path2) := FollowD8(h, r, c, maxSteps);

    if terminated1 && terminated2 {
        assert outlet1 == outlet2;
    }
}
