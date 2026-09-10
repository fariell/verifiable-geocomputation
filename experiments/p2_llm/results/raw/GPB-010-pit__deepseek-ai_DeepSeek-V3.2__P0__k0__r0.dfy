// Formalization of D8 steepest-descent routing pit condition
// Property: If no neighbor is strictly lower than the center, flow direction is NoFlow.

module P005_D8 {
  // Grid dimensions
  const N: int
  const M: int
  ghost predicate ValidGrid() reads {
    N > 0 && M > 0
  }

  // Height values
  type Height = real
  ghost predicate ValidHeight(h: Height) reads {
    true  // No constraints on height values for this property
  }

  // Flow directions
  datatype FlowDir = 
    | East
    | Southeast
    | South
    | Southwest
    | West
    | Northwest
    | North
    | Northeast
    | NoFlow

  // Neighbor offsets for D8
  const neighborOffsets: seq<(int, int)> := [
    (1, 0),   // E
    (1, 1),   // SE
    (0, 1),   // S
    (-1, 1),  // SW
    (-1, 0),  // W
    (-1, -1), // NW
    (0, -1),  // N
    (1, -1)   // NE
  ]

  // Grid access with bounds checking
  function GridAt(grid: seq<seq<Height>>, r: int, c: int): Height
    requires ValidGrid()
    requires 0 <= r < N && 0 <= c < M
    requires |grid| == N && forall i :: 0 <= i < N ==> |grid[i]| == M
    reads grid
  {
    grid[r][c]
  }

  // D8 steepest-descent computation
  function D8FlowAt(grid: seq<seq<Height>>, r: int, c: int): FlowDir
    requires ValidGrid()
    requires 0 <= r < N && 0 <= c < M
    requires |grid| == N && forall i :: 0 <= i < N ==> |grid[i]| == M
    reads grid
    decreases *
  {
    var center := GridAt(grid, r, c);
    var bestDir: FlowDir := NoFlow;
    var bestPower: real := 0.0;

    var i := 0;
    while i < |neighborOffsets|
      invariant 0 <= i <= |neighborOffsets|
      invariant bestDir == NoFlow ==> bestPower == 0.0
      decreases |neighborOffsets| - i
    {
      var (dr, dc) := neighborOffsets[i];
      var nr := r + dr;
      var nc := c + dc;
      
      if 0 <= nr < N && 0 <= nc < M {
        var neighbor := GridAt(grid, nr, nc);
        var drop := center - neighbor;
        if drop > 0.0 {
          var dist2 := if dr != 0 && dc != 0 then 2.0 else 1.0;
          var power := drop * drop / dist2;
          if bestDir == NoFlow || power > bestPower {
            bestDir := match (dr, dc)
              case (1, 0) => East
              case (1, 1) => Southeast
              case (0, 1) => South
              case (-1, 1) => Southwest
              case (-1, 0) => West
              case (-1, -1) => Northwest
              case (0, -1) => North
              case (1, -1) => Northeast
            };
            bestPower := power;
          }
        }
      }
      i := i + 1;
    }
    
    bestDir
  }

  // Main theorem: pit condition implies NoFlow
  theorem PitImpliesNoFlow(grid: seq<seq<Height>>, r: int, c: int)
    requires ValidGrid()
    requires 0 <= r < N && 0 <= c < M
    requires |grid| == N && forall i :: 0 <= i < N ==> |grid[i]| == M
    requires forall dr, dc :: 
      (dr, dc) in neighborOffsets && 0 <= r + dr < N && 0 <= c + dc < M ==>
        GridAt(grid, r + dr, c + dc) >= GridAt(grid, r, c)
    ensures D8FlowAt(grid, r, c) == NoFlow
    reads grid
  {
    // Proof by contradiction: assume D8FlowAt returns a direction
    if D8FlowAt(grid, r, c) != NoFlow {
      // Then there exists a neighbor with positive drop
      var center := GridAt(grid, r, c);
      
      // Unroll the loop in D8FlowAt to find the contradiction
      var i: int := 0;
      while i < |neighborOffsets|
        invariant 0 <= i <= |neighborOffsets|
        invariant forall j :: 0 <= j < i ==> 
          let (dr, dc) := neighborOffsets[j] in
          !(0 <= r + dr < N && 0 <= c + dc < M && 
            GridAt(grid, r + dr, c + dc) < center)
        decreases |neighborOffsets| - i
      {
        var (dr, dc) := neighborOffsets[i];
        var nr := r + dr;
        var nc := c + dc;
        
        if 0 <= nr < N && 0 <= nc < M {
          var neighbor := GridAt(grid, nr, nc);
          // By precondition, neighbor >= center
          assert neighbor >= center;
          // Therefore drop <= 0, so this neighbor cannot be selected
        }
        i := i + 1;
      }
      
      // After checking all neighbors, no neighbor has positive drop
      // Therefore D8FlowAt must return NoFlow
      assert false; // Contradiction with our assumption
    }
  }

  // Example witness: a 3x3 pit
  method ExamplePit()
    returns (grid: seq<seq<Height>>, r: int, c: int)
    ensures ValidGrid()
    ensures 0 <= r < N && 0 <= c < M
    ensures |grid| == N && forall i :: 0 <= i < N ==> |grid[i]| == M
    ensures forall dr, dc :: 
      (dr, dc) in neighborOffsets && 0 <= r + dr < N && 0 <= c + dc < M ==>
        GridAt(grid, r + dr, c + dc) >= GridAt(grid, r, c)
    ensures D8FlowAt(grid, r, c) == NoFlow
  {
    // Create a 3x3 grid with pit in center
    grid := [
      [1.0, 1.0, 1.0],
      [1.0, 0.0, 1.0],
      [1.0, 1.0, 1.0]
    ];
    N := 3;
    M := 3;
    r := 1;
    c := 1;
    
    // Verify the pit condition
    calc {
      GridAt(grid, 0, 0) >= GridAt(grid, 1, 1);
      GridAt(grid, 0, 1) >= GridAt(grid, 1, 1);
      GridAt(grid, 0, 2) >= GridAt(grid, 1, 1);
      GridAt(grid, 1, 0) >= GridAt(grid, 1, 1);
      GridAt(grid, 1, 2) >= GridAt(grid, 1, 1);
      GridAt(grid, 2, 0) >= GridAt(grid, 1, 1);
      GridAt(grid, 2, 1) >= GridAt(grid, 1, 1);
      GridAt(grid, 2, 2) >= GridAt(grid, 1, 1);
    }
  }
}
