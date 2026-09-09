# VG Cursor AutoRun Gate  (ASCII only - do not add non-ASCII chars)
# Called by Windows Task Scheduler every 5 minutes.
# Reads STATUS from docs/CURSOR_INBOX.md; if not DONE and no agent is running,
# launches Cursor headless CLI to execute the active task.

$ErrorActionPreference = 'Continue'
$env:CURSOR_INVOKED_AS = 'agent.exe'

$root   = Split-Path -Parent $PSScriptRoot
$inbox  = Join-Path $root 'docs\CURSOR_INBOX.md'
$runDir = Join-Path $root '_autorun'
$logDir = Join-Path $runDir 'logs'
$lock   = Join-Path $runDir '.running'

if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log   = Join-Path $logDir "gate-$stamp.log"

function Log($m) { "$((Get-Date).ToString('s')) $m" | Out-File -FilePath $log -Append -Encoding UTF8 }

Log "=== gate start ==="

if (-not (Test-Path $inbox)) { Log "ERROR: INBOX not found at $inbox"; exit 1 }

$status = (Get-Content $inbox -TotalCount 60 | Where-Object { $_ -match '^STATUS:' } | Select-Object -First 1)
Log "STATUS line: $status"

if (-not $status) { Log "ERROR: no STATUS line"; exit 1 }
if ($status -match 'DONE') { Log "noop (STATUS is DONE)"; exit 0 }

# --- provider key discovery + env injection (2026-09-09) ---
# PI stores keys as User/Machine env vars (never in git). Read them straight from the
# registry so a fresh scheduler process sees them, and inject into this process so that
# the agent and any python child inherit them.
$providerKeys = @(
    'SILICONFLOW_API_KEY','DEEPSEEK_API_KEY','DASHSCOPE_API_KEY',
    'ZHIPU_API_KEY','MOONSHOT_API_KEY','OPENROUTER_API_KEY',
    'ANTHROPIC_API_KEY','ANTHROPIC_AUTH_TOKEN'
)
$present = @()
foreach ($k in $providerKeys) {
    $v = [Environment]::GetEnvironmentVariable($k, 'User')
    if (-not $v) { $v = [Environment]::GetEnvironmentVariable($k, 'Machine') }
    if ($v) {
        $present += $k
        Set-Item -Path "env:$k" -Value $v
    }
}
Log "provider keys present: $([string]::Join(',', $present))"

# BLOCKED = waiting on PI (e.g. missing API key). Do not burn Cursor tokens every 5 min.
# Exception: BLOCKED-PI auto-unblocks the moment a provider key shows up, so PI needs
# to do nothing after setting the env var.
if ($status -match 'BLOCKED') {
    if ($status -match 'BLOCKED-PI' -and $present.Count -gt 0) {
        Log "auto-unblock: BLOCKED-PI but provider key present - proceeding"
    } else {
        Log "noop (STATUS is BLOCKED; waiting on PI)"; exit 0
    }
}

# concurrency guard: skip if an agent run is already in flight
if (Test-Path $lock) {
    $age = (Get-Date) - (Get-Item $lock).LastWriteTime
    if ($age.TotalMinutes -lt 240) {
        Log "skip: another run in flight ($([int]$age.TotalMinutes) min old)"
        exit 0
    }
    Log "stale lock ($([int]$age.TotalMinutes) min) - removing"
    Remove-Item $lock -Force
}

# locate newest cursor-agent version dir
$base = Join-Path $env:LOCALAPPDATA 'cursor-agent\versions'
$ver  = Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
if (-not $ver) { Log "ERROR: no cursor-agent version dir under $base"; exit 1 }

$node = Join-Path $ver.FullName 'node.exe'
$idx  = Join-Path $ver.FullName 'index.js'
if (-not (Test-Path $node)) { Log "ERROR: node.exe missing in $($ver.FullName)"; exit 1 }

$prompt = @'
Read docs/CURSOR_INBOX.md section A and .cursorrules in this repository.
Execute the current active task described in section A.
Rules:
- Follow .cursorrules and all honesty protocols. Never fabricate results.
- When finished: append a report to docs/CURSOR_OUTBOX.md using the format in section A.4,
  update the STATUS line in docs/CURSOR_INBOX.md section A to the next stage per the
  self-advance chain in section A.11.9, and git commit locally.
- NEVER run git push.
- If STATUS is DONE or DONE-LOCKED, do nothing and exit immediately.
'@

New-Item -ItemType File -Path $lock -Force | Out-Null
$alog = Join-Path $logDir "agent-$stamp.log"
try {
    Log "launching agent (ver $($ver.Name))"
    $out = & $node $idx -p --trust --force --output-format text $prompt 2>&1 | Out-String
    $out | Out-File -FilePath $alog -Encoding UTF8
    Log "agent finished, log: $alog"
} catch {
    Log "ERROR: agent invocation failed - $_"
} finally {
    if (Test-Path $lock) { Remove-Item $lock -Force }
    Log "=== gate end ==="
}
