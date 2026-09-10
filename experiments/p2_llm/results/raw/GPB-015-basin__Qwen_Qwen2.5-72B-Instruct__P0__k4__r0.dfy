datatype Direction = NoFlow | North | Northeast | East | Southeast | South | Southwest | West | Northwest

function method _delta(d: Direction): (int, int)
  requires d != NoFlow
{
  match d
  case North => (0, -1)
  case Northeast => (1, -1)
  case East => (1, 0)
  case Southeast => (1, 1)
  case South => (0, 1)
  case Southwest => (-1, 1)
  case West => (-1, 0)
  case Northwest => (-1, -1)
}

type Grid = array2<int>

function method d8_at(h: Grid, r: int, c: int): Direction
  requires 0 <= r < h.Length0
  requires 0 <= c < h.Length1
{
  var minDelta := 1000000;
  var minDir := NoFlow;
  for dp in -1..1, dq in -1..1 where (dp, dq) != (0, 0) {
    var nr := r + dq;
    var nc := c + dp;
    if 0 <= nr < h.Length0 && 0 <= nc < h.Length1 {
      var delta := h[nr, nc] - h[r, c];
      if delta < minDelta {
        minDelta := delta;
        minDir := match (dp, dq)
          case (0, -1) => North
          case (1, -1) => Northeast
          case (1, 0) => East
          case (1, 1) => Southeast
          case (0, 1) => South
          case (-1, 1) => Southwest
          case (-1, 0) => West
          case (-1, -1) => Northwest
          case _ => NoFlow
      }
    }
  }
  minDir
}

method follow_d8(h: Grid, r: int, c: int, max_steps: int): (terminated: bool, outlet: (int, int), path: seq<(int, int)>)
  requires 0 <= r < h.Length0
  requires 0 <= c < h.Length1
  requires max_steps >= 0
  decreases max_steps
{
  path := [ (r, c) ];
  for i := 0 to max_steps {
    var d := d8_at(h, r, c);
    if d == NoFlow {
      terminated := true;
      outlet := (r, c);
      return;
    }
    var (dp, dq) := _delta(d);
    var nr := r + dq;
    var nc := c + dp;
    if !(0 <= nr < h.Length0 && 0 <= nc < h.Length1) {
      terminated := true;
      outlet := (r, c);
      return;
    }
    r := nr;
    c := nc;
    path := path + [ (r, c) ];
    if |path| != |path.Distinct| {
      terminated := false;
      outlet := (r, c);
      return;
    }
  }
  terminated := false;
  outlet := (r, c);
}

lemma LayerAWatershedUniqueness(h: Grid, r: int, c: int, max_steps: int)
  requires 0 <= r < h.Length0
  requires 0 <= c < h.Length1
  requires max_steps >= 0
{
  var (terminated1, outlet1, path1) := follow_d8(h, r, c, max_steps);
  var (terminated2, outlet2, path2) := follow_d8(h, r, c, max_steps);

  if terminated1 && terminated2 {
    assert outlet1 == outlet2;
  }
}

method main() {
  var h: Grid := new int[5, 5];
  for i := 0 to 4 {
    for j := 0 to 4 {
      h[i, j] := i + j;
    }
  }

  var r := 2;
  var c := 2;
  var max_steps := 100;

  LayerAWatershedUniqueness(h, r, c, max_steps);
}
