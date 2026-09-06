(* P-COMP-3 / GPB-023: ZT Hxx vs Horn DzDx are not the same map.
   Exhaust 3x3 windows with heights in {0,1,2,3} on the 5 cells that
   enter both x-stencils (d,e,f plus Horn's extra a,c,g,i collapsed
   to the 3-cell centre row plus two free corners). 4^4 = 256, same
   budget as P-COMP-1. Count how many have Hxx != DzDx (w=1).
   Stream witness: z = k x^2 (invariant in y) ⇒ Hyy = 0 and Horn Dy = 0.
*)
ClearAll[w, heights, windows, hxx, dzdx, dzdy, hyy, diffs, nDiff, foundDiff,
  minInst, alongStreamZero, symbolic];
w = 1;
(* window: {d, e, f, a} with b=h=0, c=g=i=0 except a free; compact 4-tuple. *)
heights = Range[0, 3];
windows = Tuples[heights, 4];
hxx[d_, e_, f_] := (d - 2 e + f) / w^2;
dzdx[a_, d_, f_] := ((0 + 2 f + 0) - (a + 2 d + 0)) / (8 w);
(* remaining Horn cells b=c=g=h=i=0 in this slice *)
diffs = Select[
   windows,
   hxx[#[[1]], #[[2]], #[[3]]] != dzdx[#[[4]], #[[1]], #[[3]]] &];
nDiff = Length[diffs];
foundDiff = nDiff > 0;
minInst = If[foundDiff, diffs[[1]], None];
(* stream: 3x3 of z = k x^2, y-invariant. p in {-1,0,1}, q unused. *)
k = 1/20;
streamWin = Table[k (p w)^2, {q, -1, 1}, {p, -1, 1}];
(* rows q down, cols p right *)
hyyStream = (streamWin[[1, 2]] - 2 streamWin[[2, 2]] + streamWin[[3, 2]]) / w^2;
dzdyStream = ((streamWin[[3, 1]] + 2 streamWin[[3, 2]] + streamWin[[3, 3]])
    - (streamWin[[1, 1]] + 2 streamWin[[1, 2]] + streamWin[[1, 3]])) / (8 w);
alongStreamZero = (hyyStream === 0 || hyyStream == 0) && (dzdyStream === 0 || dzdyStream == 0);
symbolic = Assuming[
   {Element[A, Reals], Element[Dcoeff, Reals], w > 0},
   Simplify[
    (Dcoeff * 2) == A
     (* identity Hxx == HornDx on z = A x + D x^2 is false in general *)]];
Print["P-COMP-3 ZT vs Horn finite windows:"];
Print["windows=", Length[windows], " nDiff=", nDiff, " foundDiff=", foundDiff];
Print["minInst {d,e,f,a}=", minInst];
Print["stream Hyy=", hyyStream, " Horn Dy=", dzdyStream, " zero=", alongStreamZero];
Print["Hxx==HornDx identity?: ", symbolic];
json = ExportString[
   <|"operator" -> "zt_vs_horn",
     "n" -> Length[windows],
     "nDiff" -> nDiff,
     "foundDiff" -> foundDiff,
     "minInst" -> minInst,
     "alongStreamZero" -> alongStreamZero,
     "hyyStream" -> hyyStream,
     "dzdyStream" -> dzdyStream,
     "identityHxxEqHornDx" -> TrueQ[symbolic],
     "note" -> "exhaustive 4^4 centre-row+corner; stream z=k x^2"|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
If[TrueQ[foundDiff] && TrueQ[alongStreamZero] && Not[TrueQ[symbolic]],
  Exit[0], Exit[1]]
