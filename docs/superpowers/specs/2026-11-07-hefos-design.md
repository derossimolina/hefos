# HefOS — Spec de design (v1)

- **Data:** 2026-11-07
- **Autor:** Jerônimo de Rossi (derossimolina)
- **Status:** aprovado em brainstorming, aguardando revisão da spec escrita
- **Revisão 2026-11-13:** o HefOS passa a ser **distribuído** para máquinas antigas, não só para a máquina do autor. Piso de hardware novo (abaixo) e decisões em aberto na seção 12
- **Repositório:** https://github.com/derossimolina/hefos

---

## 1. Visão e objetivos

HefOS é um ambiente baseado em **Arch Linux + Hyprland** para laptops e desktops antigos, com **visual TUI** em toda a interface, aplicações comuns de trabalho e **IA integrada** (Hermes Agent + Claude Code + Claude Desktop).

O objetivo é **distribuir** o HefOS: ele precisa funcionar em qualquer máquina que atenda o piso abaixo, de preferência nas mais antigas. "Funciona" quer dizer testado numa matriz de máquinas definida (seção 9), não só na máquina do autor.

### Hardware alvo (piso)

| Item | Mínimo | Observação |
|---|---|---|
| Ano | **Intel a partir de 2013 (Haswell) · AMD a partir de 2012 (GCN)** | É o piso prático do Hyprland. Ele exige GPU com OpenGL ES 3; abaixo disso a interface fica lenta ou não abre |
| CPU | Intel/AMD x86_64 (com AES-NI) | Todas as CPUs do piso têm AES-NI, que deixa o LUKS rápido |
| GPU | Integrada Intel (Gen 7.5 / Haswell ou mais nova) ou AMD (GCN, APU ou dedicada) | **NVIDIA: sem suporte** (seção 11) |
| RAM | **4 GB** (8 GB recomendado) | zram é obrigatório. Desktop ocioso < 1,2 GB (seção 10) |
| Disco | **64 GB** (HD ou SSD) | |
| Firmware | **UEFI ou BIOS legado** | O Limine dá boot nos dois |

### Contexto e restrição principal

O autor vai substituir o Windows 10 da sua única máquina (i3-6006U, HD 520, 12 GB, SSD de 120 GB, 2016) pelo HefOS **enquanto continua trabalhando nos seus projetos**. Essa máquina é a primeira da matriz de testes. Para ela vale:

1. Nunca pode ficar sem um sistema utilizável por mais de um dia.
2. Toda mudança tem que ser reversível (snapshots Btrfs).
3. O Windows será **apagado** (sem dual boot). O backup prévio é obrigatório.

### Critérios de sucesso (v1)

Ver seção 10.

### Decisões tomadas no brainstorming

| Tema | Decisão |
|---|---|
| Formato de entrega | Script primeiro (v1). ISO própria via archiso na v2 |
| Migração | Apagar o Windows. Construção **incremental** dentro do Arch já instalado |
| Implementação do instalador/setup | **Bash modular + gum** |
| Linguagem visual | **Terminal clássico**: mono, bordas box-drawing, rótulos em `[ ]`, cantos retos, sem sombra/blur |
| Integração de IA | **Integrada ao desktop**: atalho, skills de sistema, widget na barra e notificações |
| Substituições | spotify-tui → **spotify_player** · neofetch → **fastfetch** (alias `neofetch`) · pywal → **matugen** · nmtui + impala com **NetworkManager usando backend iwd** |
| Apps extras | **yay**, **mpv + imv**, **Flatpak + Flathub**, **Docker** |
| Público (revisão 2026-11-13) | **Distribuição** para máquinas antigas, não só a máquina do autor |
| Piso de hardware (revisão 2026-11-13) | Intel 2013+ / AMD 2012+, 4 GB, 64 GB, UEFI ou BIOS, sem NVIDIA |

> **As seções 3 a 7 descrevem o alvo, não um contrato.** Se na prática um componente se comportar de outro jeito, a decisão é revista, registrada no journal (seção 8) e esta spec é atualizada.

---

## 2. Componentes

As fontes de pacote abaixo são as **prováveis**. O nome exato é confirmado no journal de cada componente e, depois, pelo CI (seção 9).

### 2.1 Base e sistema

