# VERIFIED_NEEDS_HUMAN 人工判定表

由秘书自动生成(`_autorun/extract_needs_human.py`),只读,不改实验数据。

共 **17 条**,来自 6 个题目,全部由 DeepSeek-R1 生成。


## 判定方法(照着做)

对每一条,只回答一个问题:**它证明的还是原来那个命题吗?**

看三处,按这个顺序:

1. **`ensures` 是否等价于 gold 结论**。弱化(把 `== 0` 写成 `>= 0`)、加限定(只在某分支成立)、换成另一个量,都算漂移。

2. **`requires` 是否引入了 gold 没有的假设**。多加一个前提让命题变简单,算漂移;
   只是把 gold 里隐含的条件(如 `w > 0`)写明,**不算**漂移。

3. **有没有作弊**。下表的红旗列标了 `assume` / `axiom` 出现次数。
   只要证明体里用 `assume` 断言了结论本身,无论机器是否通过,一律判 DRIFT。


判定写 ALIGNED / DRIFT / UNDECIDABLE 三者之一,填进每条的「判定」栏。

**UNDECIDABLE 是合法答案**,不要为了凑数硬判。


---


## GPB-001-flat  (3 条)


**gold 命题(natural_spec):**


> On any 3x3 elevation window with finite values, if all nine cells share the same elevation, the Horn (1981) slope magnitude (equivalently its square SlopeSq) is identically zero. Grid spacing w must be positive.


### DeepSeek-R1 · P0 · k3


- 文件:`GPB-001-flat__deepseek-ai_DeepSeek-R1__P0__k3__r0.dfy`(36 行)
- 红旗:**无**
- **判定**:____________


```dafny
function HornSlopeSq(m: Matrix33, w: real): real
    requires w > 0.0

lemma AllEqualImpliesZeroSlope(m: Matrix33, w: real)
    requires w > 0.0
    requires m.z00 == m.z01 && m.z00 == m.z02 &&
    ensures HornSlopeSq(m, w) == 0.0
```


### DeepSeek-R1 · P2 · k3


- 文件:`GPB-001-flat__deepseek-ai_DeepSeek-R1__P2__k3__r0.dfy`(26 行)
- 红旗:**无**
- **判定**:____________


```dafny
function HornSlopeSq(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0

lemma Theorem(a: real, b: real, c: real, d: real, e: real, f: real, g: real, h: real, i: real, w: real)
    requires w > 0.0
    requires a == b && b == c && c == d && d == e && e == f && f == g && g == h && h == i
    ensures HornSlopeSq(a, b, c, d, e, f, g, h, i, w) == 0.0
```


### DeepSeek-R1 · P2 · k4


- 文件:`GPB-001-flat__deepseek-ai_DeepSeek-R1__P2__k4__r0.dfy`(33 行)
- 红旗:**无**
- **判定**:____________


```dafny
function dzdx(elev: (int, int) -> real, w: real): real
    requires w > 0.0

function dzdy(elev: (int, int) -> real, w: real): real
    requires w > 0.0

function SlopeSq(elev: (int, int) -> real, w: real): real
    requires w > 0.0

lemma Theorem(elev: (int, int) -> real, w: real)
    requires w > 0.0
    requires forall i,j :: 0 <= i < 3 && 0 <= j < 3 ==> elev(i,j) == elev(0,0)
    ensures SlopeSq(elev, w) == 0.0
```


---


## GPB-002-planar  (4 条)


**gold 命题(natural_spec):**


> On a planar surface z = A*x + B*y + C sampled on a regular grid with spacing w>0, the Horn finite-difference estimates DzDx and DzDy recover A and B exactly (identity, not merely asymptotically).


### DeepSeek-R1 · P1 · k0


- 文件:`GPB-002-planar__deepseek-ai_DeepSeek-R1__P1__k0__r0.dfy`(82 行)
- 红旗:**无**
- **判定**:____________


```dafny
function HornDzDx(d: real, f: real, w: real): real
    requires w > 0.0

function HornDzDy(b: real, h: real, w: real): real
    requires w > 0.0

function PlaneZ(A: real, B: real, C: real, x: real, y: real): real

lemma TheoremExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0  // 网格间距必须为正
    ensures HornDzDx( PlaneZ(A, B, C, -w, 0.0),  // d = z(-w, 0) PlaneZ(A, B, C, w, 0.0),   // f = z(w, 0) w ) == A
    ensures HornDzDy( PlaneZ(A, B, C, 0.0, -w),  // b = z(0, -w) PlaneZ(A, B, C, 0.0, w),   // h = z(0, w) w ) == B

method Main() {
```


### DeepSeek-R1 · P1 · k1


- 文件:`GPB-002-planar__deepseek-ai_DeepSeek-R1__P1__k1__r0.dfy`(110 行)
- 红旗:**无**
- **判定**:____________


