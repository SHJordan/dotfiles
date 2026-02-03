# =====================================================================
# 30-functions.ps1
# - Funções utilitárias (update, rede, arquivos, etc.)
# =====================================================================

# --- Perfil: atalhos úteis ---
function Import-Profile {
    # permite recarregar mesmo que o loader tenha um "guard"
    $global:__PwshProfileLoaded = $false

    . $PROFILE.CurrentUserAllHosts

    # opcional: também recarrega o CurrentHost se você usar algo nele
    if ($PROFILE.CurrentUserCurrentHost -ne $PROFILE.CurrentUserAllHosts -and (Test-Path -LiteralPath $PROFILE.CurrentUserCurrentHost)) {
        . $PROFILE.CurrentUserCurrentHost
    }
}
Set-Alias -Name rp -Value Import-Profile -Force

function Edit-Profile
{ & $env:EDITOR $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile -Force

# --- Update do PowerShell via winget ---
function Update-PowerShell
{
    [CmdletBinding(SupportsShouldProcess)]
    param([switch]$Quiet)

    if (-not (Test-CommandExists 'winget'))
    {
        Write-Warning "winget não encontrado. (App Installer / winget)."
        return
    }

    # conecta só quando precisa
    if (-not (Test-HostReachable -HostName 'github.com' -TimeoutSeconds 1))
    {
        Write-Warning "Sem conexão com GitHub (ou bloqueado)."
        return
    }

    try
    {
        if (-not $Quiet)
        { Write-Host "Checando updates do PowerShell..." -ForegroundColor Cyan
        }

        $current = $PSVersionTable.PSVersion
        $api     = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
        $headers = @{ 'User-Agent' = 'pwsh-profile' }

        $latestTag = (Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 4).tag_name
        $latest    = [Version]($latestTag.TrimStart('v'))

        if ($current -ge $latest)
        {
            if (-not $Quiet)
            { Write-Host "PowerShell já está atualizado ($current)." -ForegroundColor Green
            }
            return
        }

        Write-Host "Atualizando PowerShell: $current -> $latest" -ForegroundColor Yellow

        if ($PSCmdlet.ShouldProcess("Microsoft.PowerShell", "winget upgrade"))
        {
            Start-Process -FilePath 'winget' -ArgumentList @(
                'upgrade','Microsoft.PowerShell',
                '--accept-source-agreements','--accept-package-agreements'
            ) -Wait -NoNewWindow

            Write-Host "Atualizado. Reinicie o pwsh para refletir a versão nova." -ForegroundColor Magenta
        }
    } catch
    {
        Write-Error "Falha ao atualizar. Erro: $($_.Exception.Message)"
    }
}

# --- Limpeza de cache com WhatIf/Confirm ---
function Clear-Cache
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param([switch]$IncludePrefetch)

    if (-not $IsWindows)
    { Write-Warning "Clear-Cache é Windows-only."; return
    }
    if (-not $global:PwshProfile.IsAdmin)
    {
        Write-Warning "Rode como Admin para limpar pastas do sistema."
        return
    }

    $targets = @(
        (Join-Path $env:SystemRoot 'Temp\*'),
        (Join-Path $env:TEMP '*'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\INetCache\*')
    )

    if ($IncludePrefetch)
    {
        $targets += (Join-Path $env:SystemRoot 'Prefetch\*')
    }

    foreach ($t in $targets)
    {
        if ($PSCmdlet.ShouldProcess($t, "Remove-Item"))
        {
            Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "Limpeza concluída." -ForegroundColor Green
}

# --- Rede ---
function Get-PublicIP
{
    [CmdletBinding()]
    param([int]$TimeoutSec = 4)

    $urls = @(
        'https://api.ipify.org',
        'https://ifconfig.me/ip'
    )

    foreach ($u in $urls)
    {
        try
        {
            $ip = (Invoke-RestMethod -Uri $u -TimeoutSec $TimeoutSec -Headers @{ 'User-Agent'='pwsh-profile' })
            if ($ip)
            { return ($ip.ToString().Trim())
            }
        } catch
        {
        }
    }

    throw "Não foi possível obter o IP público."
}

function flushdns
{
    if (-not $IsWindows)
    { return
    }
    Clear-DnsClientCache
    Write-Host "DNS limpo." -ForegroundColor Green
}

# --- Admin / sudo ---
function admin
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Command
    )

    if (-not $IsWindows)
    {
        Write-Warning "admin/sudo aqui é voltado para Windows."
        return
    }

    $cmdText = $null
    if ($Command -and $Command.Count -gt 0)
    {
        $cmdText = ($Command -join ' ')
    }

    $hasWT = Test-CommandExists 'wt'

    if ($hasWT)
    {
        if ($cmdText)
        {
            $escaped = $cmdText.Replace('"','`"')
            Start-Process -FilePath 'wt' -Verb RunAs -ArgumentList "pwsh -NoExit -Command `"$escaped`""
        } else
        {
            Start-Process -FilePath 'wt' -Verb RunAs
        }
    } else
    {
        if ($cmdText)
        {
            Start-Process -FilePath 'pwsh' -Verb RunAs -ArgumentList @('-NoExit','-Command', $cmdText)
        } else
        {
            Start-Process -FilePath 'pwsh' -Verb RunAs
        }
    }
}
Set-Alias -Name sudo -Value admin -Force

# --- Uptime (PS 7+) ---
function uptime
{
    try
    {
        $since  = Get-Uptime -Since
        $u      = Get-Uptime
        Write-Host ("System started on: {0:dddd, MMMM dd, yyyy HH:mm:ss}" -f $since) -ForegroundColor DarkGray
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f $u.Days, $u.Hours, $u.Minutes, $u.Seconds) -ForegroundColor Blue
    } catch
    {
        Write-Error "Falha ao calcular uptime: $($_.Exception.Message)"
    }
}

# --- Arquivos / diretórios ---
function touch
{
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Path)

    foreach ($p in $Path)
    {
        if (Test-Path -LiteralPath $p)
        {
            (Get-Item -LiteralPath $p).LastWriteTime = Get-Date
        } else
        {
            New-Item -ItemType File -Path $p -Force | Out-Null
        }
    }
}

function ff
{
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [string]$Path = '.')
    Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*$Name*" } |
        Select-Object -ExpandProperty FullName
}

function nf
{ param([Parameter(Mandatory)][string]$Name) New-Item -ItemType File -Path . -Name $Name -Force | Out-Null
}

function mkcd
{
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Dir)
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    Set-Location -LiteralPath $Dir
}

function docs
{
    $docs = [Environment]::GetFolderPath("MyDocuments")
    if (-not $docs)
    { $docs = (Join-Path $HOME 'Documents')
    }
    Set-Location -LiteralPath $docs
}

function dtop
{
    $dtop = [Environment]::GetFolderPath("Desktop")
    if (-not $dtop)
    { $dtop = $HOME
    }
    Set-Location -LiteralPath $dtop
}

function zip
{
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [string]$DestinationPath)

    if (-not $DestinationPath)
    {
        $DestinationPath = "$Path.zip"
    }
    Compress-Archive -Path $Path -DestinationPath $DestinationPath -Force
}

function unzip
{
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [string]$DestinationPath = '.')

    Expand-Archive -Path $Path -DestinationPath $DestinationPath -Force
}

function df
{
    if (Get-Command Get-Volume -ErrorAction SilentlyContinue)
    {
        Get-Volume
    } else
    {
        Get-PSDrive -PSProvider FileSystem
    }
}

function which
{
    param([Parameter(Mandatory)][string]$Name)
    Get-Command $Name -All | Select-Object Name, CommandType, Source, Definition
}

function export
{
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Value)
    Set-Item -Path "env:$Name" -Value $Value -Force
}

# wrappers estilo Unix (mantendo nomes que você já usa)
function ls
{
    [CmdletBinding()]
    param(
        [string]$Path = '.',
        [string]$Filter = '*',
        [switch]$Force,
        [switch]$Recurse
    )
    Get-ChildItem -LiteralPath $Path -Filter $Filter -Force:$Force -Recurse:$Recurse
}

function la
{ Get-ChildItem -LiteralPath . -Force | Format-Table -AutoSize
}
function ll
{ Get-ChildItem -LiteralPath . -Force | Format-Table -AutoSize
}

function cp
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$Source,
        [Parameter(Mandatory, Position=1)][string]$Destination,
        [switch]$Recurse,
        [switch]$Force
    )
    Microsoft.PowerShell.Management\Copy-Item -LiteralPath $Source -Destination $Destination -Recurse:$Recurse -Force:$Force
}

function mv
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)][string]$Source,
        [Parameter(Mandatory, Position=1)][string]$Destination,
        [switch]$Force
    )
    Microsoft.PowerShell.Management\Move-Item -LiteralPath $Source -Destination $Destination -Force:$Force
}

function rm
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName','PSPath')]
        [string[]]$Path,

        [switch]$Recurse,
        [switch]$Force
    )
    process
    {
        foreach ($p in $Path)
        {
            if ($PSCmdlet.ShouldProcess($p, 'Remove-Item'))
            {
                Microsoft.PowerShell.Management\Remove-Item -LiteralPath $p -Recurse:$Recurse -Force:$Force -ErrorAction Stop
            }
        }
    }
}

function trash {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName','PSPath')]
        [string[]]$Path
    )

    begin {
        if (-not $IsWindows) { throw "trash é Windows-only." }
        Add-Type -AssemblyName Microsoft.VisualBasic | Out-Null
    }

    process {
        foreach ($p in $Path) {
            $full = (Resolve-Path -LiteralPath $p -ErrorAction SilentlyContinue)?.Path
            if (-not $full) { Write-Warning "Não encontrado: $p"; continue }

            if ($PSCmdlet.ShouldProcess($full, "Enviar para Lixeira")) {
                if (Test-Path -LiteralPath $full -PathType Container) {
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                        $full,
                        'OnlyErrorDialogs',
                        'SendToRecycleBin'
                    )
                } else {
                    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                        $full,
                        'OnlyErrorDialogs',
                        'SendToRecycleBin'
                    )
                }
            }
        }
    }
}


# --- Processos ---
function pgrep
{ param([Parameter(Mandatory)][string]$Name) Get-Process $Name -ErrorAction SilentlyContinue
}
function pkill
{ param([Parameter(Mandatory)][string]$Name) Get-Process $Name -ErrorAction SilentlyContinue | Stop-Process -Force
}
function k9
{ param([Parameter(Mandatory)][string]$Name) Stop-Process -Name $Name -Force -ErrorAction SilentlyContinue
}

# --- Texto / leitura ---
function grep
{
    [CmdletBinding(DefaultParameterSetName='Pipe')]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Pattern,

        [Parameter(ParameterSetName='Path', Position=1)]
        [string[]]$Path
    )

    if ($PSCmdlet.ParameterSetName -eq 'Path')
    {
        Select-String -Pattern $Pattern -Path $Path
    } else
    {
        $input | Select-String -Pattern $Pattern
    }
}

function sed
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][string]$Find,
        [Parameter(Mandatory)][string]$Replace
    )
    (Get-Content -LiteralPath $File -Raw).Replace($Find, $Replace) | Set-Content -LiteralPath $File -Force
}

function cat
{ param([Parameter(Mandatory,ValueFromRemainingArguments)][string[]]$Path) Get-Content -LiteralPath $Path
}
function head
{ param([Parameter(Mandatory)][string]$Path, [int]$n = 10) Get-Content -LiteralPath $Path -Head $n
}
function tail
{ param([Parameter(Mandatory)][string]$Path, [int]$n = 10, [switch]$f) Get-Content -LiteralPath $Path -Tail $n -Wait:$f
}

function less
{
    param([Parameter(Mandatory)][string]$Path)
    Get-Content -LiteralPath $Path | Out-Host -Paging
}

# --- Clipboard ---
function cpy
{ param([Parameter(Mandatory)][string]$Text) Set-Clipboard -Value $Text
}
function pst
{ Get-Clipboard
}

# --- Sistema ---
function sysinfo
{
    if (-not $IsWindows)
    { return
    }
    Get-ComputerInfo
}

# --- Help ---
function Show-Help
{
    @"
PowerShell Profile - Comandos principais

Perfil:
  ep / Edit-Profile        - Edita o profile principal
  rp / Reload-Profile      - Recarrega o profile

Updates / manutenção:
  Update-PowerShell        - Atualiza PowerShell via winget (se houver update)
  Clear-Cache [-WhatIf]    - Limpa caches (Windows / Admin)

Navegação:
  docs                     - Vai para Documentos
  dtop                     - Vai para Desktop
  mkcd <dir>               - Cria e entra na pasta

Arquivos:
  touch <arq>              - Cria/atualiza timestamp
  ff <nome>                - Busca por nome (recursivo)
  zip/unzip                - Compacta / extrai
  trash <path>             - Envia para Lixeira
  ls/la/ll                 - Listagens

Rede:
  Get-PublicIP             - Mostra IP público
  flushdns                 - Limpa DNS (Windows)

Admin:
  admin / sudo [cmd]       - Abre terminal admin (wt se existir)

Dica: use 'Get-Command <nome> -Syntax' para ver parâmetros.
"@ | Write-Host
}