| Função | Componente | Fonte provável |
|---|---|---|
| Sistema de arquivos | Btrfs (subvolumes `@`, `@home`, `@snapshots`, `@log`, `@pkg`), compressão zstd | archinstall |
| Criptografia | LUKS2 (opcional, padrão ligado em laptop) | archinstall |
| Bootloader | **Limine** (UEFI e BIOS legado) + `limine-snapper-sync` (snapshots no menu de boot). Fallback: GRUB + grub-btrfs | extra / AUR |
| Snapshots | snapper + snap-pac (snapshot a cada transação pacman) | extra |
| Memória | zram-generator, **obrigatório** por causa do piso de 4 GB (sem swap em disco) | extra |
| Áudio | pipewire, pipewire-pulse, pipewire-alsa, wireplumber | extra |
| Rede | NetworkManager com backend **iwd** · nmtui · **impala** | extra |
| Bluetooth | bluez, bluez-utils · **bluetui** | extra |
| AUR | **yay** | AUR (bootstrap) |
| Apps extras | flatpak (+ Flathub), docker, docker-compose | extra |
| Login | **greetd + tuigreet** | extra |
| Sessão | **uwsm** | extra |
| Vídeo | mesa, vulkan-intel / vulkan-radeon, intel-media-driver (Broadwell+) ou libva-intel-driver (Haswell) / libva-mesa-driver, detectados pelo `lib/hw.sh`. Vulkan só onde a GPU suporta | extra |

### 2.2 Ecossistema Hyprland

hyprland · hyprlock · hypridle · hyprpaper · hyprpicker · hyprsunset · hyprpolkitagent · xdg-desktop-portal-hyprland · hyprland-qt-support (fontes: extra/AUR).

### 2.3 Desktop

| Função | Componente |
|---|---|
| Barra | **AGS v2 (Astal)** |
| Lançador | **Walker** (+ backend elephant, se a versão atual exigir) |
| Notificações | **mako** |
| Terminal | **Ghostty** |
| Shell | **zsh** + zsh-autosuggestions + zsh-syntax-highlighting + starship |
| Fonte | JetBrainsMono Nerd Font |
| Cores | **matugen** |
| Clipboard | **wl-clipboard + cliphist** (exibido pelo Walker) |
| Screenshots | **grim + slurp + swappy** |
| PDF e EPUB | **zathura + zathura-pdf-mupdf** (mupdf também lê EPUB). Fallback para EPUB: foliate |
| Arquivos | **Superfile** (principal), **Dolphin** (backup) |
| Mídia | **mpv**, **imv** |

### 2.4 CLI e TUI

neovim · btop · fastfetch (alias `neofetch`) · ncdu · wiremix · **spotify_player** · cava · lazygit · lazydocker · calcurse · nmtui · bluetui · impala.

### 2.5 Desenvolvimento

| Item | Componente | Observação |
|---|---|---|
| Python | python, python-pip, uv | |
| Node | **nodejs** (versão *current* do repo extra, não LTS), npm | "versão mais atual" |
| Bun | instalador oficial ou `bun-bin` (AUR) | |
| Rust | **rustup** (toolchain stable) | |
| PowerShell | `powershell-bin` (AUR) | |
| GitHub | github-cli (`gh`) | |
| AWS | aws-cli-v2 + **lightsailctl** (plugin do Lightsail) | |
| Containers | docker + lazydocker | usuário no grupo `docker` |
| Editor | **VS Code** (`visual-studio-code-bin`, build oficial da Microsoft) + Neovim | |

### 2.6 Aplicações

Google Chrome (`google-chrome`, AUR) · Brave (`brave-bin`, AUR) · **Obsidian** + **Obsidian CLI** (CLI oficial incluído nas versões recentes, ativado nas configurações) · Dolphin.

### 2.7 IA

Hermes Agent · Claude Code · Claude Desktop. Ver seção 5.

---

## 3. Arquitetura do repositório

