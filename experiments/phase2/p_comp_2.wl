(* P-COMP-2 / GPB-022: full-plane closure.
   (1) 4^4 pigeonhole + descent maps (same finite-set fact as P-COMP-1).
   (2) 256-cell west chain: succ[0]=0, succ[i]=i-1; every start hits 0.
   (3) 16×16 = 256 cell planar west successor; every cell terminates.
*)
ClearAll[n4, domain, allF, applyF, orbit, pigeon, descF, hitsFix, descentAll,
  ring, ringFixed, symbolic, n256, west, hits0, chainAll, n16, west2d, term2d];
n4 = 4;
domain = Range[0, n4 - 1];
allF = Tuples[domain, n4];
applyF[f_List, x_] := f[[x + 1]];
orbit[f_List, start_, len_] := NestList[applyF[f, #] &, start, len];
pigeon = Count[
    Table[DuplicateQ[orbit[f, s, n4]], {f, allF}, {s, domain}],
    False, Infinity] == 0;
descF = Select[allF, And @@ Table[#[[i + 1]] <= i, {i, 0, n4 - 1}] &];
hitsFix[f_List, start_] := MemberQ[
   Map[applyF[f, #] == # &, orbit[f, start, n4]],
   True];
descentAll = Count[
    Table[hitsFix[f, s], {f, descF}, {s, domain}],
    False, Infinity] == 0;
ring = Table[Mod[i + 1, n4], {i, 0, n4 - 1}];
ringFixed = MemberQ[Table[ring[[i + 1]] == i, {i, 0, n4 - 1}], True];
symbolic = Assuming[
   {Element[m, PositiveIntegers]},
   Simplify[m + 1 > m]];

n256 = 256;
west = Table[If[i == 0, 0, i - 1], {i, 0, n256 - 1}];
hits0[start_] := Module[{x = start, k = 0},
   While[x != 0 && k < n256, x = west[[x + 1]]; k++];
   x == 0];
chainAll = And @@ Table[hits0[s], {s, 0, n256 - 1}];

n16 = 16;
(* west2d: cell (r,c) → (r, c-1) if c>0 else self; 256 cells. *)
west2d[idx_] := Module[{r, c},
   r = Quotient[idx, n16];
   c = Mod[idx, n16];
   If[c == 0, idx, r*n16 + (c - 1)]];
term2d = And @@ Table[
    Module[{x = s, k = 0, seen},
     seen = False;
     While[west2d[x] != x && k < n16,
      x = west2d[x]; k++];
     west2d[x] == x],
    {s, 0, n16*n16 - 1}];

Print["P-COMP-2 full-plane orbits:"];
Print["|S|=", n4, " functions=", Length[allF], " descent=", Length[descF]];
Print["pigeonhole exhaustive: ", pigeon];
Print["descent all hit fix: ", descentAll];
Print["4-cycle fixed point?: ", ringFixed];
Print["256-cell west chain all hit 0: ", chainAll];
Print["16x16 west plane all terminate: ", term2d];
Print["Assuming m+1>m: ", symbolic];
json = ExportString[
   <|"operator" -> "plane-orbit",
     "n" -> n4,
     "functionsChecked" -> Length[allF],
     "descentMaps" -> Length[descF],
     "pigeonholeAll" -> pigeon,
     "descentAllFix" -> descentAll,
     "ringHasFixedPoint" -> ringFixed,
     "chain256AllHit0" -> chainAll,
     "plane16x16AllTerm" -> term2d,
     "cellsChecked" -> n256,
     "assumingPigeon" -> TrueQ[symbolic],
     "note" -> "4^4 pigeon+descent; 256-cell west chain; 16x16 plane"|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
If[TrueQ[pigeon] && TrueQ[descentAll] && ringFixed === False &&
    TrueQ[chainAll] && TrueQ[term2d] && TrueQ[symbolic],
  Exit[0], Exit[1]]
