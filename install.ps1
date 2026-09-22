#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Source = (Join-Path $PSScriptRoot 'root/.claude'),
    [string]$Target = (Join-Path $HOME '.claude'),
    [string]$ProjectSource = (Join-Path $PSScriptRoot 'project/.claude'),
    [string]$ProjectTarget = $PWD.Path
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Source)) { throw "Source not found: $Source" }
$srcRoot = (Resolve-Path $Source).Path

Write-Host "Installing root tier:`n  from $srcRoot`n  to   $Target" -ForegroundColor Cyan

$items = @('agents', 'skills', 'commands', 'templates', 'output-styles', 'CLAUDE.md', 'CONVENTIONS.md',
    'settings.json')
$jobs = $items | ForEach-Object { Join-Path $srcRoot $_ } | Where-Object { Test-Path $_ } |
    Get-ChildItem -Recurse -File |
    ForEach-Object { [pscustomobject]@{
        Src  = $_.FullName
        Rel  = $_.FullName.Substring($srcRoot.Length).TrimStart('\', '/')
        Dest = Join-Path $Target $_.FullName.Substring($srcRoot.Length).TrimStart('\', '/')
    } }

$projectClaude = Join-Path $ProjectSource 'CLAUDE.md'
if (Test-Path $projectClaude) {
    $projectDest = Join-Path $ProjectTarget 'CLAUDE.md'
    if ((Resolve-Path $ProjectTarget).Path -eq $PSScriptRoot) {
        Write-Host "  Skipping project CLAUDE.md: target is the scaffold repo itself. Run from the consuming repo, or pass -ProjectTarget." -ForegroundColor Yellow
    }
    else {
        Write-Host "Installing project tier:`n  from $projectClaude`n  to   $projectDest" -ForegroundColor Cyan
        $jobs += [pscustomobject]@{ Src = $projectClaude; Rel = 'CLAUDE.md (project)'; Dest = $projectDest }
    }
}

$added = 0; $replaced = 0; $skipped = 0

foreach ($job in $jobs) {
    $rel = $job.Rel
    $dest = $job.Dest
    $exists = Test-Path $dest

    if ($rel -eq 'settings.json') {
        $declared = Get-Content $job.Src -Raw | ConvertFrom-Json -AsHashtable
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

    if ($exists -and (Get-FileHash $dest).Hash -eq (Get-FileHash $job.Src).Hash) {
        $skipped++
        Write-Verbose ("  {0,-9} {1}" -f '[same]', $rel)
        continue
    }

    $tag = $exists ? '[replace]' : '[add]'
    if ($PSCmdlet.ShouldProcess($dest, 'Install (overwrite)')) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
        if ($rel -like 'CLAUDE.md*' -and $exists) { Copy-Item -Path $dest -Destination "$dest.bak" -Force }
        Copy-Item -Path $job.Src -Destination $dest -Force
    }
    if ($exists) { $replaced++ } else { $added++ }
    Write-Host ("  {0,-9} {1}" -f $tag, $rel) -ForegroundColor Green
}

Write-Host ("Done: {0} added, {1} replaced, {2} unchanged of {3} scanned." -f `
    $added, $replaced, $skipped, $jobs.Count) -ForegroundColor Cyan
