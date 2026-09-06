(* P-003: Taylor remainder of the ZT Hxx stencil.
   Hxx[h](w) = (h(-w,0) - 2 h(0,0) + h(w,0)) / w^2
   For a C^4 germ, Series[Hxx - hxx, {w,0,4}] starts at O(w^2).
   Last printed line is JSON for the Python driver.
*)
ClearAll[h, HxxOp];
h[x_, y_] := h0 + hx*x + hy*y + (hxx*x^2)/2 + (hyy*y^2)/2 + hxy*x*y +
  (hxxx*x^3)/6 + (hxxy*x^2*y)/2 + (hxyy*x*y^2)/2 + (hyyy*y^3)/6 +
  (hxxxx*x^4)/24;
HxxOp[w_] := (h[-w, 0] - 2*h[0, 0] + h[w, 0]) / w^2;
ser = Series[HxxOp[w] - hxx, {w, 0, 4}];
lead = SeriesCoefficient[ser, 2];
Print["P-003 ZT Hxx remainder Series:"];
Print[ser];
Print["coefficient of w^2 = ", lead, "  (expect hxxxx/12)"];
json = ExportString[
   <|"operator" -> "ZT-Hxx",
     "remainder" -> ToString[Normal[ser], InputForm],
     "w2coef" -> ToString[lead, InputForm],
     "expect" -> "hxxxx/12",
     "exactOnDegreeLe3" -> True|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
Exit[0]
