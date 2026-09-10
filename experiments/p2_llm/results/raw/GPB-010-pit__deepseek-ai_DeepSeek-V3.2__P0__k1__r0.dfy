// Formalization of D8 steepest-descent routing pit condition
// Property: If no neighbor is strictly lower than center, flow direction is NoFlow

module P005_D8 {
  // Grid dimensions
  const N: int
  const M: int
  ghost predicate ValidGrid() reads {
    N > 0 && M > 0
  }

  // Height values at grid positions
  function height(r: int, c: int): real
    requires ValidGrid()
    requires 0 <= r < N && 0 <= c < M

  // D8 neighbor offsets (row, column, squared distance)
  const neighborOffsets: seq<(int, int, real)> := [
    (0, 1, 1.0),   // E
    (1, 1, 2.0),   // SE
    (1, 0, 1.0),   // S
    (1, -1, 2.0),  // SW
    (0, -1, 1.0),  // W
    (-1, -1, 2.0), // NW
    (-1, 0, 1.0),  // N
    (-1, 1, 2.0)   // NE
  ]

  // Flow direction type
  datatype FlowDir = 
    | NoFlow()
    | Dir(name: string, dr: int, dc: int)

  // D8 steepest-descent computation
  function D8FlowAt(r: int, c: int): FlowDir
    requires ValidGrid()
    requires 0 <= r < N && 0 <= c < M
    reads height
  {
    var centerHeight := height(r, c);
    var bestDir: FlowDir := NoFlow();
    var bestPower: real := 0.0;
    
    for i := 0 to |neighborOffsets| - 1
      invariant bestDir == NoFlow() || exists j :: 0 <= j < i && 
               bestDir.Dr? && bestDir.Dc? && 
               bestPower == (centerHeight - height(r + bestDir.dr, c + bestDir.dc))^2 / neighborOffsets[j].2
    {
      var (dr, dc, dist2) := neighborOffsets[i];
      var nr := r + dr;
      var nc := c + dc;
      
      if 0 <= nr < N && 0 <= nc < M {
        var neighborHeight := height(nr, nc);
        var drop := centerHeight - neighborHeight;
        if drop > 0.0 {
          var power := drop * drop / dist2;
          if bestDir.NoFlow? || power > bestPower {
            bestDir := Dir("", dr, dc);
            bestPower := power;
          }
        }
      }
    }
    bestDir
  }

  // Predicate: No neighbor is strictly lower than center
  predicate NoLowerNeighbor(r: int, c: int)
    requires ValidGrid()
    requires 0 <= r < N && 0 <= c < M
    reads height
  {
    forall dr, dc :: 
      (dr, dc) in neighborOffsets[..].(0,1) ==> 
      (0 <= r + dr < N && 0 <= c + dc < M) ==> 
      height(r + dr, c + dc) >= height(r, c)
  }

  // Main theorem: If no neighbor is strictly lower, flow is NoFlow
  theorem D8PitNoFlow(r: int, c: int)
    requires ValidGrid()
    requires 0 <= r < N && 0 <= c < M
    requires NoLowerNeighbor(r, c)
    ensures D8FlowAt(r, c) == NoFlow()
  {
    // Show that for every neighbor, either:
    // 1. It's out of bounds, or
    // 2. Its height >= center height (so drop <= 0)
    
    // The loop in D8FlowAt examines all 8 neighbors
    // We need to prove that no neighbor satisfies drop > 0
    
    // Proof by contradiction: assume some neighbor gives drop > 0
    if D8FlowAt(r, c) != NoFlow() {
      // Then there exists a neighbor with drop > 0
      var dir := D8FlowAt(r, c);
      assert dir.Dr?; // Because it's not NoFlow
      var dr := dir.dr;
      var dc := dir.dc;
      
      // This neighbor must be in bounds (from D8FlowAt logic)
      assert 0 <= r + dr < N && 0 <= c + dc < M;
      
      // And must have drop > 0
      var drop := height(r, c) - height(r + dr, c + dc);
      assert drop > 0.0;
      
      // But NoLowerNeighbor says all neighbors have height >= center
      assert height(r + dr, c + dc) >= height(r, c);
      // Contradiction: drop > 0 implies height(neighbor) < height(center)
      assert false;
    }
  }

  // Example: 3x3 pit with rim height 1, center height 0
  method ExamplePit()
    requires ValidGrid()
    requires N >= 3 && M >= 3
    ensures exists r, c :: 0 <= r < N && 0 <= c < M && D8FlowAt(r, c) == NoFlow()
  {
    // Construct a pit at position (1,1)
    assume forall dr, dc :: 
      (dr, dc) in neighborOffsets[..].(0,1) ==> 
      height(1 + dr, 1 + dc) == 1.0;
    assume height(1, 1) == 0.0;
    
    // Verify the pit condition
    assert NoLowerNeighbor(1, 1);
    
    // Apply the theorem
    D8PitNoFlow(1, 1);
    
    // Witness exists
    assert D8FlowAt(1, 1) == NoFlow();
  }
}
