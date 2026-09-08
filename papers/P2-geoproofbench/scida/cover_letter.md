# Cover letter — Scientific Data

**Manuscript:** A machine-checked proposition set for digital elevation model analysis  
**Article type:** Data Descriptor  
**Corresponding author:** Yinggang Guo (ORCID 0000-0002-8207-9941)  
**Affiliation:** Northwest Institute of Nuclear Technology, Xi'an 710024, China  
**Email:** fariel_gyg@163.com

Upload file: `first_round/02_covering_letter.pdf` (compiled from `first_round/covering_letter.tex`).

---

Dr Guy Jones  
Chief Editor  
*Scientific Data*

Dear Dr Jones,

I am submitting a Data Descriptor entitled **A machine-checked proposition set for digital elevation model analysis** (article type: Data Descriptor; sole author). The Descriptor deposits GeoProofBench v0.1, a versioned catalogue of machine-checkable claims about digital elevation model (DEM) operators. It does not propose a new interpolator. Each concrete claim is archived as a data record: a stable identifier, a one-sentence property, independent Dafny and Lean 4 specifications, numerical gates, rasters or witnesses, and a recorded verdict. Custom code is supplied only to regenerate those verdicts.

The release contains **six** concrete first-order propositions (GPB-001 to 005 and GPB-015; GPB-002b is the two-dimensional companion of 002), **five** composition or counter-example records (P-COMP-1 to 5; P-COMP-1b is the unfilled-ring companion of 1), and **forty-four** stubbed identifiers (GPB-006 to 014 and GPB-016 to 050) reserved for later entries. Stubbed names are not implemented claims.

Independent Dafny and Lean files do not share a kernel. An AutoDL cloud re-run, without the workstation verifier cache, reports 17 verified members / 0 errors on `PCOMP_1.dfy`, 12 / 0 on `P006_terminate_under_strict.dfy`, 25 / 0 on `PCOMP_2.dfy`, 20 / 0 on `PCOMP_4_homotopy.dfy`, and 15 / 0 on `PCOMP_5_idempotent.dfy`. Those integers are verifier-reported members for each compilation unit (file plus includes), not lemma counts of GeoProofBench as a whole. `PCOMP_1.dfy` itself states 11 lemmas. Lean `lake build` of the deposited VeriGIS library against locked mathlib completes with 0 errors: the library builds. The lockfile imports 2764 mathlib modules; that number is a toolchain size, not a GeoProofBench lemma count, and is not used as evidence that the propositions hold.

Counter-examples are retained as records (`NEGATIVE-RESULT PASS`). An unfilled four-cell ring is a condition-boundary witness: without filling, D8 does not terminate, so P-COMP-1 does not apply. Two small grids show that Zevenbergen–Thorne profile curvature and Horn’s second-order slope coefficient are not interchangeable (P-COMP-3). P-COMP-4 records 8 PASS cells and 4 `FAIL-TOLERANCE` cells; all four tolerance cells are 45° resampling and are not relabelled PASS. P-COMP-5 records 12/12 hash agreement across Python, Dafny, and Lean, and 4/4 two-dimensional fill idempotence.

Input rasters include a 5×5 unit plane, a 256² synthetic terrain, and two labelled same-size synthetic stand-ins (SRTM-scale 3601² and lidar-down 256²); the stand-ins are not product-accuracy claims. Three public 256² windows (USGS 3DEP 1 m lidar, USGS 3DEP 5 m Alaska IFSAR, Copernicus GLO-30) all PASS P-COMP-1. Those products are cited as data: https://doi.org/10.5066/P13LJKFS, https://doi.org/10.5066/P9C064CO, and https://doi.org/10.5270/ESA-c5d3d65. Exact window parameters are in the article Data Availability section (reviewers do not see this letter).

The GeoProofBench v0.1 dataset is openly available at Science Data Bank, V1: https://doi.org/10.57760/sciencedb.011r9 (CSTR https://cstr.cn/31253.11.sciencedb.011r9). Science Data Bank is the national generalist repository of the Chinese Academy of Sciences; it issues a DOI and a CSTR, and this version is unrestricted under CC-BY-4.0. Software is MIT. Reviewers may download the zip from that DOI without a private link or embargo: Scientific Data is not double-blind, the Descriptor names the author, and the deposit is already open. The laboratory tree is the public GitHub copy of the same files (https://github.com/fariell/verifiable-geocomputation); an anonymous.4open.science mirror is not supplied because it would hide nothing that the article and the DOI do not already disclose.

No previous paper has published this proposition set. A related article (Guo, Liu, Rong, Shi & Tang, *Remote Sens.* **17**, 3662 (2025), https://doi.org/10.3390/rs17223662) concerns hyperspectral semantic segmentation and does not share data with this deposit. Nothing related is under consideration elsewhere. This research received no external funding and has no grant number; it was supported by the author's institutional time. The author declares no competing interests. The work uses synthetic and public elevation rasters only.

Yours sincerely,

Yinggang Guo  
Northwest Institute of Nuclear Technology  
Xi'an 710024, China  
fariel_gyg@163.com  
ORCID: 0000-0002-8207-9941