```dafny
function HornDzDx(a: real, d: real, g: real, c: real, f: real, i: real, w: real): real
    requires w > 0.0

function HornDzDy(a: real, b: real, c: real, g: real, h: real, i: real, w: real): real
    requires w > 0.0

function PlaneAt(x: real, y: real, A: real, B: real, C: real): real

function a(A: real, B: real, C: real, w: real): real { PlaneAt(-w, -w, A, B, C) }
    requires w > 0.0
    ensures HornDzDx( a(A,B,C,w), d(A,B,C,w), g(A,B,C,w), c(A,B,C,w), f(A,B,C,w), i(A,B,C,w), w) == A
    ensures HornDzDy( a(A,B,C,w), b(A,B,C,w), c(A,B,C,w), g(A,B,C,w), h(A,B,C,w), i(A,B,C,w), w) == B

method Main() {
```


### DeepSeek-R1 · P1 · k2


- 文件:`GPB-002-planar__deepseek-ai_DeepSeek-R1__P1__k2__r0.dfy`(158 行)
- 红旗:**无**
- **判定**:____________


```dafny
function plane(x: real, y: real, A: real, B: real, C: real): real

function Qa(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qb(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qc(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qd(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qe(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qf(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qg(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qh(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function Qi(A: real, B: real, C: real, w: real): real
    requires w > 0.0

function HornDzDx(
    requires w > 0.0

function HornDzDy(
    requires w > 0.0

lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures HornDzDx( Qa(A,B,C,w), Qd(A,B,C,w), Qg(A,B,C,w), Qc(A,B,C,w), Qf(A,B,C,w), Qi(A,B,C,w), w ) == A
    ensures HornDzDy( Qa(A,B,C,w), Qb(A,B,C,w), Qc(A,B,C,w), Qg(A,B,C,w), Qh(A,B,C,w), Qi(A,B,C,w), w ) == B

method Main() {
```


### DeepSeek-R1 · P1 · k4


- 文件:`GPB-002-planar__deepseek-ai_DeepSeek-R1__P1__k4__r0.dfy`(65 行)
- 红旗:**无**
- **判定**:____________


```dafny
function PlaneZ(x: real, y: real, A: real, B: real, C: real): real

function HornDx(d: real, f: real, w: real): real
    requires w > 0.0

function HornDy(b: real, h: real, w: real): real
    requires w > 0.0

lemma HornExactOnPlane(A: real, B: real, C: real, w: real)
    requires w > 0.0
    ensures HornDx( PlaneZ(-w, 0.0, A, B, C),  // d = z(-w, 0) PlaneZ( w, 0.0, A, B, C),   // f = z( w, 0) w ) == A
    ensures HornDy( PlaneZ(0.0, -w, A, B, C),  // b = z(0, -w) PlaneZ(0.0,  w, A, B, C),   // h = z(0,  w) w ) == B

method Main() {
```


---


## GPB-019-quad  (1 条)


**gold 命题(natural_spec):**


> Horn slope is exact on quadratic surfaces: DzDx and DzDy recover the true planar gradient coefficients (A,B) identically. Separately, on z = G x^3 the DzDx remainder at the origin equals G w^2 (order O(w^2)).


### DeepSeek-R1 · P1 · k1


- 文件:`GPB-019-quad__deepseek-ai_DeepSeek-R1__P1__k1__r0.dfy`(153 行)
- 红旗:**无**
- **判定**:____________


```dafny
function NumDx(a: real, b: real, c: real, d: real, f: real,

function NumDy(a: real, b: real, c: real, d: real, f: real,

function DzDx(a: real, b: real, c: real, d: real, f: real,
    requires w > 0.0

function DzDy(a: real, b: real, c: real, d: real, f: real,
    requires w > 0.0

function quadratic_z(A: real, B: real, C: real, D: real, E: real, F: real,

function quad_a(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

function quad_b(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

function quad_c(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

function quad_d(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

function quad_f(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

function quad_g(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

function quad_h(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

function quad_i(A: real, B: real, C: real, D: real, E: real, F: real, w: real): real

lemma QuadraticExactness(A: real, B: real, C: real, D: real, E: real, F: real, w: real)
    requires w > 0.0
    ensures DzDx(quad_a(A,B,C,D,E,F,w), quad_b(A,B,C,D,E,F,w), quad_c(A,B,C,D,E,F,w), quad_d(A,B,C,D,E,F,w), quad_f(A,B,C,D,E,F,w), quad_g(A,B,C,D,E,F,w), quad_h(A,B,C,D,E,F,w), quad_i(A,B,C,D,E,F,w), w)
    ensures DzDy(quad_a(A,B,C,D,E,F,w), quad_b(A,B,C,D,E,F,w), quad_c(A,B,C,D,E,F,w), quad_d(A,B,C,D,E,F,w), quad_f(A,B,C,D,E,F,w), quad_g(A,B,C,D,E,F,w), quad_h(A,B,C,D,E,F,w), quad_i(A,B,C,D,E,F,w), w)

function cubic_z(G: real, x: real, y: real): real

function cubic_a(G: real, w: real): real { cubic_z(G, -w, -w) }
    requires w > 0.0
    ensures DzDx(cubic_a(G,w), cubic_b(G,w), cubic_c(G,w), cubic_d(G,w), cubic_f(G,w), cubic_g(G,w), cubic_h(G,w), cubic_i(G,w), w)

method Main() {
```


