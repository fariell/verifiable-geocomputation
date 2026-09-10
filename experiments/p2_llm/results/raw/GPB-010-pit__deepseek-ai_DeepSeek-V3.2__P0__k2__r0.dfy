// Formal specification of D8 steepest-descent routing pit condition
// Property: If no neighbor is strictly lower than the center, flow direction is NoFlow.

// Grid dimensions and adjacency definitions
type GridIndex = (r: int, c: int)
type Direction = (
    | E
    | SE
    | S
    | SW
    | W
    | NW
    | N
    | NE
    | NoFlow
)

// Grid with positive dimensions
datatype Grid = Grid(elevations: array2<real>, rows: int, cols: int)
    requires rows > 0 && cols > 0
    requires elevations.Length0 == rows && elevations.Length1 == cols

// Valid grid indices
predicate InGrid(g: Grid, idx: GridIndex)
{
    0 <= idx.r < g.rows && 0 <= idx.c < g.cols
}

// D8 neighbor offsets with distances
const D8_NEIGHBORS: seq<(dp: int, dq: int, dist2: real)> :=
    [
        (1, 0, 1.0),   // E
        (1, 1, 2.0),   // SE
        (0, 1, 1.0),   // S
        (-1, 1, 2.0),  // SW
        (-1, 0, 1.0),  // W
        (-1, -1, 2.0), // NW
        (0, -1, 1.0),  // N
        (1, -1, 2.0)   // NE
    ];

// Get neighbor index
function NeighborIndex(center: GridIndex, offset: (dp: int, dq: int)): GridIndex
{
    (center.r + offset.dq, center.c + offset.dp)
}

// D8 flow direction calculation
function D8Flow(g: Grid, center: GridIndex): Direction
    requires InGrid(g, center)
    decreases *
{
    var center_elev := g.elevations[center.r, center.c];
    var best_dir: Direction := NoFlow;
    var best_power: real := 0.0;
    
    // Check all 8 neighbors
    for i := 0 to |D8_NEIGHBORS| - 1
        invariant best_dir == NoFlow || best_power > 0.0
    {
        var offset := D8_NEIGHBORS[i];
        var neighbor_idx := NeighborIndex(center, offset);
        
        if InGrid(g, neighbor_idx) {
            var neighbor_elev := g.elevations[neighbor_idx.r, neighbor_idx.c];
            var drop := center_elev - neighbor_elev;
            
            if drop > 0.0 {
                var power := (drop * drop) / offset.dist2;
                if best_dir == NoFlow || power > best_power {
                    best_dir := match i
                        case 0 => E
                        case 1 => SE
                        case 2 => S
                        case 3 => SW
                        case 4 => W
                        case 5 => NW
                        case 6 => N
                        case 7 => NE
                    ;
                    best_power := power;
                }
            }
        }
    }
    
    best_dir
}

// Predicate: No neighbor is strictly lower than center
predicate NoLowerNeighbor(g: Grid, center: GridIndex)
    requires InGrid(g, center)
{
    forall offset :: offset in D8_NEIGHBORS ==>
        !InGrid(g, NeighborIndex(center, offset)) ||
        g.elevations[center.r, center.c] <= g.elevations[NeighborIndex(center, offset).r, NeighborIndex(center, offset).c]
}

// Main theorem: If no neighbor is strictly lower, flow is NoFlow
theorem D8PitNoFlow(g: Grid, center: GridIndex)
    requires InGrid(g, center)
    requires NoLowerNeighbor(g, center)
    ensures D8Flow(g, center) == NoFlow
{
    // Proof by contradiction: assume flow is not NoFlow
    if D8Flow(g, center) != NoFlow {
        // Then there exists a neighbor with positive drop
        var center_elev := g.elevations[center.r, center.c];
        
        // Unfold the definition of D8Flow
        var best_dir := NoFlow;
        var best_power: real := 0.0;
        
        for i := 0 to |D8_NEIGHBORS| - 1
            invariant best_dir == NoFlow || best_power > 0.0
            invariant forall j :: 0 <= j < i ==>
                !(InGrid(g, NeighborIndex(center, D8_NEIGHBORS[j])) &&
                  center_elev - g.elevations[NeighborIndex(center, D8_NEIGHBORS[j]).r, NeighborIndex(center, D8_NEIGHBORS[j]).c] > 0.0)
        {
            var offset := D8_NEIGHBORS[i];
            var neighbor_idx := NeighborIndex(center, offset);
            
            if InGrid(g, neighbor_idx) {
                var neighbor_elev := g.elevations[neighbor_idx.r, neighbor_idx.c];
                var drop := center_elev - neighbor_elev;
                
                // By NoLowerNeighbor hypothesis, drop cannot be positive
                assert drop <= 0.0 by {
                    // This follows directly from the precondition
                    assert g.elevations[center.r, center.c] <= neighbor_elev;
                }
            }
        }
        
        // After checking all neighbors, best_dir must still be NoFlow
        assert best_dir == NoFlow;
        // Contradiction with our assumption
        assert false;
    }
}

// Example: 3×3 pit with rim height 1 and center height 0
method ExamplePit()
{
    var rows := 3;
    var cols := 3;
    var elevations := new real[rows, cols];
    
    // Initialize pit
    elevations[0,0] := 1.0; elevations[0,1] := 1.0; elevations[0,2] := 1.0;
    elevations[1,0] := 1.0; elevations[1,1] := 0.0; elevations[1,2] := 1.0;
    elevations[2,0] := 1.0; elevations[2,1] := 1.0; elevations[2,2] := 1.0;
    
    var g := Grid(elevations, rows, cols);
    var center: GridIndex := (1, 1);
    
    // Verify the pit condition
    assert InGrid(g, center);
    
    // Check that no neighbor is strictly lower
    assert NoLowerNeighbor(g, center) by {
        forall offset | offset in D8_NEIGHBORS
            ensures !InGrid(g, NeighborIndex(center, offset)) ||
                    g.elevations[center.r, center.c] <= g.elevations[NeighborIndex(center, offset).r, NeighborIndex(center, offset).c]
        {
            // All neighbors have elevation 1.0, center has 0.0
            // So center <= neighbor (0.0 <= 1.0) holds
        }
    }
    
    // Apply the theorem
    D8PitNoFlow(g, center);
    assert D8Flow(g, center) == NoFlow;
}
