(* P-COMP-1 multi-res / GPB-024: finite-set orbits are size-invariant.
   Same 4^4 pigeon / descent / ring triad as p_comp_1.wl.
   Optional: coarsened DEM CSVs (8² / 16²) must have no 4-neighbour pits.
*)
ClearAll[n, domain, allF, applyF, orbit, pigeon, descF, hitsFix, descentAll,
  ring, ringFixed, symbolic, coarsenDir, csvs, noPitQ, coarsenReport];
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
noPitQ[mat_?MatrixQ] := Module[{dims, rows, cols, bad = 0, r, c, nbrs},
  dims = Dimensions[mat];
  rows = dims[[1]]; cols = dims[[2]];
  Do[
    nbrs = {};
    If[r > 1, AppendTo[nbrs, mat[[r - 1, c]]]];
    If[r < rows, AppendTo[nbrs, mat[[r + 1, c]]]];
    If[c > 1, AppendTo[nbrs, mat[[r, c - 1]]]];
    If[c < cols, AppendTo[nbrs, mat[[r, c + 1]]]];
    If[nbrs =!= {} && Min[nbrs] > mat[[r, c]] + 10^-9, bad++],
    {r, rows}, {c, cols}];
  bad == 0];
coarsenDir = Environment["GPB024_OUT"];
If[!(StringQ[coarsenDir] && DirectoryQ[coarsenDir]),
  coarsenDir = FileNameJoin[{Directory[], "results", "gpb024"}]];
If[!(StringQ[coarsenDir] && DirectoryQ[coarsenDir]) && StringQ[$InputFileName] && $InputFileName =!= "",
  coarsenDir = FileNameJoin[{DirectoryName[$InputFileName], "results", "gpb024"}]];
Print["coarsenDir=", coarsenDir, " exists=", DirectoryQ[coarsenDir]];
csvs = If[DirectoryQ[coarsenDir], FileNames["*.csv", coarsenDir], {}];
coarsenReport = Table[
   Module[{mat, ok, name},
    name = FileNameTake[path];
    mat = Import[path, "CSV"];
    ok = MatrixQ[mat] && noPitQ[N[mat]];
    <|"file" -> name, "shape" -> Dimensions[mat], "noPit" -> ok|>],
   {path, csvs}];
Print["P-COMP-1 multi-res finite-set orbits:"];
Print["|S|=", n, " functions=", Length[allF], " descent=", Length[descF]];
Print["pigeonhole exhaustive: ", pigeon];
Print["descent all hit fix: ", descentAll];
Print["4-cycle fixed point?: ", ringFixed];
Print["Assuming m+1>m: ", symbolic];
Print["coarsened DEM no-pit: ", coarsenReport];
json = ExportString[
   <|"operator" -> "orbit-multires",
     "n" -> n,
     "functionsChecked" -> Length[allF],
     "descentMaps" -> Length[descF],
     "pigeonholeAll" -> pigeon,
     "descentAllFix" -> descentAll,
     "ringHasFixedPoint" -> ringFixed,
     "ring" -> ring,
     "assumingPigeon" -> TrueQ[symbolic],
     "coarsened" -> coarsenReport,
     "note" -> "4^4 independent of DEM size; coarsen CSVs checked for 4-nbr pits"|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
If[TrueQ[pigeon] && TrueQ[descentAll] && ringFixed === False && TrueQ[symbolic],
  Exit[0], Exit[1]]
