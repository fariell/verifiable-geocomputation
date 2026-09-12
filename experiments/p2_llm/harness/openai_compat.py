"""OpenAI-compatible chat backend for task16 (P2 LLM autoformalization benchmark).

Why this module exists
----------------------
Measured on this host 2026-09-09 (see docs/P2_AIMATH/API_REACHABILITY.md):

  * api.anthropic.com      -> DNS/TCP/TLS ok, HTTP 403 "Request not allowed"
                              (account/region policy, NOT a network fault)
  * code.newcli.com        -> DNS ok (18 ms), TCP :443 timeout 30 s
                              (Cursor gateway in ANTHROPIC_BASE_URL, unreachable)
  * public DNS (google/cf) -> blocked, so the gateway cannot be fixed by DoH

Every endpoint that IS reachable speaks **OpenAI chat-completions**, not Anthropic
messages: siliconflow / deepseek / dashscope / zhipu / moonshot / openrouter all
returned HTTP 401 (reachable, key missing) with DNS+TCP+TLS fully ok.

So the harness could not consume a domestic key even if the PI supplied one.
This module closes that gap: one env var in, W3 unblocks.

Honesty rules inherited from A.11.8
-----------------------------------
* Credentials are read from env only; never written to disk, git or results.
* No key -> explicit, typed error. Nothing is faked, no fixture is ever reported
  as a live model sample.
"""

from __future__ import annotations

import json
import os
from typing import Any

import httpx

# chat_url values below are the EXACT strings probe_api_reachability.py measured
# on 2026-09-09; do not "clean them up" without re-probing.
PROVIDERS: dict[str, dict[str, Any]] = {
    "siliconflow": {
        "env": ("SILICONFLOW_API_KEY",),
        "chat_url": "https://api.siliconflow.cn/v1/chat/completions",
        "default_model": "deepseek-ai/DeepSeek-V3.2",
        "measured_ms": 328.1,
        "note": (
            "domestic direct, TCP 82.6 ms; one key serves DeepSeek/Qwen/GLM families; "
            "W3 roster M1=V3.2 M2=Qwen2.5-72B M3=GLM-4-32B M4=R1 "
            "(see results/raw/siliconflow_model_roster_w3.json)"
        ),
    },
    "deepseek": {
        "env": ("DEEPSEEK_API_KEY",),
        "chat_url": "https://api.deepseek.com/chat/completions",
        "default_model": "deepseek-chat",
        "measured_ms": 247.7,
        "note": "vendor-direct; note path has no /v1 prefix",
    },
    "dashscope": {
        "env": ("DASHSCOPE_API_KEY",),
        "chat_url": "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
        "default_model": "qwen-plus",
        "measured_ms": 236.8,
        "note": "Alibaba Qwen, OpenAI-compatible mode",
    },
    "zhipu": {
        "env": ("ZHIPU_API_KEY",),
        "chat_url": "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        "default_model": "glm-4-plus",
        "measured_ms": 278.9,
        "note": "Zhipu GLM",
    },
    "moonshot": {
        "env": ("MOONSHOT_API_KEY",),
        "chat_url": "https://api.moonshot.cn/v1/chat/completions",
        "default_model": "moonshot-v1-8k",
        "measured_ms": 357.2,
        "note": "Moonshot / Kimi",
    },
    "openrouter": {
        "env": ("OPENROUTER_API_KEY",),
        "chat_url": "https://openrouter.ai/api/v1/chat/completions",
        "default_model": "anthropic/claude-sonnet-4.5",
        "measured_ms": 966.6,
        "note": "one key covers Claude/GPT/Gemini; needs non-CN payment",
    },
}

BACKEND_NAME = "openai"


def available_providers() -> dict[str, dict[str, Any]]:
    """Providers whose key is currently present in the environment."""
    return {
        name: spec
        for name, spec in PROVIDERS.items()
        if any(os.environ.get(k) for k in spec["env"])
    }


def discover_provider(explicit: str | None = None) -> tuple[str, dict[str, Any]]:
    """Resolve which provider to use.

    explicit: value of P2_LLM_PROVIDER / --provider, or None to auto-detect.
    Raises RuntimeError listing exactly what is missing (never prints key values).
    """
    if explicit:
        name = explicit.strip().lower()
        if name not in PROVIDERS:
            raise RuntimeError(
                f"unknown provider {explicit!r}; known={sorted(PROVIDERS)}"
            )
        spec = PROVIDERS[name]
        if not any(os.environ.get(k) for k in spec["env"]):
            raise RuntimeError(
                f"provider {name!r} selected but none of {spec['env']} is set; "
                "export the key in your shell (must stay out of git)"
            )
        return name, spec

    found = available_providers()
    if not found:
        wanted = ", ".join(sorted({k for s in PROVIDERS.values() for k in s["env"]}))
        raise RuntimeError(
            "no OpenAI-compatible key in env. Set exactly one of: " + wanted
        )
    # Deterministic order: prefer the fastest measured domestic endpoint.
    for name in ("siliconflow", "deepseek", "dashscope", "zhipu", "moonshot", "openrouter"):
        if name in found:
            return name, found[name]
    return next(iter(found.items()))


