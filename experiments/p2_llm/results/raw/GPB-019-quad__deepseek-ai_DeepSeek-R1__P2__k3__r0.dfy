// Horn slope exactness on quadratic surfaces and cubic remainder
function QuadraticSurface(x: real, y: real, P: real, Q: real, R: real, A: real, B: real, C: real): real
{
  P*x*x + Q*x*y + R*y*y + A*x + B*y + C
}

function CubicSurface(x: real, y: real, G: real): real
{
  G * x * x * x
}

function HornDzDx(x: real, y: real, w: real, f: (real, real) -> real): real
  requires w > 0.0
{
  (f(x + w, y) - f(x - w, y)) / (2.0 * w)
}

function HornDzDy(x: real, y: real, w: real, f: (real, real) -> real): real
  requires w > 0.0
{
  (f(x, y + w) - f(x, y - w)) / (2.0 * w)
}

function TrueDzDx_Quad(x: real, y: real, P: real, Q: real, R: real, A: real, B: real, C: real): real
{
  2.0*P*x + Q*y + A
}

function TrueDzDy_Quad(x: real, y: real, P: real, Q: real, R: real, A: real, B: real, C: real): real
{
  Q*x + 2.0*R*y + B
}

lemma LemmaQuadraticExact(x: real, y: real, w: real, P: real, Q: real, R: real, A: real, B: real, C: real)
  requires w > 0.0
  ensures HornDzDx(x, y, w, (a,b) => QuadraticSurface(a,b,P,Q,R,A,B,C)) 
          == TrueDzDx_Quad(x,y,P,Q,R,A,B,C)
  ensures HornDzDy(x, y, w, (a,b) => QuadraticSurface(a,b,P,Q,R,A,B,C)) 
          == TrueDzDy_Quad(x,y,P,Q,R,A,B,C)
{
  // Quadratic exactness follows by algebraic expansion
}

lemma LemmaCubicOrigin(w: real, G: real)
  requires w > 0.0
  ensures HornDzDx(0.0, 0.0, w, (a,b) => CubicSurface(a,b,G)) == G * w * w
{
  // Cubic remainder at origin is G*w² by computation
}
