# Zenodo deposit — GeoProofBench v0.1

**Status (2026-09-06):** package ready; **DOI not minted**.  
Minting requires the corresponding author to log in at
<https://zenodo.org/deposit/new> (no `ZENODO_TOKEN` in this environment).

Do not invent a `10.5281/zenodo.*` identifier. After Zenodo returns a
real DOI, paste it into:

1. `papers/P2-geoproofbench/manuscript.md` §11 and §A.5
2. `papers/P2-geoproofbench/cover_letter.md` § Data availability
3. `papers/P2/cover_letter.md` (copy)

## Form (copy into zenodo.org/deposit/new)

| Field | Value |
|---|---|
| Upload type | Dataset (+ Software) |
| Title | GeoProofBench v0.1: a verified spatial-computation benchmark suite for terrain algorithms |
| Creator | Guo, Yinggang (`0000-0002-8207-9941`) |
| Affiliation | Northwest Institute of Nuclear Technology, Xi'an 710024, China |
| Description | `metadata.json` → `metadata.description` (from manuscript Abstract / v_final §3) |
| Keywords | spatial computation, formal verification, DEM, GeoProofBench |
| License | CC-BY-4.0 (data) + MIT (code; state in description) |
| Access | Restricted until Scientific Data acceptance, then Open |
| Related identifier | `https://github.com/fariell/verifiable-geocomputation` (after public push) |

## Pack

From the repository root (PowerShell):

```powershell
powershell -File papers/P2-geoproofbench/zenodo/pack.ps1
```

Output: `papers/P2-geoproofbench/zenodo/GeoProofBench-v0.1-deposit.zip`  
Lake / `.lake` caches are **excluded** (rebuildable; not required to verify sources).

## Upload list (see FILELIST.md)

- `experiments/phase1/results/` (metrics + csv; gpb003–006 dirs may be gitignored locally)
- `experiments/phase2/results/` (gpb021/023/024 if present on disk)
- `formal/dafny/*.dfy`
- `formal/lean4/**/*.lean` (not `.lake`)
- `benchmark/`
- `experiments/phase1/figures/*.mp4`
- `experiments/phase2/figures/*.mp4`
- `papers/P2-geoproofbench/manuscript.md`
- `papers/P2-geoproofbench/figures/`
- `papers/P2-geoproofbench/cover_letter.md`
- this `zenodo/` metadata
