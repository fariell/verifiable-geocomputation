# Cover letter — Scientific Data

**Manuscript:** GeoProofBench: A Machine-Checked Proposition Set for Digital Elevation Model Analysis  
**Article type:** Data Descriptor  
**Corresponding author:** Yinggang Guo (ORCID 0000-0002-8207-9941)  
**Affiliation:** Northwest Institute of Nuclear Technology, Xi'an 710024, China  
**Email:** fariel_gyg@163.com  
**Target window:** 2026-11-15

---

Dr Guy Jones  
Chief Editor  
*Scientific Data*

Dear Dr Jones,

I am submitting the Data Descriptor **“GeoProofBench: A Machine-Checked Proposition Set for Digital Elevation Model Analysis.”** Digital elevation model (DEM) analysis is the working substrate of terrain science in geomorphology, hydrology, and civil engineering. Operators for slope, pit-filling, curvature, eight-direction flow, and watershed delineation are reused daily, yet they are almost never shipped with a machine-checkable statement of what they actually guarantee. Independent implementations disagree on flats, pits, and tie-breaking; a single undeclared flat ring can invert a published watershed map. GeoProofBench is offered as a **reference dataset and reference software**: a versioned proposition set whose every PASS verdict can be regenerated from numerical gates, a symbolic checker, a visual witness, and two independent proof assistants. The Descriptor does not propose a new interpolator. It deposits the artefacts needed so that a spatial result can be cited together with a proof obligation rather than with laboratory folklore.

The deposit has five reusable contributions, each independently citable from the article file.

**(i) GeoProofBench (GPB) v0.1.** A benchmark suite that assigns every terrain claim a stable identifier, a one-command reproduction harness, and a four-channel verdict (Python numerical gates, Wolfram symbolic check, manim animation, dual-prover verification). Entries that fail a property on noisy input are flagged `FP` (failure of property), not hidden as `FAIL`.

**(ii) Dual-track formalization (Dafny + Lean 4).** Each shipped first-order operator is specified in Dafny and independently restated in Lean 4 / mathlib. Cloud verification records **17 verified / 0 errors** on the fill-then-watershed composition (`PCOMP_1.dfy`), **12 verified / 0 errors** on termination under strict descent (`P006_terminate_under_strict.dfy`), and a Lean `lake build` of **2,760 modules with 0 errors**. The two provers do not share a kernel; agreement is therefore a genuine cross-check, not a duplicated script.

**(iii) Counter-examples as first-class records.** A flat four-ring does not terminate under D8 unless pits are filled; two small grids show that Zevenbergen–Thorne profile curvature and Horn’s second-order fit are not interchangeable functions. These records are catalogued as `NEGATIVE-RESULT PASS`. They are features of the suite: they mark where composition is allowed to stop.

**(iv) Conditional theorems with explicit boundaries.** Unique watershed outlets are stated only under pit-free / strict-descent hypotheses. The four-ring witness shows that “fill then watershed” is not a trivial relabelling of the watershed lemma. GeoProofBench therefore ships the hypothesis, the proof, and the counter-model together.

**(v) One-stop data plus reference implementation.** Python drivers, Wolfram scripts, manim animations, Dafny and Lean sources, and four DEM stacks ship in a single tree, so a reader can regenerate every number in the Descriptor without assembling a toolchain from supplementary PDFs.

The data records themselves are: **six first-order operators** (Horn slope sign; Wang–Liu pit-filling; Zevenbergen–Thorne profile curvature; Horn second-order consistency; D8 flow routing; watershed uniqueness); **three composition records** (fill-then-watershed uniqueness; termination-under-strict-descent; Zevenbergen–Thorne does not entail Horn); **four boundary witnesses** (unfilled four-ring; two Zevenbergen–Thorne versus Horn grids; geometric persistence along a stream); **five controlled noise levels** σ ∈ {0, 10⁻³, 10⁻², 10⁻¹, 0.5} m; and **four DEM stacks** (plane-5m 5×5, terrain-A 256², SRTM-30m 3601², LiDAR-downsampled 256²). Each entry is keyed to a single `GPB-N ENTRY: PASS` line. Animations of the fill-then-watershed stencil, the curvature-versus-quadratic split, and the four-panel multi-resolution comparison are included as mp4 witnesses. Where a public SRTM tile or USGS TNM cloud could not be fetched, the Descriptor labels the corresponding raster as same-size synthetic and does not claim product accuracy.

Verification is deliberately redundant. Numerical gates run on a workstation; Wolfram scripts exhaust 4⁴ small grids for pigeonhole, descent-fix, and ring-fixed-point predicates; Dafny and Lean are rechecked on an independent cloud mirror. The formal lemmas do not bind grid size, which is why the same files cover the 5×5 plane and the 3601² stack. We report those cloud logs as the authoritative verifier output (17/0, 12/0, 2,760 modules / 0 errors).

**Data availability.** A Zenodo deposit package (metadata, file manifest, and packing script) accompanies this manuscript at `papers/P2-geoproofbench/zenodo/`. The DOI will be minted when the corresponding author completes the upload at https://zenodo.org/deposit/new and will be inserted in the article at §11 and §A.5 (the article file, not only this letter, carries access instructions). The GitHub repository https://github.com/fariell/verifiable-geocomputation will be opened in the same public snapshot, after acceptance. **Data are licensed CC-BY-4.0; software is licensed MIT.** Until that snapshot, the laboratory keeps the git remote closed; this is a pre-publication gate, not an access restriction on the accepted record.

**Author contributions.** Yinggang Guo (Northwest Institute of Nuclear Technology, Xi'an 710024, China; ORCID https://orcid.org/0000-0002-8207-9941; fariel_gyg@163.com) is the sole author and is responsible for conceptualization, methodology, software, validation, formal analysis, and writing of the original draft and revisions.

**Funding, competing interests, and ethics.** This research received no external funding. The author declares no competing interests. The work uses synthetic and public-format elevation rasters only; it does not involve human participants, animals, or identifiable personal data. No previous paper has published this proposition set or these witnesses. A related methodological article (Guo, Liu, Rong, Shi & Tang, *Remote Sensing* 2025, SAM-GFNet) concerns hyperspectral semantic segmentation and **does not share data** with GeoProofBench. Nothing related is under consideration or in press at another journal.

Yours sincerely,

Yinggang Guo  
Northwest Institute of Nuclear Technology  
Xi'an 710024, China  
fariel_gyg@163.com  
ORCID: 0000-0002-8207-9941
