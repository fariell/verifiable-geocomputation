(* P-COMP-1 / GPB-021: finite-set orbits.
   (iii) pigeonhole: every f:{0..3}->{0..3} repeats within |S|+1.
   Descent subset: f[i]<=i ⇒ every start hits a fixed point within n steps.
   Contrast: 4-cycle has no fixed point (P-006b; not a descent map).
*)
ClearAll[n, domain, allF, applyF, orbit, pigeon, descF, hitsFix, descentAll,
  ring, ringFixed, symbolic];
n = 4;
domain = Range[0, n - 1];
allF = Tuples[domain, n];
applyF[f_List, x_] := f[[x + 1]];
orbit[f_List, start_, len_] := NestList[applyF[f, #] &, start, len];
pigeon = Count[
    Table[DuplicateQ[orbit[f, s, n]], {f, allF}, {s, domain}],
    False, Infinity] == 0;
descF = Select[allF, And @@ Table[#[[i + 1]] <= i, {i, 0, n - 1}] &];
hitsFix[f_List, start_] := MemberQ[
   Map[applyF[f, #] == # &, orbit[f, start, n]],
   True];
descentAll = Count[
    Table[hitsFix[f, s], {f, descF}, {s, domain}],
    False, Infinity] == 0;
ring = Table[Mod[i + 1, n], {i, 0, n - 1}];
ringFixed = MemberQ[Table[ring[[i + 1]] == i, {i, 0, n - 1}], True];
symbolic = Assuming[
   {Element[m, PositiveIntegers]},
   Simplify[m + 1 > m]];
Print["P-COMP-1 finite-set orbits:"];
Print["|S|=", n, " functions=", Length[allF], " descent=", Length[descF]];
Print["pigeonhole exhaustive: ", pigeon];
Print["descent all hit fix: ", descentAll];
Print["4-cycle fixed point?: ", ringFixed];
Print["Assuming m+1>m: ", symbolic];
json = ExportString[
   <|"operator" -> "orbit",
     "n" -> n,
     "functionsChecked" -> Length[allF],
     "descentMaps" -> Length[descF],
     "pigeonholeAll" -> pigeon,
     "descentAllFix" -> descentAll,
     "ringHasFixedPoint" -> ringFixed,
     "ring" -> ring,
     "assumingPigeon" -> TrueQ[symbolic],
     "note" -> "exhaustive 4^4; descent f[i]<=i; ring is P-006b"|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
If[TrueQ[pigeon] && TrueQ[descentAll] && ringFixed === False && TrueQ[symbolic],
  Exit[0], Exit[1]]
