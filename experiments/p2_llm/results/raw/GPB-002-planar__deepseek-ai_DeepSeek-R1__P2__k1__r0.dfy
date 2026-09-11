const A: real
const B: real
const C: real
const w: real
const x0: real
const y0: real

predicate Valid()
{
  w > 0.0
}

function z(i: int, j: int): real
{
  A * (x0 + i * w) + B * (y0 + j * w) + C
}

function DzDx(i: int, j: int): real
  requires Valid()
{
  (z(i+1, j) - z(i-1, j)) / (2.0 * w)
}

function DzDy(i: int, j: int): real
  requires Valid()
{
  (z(i, j+1) - z(i, j-1)) / (2.0 * w)
}

lemma Theorem()
  requires Valid()
  ensures forall i: int, j: int :: 
    DzDx(i, j) == A && DzDy(i, j) == B
{
  forall i: int, j: int {
    calc {
      DzDx(i, j);
      == (z(i+1, j) - z(i-1, j)) / (2.0 * w);
      == ( (A*(x0 + (i+1)*w) + B*(y0 + j*w) + C) - 
           (A*(x0 + (i-1)*w) + B*(y0 + j*w) + C) ) / (2.0 * w);
      == (A*((i+1)*w - (i-1)*w)) / (2.0 * w);
      == (A*(2*w)) / (2.0 * w);
      == A;
    }
    calc {
      DzDy(i, j);
      == (z(i, j+1) - z(i, j-1)) / (2.0 * w);
      == ( (A*(x0 + i*w) + B*(y0 + (j+1)*w) + C) - 
           (A*(x0 + i*w) + B*(y0 + (j-1)*w) + C) ) / (2.0 * w);
      == (B*((j+1)*w - (j-1)*w)) / (2.0 * w);
      == (B*(2*w)) / (2.0 * w);
      == B;
    }
  }
}
