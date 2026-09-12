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
# chosen per channel after STATUS is read (see below)
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

# --- dual channel (2026-09-12) -------------------------------------------------
# STATUS may read "W3/RUNNING + W4/WRITING-S1": the L1 batch and paper drafting run
# at the same time. Drafting spends no API credit and never touches the jsonl, so
# making it queue behind a 2.7-min-per-cell batch would waste days. Each channel gets
# its own lock file and its own marker token in the prompt, so liveness detection can
# tell the two agents apart instead of one masking the other.
# chosen per channel below, once the batch state is known.

# --- provider key discovery + env injection (2026-09-09) ---
# PI stores keys as User/Machine env vars (never in git). Read them straight from the
# registry so a fresh scheduler process sees them, and inject into this process so that
# the agent and any python child inherit them.
# Only OpenAI-compatible endpoints unblock the run: harness/openai_compat.py speaks the
# OpenAI protocol, so an Anthropic key is useless here. On 2026-09-09 23:37 the gate
# auto-unblocked on ANTHROPIC_AUTH_TOKEN alone and burned a 50-minute agent run that
# produced nothing. Anthropic keys are still injected for tooling, never used as a signal.
$providerKeys = @(
    'SILICONFLOW_API_KEY','DEEPSEEK_API_KEY','DASHSCOPE_API_KEY',
    'ZHIPU_API_KEY','MOONSHOT_API_KEY','OPENROUTER_API_KEY'
)
$injectOnly = @('ANTHROPIC_API_KEY','ANTHROPIC_AUTH_TOKEN')
$present = @()
foreach ($k in $providerKeys) {
    $v = [Environment]::GetEnvironmentVariable($k, 'User')
    if (-not $v) { $v = [Environment]::GetEnvironmentVariable($k, 'Machine') }
    if ($v) {
        $present += $k
        Set-Item -Path "env:$k" -Value $v
    }
}
foreach ($k in $injectOnly) {
    $v = [Environment]::GetEnvironmentVariable($k, 'User')
    if (-not $v) { $v = [Environment]::GetEnvironmentVariable($k, 'Machine') }
    if ($v) { Set-Item -Path "env:$k" -Value $v }
}
Log "provider keys present (OpenAI-compat, unblock signal): $([string]::Join(',', $present))"
if ($present.Count -eq 0) { Log "WARN: no OpenAI-compat key; harness cannot run live" }

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

# W3/RUNNING: L1 live batch may already be writing jsonl. Skip agent launch while
# run_l1_batch.py / run_l1_batch_pool.py is alive (avoids double-spend). If the batch
# process died, fall through so the next agent can resume or finalize (A.15.4).
# The writing channel never spawns batches, so a live batch must not block it.
# But experiment recovery OUTRANKS writing: if the batch died, a tick must go to
# resuming it even while STATUS still carries WRITING, otherwise the writing
# channel monopolises every tick and the dead batch is never picked up again.
$expNeeded = $false
if ($status -match 'RUNNING') {
    $batchAlive = Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
                  Where-Object { $_.CommandLine -match 'run_l1_batch(_pool)?\.py' }
    if ($batchAlive) {
        if ($status -match 'WRITING') {
            Log "L1 batch alive pid=$($batchAlive.ProcessId); deferring it to the writing channel"
        } else {
            Log "noop (STATUS is RUNNING and L1 batch alive pid=$($batchAlive.ProcessId))"
            exit 0
        }
    } else {
        $expNeeded = $true
        Log "STATUS RUNNING but no live run_l1_batch*.py - experiment recovery takes priority"
    }
}

$wchan  = ($status -match 'WRITING') -and (-not $expNeeded)
$lock   = if ($wchan) { Join-Path $runDir '.writing.lock' } else { Join-Path $runDir '.running' }
$marker = if ($wchan) { 'W4-PAPER-WRITING' } else { 'cursor-agent' }
Log "channel: $(if ($wchan) { 'writing' } else { 'experiment' })  lock: $(Split-Path $lock -Leaf)"