---


## GPB-P002-idem  (1 条)


**gold 命题(natural_spec):**


> Pit filling is idempotent on the 1D left-outlet specialization: Fill(Fill(a)) = Fill(a). Cells that already do not spill to the left are fixed points of Raise.


### DeepSeek-R1 · P0 · k2


- 文件:`GPB-P002-idem__deepseek-ai_DeepSeek-R1__P0__k2__r0.dfy`(61 行)
- 红旗:**无**
- **判定**:____________


```dafny
function prefixMax(a: seq<int>, i: int): int
    requires 0 <= i < |a|
    decreases i

function Fill(a: seq<int>): seq<int>
    requires |a| > 0

lemma NonDecreasing(a: seq<int>)
    requires |a| > 0
    ensures forall j :: 0 <= j < |a|-1 ==> Fill(a)[j] <= Fill(a)[j+1]

lemma LemmaPrefixMaxForNonDecreasing(b: seq<int>, i: int)
    requires |b| > 0
    requires 0 <= i < |b|
    requires forall j :: 0 <= j < |b|-1 ==> b[j] <= b[j+1]
    ensures prefixMax(b, i) == b[i]
    decreases i

lemma Idempotent(a: seq<int>)
    requires |a| > 0
    ensures Fill(Fill(a)) == Fill(a)

lemma FixedPoint(a: seq<int>, i: int)
    requires |a| > 0
    requires 0 <= i < |a|
    requires prefixMax(a, i) == a[i]
    ensures Fill(a)[i] == a[i]
```


---


## GPB-P002-mono  (6 条)


**gold 命题(natural_spec):**


> Consider the 1D Wang-Liu pit-filling specialization Fill with left outlet: Fill[0]=orig[0], Fill[i]=max(orig[i], Fill[i-1]). Each raise is monotone: no cell elevation decreases. After a full scan the profile is nondecreasing.


### DeepSeek-R1 · P0 · k0


- 文件:`GPB-P002-mono__deepseek-ai_DeepSeek-R1__P0__k0__r0.dfy`(19 行)
- 红旗:**无**
- **判定**:____________


```dafny
method FillWangLiu(orig: array<real>) returns (fill: array<real>)
    requires orig != null && orig.Length >= 1
    ensures fill != null && fill.Length == orig.Length
    ensures forall i :: 0 <= i < orig.Length ==> fill[i] >= orig[i]  // Monotonicity
    ensures forall i :: 1 <= i < orig.Length ==> fill[i] >= fill[i-1]  // Non-decreasing
```


### DeepSeek-R1 · P0 · k2


- 文件:`GPB-P002-mono__deepseek-ai_DeepSeek-R1__P0__k2__r0.dfy`(30 行)
- 红旗:**无**
- **判定**:____________


```dafny
function max(a: real, b: real): real {
    ensures |Fill(orig)| == |orig|
    ensures |orig| > 0 ==> Fill(orig)[0] == orig[0]
    ensures forall i :: 1 <= i < |orig| ==> Fill(orig)[i] == max(orig[i], Fill(orig)[i-1])
    ensures forall i, j :: 0 <= i <= j < |orig| ==> Fill(orig)[i] <= Fill(orig)[j]

function FillRest(rest: seq<real>, prev: real): seq<real>
    ensures |FillRest(rest, prev)| == |rest|
    ensures |rest| > 0 ==> FillRest(rest, prev)[0] == max(rest[0], prev)
    ensures forall i :: 1 <= i < |rest| ==> FillRest(rest, prev)[i] == max(rest[i], FillRest(rest, prev)[i-1])
    ensures forall i, j :: 0 <= i <= j < |rest| ==> FillRest(rest, prev)[i] <= FillRest(rest, prev)[j]
    ensures |rest| > 0 ==> FillRest(rest, prev)[0] >= prev
```


### DeepSeek-R1 · P2 · k0


- 文件:`GPB-P002-mono__deepseek-ai_DeepSeek-R1__P2__k0__r0.dfy`(19 行)
- 红旗:**无**
- **判定**:____________


