(* P-005: D8 steepest descent on a plane z = A x + B y.
   Ranking drop/dist is equivalent to drop^2 / dist2 among downslope cells.
   JSON for the Python driver.
*)
ClearAll[dirs, drop, score, pick];
dirs = {
   {"E", 1, 0}, {"SE", 1, 1}, {"S", 0, 1}, {"SW", -1, 1},
   {"W", -1, 0}, {"NW", -1, -1}, {"N", 0, -1}, {"NE", 1, -1}};
drop[A_, B_, w_, dp_, dq_] := -w*(A*dp + B*dq);
score[A_, B_, w_, dp_, dq_] := Module[{dlt},
   dlt = drop[A, B, w, dp, dq];
   If[dlt <= 0, 0, dlt^2/(dp^2 + dq^2)]];
pick[A_, B_, w_] := Module[{sc, best, bestN},
   sc = (# -> score[A, B, w, #[[2]], #[[3]]]) & /@ dirs;
   best = -1; bestN = "None";
   Do[
    If[sc[[k, 2]] > 0 && sc[[k, 2]] > best,
     best = sc[[k, 2]]; bestN = sc[[k, 1, 1]]],
    {k, Length[dirs]}];
   {bestN, best}];
{nW, sW} = pick[1, 0, 1];
{nNW, sNW} = pick[1, 1, 1];
Print["P-005 D8 plane argmax:"];
Print["A=1 B=0 -> ", nW, " score=", sW];
Print["A=1 B=1 -> ", nNW, " score=", sNW];
json = ExportString[
   <|"operator" -> "D8",
     "planeWest" -> nW,
     "planeNorthwest" -> nNW,
     "expectWest" -> "W",
     "expectNorthwest" -> "NW",
     "tieBreak" -> "scan E,SE,S,SW,W,NW,N,NE"|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
Exit[0]
