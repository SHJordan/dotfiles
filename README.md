# dotfiles

Este repositório guarda meus dotfiles (por enquanto focado em PowerShell 7 no Windows 11).

> ⚠️ Aviso: dotfiles executam código no seu terminal. Leia antes de rodar em máquinas que não são suas.

## Estrutura

```

dotfiles/
├─ pwsh-profile/
│  ├─ profile.ps1
│  ├─ install.ps1
│  └─ README.md
└─ README.md

```

## PowerShell (Windows 11 / PowerShell 7+)

O perfil recomendado aqui é o **Current User, All Hosts** (um único `Profile.ps1`), para evitar duplicação de banner e manter o mesmo comportamento em Windows Terminal / VS Code / etc.

### Instalação (recomendado)

1) Clone o repo em um local fixo:

```powershell
git clone https://github.com/SHJordan/dotfiles.git "$HOME\dotfiles"
```

2. Rode o instalador do perfil:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME\dotfiles\pwsh-profile\install.ps1"
```

3. Feche e abra o PowerShell de novo (ou rode `rp`, se você tiver alias de reload).

### Atualização

```powershell
git -C "$HOME\dotfiles" pull
```

Depois recarregue o perfil (se existir `rp`) ou reinicie o terminal.

## Troubleshooting

### Banner/saída duplicada ao abrir o PowerShell

Isso quase sempre acontece quando mais de um perfil está sendo executado.

Verifique quais perfis existem e seus caminhos:

```powershell
$PROFILE | Select-Object *
Test-Path $PROFILE.AllUsersAllHosts
Test-Path $PROFILE.AllUsersCurrentHost
Test-Path $PROFILE.CurrentUserAllHosts
Test-Path $PROFILE.CurrentUserCurrentHost
```

Recomendação: manter **apenas** o `CurrentUserAllHosts` com conteúdo (o “All Hosts”) e deixar os outros vazios (ou inexistentes).
