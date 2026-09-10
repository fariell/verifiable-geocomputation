"""Compile/verify generated formalizations. Never overwrites formal/ gold.

A.16 (2026-09-10): Windows host has no native dafny on PATH. Use WSL2 Ubuntu
Dafny 4.11 via `wsl -- bash -lc`, copying sources to an ASCII temp path under
%LOCALAPPDATA%\\Temp (E: Chinese paths break /mnt/e encoding).

Dafny 4.11 often returns process exit code 0 even on parse errors — always
interpret `--json-output` diagnostics / status lines for compile_rc / verify_rc.
"""

from __future__ import annotations

import argparse
import json
import os
import re
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

_WSL_DAFNY_CACHE: str | None | bool = False  # False=unprobed, None=missing, str=ok


def classify_failure(stderr: str, target: str) -> str | None:
    s = stderr.lower()
    if not stderr.strip():
        return None
    if "parse" in s or "syntax" in s or "unexpected token" in s or "rbrace" in s:
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
            "stdout": proc.stdout[-8000:],
            "stderr": proc.stderr[-8000:],
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


def win_to_wsl_path(path: Path) -> str:
    """Map C:\\Users\\... → /mnt/c/Users/... (ASCII temp only; avoid non-ASCII drives)."""
    resolved = path.resolve()
    s = str(resolved)
    if len(s) >= 2 and s[1] == ":":
        drive = s[0].lower()
        rest = s[2:].replace("\\", "/")
        return f"/mnt/{drive}{rest}"
    raise ValueError(f"cannot map to WSL path: {path}")


def ascii_temp_dir(prefix: str) -> Path:
    """Temp under LOCALAPPDATA\\Temp so WSL /mnt/c/... stays ASCII-safe."""
    base = Path(os.environ.get("LOCALAPPDATA") or tempfile.gettempdir()) / "Temp" / "p2_llm_verify"
    base.mkdir(parents=True, exist_ok=True)
    return Path(tempfile.mkdtemp(prefix=prefix, dir=str(base)))


def probe_wsl_dafny() -> str | None:
    global _WSL_DAFNY_CACHE
    if _WSL_DAFNY_CACHE is not False:
        return None if _WSL_DAFNY_CACHE is None else str(_WSL_DAFNY_CACHE)
    try:
        res = run_cmd(
            ["wsl", "--", "bash", "-lc", "command -v dafny && dafny /version"],
            timeout=90,
        )
        blob = (res.get("stdout") or "") + "\n" + (res.get("stderr") or "")
        if res["rc"] == 0 and "dafny" in blob.lower():
            _WSL_DAFNY_CACHE = "wsl:/usr/local/bin/dafny"
            return str(_WSL_DAFNY_CACHE)
    except Exception:  # pragma: no cover
        pass
    _WSL_DAFNY_CACHE = None
    return None


def interpret_dafny_output(stdout: str, stderr: str, proc_rc: int) -> dict[str, Any]:
    """Derive compile_rc / verify_rc from Dafny text or --json-output lines.

    Dafny 4.11 measured 2026-09-10: process rc stays 0 on parse errors, so we
    must not trust proc_rc alone.
    """
    parse_err = False
    other_diag = False
    verify_errors: int | None = None
    texts: list[str] = []
    for line in (stdout or "").splitlines():
        raw = line.strip()
        if raw.startswith("{") and '"type"' in raw:
            try:
                obj = json.loads(raw)
            except json.JSONDecodeError:
                texts.append(raw)
                continue
            typ = obj.get("type")
            if typ == "diagnostic":
                val = obj.get("value") or {}
                sev = int(val.get("severity") or 0)
                src = str(val.get("source") or "").lower()
                msg = str(val.get("defaultFormatMessage") or "")
                texts.append(f"{src}:{msg}")
                if sev >= 1:
                    if "parser" in src:
                        parse_err = True
                    else:
                        other_diag = True
            elif typ == "status":
                texts.append(str(obj.get("value") or ""))
            else:
                texts.append(raw)
        else:
            texts.append(raw)
    texts.append(stderr or "")
    blob = "\n".join(texts)

    if re.search(r"(\d+)\s+parse errors?\s+detected", blob, re.I):
        parse_err = True
    m_fin = re.search(
        r"finished with\s+(\d+)\s+verified,\s+(\d+)\s+errors",
        blob,
        re.I,
    )
    if m_fin:
        verify_errors = int(m_fin.group(2))

    failure = classify_failure(blob, "dafny")
    if parse_err:
        return {
            "compile_rc": 1,
            "verify_rc": 1,
            "failure_code": failure or "F1",
            "interpreted_from": "parse_errors",
            "proc_rc": proc_rc,
        }
    if other_diag and verify_errors is None:
        return {
            "compile_rc": 1,
            "verify_rc": 1,
            "failure_code": failure or "F2",
            "interpreted_from": "diagnostics",
            "proc_rc": proc_rc,
        }
    if verify_errors is not None:
        return {
            "compile_rc": 0,
            "verify_rc": 0 if verify_errors == 0 else 1,
            "failure_code": None if verify_errors == 0 else (failure or "F3"),
            "interpreted_from": "verifier_finished",
            "proc_rc": proc_rc,
            "n_verify_errors": verify_errors,
        }
    if re.search(r"\berror:", blob, re.I):
        return {
            "compile_rc": 1,
            "verify_rc": 1,
            "failure_code": failure or "F1",
            "interpreted_from": "error_token",
            "proc_rc": proc_rc,
        }
    # Last resort: trust process rc (native older CLIs).
    if proc_rc != 0:
        return {
            "compile_rc": proc_rc,
            "verify_rc": proc_rc,
            "failure_code": failure or "F1",
            "interpreted_from": "proc_rc",
            "proc_rc": proc_rc,
        }
    return {
        "compile_rc": 0,
        "verify_rc": 0,
        "failure_code": None,
        "interpreted_from": "proc_rc_zero_no_signal",
        "proc_rc": proc_rc,
        "note": "no explicit verifier status line; treating as pass only if proc_rc=0",
    }


