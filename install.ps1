# Instala esta configuracao do Claude Code em ~/.claude (Windows PowerShell 5.1+)
$ErrorActionPreference = 'Stop'

$src    = $PSScriptRoot
$claude = Join-Path $HOME '.claude'
$utf8   = New-Object System.Text.UTF8Encoding($false)

# 1. Backup do ~/.claude existente
if (Test-Path $claude) {
    $backup = Join-Path $HOME (".claude-backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Copy-Item -Path $claude -Destination $backup -Recurse -Force
    Write-Host "Backup criado em $backup"
} else {
    New-Item -ItemType Directory -Path $claude | Out-Null
}

# 2. Juntar settings.json (as chaves existentes ficam; as deste repo sobrepoem-se em caso de conflito)
function Merge-Object($base, $extra) {
    foreach ($p in $extra.PSObject.Properties) {
        $cur = $base.PSObject.Properties[$p.Name]
        if ($cur -and $cur.Value -is [System.Management.Automation.PSCustomObject] -and
            $p.Value -is [System.Management.Automation.PSCustomObject]) {
            Merge-Object $cur.Value $p.Value
        } elseif ($cur) {
            $cur.Value = $p.Value
        } else {
            $base | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value
        }
    }
}

$newSettings = Get-Content (Join-Path $src 'settings.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$target = Join-Path $claude 'settings.json'
if (Test-Path $target) {
    $settings = Get-Content $target -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $settings) { $settings = New-Object PSObject }
} else {
    $settings = New-Object PSObject
}
Merge-Object $settings $newSettings
[System.IO.File]::WriteAllText($target, ($settings | ConvertTo-Json -Depth 50), $utf8)
Write-Host "settings.json atualizado"

# 3. CLAUDE.md e skills
Copy-Item (Join-Path $src 'CLAUDE.md') (Join-Path $claude 'CLAUDE.md') -Force
$skills = Join-Path $claude 'skills'
New-Item -ItemType Directory -Path $skills -Force | Out-Null
Get-ChildItem (Join-Path $src 'skills') -Directory | ForEach-Object {
    Copy-Item $_.FullName $skills -Recurse -Force
    Write-Host "Skill copiada: $($_.Name)"
}

# 4. Comandos /plugin a correr dentro do Claude Code
Write-Host ""
Write-Host "Corre estes comandos dentro do Claude Code:"
Write-Host "  /plugin marketplace add anthropics/claude-plugins-official"
foreach ($p in $newSettings.enabledPlugins.PSObject.Properties) {
    if ($p.Value) { Write-Host "  /plugin install $($p.Name)" }
}
