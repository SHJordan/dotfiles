# =====================================================================
# 50-completions.ps1
# - Completers nativos (git/npm/deno/dotnet)
# =====================================================================

# git/npm/deno: sugestões básicas
$basicCompleter = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $custom = @{
        'git'  = @('status','add','commit','push','pull','clone','checkout','switch','fetch','merge','rebase')
        'npm'  = @('install','start','run','test','build','ci')
        'deno' = @('run','compile','bundle','test','lint','fmt','cache','info','doc','upgrade')
    }

    $cmd = $commandAst.CommandElements[0].Value
    if ($custom.ContainsKey($cmd))
    {
        $custom[$cmd] |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }
}

Register-ArgumentCompleter -Native -CommandName git, npm, deno -ScriptBlock $basicCompleter

# dotnet: só registra se existir
if (Test-CommandExists 'dotnet')
{
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition $commandAst.ToString() |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }
}