```
hefos/
├── install.sh            # (etapa 5) ponto de entrada no live ISO
├── lib/                  # ui.sh (wrappers gum no estilo TUI), log.sh, pkg.sh, hw.sh
├── installer/            # (etapa 5) fase 1, roda no live ISO
│   ├── 00-preflight.sh   # UEFI ou BIOS, internet, RAM >= 4 GB, disco >= 64 GB, CPU Intel/AMD,
│   │                     # GPU no piso (Intel Gen 7.5+ / AMD GCN); NVIDIA ou GPU abaixo do piso: aviso claro e para
│   ├── 10-disk.sh        # partições GPT (ESP no UEFI, partição BIOS boot no legado), LUKS opcional, Btrfs + subvolumes
│   ├── 20-base.sh        # pacstrap, locale pt_BR.UTF-8, fuso, usuário, Limine
│   └── 30-handoff.sh     # copia o repo para o sistema novo e agenda a fase 2
├── modules/              # fase 2, roda no sistema instalado; cada módulo é idempotente
│   ├── 00-survival.sh
│   ├── 10-core.sh
│   ├── 20-hyprland.sh
│   ├── 30-desktop.sh
│   ├── 40-cli.sh
│   ├── 50-dev.sh
│   ├── 60-apps.sh
│   └── 70-ai.sh
├── packages/             # listas por módulo: <modulo>.pacman.txt, .aur.txt, .flatpak.txt
├── config/               # dotfiles copiados para ~/.config (hypr, ags, mako, walker, ghostty, ...)
├── templates/matugen/    # templates de cor por aplicativo
├── setup/                # hefos-setup (fase 3)
├── bin/                  # hefos (apply, update, doctor, snapshot, theme), hefos-setup
├── tests/                # bats
└── docs/
    ├── journal/          # registro de cada componente (seção 8)
    ├── migration/        # runbook e windows-inventory.ps1
    └── superpowers/specs/
```

### Fases de execução (sistema final)

1. **Instalador** (live ISO): poucas perguntas → particionamento → Arch base → reboot.
2. **Provisionamento** (primeiro boot, TTY): roda os módulos com progresso. Em caso de falha, o erro fica no log e `hefos apply --resume` retoma dali. Snapshot ao final.
3. **Setup inicial** (primeiro login no Hyprland): `hefos-setup` (seção 6).

### Contratos dos módulos

- Cada módulo é **idempotente**: rodar duas vezes não quebra nada nem duplica configuração.
- Antes de agir, cada módulo tira um snapshot (`hefos snapshot "antes: <modulo>"`).
- Pacotes vêm só de `packages/<modulo>.*.txt`. O script não contém nomes de pacote soltos.
- Configs vêm só de `config/`. Configs existentes do usuário são guardadas como `.bak-<data>` antes de sobrescrever.
- Saída: exit code 0 = ok. Diferente de 0 = falha, com a mensagem em `~/.local/state/hefos/install.log`.

### Comandos `hefos`

| Comando | Função |
|---|---|
| `hefos apply <modulo>\|--all\|--resume` | Aplica módulos |
| `hefos update` | Snapshot → `git pull` → reaplica módulos alterados → `yay -Syu` |
| `hefos snapshot "<descrição>"` | Snapshot manual |
| `hefos theme <wallpaper> [--light\|--dark]` | Pipeline de tema (seção 4) |
| `hefos doctor` | Verifica binários, serviços, permissões das credenciais, snapshots e espaço livre. Mostra uma tabela TUI |

---

## 4. Desktop, tema TUI e performance

### Linguagem visual: terminal clássico

- Fonte monoespaçada em todos os componentes.
- Bordas de 1px desenhadas como box-drawing (`┌─┐ │ └─┘`), cantos retos, sem sombras, sem blur.
- Rótulos entre colchetes: `[ 1 ]`, `[ ai: modelo ]`.

```
┌─[ 1 ]─[ 2 ]─[ 3 ]──────────── [ ai: sonnet ] cpu 12% │ mem 3.1G │ ▲▼ wlan │ 14:32 ─┐

┌─ hermes ─────────────────┐
│ tarefa concluída         │
└──────────────────────────┘
```

### Barra (AGS)

Workspaces · janela ativa · `[ ai ]` · cpu/mem (a cada 2s) · rede · bluetooth · áudio · bateria · relógio.

### Pipeline de tema

`hefos theme <wallpaper>`:
1. Aplica o wallpaper no hyprpaper.
2. Roda o matugen com `templates/matugen/`, gerando cores para Hyprland, AGS, mako, Walker, Ghostty, btop, Neovim, GTK/Qt, cava, zathura e tuigreet.
3. Recarrega cada componente (`hyprctl reload`, `makoctl reload`, reinício do AGS etc.).

### Performance

- `decoration:blur:enabled = false`, sombras desligadas, animações curtas (toggle `hefos theme --no-anim`).
- `misc:vfr = true`.
- VA-API para decodificar vídeo no Chrome, Brave e mpv.
- Sem daemons de IA rodando em segundo plano.

### Atalhos principais

