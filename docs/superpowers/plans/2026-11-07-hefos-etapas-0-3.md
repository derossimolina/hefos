# HefOS — Plano de implementação: etapas 0 a 3

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sair do Windows 10 com segurança e chegar a um Arch + Hyprland em que você trabalha todo dia, com cada componente do HefOS instalado à mão, testado e registrado em journal.

**Architecture:** As tarefas 1 a 4 são código e documentação feitos **agora, no Windows**: base do repositório, script de inventário em PowerShell, runbook de migração e journals pré-preenchidos com critérios de "funciona". As tarefas 5 a 8 são **execução manual** do usuário (backup, Dia D, sobrevivência, demais etapas), guiada por esses documentos. Os scripts de instalação (módulos, `hefos`, instalador) **não** fazem parte deste plano: entram no plano da etapa 4, escrito a partir dos journals.

**Tech Stack:** PowerShell 7 + Pester 5 (inventário no Windows), Markdown (runbook/journals), Git. No Arch: archinstall, pacman, yay, snapper.

**Spec:** `docs/superpowers/specs/2026-11-07-hefos-design.md`

**Fora deste plano (planos futuros):**
- `docs/superpowers/plans/<data>-hefos-etapa-4-roteirizacao.md`: `lib/`, `modules/`, `packages/`, `config/`, comando `hefos`, `hefos-setup`, CI. Escrito quando a tarefa 8 terminar.
- `docs/superpowers/plans/<data>-hefos-etapa-5-instalador.md`: `install.sh`, `installer/`, testes em VM e USB.

## Global Constraints

- Documentação em **pt-BR**.
- Finais de linha **LF** em todos os arquivos de texto, exceto `*.ps1`, `*.bat` e `*.cmd` (CRLF). Imposto por `.gitattributes`.
- **Nunca** commitar segredos: `.env`, chaves SSH, tokens, credenciais AWS. Imposto por `.gitignore` e revisão.
- A partir do Dia D, regra única: `sudo snapper create -d "antes: <componente>"` antes de instalar qualquer componente.
- Cada componente registrado em `docs/journal/<componente>.md` seguindo `docs/journal/_template.md`. Commit + push após cada um.
- Substituições aprovadas: spotify_player, fastfetch (alias `neofetch`), matugen, NetworkManager com backend iwd.
- Hardware alvo: UEFI, 8 GB de RAM, disco de 120 GB, GPU integrada.

## Review Focus

1. **Caminhos com espaços e acentos** (ex.: `D:\Empresas\J de Rossi Molina`): o inventário precisa listar esses repos corretamente. Teste em Task 2.
2. **Repo sem upstream ou sem remote**: o número de commits sem push é indefinido. Deve ser marcado como pendente (`NoUpstream`), não como "0 sem push". Teste em Task 2.
3. **Árvores enormes** (`node_modules`, `.venv`, `target`): a varredura deve pulá-las, senão leva muito tempo numa CPU fraca. Teste em Task 2.
4. **`git` fora do PATH ou `D:` inexistente**: mensagem clara e saída com código 2, sem stack trace. Teste em Task 3.
5. **HEAD destacado** (detached HEAD): o repo aparece com branch `(detached)` e conta como pendente. Teste em Task 2.

---

## Estrutura de arquivos deste plano

```
.gitattributes                         # Task 1
.gitignore                             # Task 1
README.md                              # Task 1
docs/journal/_template.md              # Task 1
docs/journal/ROADMAP.md                # Task 4 (tracker de todos os componentes)
docs/journal/<componente>.md           # Task 4 (etapa 2 pré-preenchida) e Tasks 7–8
docs/migration/windows-inventory.ps1   # Tasks 2–3 (entrada + relatório)
docs/migration/Inventory.psm1          # Tasks 2–3 (funções testáveis)
docs/migration/README.md               # Task 3 (como rodar o inventário)
docs/migration/runbook.md              # Task 4 (etapas 0, 1 e Plano B)
tests/migration/Inventory.Tests.ps1    # Tasks 2–3
```

---

### Task 1: Base do repositório

**Files:**
- Create: `.gitattributes`, `.gitignore`, `README.md`, `docs/journal/_template.md`
- Modify: `docs/superpowers/specs/2026-11-07-hefos-design.md` (só a renormalização para LF)

