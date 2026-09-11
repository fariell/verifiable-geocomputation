function HornSlopeSq(grid: (int,int) -> real, w: real): real
  requires w > 0.0
{
  var a := grid(0,0);
  var b := grid(0,1);
  var c := grid(0,2);
  var d := grid(1,0);
  var f := grid(1,2);
  var g := grid(2,0);
  var h := grid(2,1);
  var i_val := grid(2,2);

  var dx_num := (c + 2.0*f + i_val) - (a + 2.0*d + g);
  var dy_num := (g + 2.0*h + i_val) - (a + 2.0*b + c);

  var dx := dx_num / (8.0 * w);
  var dy := dy_num / (8.0 * w);

  dx*dx + dy*dy
}

lemma Theorem(grid: (int,int) -> real, w: real)
  requires w > 0.0
  requires forall i,j :: 0 <= i < 3 && 0 <= j < 3 ==> grid(i,j) == grid(0,0)
  ensures HornSlopeSq(grid, w) == 0.0
{
  var v := grid(0,0);
  var dx_num := (grid(0,2) + 2.0*grid(1,2) + grid(2,2)) - (grid(0,0) + 2.0*grid(1,0) + grid(2,0));
  var dy_num := (grid(2,0) + 2.0*grid(2,1) + grid(2,2)) - (grid(0,0) + 2.0*grid(0,1) + grid(0,2));

  assert dx_num == (v + 2.0*v + v) - (v + 2.0*v + v) == 0.0;
  assert dy_num == (v + 2.0*v + v) - (v + 2.0*v + v) == 0.0;

  var dx := dx_num / (8.0 * w);
  var dy := dy_num / (8.0 * w);
  assert dx*dx + dy*dy == 0.0;
}