| Atalho | Ação |
|---|---|
| `Super+Enter` | Ghostty |
| `Super+Space` | Walker |
| `Super+E` / `Super+Shift+E` | Superfile / Dolphin |
| `Super+A` | Hermes (scratchpad flutuante) |
| `Super+V` | Histórico do clipboard |
| `Print` / `Shift+Print` | Área → swappy / tela cheia |
| `Super+L` | hyprlock |
| `Super+1..9` | Workspaces |
| `Super+/` | Folha de atalhos TUI |

---

## 5. Integração de IA

### Instalação

| Componente | Método | Garantia |
|---|---|---|
| Hermes Agent | Instalador oficial da Nous Research (`~/.hermes`) | Obrigatório |
| Claude Code | Instalador nativo oficial | Obrigatório |
| Claude Desktop | AUR `claude-desktop-bin` (empacotamento da comunidade) | **Melhor esforço**. Se falhar, avisa sem abortar e cria a entrada "Claude" como app do Chrome (`--app=https://claude.ai`) |

### Hermes no desktop

- **`Super+A`** alterna uma janela Ghostty flutuante (classe `hefos.hermes`, centralizada, 60% da tela) num special workspace do Hyprland. Esconder não encerra a sessão.
- **Skill `hefos-system`** (`~/.hermes/skills/hefos-system/`): descreve onde fica cada config, os comandos `hefos`, `hyprctl`, `pacman`/`yay`, `systemctl --user` e `snapper`. Regra: antes de qualquer mudança no sistema, rodar `hefos snapshot "antes: <ação>"`.
- A **aprovação de comandos perigosos** do Hermes continua ligada.
- **Widget AGS** `[ ai: <modelo> ]`: estados ocioso, rodando e erro. Clicar alterna a janela.
- **Notificação no mako** quando uma tarefa termina com a janela escondida.

### Claude Code

- `~/.claude/CLAUDE.md` global com o contexto do HefOS: layout, comandos `hefos` e a regra de snapshot.

### Credenciais

- Chaves em `~/.hermes/.env` com permissão `600`. Nunca no repositório nem em logs.
- `hefos doctor` alerta sobre permissões erradas.

### Pontos a validar na implementação

- Qual hook/evento o Hermes oferece para avisar o fim de uma tarefa. Se não houver, o fallback é um wrapper `hefos-ai` em volta do `hermes`, que gera os eventos para o AGS e o mako.
- O formato atual da configuração de provedores e modelos do Hermes.

### Fora da v1

Hermes como daemon/serviço, gateway (Telegram etc.), modelos locais, MCPs extras.

---

## 6. Setup inicial TUI (`hefos-setup`)

Abre automaticamente no primeiro login (Ghostty em tela cheia). É desenhado com gum no estilo terminal clássico e usa a paleta padrão do HefOS até o wallpaper ser escolhido.

### Princípios

- Cada passo pode ser pulado e refeito depois com `hefos-setup <passo>`. Os passos também aparecem no Walker.
- Toda credencial é **testada na hora**. Se falhar: `[ tentar de novo ]` `[ editar ]` `[ pular ]`.
- Segredos são digitados mascarados (`gum input --password`) e nunca aparecem na tela nem em `~/.local/state/hefos/setup.log`.

### Passos

| # | Passo | Ação | Validação |
|---|---|---|---|
| 1 | `rede` | Se estiver offline, abre o impala | ping |
| 2 | `github` | Nome/e-mail do git, `gh auth login` (device flow), chave SSH ed25519 enviada ao GitHub | `gh auth status` |
| 3 | `hermes` | Provedor (OpenRouter, Anthropic, OpenAI, Nous Portal, endpoint compatível com OpenAI com URL), chave, modelo principal, modelo leve opcional. Aceita vários provedores; o primeiro é o padrão | chamada mínima ao modelo |
| 4 | `claude` | Login no `claude`. O Claude Desktop faz o login na primeira abertura | `claude` responde |
| 5 | `aws` (opcional) | `aws configure sso` ou chaves | `aws sts get-caller-identity`; `lightsailctl` presente |
| 6 | `tema` | Wallpaper incluído ou arquivo próprio, claro ou escuro → `hefos theme` | prévia aplicada |
| 7 | `spotify` (opcional) | Autenticação do spotify_player | login ok |
| 8 | `resumo` | Tabela `✓ / – / ✗` e comandos para refazer os passos | grava `~/.local/state/hefos/setup.done` |

---

## 7. Segurança e confiabilidade

