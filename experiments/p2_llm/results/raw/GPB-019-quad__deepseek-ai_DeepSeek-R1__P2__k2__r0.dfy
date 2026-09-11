type Surface = (real, real) -> real

function DzDx(z: Surface, i: int, j: int, w: real): real
  requires w > 0.0
{
  (z((i+1)*w, j*w) - z((i-1)*w, j*w)) / (2.0 * w)
}

function DzDy(z: Surface, i: int, j: int, w: real): real
  requires w > 0.0
{
  (z(i*w, (j+1)*w) - z(i*w, (j-1)*w)) / (2.0 * w)
}

function quadratic(A: real, B: real, C: real): Surface
{
  (x,y) => A*x + B*y + C
}

function cubic(G: real): Surface
{
  (x,y) => G * x * x * x
}

lemma Theorem1_ExactQuadraticGradient(A: real, B: real, C: real, w: real, i: int, j: int)
  requires w > 0.0
  ensures DzDx(quadratic(A,B,C), i, j, w) == A
  ensures DzDy(quadratic(A,B,C), i, j, w) == B
{
  calc {
    DzDx(quadratic(A,B,C), i, j, w);
    ==
    (quadratic(A,B,C)((i+1)*w, j*w) - quadratic(A,B,C)((i-1)*w, j*w)) / (2.0 * w);
    ==
    (A*(i+1)*w + B*j*w + C - (A*(i-1)*w + B*j*w + C)) / (2.0 * w);
    ==
    (A*w*(i+1 - (i-1))) / (2.0 * w);
    ==
    (A*w*2) / (2.0 * w);
    ==
    A;
  }
  calc {
    DzDy(quadratic(A,B,C), i, j, w);
    ==
    (quadratic(A,B,C)(i*w, (j+1)*w) - quadratic(A,B,C)(i*w, (j-1)*w)) / (2.0 * w);
    ==
    (A*i*w + B*(j+1)*w + C - (A*i*w + B*(j-1)*w + C)) / (2.0 * w);
    ==
    (B*w*(j+1 - (j-1))) / (2.0 * w);
    ==
    (B*w*2) / (2.0 * w);
    ==
    B;
  }
}

lemma Theorem2_CubicOriginRemainder(G: real, w: real)
  requires w > 0.0
  ensures DzDx(cubic(G), 0, 0, w) == G * w * w
{
  calc {
    DzDx(cubic(G), 0, 0, w);
    ==
    (cubic(G)(w, 0.0) - cubic(G)(-w, 0.0)) / (2.0 * w);
    ==
    (G*w*w*w - G*(-w)*(-w)*(-w)) / (2.0 * w);
    ==
    (G*w*w*w - G*(-w*w*w)) / (2.0 * w);
    ==
    (G*w*w*w + G*w*w*w) / (2.0 * w);
    ==
    (2.0 * G * w * w * w) / (2.0 * w);
    ==
    G * w * w;
  }
}
