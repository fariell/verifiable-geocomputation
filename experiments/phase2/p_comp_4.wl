(* P-COMP-4 / GPB-025: plane resampling homotopy.
   Horn DzDx on z=A x at w and 2 w both recover A.
   Cubic remainder |G w^2| shrinks when w halves.
*)
ClearAll[A, w, hornDx, plane, rHalf, rDouble, cubic];
A = 3/10;
w = 1;
plane[p_, q_, ww_] := A*(p*ww);
hornDx[ww_] := Module[{a, b, c, d, f, g, h, i},
   a = plane[-1, -1, ww]; b = plane[0, -1, ww]; c = plane[1, -1, ww];
   d = plane[-1, 0, ww]; f = plane[1, 0, ww];
   g = plane[-1, 1, ww]; h = plane[0, 1, ww]; i = plane[1, 1, ww];
   ((c + 2 f + i) - (a + 2 d + g))/(8 ww)];
rHalf = hornDx[w/2];
rDouble = hornDx[2 w];
cubic[ww_] := Module[{a, c, d, f, g, i, G = 1},
   a = G*((-1)*ww)^3; c = G*(ww)^3;
   d = a; f = c; g = a; i = c;
   ((c + 2 f + i) - (a + 2 d + g))/(8 ww)];
Print["P-COMP-4 plane resample:"];
Print["Horn Dx w/2 = ", rHalf, " w = ", hornDx[w], " 2w = ", rDouble];
Print["cubic rem w/2 = ", cubic[w/2], " 2w = ", cubic[2 w]];
json = ExportString[
   <|"operator" -> "resample-homotopy",
     "dxHalf" -> rHalf,
     "dxOne" -> hornDx[w],
     "dxDouble" -> rDouble,
     "planarAllA" -> TrueQ[rHalf == A && hornDx[w] == A && rDouble == A],
     "cubicShrinks" -> TrueQ[Abs[cubic[w/2]] < Abs[cubic[2 w]]],
     "note" -> "plane z=A x; R_alpha changes w"|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
If[TrueQ[rHalf == A] && TrueQ[rDouble == A] && TrueQ[Abs[cubic[w/2]] < Abs[cubic[2 w]]],
  Exit[0], Exit[1]]
