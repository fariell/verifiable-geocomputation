const A: real
const B: real
const C: real
const w: real where w > 0.0

function z(x: real, y: real): real
{
  A * x + B * y + C
}

function grid(i: int, j: int): real
{
  z(i as real * w, j as real * w)
}

lemma Theorem(i: int, j: int)
  ensures (grid(i+1, j) - grid(i-1, j)) / (2.0 * w) == A
  ensures (grid(i, j+1) - grid(i, j-1)) / (2.0 * w) == B
{
  calc {
    grid(i+1, j) - grid(i-1, j);
    ==
    (A * ((i+1) as real * w) + B * (j as real * w) + C) - 
    (A * ((i-1) as real * w) + B * (j as real * w) + C);
    ==
    A * w * ((i+1) as real - (i-1) as real);
    ==
    A * w * 2.0;
  }
  calc {
    grid(i, j+1) - grid(i, j-1);
    ==
    (A * (i as real * w) + B * ((j+1) as real * w) + C) - 
    (A * (i as real * w) + B * ((j-1) as real * w) + C);
    ==
    B * w * ((j+1) as real - (j-1) as real);
    ==
    B * w * 2.0;
  }
}
