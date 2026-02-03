# =====================================================================
# 98-custom.ps1 (opcional)
# - Se existir um arquivo profile.custom.ps1, ele será carregado por último.
# =====================================================================

$custom = Join-Path (Split-Path -Parent $PROFILE.CurrentUserAllHosts) 'profile.custom.ps1'
if (Test-Path -LiteralPath $custom) {
    try { . $custom } catch { Write-Warning "Falha ao carregar profile.custom.ps1: $($_.Exception.Message)" }
}