**Interfaces:**
- Produces: o template de journal com as seções exatas da spec §8 (`Data`, `Critério de "funciona"`, `Snapshot`, `## Comandos`, `## Configs alteradas`, `## Problemas e soluções`, `## Resultado`). As Tasks 4, 7 e 8 copiam esse template.

- [ ] **Step 1: Criar `.gitattributes`**

```gitattributes
* text=auto eol=lf
*.ps1 text eol=crlf
*.psm1 text eol=crlf
*.bat text eol=crlf
*.cmd text eol=crlf
*.png binary
*.jpg binary
```

- [ ] **Step 2: Criar `.gitignore`**

Precisa cobrir: `.env`, `*.env`, `id_*` (exceto `*.pub`), `*.pem`, `.aws/`, `credentials`, `*.log`, `inventory-report*.md`, `.DS_Store`, `Thumbs.db`.

- [ ] **Step 3: Criar `README.md`**

Uma página: o que é o HefOS (1 parágrafo da spec §1), status ("em construção — etapa 0"), links para a spec, o plano, o runbook e o `docs/journal/ROADMAP.md`.

- [ ] **Step 4: Criar `docs/journal/_template.md`** com o modelo exato da spec §8.

- [ ] **Step 5: Renormalizar e verificar os finais de linha**

Run: `git add --renormalize . && git ls-files --eol`
Expected: todo `.md` mostra `i/lf w/lf`. Nenhum arquivo `i/crlf`, exceto `.ps1`/`.psm1`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: base do repositório (gitattributes LF, gitignore de segredos, README, template de journal)"
```

---

### Task 2: Inventário — status dos repositórios git

**Files:**
- Create: `docs/migration/Inventory.psm1`
- Test: `tests/migration/Inventory.Tests.ps1`

**Interfaces:**
- Produces:
  - `Find-GitRepos -Roots <string[]> [-MaxDepth <int> = 5] -> string[]`: caminhos absolutos dos diretórios que contêm `.git`. Não desce em `node_modules`, `.venv`, `venv`, `target`, `.git`, `$RECYCLE.BIN`, `System Volume Information`, nem dentro de um repo já encontrado.
  - `Get-GitRepoStatus -Path <string> -> [pscustomobject]` com `Path` (string), `Branch` (string, `(detached)` se HEAD destacado), `Uncommitted` (int, linhas de `git status --porcelain`), `Unpushed` (int, ou `$null` sem upstream), `NoUpstream` (bool), `HasRemote` (bool), `Pending` (bool = `Uncommitted -gt 0 -or NoUpstream -or Unpushed -gt 0 -or Branch -eq '(detached)'`).

- [ ] **Step 1: Instalar o Pester 5** (hoje só existe o 3.4.0)

Run: `pwsh -NoProfile -Command "Install-Module Pester -MinimumVersion 5.5 -Scope CurrentUser -Force -SkipPublisherCheck"`
Expected: `Get-Module -ListAvailable Pester` lista uma versão 5.x.

- [ ] **Step 2: Escrever os testes que falham**

Os testes criam repos de fixture em `$TestDrive` com `git init` + `git commit --allow-empty` (com `-c user.name=t -c user.email=t@t`). Repos com remote usam um repo bare local como `origin`.

```powershell
BeforeAll { Import-Module "$PSScriptRoot/../../docs/migration/Inventory.psm1" -Force }

Describe 'Find-GitRepos' {
  It 'encontra repo em caminho com espaços e acentos' {
    # cria "$TestDrive/J de Rossi Molina/projeto ção" como repo
    (Find-GitRepos -Roots $TestDrive) | Should -Contain $repoComAcento
  }
  It 'não desce em node_modules' {
    # repo dentro de "$TestDrive/app/node_modules/pkg"
    (Find-GitRepos -Roots $TestDrive) | Should -Not -Contain $repoEmNodeModules
  }
  It 'não lista repo aninhado dentro de outro repo' { ... | Should -Not -Contain $aninhado }
}

