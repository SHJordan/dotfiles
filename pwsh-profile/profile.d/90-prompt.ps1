# =====================================================================
# 90-prompt.ps1
# - Window title (com [ADMIN])
# - Prompt fallback
# - Inicialização de Starship OU Oh-My-Posh (um por vez)
# =====================================================================

# Título da janela
try
{
    $adminSuffix = if ($global:PwshProfile.IsAdmin)
    { " [ADMIN]" 
    } else
    { "" 
    }
    $Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminSuffix"
} catch
{
}

# Prompt fallback (se nenhum tema carregar)
function global:prompt
{
    $loc = Get-Location
    if ($global:PwshProfile.IsAdmin)
    {
        return ("[{0}] # " -f $loc)
    }
    return ("[{0}] $ " -f $loc)
}

# Inicializa tema escolhido (sem usar os 2 ao mesmo tempo)
$theme = Get-PwshTheme

switch ($theme)
{
    'starship'
    {
        if (Test-CommandExists 'starship')
        {
            try
            { Invoke-Expression (& starship init powershell) 
            } catch
            {
                Write-Warning "Falha ao iniciar starship: $($_.Exception.Message)"
            }
        } else
        {
            Write-Warning "Tema 'starship' selecionado, mas o comando 'starship' não existe."
        }
    }

    'omp'
    {
        if (-not (Test-CommandExists 'oh-my-posh'))
        {
            Write-Warning "Tema 'omp' selecionado, mas o comando 'oh-my-posh' não existe."
            break
        }

        # Preferência: config local (mais rápido e funciona offline)
        $candidates = @()
        if ($env:POSH_THEMES_PATH)
        {
            $candidates += (Join-Path $env:POSH_THEMES_PATH 'star.omp.json')
        }
        $candidates += $global:PwshProfile.Paths.OmpTheme

        $config = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1

        if (-not $config)
        {
            New-Item -ItemType Directory -Path $global:PwshProfile.Paths.OmpDir -Force | Out-Null
            Write-Warning "Não achei o tema local 'star.omp.json'. Coloque um tema em:"
            Write-Warning "  $($global:PwshProfile.Paths.OmpTheme)"
            Write-Warning "ou use POSH_THEMES_PATH (instalação padrão do Oh My Posh)."
            break
        }

        try
        {
            oh-my-posh init pwsh --config $config | Invoke-Expression
        } catch
        {
            Write-Warning "Falha ao iniciar oh-my-posh: $($_.Exception.Message)"
        }
    }
}
