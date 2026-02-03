# =====================================================================
# 00-bootstrap.ps1
# - Carregado primeiro
# - Só helpers leves e estado global do perfil
# =====================================================================

# Estado global do perfil (não use $Profile / $PROFILE - é variável reservada!)
if (-not $global:PwshProfile)
{
    $global:PwshProfile = [ordered]@{}
}

function Test-IsAdmin
{
    if (-not $IsWindows)
    { return $false 
    }
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = [Security.Principal.WindowsPrincipal]::new($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-CommandExists
{
    param([Parameter(Mandatory)][string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-HostReachable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HostName,
        [int]$TimeoutSeconds = 1
    )
    try
    {
        return Test-Connection $HostName -Count 1 -Quiet -TimeoutSeconds $TimeoutSeconds
    } catch
    {
        return $false
    }
}

function Invoke-OncePerDays
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Days,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    if (-not $global:PwshProfile.Paths.State)
    { return 
    }

    $stampFile = Join-Path $global:PwshProfile.Paths.State "$Name.stamp"
    $now = Get-Date

    $shouldRun = $true
    if (Test-Path -LiteralPath $stampFile)
    {
        try
        {
            $last = Get-Content -LiteralPath $stampFile -Raw | ForEach-Object { $_.Trim() }
            if ($last)
            {
                $lastRun = [DateTime]::Parse($last)
                if (($now - $lastRun).TotalDays -lt $Days)
                { $shouldRun = $false 
                }
            }
        } catch
        { $shouldRun = $true 
        }
    }

    if ($shouldRun)
    {
        & $Action
        try
        { Set-Content -LiteralPath $stampFile -Value ($now.ToString("o")) -Force 
        } catch
        {
        }
    }
}

# Caminhos do perfil
$profileHome = Split-Path -Parent $PROFILE.CurrentUserAllHosts
$profileD    = Join-Path $profileHome 'profile.d'
$stateDir    = Join-Path $profileHome '.state'

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

$global:PwshProfile.IsWindows = $IsWindows
$global:PwshProfile.IsAdmin   = Test-IsAdmin
$global:PwshProfile.Paths     = [ordered]@{
    Home     = $profileHome
    D        = $profileD
    State    = $stateDir
    Theme    = (Join-Path $HOME '.pwsh_theme')
    OmpDir   = (Join-Path $HOME '.config\oh-my-posh')
    OmpTheme = (Join-Path (Join-Path $HOME '.config\oh-my-posh') 'star.omp.json')
}
