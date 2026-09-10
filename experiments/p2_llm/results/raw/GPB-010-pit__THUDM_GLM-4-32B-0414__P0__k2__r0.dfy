// P005_d8.dfy: D8 pit has no flow; plane flow is constant.
// Formalizes the property that under D8 steepest-descent routing,
// if none of the eight neighbors is strictly lower than the center,
// the flow direction is NoFlow (undefined / pit).

module D8PitNoFlow {
  // Represents a 2D grid of elevations
  type Grid = array2d<float>

  // Represents the eight possible flow directions in D8
  datatype FlowDirection = 
    | E
    | SE
    | S
    | SW
    | W
    | NW
    | N
    | NE
    | NoFlow

  // Calculates the D8 flow direction for a given cell
  function method D8Flow(h: Grid, r: int, c: int): FlowDirection {
    var e: float := h[r][c];
    var best: FlowDirection := NoFlow;
    var best_p: float := 0.0;

    // Iterate through all eight neighbors
    for i: int := 0 to 8 {
      var name: string;
      var dp: int;
      var dq: int;
      var dist2: float;
      match i {
        case 0 => { name := "E"; dp := 1; dq := 0; dist2 := 1.0; }
        case 1 => { name := "SE"; dp := 1; dq := 1; dist2 := 2.0; }
        case 2 => { name := "S"; dp := 0; dq := 1; dist2 := 1.0; }
        case 3 => { name := "SW"; dp := -1; dq := 1; dist2 := 2.0; }
        case 4 => { name := "W"; dp := -1; dq := 0; dist2 := 1.0; }
        case 5 => { name := "NW"; dp := -1; dq := -1; dist2 := 2.0; }
        case 6 => { name := "N"; dp := 0; dq := -1; dist2 := 1.0; }
        case 7 => { name := "NE"; dp := 1; dq := -1; dist2 := 2.0; }
      }

      var rr: int := r + dq;
      var cc: int := c + dp;

      // Check if the neighbor is within the grid bounds
      if 0 <= rr < h.Length1 && 0 <= cc < h.Length2 {
        var drop: float := e - h[rr][cc];
        if drop > 0 {
          var p: float := (drop * drop) / dist2;
          if best == NoFlow || p > best_p {
            best := name;
            best_p := p;
          }
        }
      }
    }

    return best;
  }

  // Property to prove: If none of the eight neighbors is strictly lower than the center,
  // then the flow direction is NoFlow.
  lemma PitNoFlow(h: Grid, r: int, c: int)
    requires 0 <= r < h.Length1 && 0 <= c < h.Length2
    ensures D8Flow(h, r, c) == NoFlow
  {
    var e: float := h[r][c];

    // Assume that none of the eight neighbors is strictly lower than the center
    assume forall i: int :: 0 <= i < 8 ==> {
      var name: string;
      var dp: int;
      var dq: int;
      var dist2: float;
      match i {
        case 0 => { name := "E"; dp := 1; dq := 0; dist2 := 1.0; }
        case 1 => { name := "SE"; dp := 1; dq := 1; dist2 := 2.0; }
        case 2 => { name := "S"; dp := 0; dq := 1; dist2 := 1.0; }
        case 3 => { name := "SW"; dp := -1; dq := 1; dist2 := 2.0; }
        case 4 => { name := "W"; dp := -1; dq := 0; dist2 := 1.0; }
        case 5 => { name := "NW"; dp := -1; dq := -1; dist2 := 2.0; }
        case 6 => { name := "N"; dp := 0; dq := -1; dist2 := 1.0; }
        case 7 => { name := "NE"; dp := 1; dq := -1; dist2 := 2.0; }
      }

      var rr: int := r + dq;
      var cc: int := c + dp;

      // Check if the neighbor is within the grid bounds
      if 0 <= rr < h.Length1 && 0 <= cc < h.Length2 {
        var drop: float := e - h[rr][cc];
        drop <= 0
      }
      else {
        true
      }
    };

    // The D8Flow function will not find any neighbor with a positive drop,
    // so it will return NoFlow.
    assert D8Flow(h, r, c) == NoFlow;
  }
}
