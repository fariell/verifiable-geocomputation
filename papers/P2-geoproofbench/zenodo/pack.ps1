# Pack GeoProofBench v0.1 for a manual Zenodo upload.
# Does not call the Zenodo API (no token in this environment).
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$outDir = Join-Path $PSScriptRoot "."
$staging = Join-Path $outDir "_staging"
$zip = Join-Path $outDir "GeoProofBench-v0.1-deposit.zip"

if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Path $staging | Out-Null

$paths = @(
  "formal\dafny",
  "formal\lean4\lakefile.toml",
  "formal\lean4\lean-toolchain",
  "formal\lean4\VeriGIS.lean",
  "formal\lean4\VeriGIS",
  "benchmark",
  "experiments\phase1\figures",
  "experiments\phase2\figures",
  "experiments\phase1\results",
  "experiments\phase2\results",
  "papers\P2-geoproofbench\manuscript.md",
  "papers\P2-geoproofbench\cover_letter.md",
  "papers\P2-geoproofbench\figures",
  "papers\P2-geoproofbench\scida\geoproofbench.tex",
  "papers\P2-geoproofbench\scida\geoproofbench.pdf",
  "papers\P2-geoproofbench\scida\cover_letter.md",
  "papers\P2-geoproofbench\scida\CHECKLIST.md",
  "papers\P2-geoproofbench\scida\figures",
  "papers\P2-geoproofbench\zenodo\metadata.json",
  "papers\P2-geoproofbench\zenodo\README.md",
  "papers\P2-geoproofbench\zenodo\FILELIST.md",
  "papers\P2-geoproofbench\zenodo\SCIENCEDB_FORM.md",
  "papers\P2-geoproofbench\zenodo\cover.png"
)

function Copy-DepositItem([string]$rel) {
  $src = Join-Path $root $rel
  if (-not (Test-Path $src)) {
    Write-Host "SKIP missing: $rel"
    return
  }
  $dst = Join-Path $staging $rel
  $dstParent = Split-Path $dst -Parent
  if (-not (Test-Path $dstParent)) {
    New-Item -ItemType Directory -Path $dstParent -Force | Out-Null
  }
  $item = Get-Item $src
  if ($item.PSIsContainer) {
    Copy-Item -Path $src -Destination $dst -Recurse -Force
  } else {
    Copy-Item -Path $src -Destination $dst -Force
  }
}

foreach ($p in $paths) { Copy-DepositItem $p }

Get-ChildItem -Path $staging -Recurse -Directory -Filter ".lake" -ErrorAction SilentlyContinue |
  Remove-Item -Recurse -Force
Get-ChildItem -Path $staging -Recurse -Directory -Filter "lake-packages" -ErrorAction SilentlyContinue |
  Remove-Item -Recurse -Force
foreach ($junk in @("partial_movie_files", "__pycache__", "Tex", ".ipynb_checkpoints", "texts", "images")) {
  Get-ChildItem -Path $staging -Recurse -Directory -Filter $junk -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force
}

if (Test-Path $zip) { Remove-Item -Force $zip }
& "C:\ProgramData\anaconda3\python.exe" -c @"
import os, zipfile, time
staging = r'''$staging'''
zip_path = r'''$zip'''
time.sleep(1.5)
n_ok, n_skip = 0, 0
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(staging):
        dirs[:] = [d for d in dirs if d not in {'.lake', 'lake-packages'}]
        for name in files:
            full = os.path.join(root, name)
            rel = os.path.relpath(full, staging).replace('\\', '/')
            try:
                zf.write(full, rel)
                n_ok += 1
            except OSError as e:
                print('SKIP locked', rel, e)
                n_skip += 1
print('zipped', n_ok, 'skipped', n_skip)
print('bytes', os.path.getsize(zip_path))
"@

$bytes = (Get-Item $zip).Length
Write-Host ("ZIP {0}  bytes={1}  MB={2}" -f $zip, $bytes, [math]::Round($bytes/1MB, 2))
Remove-Item -Recurse -Force $staging
