# pwsh-profile

Perfil do **PowerShell 7+** (Windows 11), pensado para:

- carregar rápido (idempotente e com checks antes de importar)
- evitar “banner duplicado”
- manter o setup sincronizado via Git/GitHub

## Onde o PowerShell procura o Profile

No Windows, os perfis padrão ficam em `Documents\PowerShell`:

- Current User, All Hosts:  
  `"$HOME\Documents\PowerShell\Profile.ps1"`

- Current User, Current Host:  
  `"$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"`

> O PowerShell pode executar múltiplos perfis em sequência. Se você tiver banner em mais de um, ele aparece duplicado.

## Instalação (recomendado)

Use o `install.ps1` desta pasta. Ele cria um *shim* no caminho real do profile que aponta para o arquivo do repo.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME\dotfiles\pwsh-profile\install.ps1"
```

## Instalação (manual)

Copie o arquivo para o caminho do Profile (All Hosts):

```powershell
$dest = $PROFILE.CurrentUserAllHosts
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
Copy-Item -Force "$HOME\dotfiles\pwsh-profile\profile.ps1" $dest
```

## Comandos úteis

Sugestões comuns (dependem do que você colocou no `profile.ps1`):

* Recarregar profile: `rp`
* Trocar tema (se existir): `Set-PwshTheme starship` / `Set-PwshTheme omp`

## Problemas comuns

### Profile rodando 2x

1. Veja o que existe:

```powershell
$PROFILE | Select-Object *
```

2. Garanta que só UM arquivo tenha “banner”/saída:

* Recomendo centralizar tudo em `CurrentUserAllHosts` (`Profile.ps1`)
* Deixe `Microsoft.PowerShell_profile.ps1` vazio ou inexistente (se você não precisar dele)

### Pasta Documents no OneDrive

Se seu `Documents` estiver redirecionado (OneDrive/Network Share), podem ocorrer erros ao carregar módulos.
Considere mover “Documentos” para local normal ou manter o profile minimalista e resiliente.

---

## Script recomendado para sincronizar bem entre PCs (crie `pwsh-profile/install.ps1`)

Esse é o pulo do gato pra você **não copiar arquivo manualmente** em cada PC.  
Ele cria um *shim* em `$PROFILE.CurrentUserAllHosts` que **dot-sourça** o `profile.ps1` do repo.

> Assim, seu “profile real” vira só um apontador e você edita/sincroniza só via Git.

```powershell
# pwsh-profile/install.ps1
# Instala o profile "CurrentUserAllHosts" apontando para este repo.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoProfile = Join-Path $PSScriptRoot 'profile.ps1'
if (-not (Test-Path $repoProfile)) {
    throw "Não encontrei: $repoProfile"
}

$targetProfile = $PROFILE.CurrentUserAllHosts
$targetDir = Split-Path -Parent $targetProfile

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$shim = @"
# Auto-gerado por pwsh-profile/install.ps1
# Este arquivo só aponta para o profile versionado no repo.
# Repo: $repoProfile

if (-not (`$global:__DOTFILES_PWSH_PROFILE_LOADED)) {
    `$global:__DOTFILES_PWSH_PROFILE_LOADED = `$true
    . `"$repoProfile`"
}
"@

Set-Content -Path $targetProfile -Value $shim -Encoding UTF8
Write-Host "OK: instalado em $targetProfile" -ForegroundColor Green
Write-Host "Reinicie o pwsh ou rode: . `$PROFILE.CurrentUserAllHosts" -ForegroundColor Yellow
```

**Por que esse `__DOTFILES_PWSH_PROFILE_LOADED`?**
Porque mesmo você tentando manter só um profile, às vezes algum host (ou outro arquivo antigo) acaba dot-sourçando de novo — essa flag garante **idempotência** e elimina banner duplicado.
