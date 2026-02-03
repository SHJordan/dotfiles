# =====================================================================
# 20-modules.ps1
# - Imports opcionais (não instala nada no startup!)
# - Função para instalar dependências quando você quiser
# =====================================================================

# Terminal-Icons (importa só se existir)
if (Get-Module -ListAvailable -Name Terminal-Icons)
{
    try
    { Import-Module Terminal-Icons -ErrorAction SilentlyContinue 
    } catch
    {
    }
}

function Install-ProfileDependencies
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$TerminalIcons,
        [switch]$All
    )

    if ($All)
    { $TerminalIcons = $true 
    }

    if ($TerminalIcons)
    {
        if (-not (Get-Module -ListAvailable -Name Terminal-Icons))
        {
            if ($PSCmdlet.ShouldProcess("Terminal-Icons", "Install-Module (CurrentUser)"))
            {
                Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -AllowClobber
                Write-Host "Terminal-Icons instalado. Você pode rodar 'rp' para recarregar." -ForegroundColor Green
            }
        } else
        {
            Write-Host "Terminal-Icons já está instalado." -ForegroundColor DarkGray
        }
    }
}