def _extract_content(data: dict[str, Any]) -> str:
    choices = data.get("choices")
    if isinstance(choices, list) and choices:
        msg = choices[0].get("message") or {}
        text = msg.get("content")
        if isinstance(text, str) and text.strip():
            return text
        if isinstance(text, list):  # some gateways return content parts
            parts = [
                p.get("text", "")
                for p in text
                if isinstance(p, dict) and p.get("type") == "text"
            ]
            if parts:
                return "\n".join(parts)
        # DeepSeek-R1 via siliconflow: final answer in content; if empty, do not
        # substitute reasoning_content (that would poison .dfy). Surface empty.
        if isinstance(text, str):
            return text
    # OpenAI-compatible gateways sometimes expose a bare completion field.
    if isinstance(data.get("content"), str):
        return data["content"]
    raise RuntimeError(
        "cannot extract text from OpenAI-compatible response keys="
        f"{list(data)}; body={json.dumps(data)[:400]}"
    )


def _call_chat_api_stream(
    *,
    name: str,
    spec: dict[str, Any],
    api_key: str,
    resolved_model: str,
    prompt: str,
    temperature: float,
    max_tokens: int,
    timeout_s: float,
) -> dict[str, Any]:
    """Stream reasoner responses so idle-until-first-byte does not ReadTimeout.

    Non-stream R1 calls often sit silent for >900s while the server reasons, then
    httpx raises ReadTimeout before any body arrives. Streaming resets the read
    idle timer on each SSE chunk (reasoning_content / content deltas).
    """
    body = {
        "model": resolved_model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature,
        "max_tokens": max_tokens,
        "stream": True,
        "stream_options": {"include_usage": True},
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "content-type": "application/json",
    }
    # Per-chunk idle timeout + generous overall wall clock for long chains.
    timeout = httpx.Timeout(timeout_s, connect=30.0)
    content_parts: list[str] = []
    reasoning_parts: list[str] = []
    usage: dict[str, Any] | None = None
    resp_model = resolved_model
    resp_id: str | None = None

    with httpx.Client(timeout=timeout) as client:
        try:
            with client.stream(
                "POST", spec["chat_url"], headers=headers, json=body
            ) as resp:
                if resp.status_code >= 400:
                    err_body = resp.read().decode("utf-8", errors="replace")[:500]
                    hint = ""
                    if resp.status_code in (401, 403):
                        hint = (
                            " — endpoint is REACHABLE but the key was rejected "
                            "(invalid, wrong provider, or account not entitled); "
                            "this is not a network fault"
                        )
                    raise RuntimeError(
                        f"{name} HTTP {resp.status_code}: {err_body}{hint}"
                    )
                for line in resp.iter_lines():
                    if not line:
                        continue
                    if line.startswith(":"):
                        continue  # SSE comment / keepalive
                    if not line.startswith("data:"):
                        continue
                    payload = line[5:].strip()
                    if payload == "[DONE]":
                        break
                    try:
                        chunk = json.loads(payload)
                    except json.JSONDecodeError:
                        continue
                    if chunk.get("id"):
                        resp_id = chunk["id"]
                    if chunk.get("model"):
                        resp_model = chunk["model"]
                    if chunk.get("usage"):
                        usage = chunk["usage"]
                    choices = chunk.get("choices") or []
                    if not choices:
                        continue
                    delta = choices[0].get("delta") or {}
                    c = delta.get("content")
                    if isinstance(c, str) and c:
                        content_parts.append(c)
                    rc = delta.get("reasoning_content")
                    if isinstance(rc, str) and rc:
                        reasoning_parts.append(rc)
        except Exception as exc:
            raise RuntimeError(
                f"{name} unreachable at {spec['chat_url']}: "
                f"{type(exc).__name__}: {exc}"
            ) from exc

    text = "".join(content_parts)
    return {
        "content": [{"type": "text", "text": text}],
        "model": resp_model,
        "usage": usage,
        "id": resp_id,
        "_resolved_base": spec["chat_url"],
        "_provider": name,
        "_requested_model": resolved_model,
        "_streamed": True,
        "_reasoning_chars": sum(len(x) for x in reasoning_parts),
    }