# concurrency guard: skip if an agent run is already in flight
if (Test-Path $lock) {
    $age = (Get-Date) - (Get-Item $lock).LastWriteTime
    # A lock only counts as real while a cursor-agent node process is actually alive.
    # If the scheduler (or a crash) kills gate.ps1 mid-run, finally{} never executes and
    # the lock is orphaned -> every later tick skips and the chain stalls forever.
    # Seen 2026-09-09 23:37: agent died with an empty log, lock blocked the chain 45+ min.
    # With two channels live at once, "any cursor-agent node" is no longer proof that
    # THIS channel's agent is alive. Match on the channel marker instead, otherwise a
    # dead writing agent is masked by the experiment agent and its lock never clears.
    $alive = Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
             Where-Object { $_.CommandLine -match 'cursor-agent' -and $_.CommandLine -match $marker }
    if (-not $alive) {
        Log "orphan lock ($([int]$age.TotalMinutes) min old, no live cursor-agent node) - removing"
        Remove-Item $lock -Force
    } elseif ($age.TotalMinutes -lt 240) {
        Log "skip: another run in flight ($([int]$age.TotalMinutes) min old)"
        exit 0
    } else {
        Log "stale lock ($([int]$age.TotalMinutes) min) - removing"
        Remove-Item $lock -Force
    }
}

# locate cursor-agent version dir.
# PINNED, not "newest". The CLI self-updates, and every upgrade so far has
# broken headless mode: 2026.09.10-fd3934a (installed 2026-09-11 14:02) dies on
# startup with "Connection lost, reconnecting to agentn.global.api5.cursor.sh"
# and left the whole chain stalled for 21 hours with zero output.
# 2026.09.08-6caf4ff is the last version verified to work end to end.
# To adopt a newer version, test it with a one-off `agent -p --trust --force`
# run first and then bump PINNED_VER deliberately - never let the chain
# silently follow whatever the updater dropped in.
$base = Join-Path $env:LOCALAPPDATA 'cursor-agent\versions'
$PINNED_VER = '2026.09.08-6caf4ff'

$ver = $null
$pinned = Join-Path $base $PINNED_VER
if (Test-Path $pinned) {
    $ver = Get-Item $pinned
    Log "agent CLI pinned $PINNED_VER"
} else {
    Log "WARN: pinned $PINNED_VER missing - falling back to newest (unverified)"
    $ver = Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending | Select-Object -First 1
}
if (-not $ver) { Log "ERROR: no cursor-agent version dir under $base"; exit 1 }

$node = Join-Path $ver.FullName 'node.exe'
$idx  = Join-Path $ver.FullName 'index.js'
if (-not (Test-Path $node)) { Log "ERROR: node.exe missing in $($ver.FullName)"; exit 1 }

$expPrompt = @'
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

# Paper drafting runs concurrently with the live batch. It reads results read-only.
$writePrompt = @'
W4-PAPER-WRITING channel. You are drafting the paper ONLY. Another agent is running
the L1 experiment batch at the same time - do not interfere with it.

Read docs/CURSOR_INBOX.md section A (especially A.15.2 framing, A.17.19 writing base,
A.17.11 red lines) and .cursorrules in this repository.
Then execute ONLY the paper-writing stage named in the STATUS line (e.g. W4/WRITING-S1).
Rules:
- Draft into papers/P3-llm-autoformalization/manuscript.md (create from
  papers/TEMPLATE.md). Never edit papers/P2/ - that is the already-submitted first paper.
- DO NOT start, resume, kill or otherwise touch run_l1_batch*.py or any experiment
  process. DO NOT append to experiment jsonl. Reading results for numbers is fine.
- Use ONLY measured numbers from experiments/p2_llm/results/. Never invent a figure.
- Honesty: no semantic fidelity percentage until PI rules on the VERIFIED_NEEDS_HUMAN
  records (see _autorun/needs_human_review.md). TOOLCHAIN_MISSING is never a pass.
- When finished: append a report to docs/CURSOR_OUTBOX.md, update the STATUS line to
  the next writing stage as instructed in section A, and git commit locally.
- NEVER run git push.
'@

$prompt = if ($wchan) { $writePrompt } else { $expPrompt }

New-Item -ItemType File -Path $lock -Force | Out-Null
$alog = Join-Path $logDir "$(if ($wchan) { 'write' } else { 'agent' })-$stamp.log"
try {
    Log "launching agent (ver $($ver.Name))"
    # Stream to disk line by line. Buffering everything in memory and writing once at
    # the end means a killed agent leaves a 0-byte log with zero diagnostics.
    "agent started $((Get-Date).ToString('s')) pid=$PID" | Out-File -FilePath $alog -Encoding UTF8
    & $node $idx -p --trust --force --output-format text $prompt 2>&1 |
        Tee-Object -FilePath $alog -Append | Out-Null
    Log "agent finished, exit=$LASTEXITCODE, log: $alog"
} catch {
    Log "ERROR: agent invocation failed - $_"
} finally {
    if (Test-Path $lock) { Remove-Item $lock -Force }
    Log "=== gate end ==="
}
