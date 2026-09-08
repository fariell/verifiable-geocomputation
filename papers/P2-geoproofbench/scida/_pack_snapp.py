"""Pack SNAPP Article zip and smoke-compile it in isolation."""
from __future__ import annotations

import shutil
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
UPLOAD = ROOT / "snapp_upload"
FIGS = [
    "fig1_fill_watershed.pdf",
    "fig2_multires.pdf",
    "fig3_realworld.pdf",
    "fig4_zt_horn.pdf",
]
ZIP_NAME = "geoproofbench_latex.zip"


def main() -> None:
    UPLOAD.mkdir(exist_ok=True)
    zip_path = UPLOAD / ZIP_NAME
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(ROOT / "geoproofbench.tex", "geoproofbench.tex")
        for name in FIGS:
            src = ROOT / "figures" / name
            if not src.exists():
                raise SystemExit(f"missing figure {src}")
            z.write(src, f"figures/{name}")
    names = zipfile.ZipFile(zip_path).namelist()
    print("ZIP", zip_path, "bytes", zip_path.stat().st_size)
    print("CONTENTS", names)

    smoke = UPLOAD / "_smoke_compile"
    if smoke.exists():
        shutil.rmtree(smoke)
    smoke.mkdir()
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(smoke)
    for _ in range(2):
        r = subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", "geoproofbench.tex"],
            cwd=smoke,
            capture_output=True,
            text=True,
        )
        if r.returncode != 0:
            print(r.stdout[-2000:])
            print(r.stderr[-2000:])
            raise SystemExit("smoke pdflatex failed")
    pdf = smoke / "geoproofbench.pdf"
    if not pdf.exists():
        raise SystemExit("smoke pdf missing")
    print("SMOKE_PDF", pdf.stat().st_size, "pages check log")
    log = (smoke / "geoproofbench.log").read_text(encoding="utf-8", errors="replace")
    if "Output written on geoproofbench.pdf" not in log:
        raise SystemExit("no output written")
    if "undefined references" in log.lower():
        print("WARN undefined references")
    shutil.rmtree(smoke)
    print("SMOKE_OK")

    article_pdf = ROOT / "geoproofbench.pdf"
    letter_pdf = ROOT / "first_round" / "covering_letter.pdf"
    shutil.copy2(article_pdf, ROOT / "first_round" / "01_article.pdf")
    shutil.copy2(letter_pdf, ROOT / "first_round" / "02_covering_letter.pdf")
    shutil.copy2(letter_pdf, UPLOAD / "covering_letter.pdf")
    print("COPIED first_round/01_article.pdf, 02_covering_letter.pdf")
    print("COPIED snapp_upload/covering_letter.pdf")


if __name__ == "__main__":
    main()
