# =====================================================================
# 10-env.ps1
# - Variáveis de ambiente
# - Editor padrão
# - Telemetria (opt-out manual)
# - Theme selection helpers
# - zoxide init (se existir)
# =====================================================================

# Puxa o valor persistido (User/Machine) pro processo atual, se existir
$teleUser    = [Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'User')
$teleMachine = [Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'Machine')
if ($teleUser)
{ $env:POWERSHELL_TELEMETRY_OPTOUT = $teleUser 
} elseif ($teleMachine)
{ $env:POWERSHELL_TELEMETRY_OPTOUT = $teleMachine 
}

function Set-PwshTelemetryOptOut
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('User','Machine')]
        [string]$Target = 'User'
    )

    if ($Target -eq 'Machine' -and -not $global:PwshProfile.IsAdmin)
    {
        Write-Warning "Para setar em Machine, rode o pwsh como Administrador."
        return
    }

    $value = '1'
    if ($PSCmdlet.ShouldProcess("$Target environment", "Set POWERSHELL_TELEMETRY_OPTOUT=$value"))
    {
        [Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', $value, $Target)
        $env:POWERSHELL_TELEMETRY_OPTOUT = $value
        Write-Host "OK. Reinicie o pwsh para surtir efeito total." -ForegroundColor Yellow
    }
}

# Editor padrão
$EDITOR = if (Test-CommandExists 'nvim')
{ 'nvim' 
} elseif (Test-CommandExists 'pvim')
{ 'pvim' 
} elseif (Test-CommandExists 'vim')
{ 'vim' 
} elseif (Test-CommandExists 'vi')
{ 'vi' 
} elseif (Test-CommandExists 'code')
{ 'code' 
} elseif (Test-CommandExists 'notepad++')
{ 'notepad++' 
} elseif (Test-CommandExists 'sublime_text')
{ 'sublime_text' 
} else
{ 'notepad' 
}

$env:EDITOR = $EDITOR
$env:VISUAL = $EDITOR

# Mantém seu alias "vim" apontando pro editor escolhido
Set-Alias -Name vim -Value $EDITOR -Force

function Get-PwshTheme
{
    $file = $global:PwshProfile.Paths.Theme
    if (Test-Path -LiteralPath $file)
    {
        $t = (Get-Content -LiteralPath $file -Raw).Trim()
        if ($t)
        { return $t 
        }
    }
    return 'starship'
}

function Set-PwshTheme
{
    [CmdletBinding()]
    param(
        [ValidateSet('starship','omp')]
        [Parameter(Mandatory)]
        [string]$Theme
    )
    Set-Content -LiteralPath $global:PwshProfile.Paths.Theme -Value $Theme -Force
    Write-Host "Tema salvo: $Theme (reinicie o pwsh ou rode 'rp')." -ForegroundColor Green
}

# zoxide (se existir)
if (Test-CommandExists 'zoxide')
{
    try
    {
        Invoke-Expression (& { (zoxide init powershell --no-cmd | Out-String) })
        if (Get-Command __zoxide_z -ErrorAction SilentlyContinue)
        {
            Set-Alias -Name z  -Value __zoxide_z  -Option AllScope -Scope Global -Force
            Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force
        }
    } catch
    {
        Write-Warning "Falha ao inicializar zoxide: $($_.Exception.Message)"
    }
}
