# =====================================================================
# 40-psreadline.ps1
# - Configuração PSReadLine (somente se disponível)
# =====================================================================

if (Get-Module -ListAvailable PSReadLine)
{
    try
    { Import-Module PSReadLine -ErrorAction SilentlyContinue 
    } catch
    {
    }

    Set-PSReadLineOption `
        -EditMode Windows `
        -HistoryNoDuplicates:$true `
        -HistorySearchCursorMovesToEnd:$true `
        -PredictionSource HistoryAndPlugin `
        -PredictionViewStyle ListView `
        -BellStyle None `
        -MaximumHistoryCount 10000 `
        -Colors @{
        Command   = '#87CEEB'
        Parameter = '#98FB98'
        Operator  = '#FFB6C1'
        Variable  = '#DDA0DD'
        String    = '#FFDAB9'
        Number    = '#B0E0E6'
        Type      = '#F0E68C'
        Comment   = '#D3D3D3'
        Keyword   = '#8367c7'
        Error     = '#FF6347'
    }

    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete

    Set-PSReadLineKeyHandler -Chord 'Ctrl+d'         -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w'         -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d'          -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow'-Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z'         -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y'         -Function Redo

    # Não gravar comandos sensíveis no histórico
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $sensitive = @('password','secret','token','apikey','connectionstring')
        -not ($sensitive | Where-Object { $line -match $_ })
    }
}
