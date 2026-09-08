"""Compile/verify generated formalizations. Never overwrites formal/ gold."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from common import (
    RESULTS_RAW,
    RESULTS_SCORED,
    which_tool,
    write_json,
)


def classify_failure(stderr: str, target: str) -> str | None:
    s = stderr.lower()
    if not stderr.strip():
        return None
    if "parse" in s or "syntax" in s or "unexpected token" in s:
        return "F1"
    if "type" in s or "unable to resolve" in s or "unknown identifier" in s:
        return "F2"
    if "decreases" in s or "termination" in s or "well-founded" in s:
        return "F5"
    if target == "dafny" and ("assert" in s or "a postcondition" in s or "a precondition" in s):
        return "F3"
    return "F1"  # conservative default when toolchain fails


def run_cmd(cmd: list[str], cwd: Path | None = None, timeout: int = 300) -> dict[str, Any]:
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        return {
            "cmd": cmd,
            "rc": proc.returncode,
            "stdout": proc.stdout[-4000:],
            "stderr": proc.stderr[-4000:],
        }
    except FileNotFoundError as exc:
        return {"cmd": cmd, "rc": 127, "stdout": "", "stderr": str(exc)}
    except subprocess.TimeoutExpired as exc:
        return {
            "cmd": cmd,
            "rc": 124,
            "stdout": (exc.stdout or "")[-2000:] if isinstance(exc.stdout, str) else "",
            "stderr": f"timeout after {timeout}s",
        }


def verify_dafny(source: Path) -> dict[str, Any]:
    dafny = which_tool(["dafny", "Dafny"])
    if not dafny:
        return {
            "toolchain": None,
            "status": "TOOLCHAIN_MISSING",
            "compile_rc": None,
            "verify_rc": None,
            "note": "dafny not on PATH (local). Authority verify is AutoDL per playbook.",
        }
    # Work in a temp copy so we never touch formal/
    with tempfile.TemporaryDirectory(prefix="p2_llm_dafny_") as td:
        td_path = Path(td)
        dst = td_path / source.name
        shutil.copy2(source, dst)
        compile_res = run_cmd([dafny, "/compile:0", str(dst)], cwd=td_path)
        verify_res = None
        if compile_res["rc"] == 0:
            verify_res = run_cmd([dafny, "verify", str(dst)], cwd=td_path)
        return {
            "toolchain": dafny,
            "status": "RAN",
            "compile": compile_res,
            "verify": verify_res,
            "compile_rc": compile_res["rc"],
            "verify_rc": None if verify_res is None else verify_res["rc"],
            "failure_code": classify_failure(
                (compile_res.get("stderr") or "")
                + "\n"
                + ((verify_res or {}).get("stderr") or ""),
                "dafny",
            )
            if (compile_res["rc"] != 0 or (verify_res and verify_res["rc"] != 0))
            else None,
        }


def verify_lean(source: Path) -> dict[str, Any]:
    lake = which_tool(["lake"])
    lean = which_tool(["lean"])
    if not lake and not lean:
        return {
            "toolchain": None,
            "status": "TOOLCHAIN_MISSING",
            "compile_rc": None,
            "verify_rc": None,
            "note": "lake/lean not on PATH (local). Authority build is AutoDL.",
        }
    with tempfile.TemporaryDirectory(prefix="p2_llm_lean_") as td:
        td_path = Path(td)
        dst = td_path / source.name
        shutil.copy2(source, dst)
        if lean:
            res = run_cmd([lean, str(dst)], cwd=td_path)
            return {
                "toolchain": lean,
                "status": "RAN",
                "compile": res,
                "verify": res,
                "compile_rc": res["rc"],
                "verify_rc": res["rc"],
                "failure_code": classify_failure(res.get("stderr") or "", "lean")
                if res["rc"] != 0
                else None,
                "note": "standalone `lean` on isolated file; may need VeriGIS imports on AutoDL",
            }
        return {
            "toolchain": lake,
            "status": "BLOCKED",
            "compile_rc": None,
            "verify_rc": None,
            "note": "lake present but isolated file needs VeriGIS tree; defer to AutoDL lake build",
        }


def update_raw_json(raw_json: Path, verify_payload: dict[str, Any]) -> None:
    data = json.loads(raw_json.read_text(encoding="utf-8"))
    data["compile_rc"] = verify_payload.get("compile_rc")
    data["verify_rc"] = verify_payload.get("verify_rc")
    data["verify_status"] = verify_payload.get("status")
    data["verify_note"] = verify_payload.get("note")
    data["failure_code_auto"] = verify_payload.get("failure_code")
    write_json(raw_json, data)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH run_verify")
    p.add_argument("--source", required=True, help="path to generated .dfy/.lean under results/raw")
    p.add_argument("--raw-json", default="", help="optional raw JSON to update with rcs")
    args = p.parse_args(argv)

    source = Path(args.source)
    if not source.is_file():
        print(f"source missing: {source}", file=sys.stderr)
        return 2
    # Safety: refuse anything under formal/
    if "formal" in source.resolve().parts and "p2_llm" not in source.resolve().parts:
        # Extra guard: path must be under results
        print("refuse verify path outside results/; never touch formal/", file=sys.stderr)
        return 3
    try:
        source.resolve().relative_to(RESULTS_RAW.resolve())
    except ValueError:
        print(f"source must live under {RESULTS_RAW}", file=sys.stderr)
        return 3

    if source.suffix.lower() == ".dfy":
        payload = verify_dafny(source)
        target = "dafny"
    elif source.suffix.lower() == ".lean":
        payload = verify_lean(source)
        target = "lean"
    else:
        print("unsupported suffix", file=sys.stderr)
        return 2

    payload["source"] = str(source)
    payload["target"] = target
    out = RESULTS_SCORED / f"{source.stem}.verify.json"
    write_json(out, payload)
    if args.raw_json:
        update_raw_json(Path(args.raw_json), payload)
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    if payload.get("status") == "TOOLCHAIN_MISSING":
        return 0  # honest skip is not a harness crash
    if payload.get("compile_rc") not in (0, None):
        return 1
    if payload.get("verify_rc") not in (0, None):
        return 1
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