def is_metric_eligible(
    *,
    verify_status: str | None,
    compile_rc: int | None,
    verify_rc: int | None,
    generate_status: str | None = None,
) -> bool:
    """A.16 strict gate: real RAN + both rcs non-null. Never SKIP / TOOLCHAIN_MISSING."""
    if verify_status != "RAN":
        return False
    if compile_rc is None or verify_rc is None:
        return False
    if generate_status in ("GENERATED_FIXTURE", "PROVIDER_ERROR"):
        return False
    return True


def verify_dafny(source: Path) -> dict[str, Any]:
    dafny = which_tool(["dafny", "Dafny"])
    use_wsl = False
    toolchain_label: str | None = dafny
    if not dafny:
        wsl = probe_wsl_dafny()
        if not wsl:
            return {
                "toolchain": None,
                "status": "TOOLCHAIN_MISSING",
                "compile_rc": None,
                "verify_rc": None,
                "note": (
                    "dafny not on Windows PATH; WSL dafny also unavailable. "
                    "Authority verify is AutoDL per playbook."
                ),
            }
        use_wsl = True
        toolchain_label = wsl

    td_path = ascii_temp_dir("p2_llm_dafny_")
    try:
        # ASCII-safe stem — avoid Chinese / long path issues inside WSL.
        dst = td_path / "candidate.dfy"
        shutil.copy2(source, dst)
        if use_wsl:
            wsl_file = win_to_wsl_path(dst)
            # Single authoritative command; --json-output for reliable diagnostics.
            cmd = [
                "wsl",
                "--",
                "bash",
                "-lc",
                f'dafny verify --json-output "{wsl_file}"',
            ]
            verify_res = run_cmd(cmd, cwd=td_path, timeout=300)
            interpreted = interpret_dafny_output(
                verify_res.get("stdout") or "",
                verify_res.get("stderr") or "",
                int(verify_res.get("rc") or 0),
            )
            return {
                "toolchain": toolchain_label,
                "status": "RAN",
                "compile": None,
                "verify": verify_res,
                "compile_rc": interpreted["compile_rc"],
                "verify_rc": interpreted["verify_rc"],
                "failure_code": interpreted.get("failure_code"),
                "interpret": interpreted,
                "note": "via WSL2 Ubuntu dafny 4.11; source copied to ASCII temp",
            }

        compile_res = run_cmd([dafny, "/compile:0", str(dst)], cwd=td_path)
        compile_interp = interpret_dafny_output(
            compile_res.get("stdout") or "",
            compile_res.get("stderr") or "",
            int(compile_res.get("rc") or 0),
        )
        verify_res = None
        verify_interp: dict[str, Any] | None = None
        if compile_interp["compile_rc"] == 0:
            verify_res = run_cmd([dafny, "verify", "--json-output", str(dst)], cwd=td_path)
            verify_interp = interpret_dafny_output(
                verify_res.get("stdout") or "",
                verify_res.get("stderr") or "",
                int(verify_res.get("rc") or 0),
            )
            compile_rc = 0
            verify_rc = verify_interp["verify_rc"]
            failure_code = verify_interp.get("failure_code")
        else:
            compile_rc = compile_interp["compile_rc"]
            verify_rc = 1
            failure_code = compile_interp.get("failure_code")
        return {
            "toolchain": toolchain_label,
            "status": "RAN",
            "compile": compile_res,
            "verify": verify_res,
            "compile_rc": compile_rc,
            "verify_rc": verify_rc,
            "failure_code": failure_code,
            "interpret": {"compile": compile_interp, "verify": verify_interp},
        }
    finally:
        shutil.rmtree(td_path, ignore_errors=True)


def verify_lean(source: Path) -> dict[str, Any]:
    lake = which_tool(["lake"])
    lean = which_tool(["lean"])
    if not lake and not lean:
        # Probe WSL lean (may be absent — honest TOOLCHAIN_MISSING).
        wsl_lean = run_cmd(
            ["wsl", "--", "bash", "-lc", "command -v lean && lean --version"],
            timeout=60,
        )
        blob = (wsl_lean.get("stdout") or "") + (wsl_lean.get("stderr") or "")
        if wsl_lean.get("rc") == 0 and "Lean" in blob:
            td_path = ascii_temp_dir("p2_llm_lean_")
            try:
                dst = td_path / "candidate.lean"
                shutil.copy2(source, dst)
                wsl_file = win_to_wsl_path(dst)
                res = run_cmd(
                    ["wsl", "--", "bash", "-lc", f'lean "{wsl_file}"'],
                    cwd=td_path,
                    timeout=300,
                )
                return {
                    "toolchain": "wsl:lean",
                    "status": "RAN",
                    "compile": res,
                    "verify": res,
                    "compile_rc": res["rc"],
                    "verify_rc": res["rc"],
                    "failure_code": classify_failure(res.get("stderr") or "", "lean")
                    if res["rc"] != 0
                    else None,
                    "note": "via WSL lean on isolated file; may need VeriGIS imports",
                }
            finally:
                shutil.rmtree(td_path, ignore_errors=True)
        return {
            "toolchain": None,
            "status": "TOOLCHAIN_MISSING",
            "compile_rc": None,
            "verify_rc": None,
            "note": "lake/lean not on PATH (local or WSL). Authority build is AutoDL.",
        }
    td_path = ascii_temp_dir("p2_llm_lean_")
    try:
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
    finally:
        shutil.rmtree(td_path, ignore_errors=True)


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