- Snapshot antes de qualquer instalação, manual ou por módulo. `snap-pac` cobre as transações do pacman.
- Os snapshots aparecem no menu do Limine, então um update quebrado é desfeito pelo boot.
- LUKS2 opcional (padrão ligado em laptop).
- Credenciais só em arquivos `600` do usuário. O repo tem `.gitignore` para `.env`, chaves e tokens.
- Pacotes AUR: só pacotes listados e revisados em `packages/*.aur.txt`.

---

## 8. Estratégia de construção e migração

### Princípio

**Primeiro testar, depois roteirizar.** Cada componente é instalado à mão, testado e registrado. Só depois que uma etapa inteira está testada ela vira script.

### Ciclo por componente

1. `sudo snapper create -d "antes: <componente>"`. É a única regra que vale desde o primeiro dia.
2. Instalar à mão (pacman, yay ou instalador oficial).
3. Testar contra um critério curto de "funciona", escrito no journal antes de começar.
4. Registrar em `docs/journal/<componente>.md`: comandos exatos, configs alteradas, problemas e soluções, resultado do teste. Commit e push.
5. Quando todos os componentes de uma etapa passarem, o journal vira `modules/NN-*.sh` + `packages/` + `config/`.

### Modelo de journal (`docs/journal/<componente>.md`)

```markdown
# <componente>
- Data:
- Critério de "funciona":
- Snapshot: <número/descrição>
## Comandos
## Configs alteradas
## Problemas e soluções
## Resultado
```

### Etapas

| Etapa | Modo | Conteúdo | Pronto quando |
|---|---|---|---|
| **0. Backup** | No Windows | `docs/migration/windows-inventory.ps1` lista repos com mudanças sem commit/push, tamanhos, o vault do Obsidian, `~/.ssh`, `~/.aws`, `~/.claude` e os perfis dos navegadores, e diz se `D:` é partição ou disco físico. Push de todos os repos. Documentos e vault no disco externo **e** na nuvem. Sync de conta no Chrome e no Brave. Pendrive com o Arch ISO (checksum conferido) e pendrive de recuperação do Windows 10 | O inventário mostra zero itens sem backup |
| **1. Base** | Dia D | archinstall: UEFI, Btrfs com subvolumes + snapper, LUKS opcional, perfil Hyprland, PipeWire, NetworkManager, locale pt_BR, usuário com sudo. Se o archinstall não oferecer Limine/snapper, usa GRUB + snapper e migra depois | O Hyprland abre e a rede funciona |
| **2. Sobrevivência** | À mão + journal | yay → Ghostty → git + gh → Chrome → Node → Claude Code → VS Code → Obsidian, um de cada vez. Depois restaura os dados e clona os repos | **Você consegue trabalhar nos seus projetos** |
| **3. Demais etapas** | À mão + journal | (a) rollback: snap-pac, Limine + limine-snapper-sync, zram · (b) visual TUI: greetd/tuigreet, uwsm, AGS, Walker, mako, matugen, fonte, ecossistema Hypr · (c) CLI · (d) dev · (e) apps · (f) IA · (g) setup TUI | Cada item tem journal com resultado ✓ |
| **4. Roteirização** | Repo | Os journals viram módulos, listas de pacotes e configs. Comandos `hefos`. **A partir daqui vale a regra "tudo pelo repo"**: nenhuma mudança direto no sistema; tudo entra no repo e é aplicado com `hefos apply` | `hefos apply --all` roda limpo na máquina atual (idempotência) |
| **5. Reprodutibilidade** | VM / USB externo | `install.sh` + `installer/` substituem o archinstall. Teste do zero: fases 1 e 2 na matriz de VMs (seção 9); fluxo completo num SSD externo USB e nas máquinas reais da matriz | Sistema reconstruído do zero passa no checklist da seção 10 |
| **6. ISO** | v2 | archiso embalando o instalador | Fora do escopo da v1 |

### Plano B

- **Dia D falhou antes da etapa 2:** reinstala a base com o archinstall a partir do pendrive (dados seguros no backup).
- **Algo quebrou depois:** boot por um snapshot anterior ou `snapper rollback`.
- **Último recurso:** pendrive de recuperação do Windows 10.
- O disco de backup fica intocado por 30 dias após o Dia D.

---

## 9. Testes

### Automatizado (GitHub Actions, a partir da etapa 4)

- `shellcheck` em todos os `.sh`.
- `bats` para `lib/`: parse das listas, detecção de hardware, idempotência das funções de config.
- Job em container `archlinux:latest`: confere se todo pacote em `packages/*.pacman.txt` existe (`pacman -Si`) e se todo pacote em `*.aur.txt` existe (AUR RPC).