Describe 'Get-GitRepoStatus' {
  It 'repo limpo e sincronizado não fica pendente' {
    $s = Get-GitRepoStatus $repoSincronizado
    $s.Pending | Should -BeFalse; $s.Unpushed | Should -Be 0
  }
  It 'conta arquivos não commitados' {
    # 2 arquivos novos
    (Get-GitRepoStatus $repoSujo).Uncommitted | Should -Be 2
  }
  It 'conta commits sem push' {
    # 3 commits à frente de origin
    (Get-GitRepoStatus $repoAFrente).Unpushed | Should -Be 3
  }
  It 'sem upstream fica pendente com Unpushed nulo' {
    $s = Get-GitRepoStatus $repoSemRemote
    $s.NoUpstream | Should -BeTrue; $s.HasRemote | Should -BeFalse
    $s.Unpushed | Should -BeNullOrEmpty; $s.Pending | Should -BeTrue
  }
  It 'HEAD destacado fica pendente' {
    $s = Get-GitRepoStatus $repoDetached
    $s.Branch | Should -Be '(detached)'; $s.Pending | Should -BeTrue
  }
}
```

- [ ] **Step 3: Rodar e confirmar a falha**

Run: `pwsh -NoProfile -Command "Invoke-Pester tests/migration -Output Detailed"`
Expected: FAIL (módulo inexistente).

- [ ] **Step 4: Implementar `Find-GitRepos` e `Get-GitRepoStatus` em `docs/migration/Inventory.psm1`**

Varredura com `Get-ChildItem -Directory -Force` recursiva manual (para poder podar diretórios), com `-LiteralPath` sempre (por causa de `[`, espaços e acentos). Status via `git -C <path>`: `rev-parse --abbrev-ref HEAD` (devolve `HEAD` quando destacado), `status --porcelain`, `remote`, `rev-list --count @{u}..HEAD` (falha sem upstream, o que define `NoUpstream`). Exportar só as funções públicas.

- [ ] **Step 5: Rodar e confirmar que passa**

Run: `pwsh -NoProfile -Command "Invoke-Pester tests/migration -Output Detailed"`
Expected: todos os testes PASS.

- [ ] **Step 6: Commit**

```bash
git add docs/migration/Inventory.psm1 tests/migration/Inventory.Tests.ps1
git commit -m "feat(migration): inventário de repositórios git com testes Pester"
```

---

### Task 3: Inventário — discos, itens sensíveis e relatório

**Files:**
- Modify: `docs/migration/Inventory.psm1`
- Create: `docs/migration/windows-inventory.ps1`, `docs/migration/README.md`
- Test: `tests/migration/Inventory.Tests.ps1`

**Interfaces:**
- Consumes: `Find-GitRepos`, `Get-GitRepoStatus` (Task 2).
- Produces:
  - `Get-DriveLayout -> [pscustomobject]` com `DExists` (bool), `DIsSeparateDisk` (bool ou `$null`), `CDiskModel`, `DDiskModel`, `CDiskSizeGB`, `DDiskSizeGB`. Usa `Get-Partition -DriveLetter` + `Get-Disk` e compara `DiskNumber`.
  - `Get-SensitiveItems -Paths <hashtable> -> [pscustomobject[]]` com `Name`, `Path`, `Exists` (bool), `SizeMB` (double). Os defaults ficam no script de entrada: `ssh=~/.ssh`, `aws=~/.aws`, `claude=~/.claude`, `gitconfig=~/.gitconfig`, `obsidian=D:\new_obsidian`, `chrome=%LOCALAPPDATA%\Google\Chrome\User Data`, `brave=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data`.
  - `Format-InventoryReport -Repos <obj[]> -Drives <obj> -Items <obj[]> -> string`: Markdown com seções `## Repositórios pendentes`, `## Repositórios ok` (só a contagem), `## Discos`, `## Itens para backup manual` e uma linha final `PENDENTES: <n>`.
  - `windows-inventory.ps1 [-Roots <string[]> = @('D:\', $HOME)] [-OutFile <string> = ./inventory-report.md]`. Códigos de saída: `0` sem pendências, `1` com pendências, `2` erro de pré-requisito (git fora do PATH ou nenhuma raiz existente), sempre com mensagem em uma linha, sem stack trace.

- [ ] **Step 1: Escrever os testes que falham**

```powershell
Describe 'Get-SensitiveItems' {
  It 'marca caminho inexistente sem erro' {
    $r = Get-SensitiveItems -Paths @{ x = "$TestDrive/nao-existe" }
    $r.Exists | Should -BeFalse; $r.SizeMB | Should -Be 0
  }
  It 'soma o tamanho de diretório existente' { ... $r.SizeMB | Should -BeGreaterThan 0 }
}
Describe 'Format-InventoryReport' {
  It 'conta pendentes de repos e termina com PENDENTES: n' {
    $txt = Format-InventoryReport -Repos @($pendente, $ok) -Drives $drv -Items @()
    $txt | Should -Match 'PENDENTES: 1$'
    $txt | Should -Match '## Repositórios pendentes'
  }
  It 'mostra NoUpstream como "sem upstream", não como 0' {
    $txt | Should -Match 'sem upstream'
  }
}
Describe 'windows-inventory.ps1' {
  It 'sai com 2 e mensagem clara quando nenhuma raiz existe' {
    pwsh -NoProfile -File $script -Roots "$TestDrive/nada" -OutFile "$TestDrive/r.md"
    $LASTEXITCODE | Should -Be 2
  }
  It 'sai com 1 quando há repo pendente' {
    pwsh -NoProfile -File $script -Roots $fixtureComPendente -OutFile "$TestDrive/r.md"
    $LASTEXITCODE | Should -Be 1; "$TestDrive/r.md" | Should -Exist
  }
}
```

`Get-DriveLayout` depende do hardware: entra num teste só de forma (propriedades presentes, `DExists` booleano), sem afirmar valores.

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `pwsh -NoProfile -Command "Invoke-Pester tests/migration -Output Detailed"`
Expected: os testes novos FAIL.

- [ ] **Step 3: Implementar as três funções e `windows-inventory.ps1`**

O script de entrada importa o módulo, valida os pré-requisitos (`Get-Command git`), filtra as raízes existentes, roda tudo, grava `-OutFile`, imprime o resumo na tela e sai com o código certo.

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `pwsh -NoProfile -Command "Invoke-Pester tests/migration -Output Detailed"`
Expected: todos PASS.

- [ ] **Step 5: Escrever `docs/migration/README.md`**

Como rodar (`pwsh -File docs/migration/windows-inventory.ps1`), o que cada seção do relatório significa e o objetivo da etapa 0: rodar até `PENDENTES: 0`. Avisar que `inventory-report.md` está no `.gitignore` porque lista caminhos pessoais.

- [ ] **Step 6: Execução real (fumaça)**

Run: `pwsh -NoProfile -File docs/migration/windows-inventory.ps1`
Expected: o relatório é gerado em até ~5 min. A seção Discos diz se `D:` é disco separado ou partição. Repos conhecidos (`D:\projects\*`) aparecem.

- [ ] **Step 7: Commit**

```bash
git add docs/migration tests/migration
git commit -m "feat(migration): discos, itens sensíveis e relatório do inventário"
```

---

### Task 4: Runbook de migração, ROADMAP e journals da etapa 2

**Files:**
- Create: `docs/migration/runbook.md`, `docs/journal/ROADMAP.md`, `docs/journal/{yay,ghostty,git-gh,chrome,nodejs,claude-code,vscode,obsidian}.md`

**Interfaces:**
- Consumes: `docs/journal/_template.md` (Task 1), relatório do inventário (Task 3).
- Produces: `ROADMAP.md` é o tracker único das Tasks 7 e 8. A tabela tem as colunas `Etapa | Componente | Critério de "funciona" | Journal | Status` (status: `—` pendente, `✓` ok, `✗` falhou/substituído).

- [ ] **Step 1: Conferir o archinstall atual**

Consultar a documentação da versão atual do archinstall (wiki do Arch e repositório `archlinux/archinstall`) e anotar se ela oferece: (a) Limine como bootloader, (b) snapshots snapper no Btrfs, (c) perfil Hyprland, (d) NetworkManager com iwd. Essas respostas definem o Step 2.

- [ ] **Step 2: Escrever `docs/migration/runbook.md`**

Três seções:
- **Etapa 0: Backup.** Checklist da spec §8 linha 0, terminando em "inventário com `PENDENTES: 0`", pendrive do Arch ISO (checksum com `Get-FileHash` comparado ao `sha256sums.txt` oficial) e pendrive de recuperação do Windows 10.
- **Etapa 1: Dia D.** Passo a passo: boot pelo pendrive, `iwctl` para conectar no Wi-Fi, `archinstall`, e a **escolha exata em cada menu** com base no Step 1. Inclui disco-alvo (conferir modelo/tamanho com `lsblk -o NAME,MODEL,SIZE`), Btrfs com subvolumes `@ @home @snapshots @log @pkg` e compressão zstd, LUKS (sim em laptop), bootloader, perfil Hyprland, áudio PipeWire, rede NetworkManager, locale `pt_BR.UTF-8`, fuso `America/Sao_Paulo`, teclado conforme a máquina (`br-abnt2` ou `us-intl`), usuário com sudo. Critério de pronto: o Hyprland abre e a rede funciona. Primeiro snapshot: `sudo snapper -c root create -d "base: archinstall"`.
- **Plano B.** Os quatro cenários da spec §8.

- [ ] **Step 3: Escrever `docs/journal/ROADMAP.md`**

Uma linha para **cada** componente da spec §2, agrupados nas etapas da spec §8: 2 (sobrevivência), 3a rollback, 3b visual TUI, 3c CLI, 3d dev, 3e apps, 3f IA, 3g setup. Cada linha tem um critério verificável por comando ou ação, por exemplo:
- `ghostty`: "abre com JetBrainsMono Nerd Font; `ghostty +show-config` sem erro"
- `snapper`: "`sudo pacman -S` de um pacote cria par pre/post em `snapper list`"
- `nm-iwd`: "`nmcli dev` mostra wifi gerenciado; `impala` lista redes; `nmtui` conecta"
- `hermes`: "`hermes` responde com o modelo configurado"
- `ram-ocioso`: "`free -m` após 2 min no desktop: usado < 1200 MB"
- `boot`: "`systemd-analyze` até o greetd < 20 s"

- [ ] **Step 4: Criar os 8 journals da etapa 2** a partir do template, com `Critério de "funciona"` preenchido (igual ao ROADMAP) e `## Comandos` contendo os **comandos sugeridos, marcados "(sugestão — conferir na hora)"**:
  - `yay`: clone do AUR + `makepkg -si`
  - `ghostty`: pacman `ghostty ttf-jetbrains-mono-nerd`
  - `git-gh`: `git github-cli`, `gh auth login`, `ssh-keygen -t ed25519`
  - `chrome`: `yay -S google-chrome`
  - `nodejs`: pacman `nodejs npm`
  - `claude-code`: instalador nativo oficial
  - `vscode`: `yay -S visual-studio-code-bin`
  - `obsidian`: pacman `obsidian`

- [ ] **Step 5: Verificar a cobertura**

Run: `grep -c '^| ' docs/journal/ROADMAP.md`
Expected: pelo menos o número de componentes da spec §2 (conferir a lista item a item contra a spec; nenhum componente da §2 fora do ROADMAP).

- [ ] **Step 6: Commit e push da branch**

```bash
git add docs
git commit -m "docs: runbook de migração, ROADMAP de componentes e journals da etapa 2"
git push -u origin docs/hefos-spec
```

---

### Task 5: Etapa 0 — Backup (manual, no Windows)

Executor: **usuário**, com o Claude Code ajudando a resolver pendências.

- [ ] **Step 1:** Rodar o inventário: `pwsh -File docs/migration/windows-inventory.ps1`.
- [ ] **Step 2:** Resolver cada repo pendente: commit/push, criar remote no GitHub para os que não têm, ou registrar no relatório que o repo vai para o disco externo.
- [ ] **Step 3:** Copiar o vault do Obsidian e os documentos para o disco externo **e** para a nuvem. Conferir abrindo três arquivos aleatórios de cada cópia.
- [ ] **Step 4:** Copiar `~/.ssh`, `~/.aws`, `~/.claude` e `~/.gitconfig` para o disco externo (pasta separada, fora de qualquer nuvem pública). Ligar o sync de conta no Chrome e no Brave e conferir senhas e favoritos em outro dispositivo ou em `passwords.google.com`.
- [ ] **Step 5:** Gravar o pendrive com o Arch ISO (checksum conferido) e o pendrive de recuperação do Windows 10.
- [ ] **Step 6:** Rodar o inventário de novo. Expected: `PENDENTES: 0` (ou cada pendente justificado no runbook). **Só então marcar o Dia D.**

---

### Task 6: Etapa 1 — Dia D (manual)

- [ ] **Step 1:** Seguir `docs/migration/runbook.md` → Etapa 1 do início ao fim.
- [ ] **Step 2:** Verificar o critério de pronto: Hyprland abre, `ping archlinux.org` responde, `snapper list` mostra o snapshot "base: archinstall".
- [ ] **Step 3:** Registrar em `docs/journal/base.md` as escolhas feitas em cada menu e as divergências do runbook. O commit fica para quando o git estiver configurado (Task 7, `git-gh`).

---

### Task 7: Etapa 2 — Sobrevivência (manual, ciclo da spec §8)

Para cada componente, **na ordem**: yay → ghostty → git-gh → chrome → nodejs → claude-code → vscode → obsidian:

- [ ] **Step 1:** `sudo snapper create -d "antes: <componente>"`.
- [ ] **Step 2:** Instalar seguindo o journal (ajustando o que for preciso).
- [ ] **Step 3:** Rodar o critério de "funciona". Se falhar: corrigir ou `snapper rollback` e registrar o problema.
- [ ] **Step 4:** Completar o journal (comandos reais, configs, problemas, resultado) e marcar `✓` no ROADMAP.
- [ ] **Step 5:** Commit + push (a partir do `git-gh`; os journals anteriores entram no primeiro commit).

Ao final:
- [ ] **Step 6:** Restaurar os dados do backup, clonar os repos e abrir um projeto real no VS Code e no Claude Code. Expected: **você consegue trabalhar.** Marcar o marco no ROADMAP.

---

### Task 8: Etapa 3 — Demais componentes (manual, ciclo da spec §8)

Mesmo ciclo da Task 7 (snapshot → instalar → testar → journal → ROADMAP → commit), seguindo os grupos do ROADMAP **nesta ordem**, porque cada um depende do anterior:

- [ ] **3a Rollback:** snap-pac, Limine + limine-snapper-sync (se a base usou GRUB), zram-generator. Teste de aceite 5 da spec §10: instalar um pacote, voltar o snapshot pelo menu de boot e conferir que o pacote sumiu.
- [ ] **3b Visual TUI:** greetd + tuigreet, uwsm, ecossistema Hypr, fonte, Ghostty com tema, AGS (barra), Walker, mako, matugen + `hefos theme` provisório como script em `~/.local/bin`, cliphist, grim/slurp/swappy, zathura. Medir RAM ociosa e tempo de boot (critério 3).
- [ ] **3c CLI:** zsh + plugins + starship, neovim, btop, fastfetch + alias, ncdu, superfile, lazygit, calcurse, wiremix, cava, spotify_player, NetworkManager com backend iwd + impala + nmtui, bluetui.
- [ ] **3d Dev:** python + uv, rustup, bun, powershell, docker + grupo + lazydocker, aws-cli-v2 + lightsailctl.
- [ ] **3e Apps:** brave, dolphin, mpv, imv, flatpak + Flathub, Obsidian CLI.
- [ ] **3f IA:** Hermes Agent (+ skill `hefos-system`, scratchpad `Super+A`, widget AGS, notificação no mako; descobrir o hook de fim de tarefa e registrar), `~/.claude/CLAUDE.md`, Claude Desktop (ou fallback com app do Chrome).
- [ ] **3g Setup TUI:** protótipo do `hefos-setup` em gum, rodado à mão passo a passo, só para validar o fluxo. A versão final entra no plano da etapa 4.
- [ ] **Encerramento:** ROADMAP 100% `✓`/`✗` justificado. Atualizar a spec com o que mudou na prática (§1 diz que as §3–7 são o alvo). Então escrever o plano da etapa 4.
