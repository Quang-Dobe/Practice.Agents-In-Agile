#requires -Version 7.0
<#
.SYNOPSIS
    Installs the USER-tier crew (agents + concern skills + templates + commands) from this
    scaffold's .claude-user/ into user scope (~/.claude/), where the harness can discover agents
    and resolve the thin agents' `skills:` manifests by name.

.DESCRIPTION
    The feature crew is thin: each agent declares a `skills:` manifest and the harness preloads
    those concern-named skills at startup. Skill NAMES only resolve when the skills live on a
    discovery root (~/.claude/skills/ or a repo's .claude/skills/). .claude-user/ is NOT a
    discovery root, so the generic tier must be installed to ~/.claude/. This script does that.

    Idempotent: re-running overwrites the installed copies. It never deletes a repo's own
    project-tier .claude/ content.

.NOTES
    - Feature crew (6 role agents + 12 generic skills + 4 feature/workflow command groups +
      templates) is fully user-scope-ready after this runs.
    - The WIKI kit (project-explorer / project-overview / project-wiki-enhancer + their skills and
      project/* commands) resolves its skills BY NAME via each agent's `skills:` manifest — no
      internal `.claude-user/...` path reads remain, so it works unchanged at user scope.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Source = (Join-Path $PSScriptRoot '.claude-user'),
    [string]$Target = (Join-Path $HOME '.claude')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Source)) { throw "Source not found: $Source" }

Write-Host "Installing USER tier:`n  from $Source`n  to   $Target" -ForegroundColor Cyan

# Subtrees that must live on the user-scope discovery root.
$subtrees = @('agents', 'skills', 'commands', 'templates')

foreach ($sub in $subtrees) {
    $src = Join-Path $Source $sub
    if (-not (Test-Path $src)) { continue }
    $dst = Join-Path $Target $sub
    if ($PSCmdlet.ShouldProcess($dst, "Sync $sub")) {
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
        $count = (Get-ChildItem -Path $dst -Recurse -File | Measure-Object).Count
        Write-Host ("  [ok] {0,-10} -> {1} ({2} files)" -f $sub, $dst, $count) -ForegroundColor Green
    }
}

# CONVENTIONS.md is reference docs for project-tier authors.
$conv = Join-Path $Source 'CONVENTIONS.md'
if ((Test-Path $conv) -and $PSCmdlet.ShouldProcess((Join-Path $Target 'CONVENTIONS.md'), 'Copy CONVENTIONS.md')) {
    Copy-Item -Path $conv -Destination (Join-Path $Target 'CONVENTIONS.md') -Force
    Write-Host "  [ok] CONVENTIONS.md -> $Target" -ForegroundColor Green
}

Write-Host "`nDone. The thin feature-crew agents now resolve their skills by name at user scope." -ForegroundColor Cyan
Write-Host "Per-repo project rules still go in each repo's own .claude/skills/ (see CONVENTIONS.md)." -ForegroundColor DarkGray
Write-Host "Wiki kit (project-*) resolves skills by name at user scope — no path follow-up needed." -ForegroundColor DarkGray