```dafny
method Fill(orig: array<int>) returns (fill: array<int>)
    requires orig.Length >= 1
    ensures fill.Length == orig.Length
    ensures forall i :: 0 <= i < fill.Length ==> fill[i] >= orig[i]  // Monotonicity
    ensures forall i :: 0 <= i < fill.Length-1 ==> fill[i] <= fill[i+1]  // Nondecreasing
```


### DeepSeek-R1 · P2 · k2


- 文件:`GPB-P002-mono__deepseek-ai_DeepSeek-R1__P2__k2__r0.dfy`(28 行)
- 红旗:**无**
- **判定**:____________


```dafny
method Fill(orig: array<int>) returns (fill: array<int>)
    requires orig.Length > 0
    ensures fill.Length == orig.Length
    ensures fill[0] == orig[0]
    ensures forall i :: 1 <= i < orig.Length ==> fill[i] == (if orig[i] > fill[i-1] then orig[i] else fill[i-1])
    ensures forall i :: 0 <= i < orig.Length ==> orig[i] <= fill[i]
    ensures forall i :: 0 <= i < orig.Length - 1 ==> fill[i] <= fill[i+1]
```


### DeepSeek-R1 · P2 · k3


- 文件:`GPB-P002-mono__deepseek-ai_DeepSeek-R1__P2__k3__r0.dfy`(26 行)
- 红旗:**无**
- **判定**:____________


```dafny
method FillPits(orig: array<int>) returns (fill: array<int>)
    requires orig != null
    ensures fill != null && fill.Length == orig.Length
    ensures forall i :: 0 <= i < fill.Length ==> fill[i] >= orig[i]
    ensures forall i :: 1 <= i < fill.Length ==> fill[i] >= fill[i-1]
```


### DeepSeek-R1 · P2 · k4


- 文件:`GPB-P002-mono__deepseek-ai_DeepSeek-R1__P2__k4__r0.dfy`(19 行)
- 红旗:**无**
- **判定**:____________


```dafny
method Fill(orig: array<int>) returns (fill: array<int>)
    requires orig != null
    ensures fill != null && fill.Length == orig.Length
    ensures forall i | 0 <= i < orig.Length :: fill[i] >= orig[i]  // Monotonicity
    ensures forall i | 0 <= i < orig.Length - 1 :: fill[i] <= fill[i+1]  // Nondecreasing
```


---


## GPB-P002bis-raise  (2 条)


**gold 命题(natural_spec):**


> In the 2D local raise step RaiseNbr, raising a 4-neighbor from an already-processed cell never decreases any cell elevation, and the neighbor is lifted at least to max(original neighbor, processed cell fill).


### DeepSeek-R1 · P2 · k0


- 文件:`GPB-P002bis-raise__deepseek-ai_DeepSeek-R1__P2__k0__r0.dfy`(24 行)
- 红旗:**无**
- **判定**:____________


```dafny
function max(a: int, b: int): int {
    requires grid != null
    requires 0 <= processed.0 < grid.Length0 && 0 <= processed.1 < grid.Length1
    requires 0 <= neighbor.0 < grid.Length0 && 0 <= neighbor.1 < grid.Length1
    requires Is4Neighbor(processed, neighbor)
    modifies grid
    ensures grid[neighbor.0, neighbor.1] >= max(old(grid[neighbor.0, neighbor.1]), old(grid[processed.0, processed.1]))
    ensures forall i, j :: 0 <= i < grid.Length0 && 0 <= j < grid.Length1 && (i, j) != (neighbor.0, neighbor.1) ==> grid[i, j] == old(grid[i, j])
```


### DeepSeek-R1 · P2 · k4


- 文件:`GPB-P002bis-raise__deepseek-ai_DeepSeek-R1__P2__k4__r0.dfy`(28 行)
- 红旗:**无**
- **判定**:____________


```dafny
function abs(x: int): int {
    requires grid != null && processed != null
    requires grid.Length0 == processed.Length0 && grid.Length1 == processed.Length1
    requires 0 <= c_row < grid.Length0 && 0 <= c_col < grid.Length1
    requires processed[c_row, c_col] == true
    requires abs(dx) + abs(dy) == 1
    requires 0 <= c_row+dx < grid.Length0 && 0 <= c_col+dy < grid.Length1
    modifies grid
    ensures grid[c_row, c_col] == old(grid[c_row, c_col])
    ensures forall i,j :: 0<=i<grid.Length0 && 0<=j<grid.Length1 && (i != c_row+dx || j != c_col+dy) ==> grid[i,j] == old(grid[i,j])
    ensures grid[c_row+dx, c_col+dy] >= old(grid[c_row+dx, c_col+dy])
    ensures grid[c_row+dx, c_col+dy] >= old(grid[c_row, c_col])
    ensures grid[c_row+dx, c_col+dy] == max(old(grid[c_row+dx, c_col+dy]), old(grid[c_row, c_col]))
```
