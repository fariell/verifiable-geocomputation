function hornSlopeSq(grid: array2<real>, w: real): real
  requires w > 0.0
  requires grid.Length0 == 3 && grid.Length1 == 3
{
  // Horn (1981) finite-difference slope components
  var dzdx := ( (grid[0,2] + 2.0*grid[1,2] + grid[2,2]) 
              - (grid[0,0] + 2.0*grid[1,0] + grid[2,0]) ) / (8.0 * w);
  var dzdy := ( (grid[0,0] + 2.0*grid[0,1] + grid[0,2]) 
              - (grid[2,0] + 2.0*grid[2,1] + grid[2,2]) ) / (8.0 * w);
  dzdx*dzdx + dzdy*dzdy
}

lemma hornSlopeZeroOnConstant(grid: array2<real>, w: real)
  requires w > 0.0
  requires grid.Length0 == 3 && grid.Length1 == 3
  requires forall i,j :: 0 <= i < 3 && 0 <= j < 3 ==> grid[i,j] == grid[0,0]
  ensures hornSlopeSq(grid, w) == 0.0
{
  // All values equal to constant c
  var c := grid[0,0];
  
  // dzdx numerator reduces to zero
  assert ( (grid[0,2] + 2.0*grid[1,2] + grid[2,2]) 
         - (grid[0,0] + 2.0*grid[1,0] + grid[2,0]) ) 
         == (c + 2.0*c + c) - (c + 2.0*c + c) 
         == 0.0;
         
  // dzdy numerator reduces to zero
  assert ( (grid[0,0] + 2.0*grid[0,1] + grid[0,2]) 
         - (grid[2,0] + 2.0*grid[2,1] + grid[2,2]) ) 
         == (c + 2.0*c + c) - (c + 2.0*c + c) 
         == 0.0;
}