def call_chat_api(
    *,
    prompt: str,
    model: str = "",
    temperature: float = 0.0,
    max_tokens: int = 4096,
    timeout_s: float | None = None,
    provider: str | None = None,
) -> dict[str, Any]:
    """Call an OpenAI-compatible endpoint. Return shape matches extract_text()."""
    name, spec = discover_provider(provider)
    api_key = next(os.environ.get(k) for k in spec["env"] if os.environ.get(k))
    resolved_model = model or spec["default_model"]
    is_reasoner = any(tag in resolved_model for tag in ("R1", "reasoner", "Reasoner"))
    # A.17.14 +: reasoners need long budgets; streaming avoids first-byte ReadTimeout.
    if timeout_s is None:
        timeout_s = 1800.0 if is_reasoner else 180.0

    if is_reasoner:
        return _call_chat_api_stream(
            name=name,
            spec=spec,
            api_key=api_key,
            resolved_model=resolved_model,
            prompt=prompt,
            temperature=temperature,
            max_tokens=max_tokens,
            timeout_s=timeout_s,
        )

    body = {
        "model": resolved_model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature,
        "max_tokens": max_tokens,
    }
    headers = {
        "Authorization": f"Bearer {api_key}",
        "content-type": "application/json",
    }

    with httpx.Client(timeout=timeout_s) as client:
        try:
            resp = client.post(spec["chat_url"], headers=headers, json=body)
        except Exception as exc:
            raise RuntimeError(
                f"{name} unreachable at {spec['chat_url']}: "
                f"{type(exc).__name__}: {exc}"
            ) from exc

        try:
            data = resp.json()
        except Exception:
            data = {"raw_http_body": resp.text[:8000]}

        if resp.status_code >= 400:
            hint = ""
            if resp.status_code in (401, 403):
                hint = (
                    " — endpoint is REACHABLE but the key was rejected "
                    "(invalid, wrong provider, or account not entitled); "
                    "this is not a network fault"
                )
            raise RuntimeError(
                f"{name} HTTP {resp.status_code}: {resp.text[:500]}{hint}"
            )

    return {
        "content": [{"type": "text", "text": _extract_content(data)}],
        "model": data.get("model") or resolved_model,
        "usage": data.get("usage"),
        "id": data.get("id"),
        "_resolved_base": spec["chat_url"],
        "_provider": name,
        "_requested_model": resolved_model,
    }


def probe_live_api_openai(model: str = "", provider: str | None = None) -> dict[str, Any]:
    """Cheap reachability probe (16 tokens). Same report shape as run_l1_batch's
    probe_live_api so the --require-live gate works unchanged."""
    try:
        name, spec = discover_provider(provider)
    except RuntimeError as exc:
        return {
            "live_api_ok": False,
            "error": str(exc),
            "error_class": "missing-key",
            "provider": provider,
            "model_locked": None,
        }

    api_key = next(os.environ.get(k) for k in spec["env"] if os.environ.get(k))
    requested = model or spec["default_model"]
    # Connectivity probe must stay cheap. R1/reasoners spend minutes on "ping"
    # (measured 2026-09-11: 180s ReadTimeout) while V3.2 returns in <5s. Use a
    # fast model for the gate; the batch still generates with `requested`.
    probe_model = requested
    if any(tag in requested for tag in ("R1", "reasoner", "Reasoner")):
        probe_model = spec.get("default_model") or "deepseek-ai/DeepSeek-V3.2"
    resolved = probe_model
    body = {
        "model": resolved,
        "messages": [{"role": "user", "content": "Reply with exactly: PONG"}],
        "temperature": 0.0,
        "max_tokens": 16,
    }
    headers = {"Authorization": f"Bearer {api_key}", "content-type": "application/json"}
    # Siliconflow: 30s was too tight under load; 60s is enough for V3.2 ping.
    probe_timeout = 60.0
    try:
        with httpx.Client(timeout=probe_timeout) as client:
            resp = client.post(spec["chat_url"], headers=headers, json=body)
    except Exception as exc:
        return {
            "live_api_ok": False,
            "error": f"{name}: {type(exc).__name__}: {exc}",
            "error_class": "network",
            "provider": name,
            "endpoint": spec["chat_url"],
            "model_locked": None,
            "probe_timeout_s": probe_timeout,
            "probe_model": resolved,
            "requested_model": requested,
        }

    ok = resp.status_code < 400
    out = {
        "live_api_ok": ok,
        "status_code": resp.status_code,
        "provider": name,
        "endpoint": spec["chat_url"],
        # Lock the *batch* model id, not the cheap probe stand-in.
        "model_locked": requested if ok else None,
        "error_class": None if ok else ("auth" if resp.status_code in (401, 403) else "http"),
        "error": None if ok else resp.text[:300],
        "probe_timeout_s": probe_timeout,
        "probe_model": resolved,
        "requested_model": requested,
    }
    if ok:
        try:
            out["echo"] = _extract_content(resp.json())[:120]
        except Exception:
            out["echo"] = None
    return out
