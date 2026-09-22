#requires -Version 7.0
<#
.SYNOPSIS
    Installs the root tier (agents, skills, commands, templates, output-styles + CLAUDE.md,
    CONVENTIONS.md, settings.json) from this scaffold's root/.claude/ into user scope (~/.claude/).

.DESCRIPTION
    Per-file mirror: every source file replaces the file at the same relative path under the
    target. Folders are merged, never wiped — target-only files (your own skills, agents, ...)
    survive. README.md stays repo-only. Preview with -WhatIf.
    Before CLAUDE.md is replaced with different content, the old one is kept as CLAUDE.md.bak.

    settings.json is the one exception to the mirror: it is merged key by key, so only the keys
    this repo declares are written and the target's own keys survive. Old copy kept as .bak.

    A file whose bytes already match the source is skipped, not rewritten, so the output is a
    true change list. Use -Verbose to also list the skipped files.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Source = (Join-Path $PSScriptRoot 'root/.claude'),
    [string]$Target = (Join-Path $HOME '.claude')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Source)) { throw "Source not found: $Source" }
$srcRoot = (Resolve-Path $Source).Path

Write-Host "Installing root tier:`n  from $srcRoot`n  to   $Target" -ForegroundColor Cyan

$items = @('agents', 'skills', 'commands', 'templates', 'output-styles', 'CLAUDE.md', 'CONVENTIONS.md',
    'settings.json')
$files = $items | ForEach-Object { Join-Path $srcRoot $_ } | Where-Object { Test-Path $_ } |
    Get-ChildItem -Recurse -File

$added = 0; $replaced = 0; $skipped = 0

foreach ($file in $files) {
    $rel = $file.FullName.Substring($srcRoot.Length).TrimStart('\', '/')
    $dest = Join-Path $Target $rel
    $exists = Test-Path $dest

    # settings.json is merged, never replaced: only the keys this repo declares are written, so the
    # target's own keys (model, enabledPlugins, theme, ...) survive every install.
    if ($rel -eq 'settings.json') {
        $declared = Get-Content $file.FullName -Raw | ConvertFrom-Json -AsHashtable
        $merged = ($exists ? (Get-Content $dest -Raw) : '{}') | ConvertFrom-Json -AsHashtable
        $changed = [System.Collections.Generic.List[string]]::new()
        foreach ($key in $declared.Keys) {
            $old = $merged.ContainsKey($key) ? (ConvertTo-Json $merged[$key] -Compress -Depth 20) : $null
            if ($old -ne (ConvertTo-Json $declared[$key] -Compress -Depth 20)) { $changed.Add($key) }
        }

        if ($changed.Count -eq 0) {
            $skipped++
            Write-Verbose ("  {0,-9} {1}" -f '[same]', $rel)
            continue
        }

        $tag = $exists ? '[merge]' : '[add]'
        if ($PSCmdlet.ShouldProcess($dest, "Install (merge keys: $($changed -join ', '))")) {
            New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
            if ($exists) { Copy-Item -Path $dest -Destination "$dest.bak" -Force }
            foreach ($key in $declared.Keys) { $merged[$key] = $declared[$key] }
            ConvertTo-Json $merged -Depth 20 | Set-Content -Path $dest -Encoding utf8
        }
        if ($exists) { $replaced++ } else { $added++ }
        Write-Host ("  {0,-9} {1}  ({2})" -f $tag, $rel, ($changed -join ', ')) -ForegroundColor Green
        continue
    }

    if ($exists -and (Get-FileHash $dest).Hash -eq (Get-FileHash $file.FullName).Hash) {
        $skipped++
        Write-Verbose ("  {0,-9} {1}" -f '[same]', $rel)
        continue
    }

    $tag = $exists ? '[replace]' : '[add]'
    if ($PSCmdlet.ShouldProcess($dest, 'Install (overwrite)')) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
        if ($rel -eq 'CLAUDE.md' -and $exists) { Copy-Item -Path $dest -Destination "$dest.bak" -Force }
        Copy-Item -Path $file.FullName -Destination $dest -Force
    }
    if ($exists) { $replaced++ } else { $added++ }
    Write-Host ("  {0,-9} {1}" -f $tag, $rel) -ForegroundColor Green
}

Write-Host ("Done: {0} added, {1} replaced, {2} unchanged of {3} scanned." -f `
    $added, $replaced, $skipped, $files.Count) -ForegroundColor Cyan
