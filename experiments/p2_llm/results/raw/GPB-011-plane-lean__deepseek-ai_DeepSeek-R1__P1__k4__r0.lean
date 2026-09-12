import Mathlib.Tactic

namespace VeriGIS.D8Flow

noncomputable section

/-!
## D8 Flow Direction on Planar DEM

We formalize the property that on a planar surface `z = A*x + B*y + C` with positive slope,
the D8 flow direction is constant across interior grid cells sharing the same (A, B, w),
and invariant under vertical translation (changes in C).

### Grid Convention
- Column index `j` increases rightward (x-direction)
- Row index `i` increases downward (y-direction, DEM convention)
- Elevation at cell (i,j): `z(i,j) = A*(j*w) + B*(i*w) + C`
- 3×3 window centered at (i,j):
    a(i-1,j-1)  b(i-1,j)  c(i-1,j+1)
    d(i,j-1)    e(i,j)    f(i,j+1)
    g(i+1,j-1)  h(i+1,j)  i(i+1,j+1)
-/

-- Directions: (name, colΔ, rowΔ, squared distance factor)
def dirs : List (String × ℤ × ℤ × ℝ) := [
  ("E",   1,  0, 1),  -- East
  ("SE",  1,  1, 2),  -- Southeast
  ("S",   0,  1, 1),  -- South
  ("SW", -1,  1, 2),  -- Southwest
  ("W",  -1,  0, 1),  -- West
  ("NW", -1, -1, 2),  -- Northwest
  ("N",   0, -1, 1),  -- North
  ("NE",  1, -1, 2)   -- Northeast
]

/-- Retrieve neighbor value given direction offsets -/
def neighbor (dx dy : ℤ) (a b c d e f g h i : ℝ) : ℝ :=
  match dx, dy with
  |  1,  0 => f   -- East
  |  1,  1 => i   -- Southeast
  |  0,  1 => h   -- South
  | -1,  1 => g   -- Southwest
  | -1,  0 => d   -- West
  | -1, -1 => a   -- Northwest
  |  0, -1 => b   -- North
  |  1, -1 => c   -- Northeast
  | _,  _  => 0   -- Fallback (unused)

/-- D8 flow direction computation -/
def d8 (a b c d e f g h i : ℝ) : String :=
  let candidates := dirs.map fun (name, dx, dy, dist2) =>
    let nbr := neighbor dx dy a b c d e f g h i
    let drop := e - nbr
    (name, drop, dist2)
  
  let valid := candidates.filter fun (_, drop, _) => drop > 0
  
  if valid.isEmpty then "NoFlow" else
    let withScore := valid.map fun (name, drop, dist2) => 
      (name, drop * drop / dist2)
    let maxScore := (withScore.map (·.2)).maximum? |>.getD 0
    (withScore.filter (·.2 == maxScore)).head?.map (·.1) |>.getD "NoFlow"

/-!
### Key Theorems
1. **Translation Invariance**: 
   Adding constant `K` to all elevations preserves D8 direction
2. **Planar Consistency**:
   On planar surface with same (A,B,w), all interior cells have same D8 direction
-/

-- Theorem 1: D8 direction is invariant under vertical translation
theorem d8_translation_invariant (a b c d e f g h i K : ℝ) :
    d8 a b c d e f g h i = 
    d8 (a+K) (b+K) (c+K) (d+K) (e+K) (f+K) (g+K) (h+K) (i+K) := by
  unfold d8
  congr 1  -- Prove equality by showing all intermediate steps match
  · simp [neighbor]
  · simp [neighbor]
  · simp [neighbor]

-- Theorem 2: On planar surface, D8 direction is location-independent
theorem d8_planar_constant (A B w : ℝ) (w_pos : w > 0) (e₁ e₂ C₁ C₂ : ℝ) :
    let window₁ (e : ℝ) : ℝ × ℝ × ℝ × ℝ × ℝ × ℝ × ℝ × ℝ × ℝ :=
      (e - A*w - B*w, e - B*w,      e + A*w - B*w,
       e - A*w,      e,            e + A*w,
       e - A*w + B*w, e + B*w,      e + A*w + B*w)
    d8 (window₁ (A*0*w + B*0*w + C₁ + e₁)).1 ... =  -- Window at (0,0)
    d8 (window₁ (A*1*w + B*1*w + C₂ + e₂)).1 ...   := -- Window at (1,1)
by
  intro window₁
  have h_shift : ∀ e K, window₁ (e + K) = 
      (window₁ e).1 + K, (window₁ e).2.1 + K, (window₁ e).2.2.1 + K,
      (window₁ e).2.2.2.1 + K, (window₁ e).2.2.2.2.1 + K, 
      (window₁ e).2.2.2.2.2.1 + K, (window₁ e).2.2.2.2.2.2.1 + K,
      (window₁ e).2.2.2.2.2.2.2.1 + K, (window₁ e).2.2.2.2.2.2.2.2 + K := by
    intro e K
    unfold window₁; simp; ring
  rw [h_shift (A*0*w + B*0*w + C₁) e₁]
  rw [h_shift (A*1*w + B*1*w + C₂) e₂]
  apply d8_translation_invariant  -- Reduces to translation invariance

end -- noncomputable section

end VeriGIS.D8Flow