### Manual

- Etapas 1 a 3: critério de "funciona" de cada componente, registrado no journal.
- Etapa 4: `hefos apply --all` duas vezes seguidas sem erro e sem mudanças na segunda.
- Etapa 5: matriz de VMs (fases 1 e 2) e SSD externo (fluxo completo).
- `hefos doctor` limpo.

### Matriz de compatibilidade (revisão 2026-11-13)

Como o HefOS é distribuído, "funciona" vale para uma matriz, não para uma máquina.

**VMs** (QEMU/OVMF; no CI quando der, senão à mão a cada release):

| Firmware | RAM | Disco | O que valida |
|---|---|---|---|
| UEFI | 4 GB | 64 GB | Instalador, piso de RAM e disco |
| BIOS legado | 4 GB | 64 GB | Instalador e Limine no BIOS |
| UEFI | 8 GB | 120 GB | Configuração recomendada |

As VMs não validam o desktop: sem aceleração de vídeo, o Hyprland não representa uma máquina real.

**Máquinas reais** (pelo menos uma de cada linha antes da v1):

| Perfil | Exemplo | Status |
|---|---|---|
| Intel no piso (Haswell, 2013–2014) | — | a conseguir |
| Intel intermediária (Skylake, 2015–2017) | Máquina do autor: i3-6006U, HD 520, 12 GB, SATA em modo RAID/RST | disponível |
| AMD APU (GCN) | — | a conseguir |

O `hefos doctor` deve gerar um relatório de compatibilidade (CPU, GPU, RAM, firmware, resultado de cada verificação) que voluntários possam anexar a uma issue.

---

## 10. Critérios de aceite da v1

1. A instalação do zero (etapa 5) termina sem intervenção além das perguntas iniciais.
2. Todos os componentes da seção 2 funcionam.
3. Desktop ocioso usando **menos de 1,2 GB de RAM** (inclusive numa máquina de 4 GB); boot até o tuigreet em **menos de 20s** no SSD.
4. `Super+A` abre o Hermes respondendo com o modelo configurado no `hefos-setup`.
5. Um update quebrado é desfeito escolhendo um snapshot no menu de boot.
6. `hefos update` e `hefos apply --resume` funcionam.
7. Sistema completo instalado ocupa **no máximo 30 GB**, deixando 34 GB ou mais livres num disco de 64 GB.
8. `hefos doctor` passa sem erros.
9. A instalação passa em todas as linhas da matriz de VMs e em pelo menos uma máquina real de cada perfil (seção 9).

---

## 11. Fora do escopo da v1

- ISO própria (archiso): v2.
- Setup inicial reescrito em Go/Bubble Tea: v2, se o gum ficar limitado.
- Hermes como daemon, gateway e modelos locais.
- Dual boot.
- GPUs NVIDIA (dedicadas ou híbridas): o Hyprland funciona mal com elas, sobretudo nas antigas. O preflight avisa e para.
- Máquinas abaixo do piso (Intel antes de Haswell, AMD antes de GCN): exigiriam outro compositor (ex.: Sway) e uma segunda trilha de testes.
- LibreOffice (pode entrar via Flatpak quando precisar).

---

## 12. Decisões em aberto (revisão 2026-11-13)

A mudança para distribuição deixou estas perguntas para decidir, uma de cada vez. Cada decisão atualiza esta spec e o plano.

| # | Pergunta | Proposta inicial |
|---|---|---|
| 1 | A ISO com modo live sobe da v2 para a v1? Quem baixa precisa testar o hardware antes de apagar o próprio sistema | Sim: v1 = ISO live + instalador |
| 2 | Uma edição só, ou leve (4 GB) e completa (8 GB)? Chrome, VS Code, Claude Desktop e Docker pesam em 4 GB | Uma edição base enxuta; os apps pesados viram módulos opcionais no `hefos-setup` |
| 3 | Onde desenvolver sem apagar o Windows do autor? | SSD externo USB na máquina do autor; VMs para o instalador |
| 4 | Locale e idioma: só pt-BR ou também inglês? | Perguntar no instalador; documentação em pt-BR primeiro |
| 5 | O que da configuração pessoal do autor (Hermes, AWS, Obsidian CLI, lightsailctl) fica no HefOS distribuído? | Base genérica; o que é pessoal vira módulo opcional ou fica fora |

Enquanto essas decisões não forem tomadas, o plano das etapas 0 a 3 e o runbook continuam valendo **só para a máquina do autor**.
