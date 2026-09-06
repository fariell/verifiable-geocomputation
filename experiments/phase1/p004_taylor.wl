(* P-004: Taylor remainder of the Horn ∂x stencil.
   HornDx[w] = ((h(w,-w)+2 h(w,0)+h(w,w)) - (h(-w,-w)+2 h(-w,0)+h(-w,w))) / (8 w)
   For a C^4 germ, Series[HornDx - hx, {w,0,4}] starts at O(w^2).
   Last printed block is JSON for the Python driver.
*)
ClearAll[h, HornDx];
h[x_, y_] := h0 + hx*x + hy*y + (hxx*x^2)/2 + (hyy*y^2)/2 + hxy*x*y +
  (hxxx*x^3)/6 + (hxxy*x^2*y)/2 + (hxyy*x*y^2)/2 + (hyyy*y^3)/6 +
  (hxxxx*x^4)/24;
HornDx[w_] := ((h[w, -w] + 2*h[w, 0] + h[w, w]) -
    (h[-w, -w] + 2*h[-w, 0] + h[-w, w]))/(8*w);
ser = Series[HornDx[w] - hx, {w, 0, 4}];
lead = SeriesCoefficient[ser, 2];
Print["P-004 Horn Dx remainder Series:"];
Print[ser];
Print["coefficient of w^2 = ", lead, "  (expect (2 hxxx + 3 hxyy)/12)"];
json = ExportString[
   <|"operator" -> "Horn-Dx",
     "remainder" -> ToString[Normal[ser], InputForm],
     "w2coef" -> ToString[lead, InputForm],
     "expect" -> "(2*hxxx + 3*hxyy)/12",
     "exactOnDegreeLe2" -> True|>,
   "RawJSON"];
Print["JSON-BEGIN"];
Print[json];
Print["JSON-END"];
Exit[0]
