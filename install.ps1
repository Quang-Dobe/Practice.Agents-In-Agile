#requires -Version 7.0
<#
.SYNOPSIS
    Installs the root-tier crew (agents + concern skills + templates + commands) from this
    scaffold's root/.claude/ into user scope (~/.claude/), where the harness can discover agents
    and resolve the thin agents' `skills:` manifests by name.

.DESCRIPTION
    The feature crew is thin: each agent declares a `skills:` manifest and the harness preloads
    those concern-named skills at startup. Skill NAMES only resolve when the skills live on a
    discovery root (~/.claude/skills/ or a repo's .claude/skills/). root/.claude/ is NOT a
    discovery root, so the generic tier must be installed to ~/.claude/. This script does that.

    Add-only for agents/skills/commands/templates: re-running copies ONLY files that are missing
    at the target. Existing target files are left untouched (never overwritten, never deleted), so
    local edits survive a re-run. New folders/files added to the scaffold flow through. It never
    deletes a repo's own repo-tier .claude/ content.
    NOTE: because existing files are skipped, edits to an ALREADY-installed scaffold file do not
    propagate on re-run — delete the target file first (or hand-merge) to pick up such a change.

.NOTES
    - Feature crew (6 role agents + 12 generic skills + 4 feature/workflow command groups +
      templates) is fully user-scope-ready after this runs.
    - The WIKI kit (project-explorer / project-overview / project-update + their skills and
      project/* commands) resolves its skills BY NAME via each agent's `skills:` manifest — no
      internal `root/.claude/...` path reads remain, so it works unchanged at user scope.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Source = (Join-Path $PSScriptRoot 'root/.claude'),
    [string]$Target = (Join-Path $HOME '.claude'),
    # Report-only: run the per-file loop and print [add]/[skip] for every file, but write nothing.
    # Unlike -WhatIf (which short-circuits the loop and shows folder-level ops only).
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Source)) { throw "Source not found: $Source" }

Write-Host "Installing root tier:`n  from $Source`n  to   $Target" -ForegroundColor Cyan

# Subtrees that must live on the user-scope discovery root.
$subtrees = @('agents', 'skills', 'commands', 'templates')

foreach ($sub in $subtrees) {
    $src = Join-Path $Source $sub
    if (-not (Test-Path $src)) { continue }
    $dst = Join-Path $Target $sub
    if ($DryRun -or $PSCmdlet.ShouldProcess($dst, "Add new files to $sub (skip existing)")) {
        if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $dst | Out-Null }
        $srcRoot = (Resolve-Path $src).Path
        $added = 0
        $kept = 0
        Get-ChildItem -Path $src -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($srcRoot.Length).TrimStart('\', '/')
            $destFile = Join-Path $dst $rel
            if (Test-Path $destFile) {
                $kept++
                Write-Host ("       [skip] {0}\{1} (already exists)" -f $sub, $rel) -ForegroundColor DarkYellow
                return
            }
            if (-not $DryRun) {
                $destDir = Split-Path $destFile -Parent
                New-Item -ItemType Directory -Force -Path $destDir | Out-Null
                Copy-Item -Path $_.FullName -Destination $destFile
            }
            $added++
            $tag = if ($DryRun) { '[add?]' } else { '[add] ' }
            Write-Host ("       {0} {1}\{2}" -f $tag, $sub, $rel) -ForegroundColor Green
        }
        $prefix = if ($DryRun) { '[dry]' } else { '[ok] ' }
        Write-Host ("  {0} {1,-10} -> {2} (+{3} new, {4} kept)" -f $prefix, $sub, $dst, $added, $kept) -ForegroundColor Cyan
    }
}

# CONVENTIONS.md is reference docs for repo-tier authors.
$conv = Join-Path $Source 'CONVENTIONS.md'
if ((Test-Path $conv) -and ($DryRun -or $PSCmdlet.ShouldProcess((Join-Path $Target 'CONVENTIONS.md'), 'Copy CONVENTIONS.md'))) {
    if (-not $DryRun) { Copy-Item -Path $conv -Destination (Join-Path $Target 'CONVENTIONS.md') -Force }
    $ctag = if ($DryRun) { '[dry] CONVENTIONS.md (would overwrite)' } else { '[ok] CONVENTIONS.md' }
    Write-Host "  $ctag -> $Target" -ForegroundColor Green
}

Write-Host "`nDone. The thin feature-crew agents now resolve their skills by name at user scope." -ForegroundColor Cyan
Write-Host "Per-repo project rules still go in each repo's own .claude/skills/ (see CONVENTIONS.md)." -ForegroundColor DarkGray
Write-Host "Wiki kit (project-*) resolves skills by name at user scope — no path follow-up needed." -ForegroundColor DarkGray
