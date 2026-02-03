[CmdletBinding()]
param(
    [ValidateSet('Copy','Link')]
    [string]$Mode = 'Copy',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Backup-Path([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        $bak = "$Path.bak.$(Get-Date -Format yyyyMMdd_HHmmss)"
        Copy-Item -LiteralPath $Path -Destination $bak -Recurse -Force
        return $bak
    }
    return $null
}

$repoRoot   = $PSScriptRoot
$srcLoader  = Join-Path $repoRoot 'profile.ps1'
$srcD       = Join-Path $repoRoot 'profile.d'

if (-not (Test-Path -LiteralPath $srcLoader)) { throw "Não achei $srcLoader" }
if (-not (Test-Path -LiteralPath $srcD))      { throw "Não achei $srcD" }

$dstLoader  = $PROFILE.CurrentUserAllHosts
$dstHome    = Split-Path -Parent $dstLoader
$dstD       = Join-Path $dstHome 'profile.d'
$dstHost    = $PROFILE.CurrentUserCurrentHost

New-Item -ItemType Directory -Path $dstHome -Force | Out-Null

Write-Host "Repo: $repoRoot" -ForegroundColor Cyan
Write-Host "Destino loader: $dstLoader" -ForegroundColor Cyan
Write-Host "Destino profile.d: $dstD" -ForegroundColor Cyan

# Backups
$backups = @()
if ($Force) {
    $b1 = Backup-Path $dstLoader; if ($b1) { $backups += $b1 }
    if (Test-Path -LiteralPath $dstD) { $b2 = Backup-Path $dstD; if ($b2) { $backups += $b2 } }
    if ($dstHost -and (Test-Path -LiteralPath $dstHost)) { $b3 = Backup-Path $dstHost; if ($b3) { $backups += $b3 } }
}

# Evita “profile antigo” duplicar coisas: cria stub no CurrentHost (opcional, mas eu recomendo)
if ($dstHost -and $dstHost -ne $dstLoader) {
    if (-not (Test-Path -LiteralPath $dstHost) -or $Force) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $dstHost) -Force | Out-Null
        Set-Content -LiteralPath $dstHost -Encoding utf8 -Value @"
# CurrentUserCurrentHost (stub)
# Mantido vazio para evitar carregar coisas duplicadas.
# Use: $dstLoader
"@
    }
}

# Instala
if ($Mode -eq 'Copy') {
    New-Item -ItemType Directory -Path $dstD -Force | Out-Null

    Copy-Item -LiteralPath $srcLoader -Destination $dstLoader -Force
    Copy-Item -LiteralPath $srcD\* -Destination $dstD -Recurse -Force
    Write-Host "Instalado via COPY." -ForegroundColor Green
}
else {
    # LINK mode
    # - Diretório: junction (não precisa admin)
    # - Arquivo: tenta symlink, se falhar cai pra copy
    if (Test-Path -LiteralPath $dstD) {
        Remove-Item -LiteralPath $dstD -Recurse -Force
    }

    New-Item -ItemType Junction -Path $dstD -Target $srcD -Force | Out-Null

    if (Test-Path -LiteralPath $dstLoader) {
        Remove-Item -LiteralPath $dstLoader -Force
    }

    try {
        New-Item -ItemType SymbolicLink -Path $dstLoader -Target $srcLoader -Force | Out-Null
        Write-Host "Instalado via LINK (junction + symlink)." -ForegroundColor Green
    } catch {
        Copy-Item -LiteralPath $srcLoader -Destination $dstLoader -Force
        Write-Warning "Symlink falhou (normal sem Dev Mode/admin). Loader foi COPIADO, mas profile.d está linkado."
    }
}

if ($backups.Count -gt 0) {
    Write-Host "Backups criados:" -ForegroundColor Yellow
    $backups | ForEach-Object { Write-Host " - $_" }
}

Write-Host "OK. Abra um novo pwsh ou rode: . `"$dstLoader`"" -ForegroundColor Green
