# Inventário do Windows (etapa 0)

O objetivo da etapa 0 é chegar ao Dia D sem nada que se perca ao apagar o Windows. O script `windows-inventory.ps1` aponta o que ainda falta. **Rode até o relatório terminar com `PENDENTES: 0`.**

## Como rodar

Na raiz do repositório, no Windows PowerShell 5.1 ou no PowerShell 7:

```powershell
powershell -NoProfile -File docs/migration/windows-inventory.ps1
```

Parâmetros opcionais:

| Parâmetro | Padrão | Uso |
|---|---|---|
| `-Roots` | `D:\`, `$HOME` | Pastas onde procurar repositórios git |
| `-OutFile` | `./inventory-report.md` | Onde gravar o relatório |
| `-MaxDepth` | `5` | Profundidade máxima da busca |
| `-SkipSensitive` | desligado | Pula a medição de `.ssh`, perfis de navegador etc. |

Códigos de saída: `0` sem pendências, `1` com pendências, `2` erro de pré-requisito (git fora do PATH ou nenhuma raiz existente).

A busca não entra em `node_modules`, `.venv`, `venv`, `target`, `.git`, na lixeira, em junções/links nem em repositórios aninhados.

## Seções do relatório

- **Repositórios pendentes**: repos com arquivos não commitados, commits sem push, sem upstream (`sem upstream`, ou seja, não dá para saber se está tudo no GitHub) ou com HEAD destacado. Resolva cada um com commit + push, crie o remote no GitHub ou anote no runbook que ele vai só para o disco externo.
- **Repositórios ok**: só a contagem dos repos limpos e sincronizados.
- **Discos**: modelo e tamanho dos discos do C: e do D:, e se o D: é um disco físico separado (sobrevive ao Dia D) ou uma partição do mesmo disco (será apagado). Avisa se o controlador está em modo RAID/Intel RST.
- **Itens para backup manual**: `~/.ssh`, `~/.aws`, `~/.claude`, `~/.gitconfig`, o vault do Obsidian e os perfis do Chrome e do Brave, com tamanho. O script não sabe se você já os copiou: confira cada um com o checklist do [runbook](runbook.md).

## Privacidade

`inventory-report.md` lista caminhos pessoais e está no `.gitignore`. Não o commite.

## Testes

```powershell
Install-Module Pester -MinimumVersion 5.5 -Scope CurrentUser -Force -SkipPublisherCheck
Invoke-Pester tests/migration -Output Detailed
```

Os arquivos `.ps1`/`.psm1` são salvos em UTF-8 **com BOM** e CRLF: sem o BOM, o PowerShell 5.1 lê os acentos errado.
