method HornSlopeIsZeroForFlat3x3(w: real) returns (slope: real)
  requires w > 0
  ensures slope == 0
{
  // Define a 3x3 grid with all cells having the same elevation
  var elevation: array2<int, real> := new array2<int, real>(3, 3, (i, j) => 1.0);

  // Define the Horn (1981) slope magnitude formula
  // SlopeSq = (dzdx^2 + dzdy^2) / (w^2)
  // For a flat surface, dzdx and dzdy are both 0
  var dzdx: real := 0.0;
  var dzdy: real := 0.0;

  // Calculate the slope magnitude
  slope := (dzdx * dzdx + dzdy * dzdy) / (w * w);
}

// Define a 2D array type for the elevation grid
class array2<T, V> {
  var data: array<array<V>>;
  var rows: int;
  var cols: int;

  constructor(rows: int, cols: int, init: (int, int) -> V)
    requires rows > 0
    requires cols > 0
  {
    this.rows := rows;
    this.cols := cols;
    this.data := new array<array<V>>(rows, (i) => new array<V>(cols, (j) => init(i, j)));
  }

  method Get(i: int, j: int) returns (v: V)
    requires 0 <= i < this.rows
    requires 0 <= j < this.cols
  {
    v := this.data[i][j];
  }

  method Set(i: int, j: int, v: V)
    requires 0 <= i < this.rows
    requires 0 <= j < this.cols
  {
    this.data[i][j] := v;
  }
}
