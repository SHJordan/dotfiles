# =====================================================================
# PowerShell Profile Loader (CurrentUserAllHosts)
# Local: $PROFILE.CurrentUserAllHosts  (Windows 11 / PowerShell 7)
# Carrega todos os arquivos em: ...\Documents\PowerShell\profile.d\
# =====================================================================

$profileHome = Split-Path -Parent $PROFILE.CurrentUserAllHosts
$profileD    = Join-Path $profileHome 'profile.d'

if (-not (Test-Path -LiteralPath $profileD))
{
    New-Item -ItemType Directory -Path $profileD -Force | Out-Null
}

Get-ChildItem -LiteralPath $profileD -Filter '*.ps1' -File |
    Sort-Object Name |
    ForEach-Object {
        try
        {
            . $_.FullName
        } catch
        {
            Write-Warning "Falha ao carregar '$($_.Name)': $($_.Exception.Message)"
        }
    }
