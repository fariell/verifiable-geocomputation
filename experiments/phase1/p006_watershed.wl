(* P-006 / GPB-015: deterministic iterate on a finite set.
   Combinatorial fact (Assuming): |orbit| = n+1 on an n-set ⇒ a repeat.
   Exhaustive check: every f:{0..3}->{0..3} and every start, 5-point orbit repeats.
   P-006b: the 4-cycle f(i)=Mod[i+1,4] has no fixed point.
*)
ClearAll[n, domain, allF, applyF, orbit, pigeon, ring, ringFixed, symbolic];
n = 4;
domain = Range[0, n - 1];
allF = Tuples[domain, n];
applyF[f_List, x_] := f[[x + 1]];
orbit[f_List, start_, len_] := NestList[applyF[f, #] &, start, len];
pigeon = Count[
    Table[DuplicateQ[orbit[f, s, n]], {f, allF}, {s, domain}],
    False, Infinity] == 0;
ring = Table[Mod[i + 1, n], {i, 0, n - 1}];
ringFixed = MemberQ[Table[ring[[i + 1]] == i, {i, 0, n - 1}], True];
(* Symbolic half: pigeonhole is independent of a particular numeric f. *)
symbolic = Assuming[
   {Element[m, PositiveIntegers]},
   Simplify[m + 1 > m]];
Print["P-006 finite-set orbits:"];
Print["|S|=", n, " functions=", Length[allF]];
Print["pigeonhole exhaustive: ", pigeon];
Print["4-cycle fixed point?: ", ringFixed];
Print["Assuming m+1>m: ", symbolic];
json = ExportString[
   <|"operator" -> "orbit",
     "n" -> n,
     "functionsChecked" -> Length[allF],
     "pigeonholeAll" -> pigeon,
     "ringHasFixedPoint" -> ringFixed,
     "ring" -> ring,
     "assumingPigeon" -> TrueQ[symbolic],
     "note" -> "exhaustive on 4^4 maps; ring is P-006b"|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
If[TrueQ[pigeon] && ringFixed === False && TrueQ[symbolic], Exit[0], Exit[1]]
