# Zenodo / ScienceDB deposit — GeoProofBench v0.1

**Status (2026-09-07):** Science Data Bank V1 minted.

- DOI: <https://doi.org/10.57760/sciencedb.011r9>
- CSTR: <https://cstr.cn/31253.11.sciencedb.011r9> (`31253.11.sciencedb.011r9`)

Citation (GB/T): 郭迎钢. 面向数字高程模型分析的机器可检验命题集 GeoProofBench v0.1[DS/OL]. V1. Science Data Bank, 2026[2026-09-07]. https://cstr.cn/31253.11.sciencedb.011r9. CSTR:31253.11.sciencedb.011r9.

Files remain restricted until Scientific Data acceptance. Do not mint a second, invented Zenodo DOI unless a mirror is later required.

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
