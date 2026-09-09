"""W3.5 Line-1: L1–L4 reachability probe for candidate LLM API endpoints.

Honesty: report measured fields only. No key required for L1–L3; L4 without key
expects 401/403 (= reachable-but-rejected) vs timeout/DNS (= unreachable).
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import ssl
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import httpx

from common import RESULTS_RAW, utc_today, write_json

REPO_RESULTS = RESULTS_RAW.parent  # experiments/p2_llm/results

ENDPOINTS: list[dict[str, str]] = [
    {
        "id": "anthropic_official",
        "url": "https://api.anthropic.com/v1/messages",
        "note": "official Anthropic; historically HTTP 403 from this host",
    },
    {
        "id": "openrouter",
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "note": "aggregator OpenAI-compatible",
    },
    {
        "id": "siliconflow",
        "url": "https://api.siliconflow.cn/v1/chat/completions",
        "note": "SiliconFlow CN OpenAI-compatible",
    },
    {
        "id": "deepseek",
        "url": "https://api.deepseek.com/chat/completions",
        "note": "DeepSeek CN",
    },
    {
        "id": "zhipu",
        "url": "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        "note": "Zhipu GLM",
    },
    {
        "id": "dashscope",
        "url": "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        "note": "Qwen OpenAI-compatible mode",
    },
    {
        "id": "moonshot",
        "url": "https://api.moonshot.cn/v1/chat/completions",
        "note": "Moonshot/Kimi",
    },
]


def _ms(t0: float) -> float:
    return round((time.perf_counter() - t0) * 1000.0, 1)


def classify_http(status: int | None, exc_name: str | None) -> str:
    if exc_name:
        low = exc_name.lower()
        if "dns" in low or "gaierror" in low or "name or service" in low:
            return "DNS"
        if "timeout" in low:
            return "timeout"
        if "ssl" in low or "tls" in low or "certificate" in low:
            return "TLS"
        if "connect" in low:
            return "TCP"
        return "other"
    if status is None:
        return "other"
    if status == 403:
        return "HTTP-403"
    if status == 401:
        return "HTTP-401"
    if status == 404:
        return "HTTP-404"
    if status == 405:
        return "HTTP-405"
    if 200 <= status < 300:
        return "HTTP-2xx"
    if 400 <= status < 500:
        return f"HTTP-{status}"
    if status >= 500:
        return f"HTTP-{status}"
    return "other"


def probe_dns(host: str, timeout_s: float = 10.0) -> dict[str, Any]:
    t0 = time.perf_counter()
    try:
        infos = socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)
        ips = sorted({i[4][0] for i in infos})
        return {
            "resolve_ok": True,
            "resolve_ip": ips[0] if ips else None,
            "resolve_ips": ips[:8],
            "resolve_ms": _ms(t0),
            "err": None,
        }
    except Exception as exc:
        return {
            "resolve_ok": False,
            "resolve_ip": None,
            "resolve_ips": [],
            "resolve_ms": _ms(t0),
            "err": f"{type(exc).__name__}: {exc}",
        }


def probe_tcp(host: str, port: int = 443, timeout_s: float = 15.0) -> dict[str, Any]:
    t0 = time.perf_counter()
    try:
        with socket.create_connection((host, port), timeout=timeout_s):
            return {"tcp_ok": True, "tcp_ms": _ms(t0), "err": None}
    except Exception as exc:
        return {"tcp_ok": False, "tcp_ms": _ms(t0), "err": f"{type(exc).__name__}: {exc}"}


def probe_tls(host: str, port: int = 443, timeout_s: float = 15.0) -> dict[str, Any]:
    t0 = time.perf_counter()
    ctx = ssl.create_default_context()
    try:
        with socket.create_connection((host, port), timeout=timeout_s) as raw:
            with ctx.wrap_socket(raw, server_hostname=host) as ssock:
                cert = ssock.getpeercert() or {}
                cn = None
                for rdn in cert.get("subject", ()):
                    for typ, val in rdn:
                        if typ == "commonName":
                            cn = val
                            break
                    if cn:
                        break
                return {
                    "tls_ok": True,
                    "tls_ms": _ms(t0),
                    "cert_cn": cn,
                    "tls_version": ssock.version(),
                    "err": None,
                }
    except Exception as exc:
        return {
            "tls_ok": False,
            "tls_ms": _ms(t0),
            "cert_cn": None,
            "tls_version": None,
            "err": f"{type(exc).__name__}: {exc}",
        }


def probe_http(url: str, timeout_s: float = 30.0, proxies: dict[str, str] | None = None) -> dict[str, Any]:
    """No-key L4 probe: POST minimal JSON. 401/403 prove reachability."""
    t0 = time.perf_counter()
    headers = {
        "content-type": "application/json",
        "anthropic-version": "2023-06-01",
        "user-agent": "verifiable-geocomputation-p2-reachability/0.1",
    }
    # Minimal bodies: Anthropic Messages vs OpenAI chat.completions
    if "anthropic.com" in url and "/messages" in url:
        body: dict[str, Any] = {
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1,
            "messages": [{"role": "user", "content": "ping"}],
        }
    else:
        body = {
            "model": "probe-no-key",
            "messages": [{"role": "user", "content": "ping"}],
            "max_tokens": 1,
        }
    try:
        with httpx.Client(timeout=timeout_s, proxies=proxies, follow_redirects=True) as client:
            resp = client.post(url, headers=headers, json=body)
        return {
            "http_ok": True,
            "http_status": resp.status_code,
            "http_ms": _ms(t0),
            "err_class": classify_http(resp.status_code, None),
            "body_excerpt": resp.text[:240].replace("\n", " "),
            "err": None,
        }
    except Exception as exc:
        name = type(exc).__name__
        return {
            "http_ok": False,
            "http_status": None,
            "http_ms": _ms(t0),
            "err_class": classify_http(None, f"{name}: {exc}"),
            "body_excerpt": None,
            "err": f"{name}: {exc}"[:500],
        }


def reachability_tier(row: dict[str, Any]) -> str:
    """推荐 / 可用 / 不可用 — based on measured layers only."""
    l4 = row["L4"]
    ec = l4.get("err_class") or ""
    if l4.get("http_status") in (401, 403):
        return "可用"  # reachable; needs key / allowlist
    if isinstance(l4.get("http_status"), int) and 200 <= l4["http_status"] < 500:
        return "可用"
    if row["L1"]["resolve_ok"] and row["L2"]["tcp_ok"] and row["L3"]["tls_ok"]:
        if ec.startswith("HTTP-"):
            return "可用"
        if ec in ("timeout", "TCP", "DNS", "TLS"):
            return "不可用"
        return "可用"  # TLS up, HTTP odd — still network-reachable
    return "不可用"


def probe_one(ep: dict[str, str], *, timeout_s: float, proxies: dict[str, str] | None) -> dict[str, Any]:
    url = ep["url"]
    parsed = urlparse(url)
    host = parsed.hostname or ""
    port = parsed.port or 443
    l1 = probe_dns(host)
    l2 = {"tcp_ok": False, "tcp_ms": None, "err": "skipped: DNS failed"}
    l3 = {"tls_ok": False, "tls_ms": None, "cert_cn": None, "tls_version": None, "err": "skipped"}
    if l1["resolve_ok"]:
        l2 = probe_tcp(host, port, timeout_s=min(timeout_s, 20.0))
        if l2["tcp_ok"]:
            l3 = probe_tls(host, port, timeout_s=min(timeout_s, 20.0))
    l4 = probe_http(url, timeout_s=timeout_s, proxies=proxies)
    row = {
        "id": ep["id"],
        "url": url,
        "note": ep["note"],
        "host": host,
        "L1": l1,
        "L2": l2,
        "L3": l3,
        "L4": l4,
        "tier": "pending",
    }
    row["tier"] = reachability_tier(row)
    return row


def proxy_env_snapshot() -> dict[str, Any]:
    keys = ("HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "https_proxy", "http_proxy", "all_proxy")
    present = {k: (os.environ.get(k) or "") for k in keys}
    set_keys = [k for k, v in present.items() if v]
    # Never echo full proxy URL with credentials into repo — redact userinfo.
    redacted: dict[str, str | None] = {}
    for k, v in present.items():
        if not v:
            redacted[k] = None
            continue
        try:
            p = urlparse(v)
            if p.hostname:
                redacted[k] = f"{p.scheme}://{p.hostname}:{p.port or ''}"
            else:
                redacted[k] = "<set-non-url>"
        except Exception:
            redacted[k] = "<set>"
    return {"proxy_keys_set": set_keys, "proxy_redacted": redacted}


def key_env_snapshot() -> dict[str, bool]:
    names = (
        "ANTHROPIC_API_KEY",
        "ANTHROPIC_AUTH_TOKEN",
        "OPENROUTER_API_KEY",
        "OPENAI_API_KEY",
        "DEEPSEEK_API_KEY",
        "SILICONFLOW_API_KEY",
        "ZHIPU_API_KEY",
        "DASHSCOPE_API_KEY",
        "MOONSHOT_API_KEY",
    )
    return {n: bool(os.environ.get(n)) for n in names}


def run_probe(timeout_s: float = 30.0) -> dict[str, Any]:
    proxy_info = proxy_env_snapshot()
    keys = key_env_snapshot()
    rows: list[dict[str, Any]] = []
    for ep in ENDPOINTS:
        print(f"[probe] {ep['id']} …", flush=True)
        rows.append(probe_one(ep, timeout_s=timeout_s, proxies=None))

    # Endpoint #8: if any proxy set, re-probe anthropic via that proxy
    proxy_reprobe = None
    if proxy_info["proxy_keys_set"]:
        # httpx reads env proxies automatically if trust_env=True; also pass explicitly
        env_proxy = (
            os.environ.get("HTTPS_PROXY")
            or os.environ.get("https_proxy")
            or os.environ.get("ALL_PROXY")
            or os.environ.get("all_proxy")
            or os.environ.get("HTTP_PROXY")
            or os.environ.get("http_proxy")
        )
        proxies = {"http://": env_proxy, "https://": env_proxy} if env_proxy else None
        print("[probe] anthropic_via_proxy …", flush=True)
        ep8 = {
            "id": "anthropic_via_proxy",
            "url": "https://api.anthropic.com/v1/messages",
            "note": "official Anthropic via env proxy (endpoint #8)",
        }
        proxy_reprobe = probe_one(ep8, timeout_s=timeout_s, proxies=proxies)
        rows.append(proxy_reprobe)
    else:
        proxy_reprobe = {
            "id": "anthropic_via_proxy",
            "skipped": True,
            "reason": "no HTTPS_PROXY/HTTP_PROXY/ALL_PROXY set",
            "tier": "不可用",
        }
        rows.append(
            {
                "id": "anthropic_via_proxy",
                "url": "https://api.anthropic.com/v1/messages",
                "note": "proxy re-probe skipped — no proxy env",
                "host": "api.anthropic.com",
                "L1": {"resolve_ok": None, "resolve_ip": None, "resolve_ms": None, "err": "skipped"},
                "L2": {"tcp_ok": None, "tcp_ms": None, "err": "skipped"},
                "L3": {"tls_ok": None, "tls_ms": None, "cert_cn": None, "err": "skipped"},
                "L4": {
                    "http_ok": False,
                    "http_status": None,
                    "http_ms": None,
                    "err_class": "skipped-no-proxy",
                    "body_excerpt": None,
                    "err": "no proxy env",
                },
                "tier": "不可用",
                "skipped": True,
            }
        )

    usable = [r for r in rows if r.get("tier") == "可用"]
    recommended = None
    # Prefer CN OpenAI-compatible if usable (cost + egress), else any usable
    prefer_order = [
        "siliconflow",
        "deepseek",
        "dashscope",
        "moonshot",
        "zhipu",
        "openrouter",
        "anthropic_official",
        "anthropic_via_proxy",
    ]
    for pid in prefer_order:
        hit = next((r for r in usable if r["id"] == pid), None)
        if hit:
            recommended = pid
            break

    return {
        "schema_version": "p2_llm_api_reachability_v1",
        "call_date": utc_today(),
        "probed_at_utc": datetime.now(timezone.utc).isoformat(),
        "timeout_s": timeout_s,
        "proxy_env": proxy_info,
        "api_keys_present": keys,
        "endpoints": rows,
        "summary": {
            "n_probed": len(rows),
            "n_usable": len(usable),
            "n_unusable": sum(1 for r in rows if r.get("tier") == "不可用"),
            "usable_ids": [r["id"] for r in usable],
            "recommended_id": recommended,
            "any_key_present": any(keys.values()),
        },
    }


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="P2_AIMATH API reachability L1–L4 probe")
    p.add_argument("--timeout", type=float, default=30.0)
    p.add_argument(
        "--out",
        default=str(REPO_RESULTS / "api_reachability.json"),
        help="JSON output under experiments/p2_llm/results/",
    )
    args = p.parse_args(argv)
    report = run_probe(timeout_s=args.timeout)
    out = Path(args.out)
    write_json(out, report)
    print(json.dumps(report["summary"], ensure_ascii=False, indent=2))
    print(f"wrote {out}", flush=True)
    return 0


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    raise SystemExit(main())
