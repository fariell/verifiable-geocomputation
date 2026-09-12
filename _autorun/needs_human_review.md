# VERIFIED_NEEDS_HUMAN 人工判定表

> **本表共 10 条**,生成于 **2026-09-12 04:59 UTC**。重跑会使条数变化,以最新版为准。

由 `_autorun/extract_needs_human.py` 自动生成,只读,不改实验数据。

共 **10 条**,来自 4 个题目。


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
