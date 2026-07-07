#requires -Version 7.0
<#
.SYNOPSIS
    Installs the root tier (agents, skills, commands, templates + CLAUDE.md, CONVENTIONS.md)
    from this scaffold's root/.claude/ into user scope (~/.claude/).

.DESCRIPTION
    Per-file mirror: every source file replaces the file at the same relative path under the
    target. Folders are merged, never wiped — target-only files (your own skills, agents, ...)
    survive. settings.json, hooks/ and README.md stay repo-only. Preview with -WhatIf.
    Before CLAUDE.md is replaced with different content, the old one is kept as CLAUDE.md.bak.
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

$items = @('agents', 'skills', 'commands', 'templates', 'CLAUDE.md', 'CONVENTIONS.md')
$files = $items | ForEach-Object { Join-Path $srcRoot $_ } | Where-Object { Test-Path $_ } |
    Get-ChildItem -Recurse -File

foreach ($file in $files) {
    $rel = $file.FullName.Substring($srcRoot.Length).TrimStart('\', '/')
    $dest = Join-Path $Target $rel
    $tag = (Test-Path $dest) ? '[replace]' : '[add]'
    if ($PSCmdlet.ShouldProcess($dest, 'Install (overwrite)')) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
        if ($rel -eq 'CLAUDE.md' -and (Test-Path $dest) -and
            (Get-FileHash $dest).Hash -ne (Get-FileHash $file.FullName).Hash) {
            Copy-Item -Path $dest -Destination "$dest.bak" -Force
        }
        Copy-Item -Path $file.FullName -Destination $dest -Force
        Write-Host ("  {0,-9} {1}" -f $tag, $rel) -ForegroundColor Green
    }
}

Write-Host "Done: $($files.Count) files." -ForegroundColor Cyan
