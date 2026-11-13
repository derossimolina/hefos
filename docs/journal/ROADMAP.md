# ROADMAP de componentes

Tracker único das etapas 1 a 3 ([spec §8](../superpowers/specs/2026-11-07-hefos-design.md#8-estratégia-de-construção-e-migração)). Para cada linha: snapshot → instalar → testar o critério → journal → status aqui → commit.

Status: `—` pendente · `✓` ok · `✗` falhou ou foi substituído (justificar no journal).

## Etapa 1: Base

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 1 | base | Hyprland abre; `ping -c 3 archlinux.org` responde; `sudo snapper list` mostra "base: archinstall" | [base](base.md) | — |
| 1 | pipewire | `wpctl status` lista as saídas; um vídeo no navegador tem som | base | — |

## Etapa 2: Sobrevivência (nesta ordem)

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 2 | yay | `yay --version` responde; `yay -Ss google-chrome` lista o pacote | [yay](yay.md) | — |
| 2 | ghostty | Abre com JetBrainsMono Nerd Font; `ghostty +show-config` sem erro | [ghostty](ghostty.md) | — |
| 2 | git-gh | `gh auth status` ok; `ssh -T git@github.com` autentica; `git push` num repo de teste | [git-gh](git-gh.md) | — |
| 2 | chrome | `google-chrome-stable` abre, faz login na conta e sincroniza senhas e favoritos | [chrome](chrome.md) | — |
| 2 | nodejs | `node -v` e `npm -v` respondem; `npx --yes cowsay ok` roda | [nodejs](nodejs.md) | — |
| 2 | claude-code | `claude --version` responde; `claude` abre logado num repo | [claude-code](claude-code.md) | — |
| 2 | vscode | `code` abre um repo; extensões sincronizadas pela conta | [vscode](vscode.md) | — |
| 2 | obsidian | Abre o vault restaurado; plugins carregam; sync do git do vault funciona | [obsidian](obsidian.md) | — |
| 2 | restauração | D: montado no fstab; repos clonados; um projeto real aberto no VS Code e no Claude Code. **Você consegue trabalhar.** | restauracao | — |

## Etapa 3a: Rollback

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 3a | snapper | `sudo snapper list` lista snapshots; `snapper list-configs` mostra `root` | snapper | — |
| 3a | snap-pac | `sudo pacman -S` de um pacote cria par pre/post em `snapper list` | snap-pac | — |
| 3a | limine | Boot pelo Limine sem erro; `linux-lts` aparece no menu | limine | — |
| 3a | limine-snapper-sync | Snapshots aparecem no menu do Limine; instalar um pacote, voltar o snapshot pelo menu e o pacote some (aceite 5) | limine-snapper-sync | — |
| 3a | zram | `zramctl` mostra `/dev/zram0`; `swapon --show` lista o zram | zram | — |

## Etapa 3b: Visual TUI

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 3b | greetd-tuigreet | Boot cai no tuigreet; login abre a sessão Hyprland; sddm desabilitado | greetd-tuigreet | — |
| 3b | uwsm | `uwsm check is-active` ok; serviços do usuário iniciam com a sessão | uwsm | — |
| 3b | hypr-ecossistema | hyprlock (`Super+L`), hypridle (tela apaga), hyprpaper, hyprpicker, hyprsunset, hyprpolkitagent (prompt gráfico do `pkexec`), xdg-desktop-portal-hyprland (compartilhar tela no Chrome), hyprland-qt-support | hypr-ecossistema | — |
| 3b | fonte | `fc-list \| grep -i "JetBrainsMono Nerd"` lista a fonte | fonte | — |
| 3b | video-intel | `vainfo` mostra perfis H.264/HEVC; `vulkaninfo --summary` lista a HD 520 | video-intel | — |
| 3b | ags | Barra aparece com workspaces, `[ ai ]`, cpu/mem, rede, bluetooth, áudio, bateria e relógio | ags | — |
| 3b | walker | `Super+Space` abre o lançador e executa um app | walker | — |
| 3b | mako | `notify-send teste` mostra notificação no estilo TUI | mako | — |
| 3b | matugen | `hefos theme <wallpaper>` (provisório em `~/.local/bin`) recolore Hyprland, AGS, mako, Walker e Ghostty | matugen | — |
| 3b | cliphist | `Super+V` lista o histórico e cola o item escolhido | cliphist | — |
| 3b | screenshots | `Print` abre o swappy com a área; `Shift+Print` salva a tela cheia (grim + slurp + swappy) | screenshots | — |
| 3b | zathura | Abre um PDF e um EPUB (`zathura-pdf-mupdf`) | zathura | — |
| 3b | ram-ocioso | `free -m` após 2 min no desktop: usado < 1200 MB (aceite 3) | ram-ocioso | — |
| 3b | boot | `systemd-analyze` até o greetd < 20 s (aceite 3) | boot | — |

## Etapa 3c: CLI e TUI

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 3c | zsh | Shell padrão é zsh; autosuggestions e syntax-highlighting ativos; starship desenha o prompt | zsh | — |
| 3c | neovim | `nvim` abre com o tema matugen | neovim | — |
| 3c | btop | `btop` abre com o tema | btop | — |
| 3c | fastfetch | `neofetch` (alias) roda o fastfetch | fastfetch | — |
| 3c | ncdu | `ncdu ~` navega | ncdu | — |
| 3c | superfile | `Super+E` abre o superfile | superfile | — |
| 3c | lazygit | `lazygit` abre num repo | lazygit | — |
| 3c | calcurse | `calcurse` abre e salva um compromisso | calcurse | — |
| 3c | wiremix | `wiremix` mostra as saídas do PipeWire e muda o volume | wiremix | — |
| 3c | cava | `cava` anima com áudio tocando | cava | — |
| 3c | spotify_player | Toca uma música autenticado | spotify_player | — |
| 3c | nm-iwd | `nmcli dev` mostra wifi gerenciado; `impala` lista redes; `nmtui` conecta | nm-iwd | — |
| 3c | bluetui | `bluetui` pareia um dispositivo e o áudio sai por ele | bluetui | — |

## Etapa 3d: Desenvolvimento

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 3d | python-uv | `python --version`, `uv --version`; `uv run` num projeto real | python-uv | — |
| 3d | rustup | `rustc --version` (stable); `cargo new` + `cargo run` | rustup | — |
| 3d | bun | `bun --version`; `bun run` num projeto | bun | — |
| 3d | powershell | `pwsh -v`; roda o `Invoke-Pester tests/migration` deste repo | powershell | — |
| 3d | docker | `docker run --rm hello-world` sem sudo (usuário no grupo `docker`); `lazydocker` abre | docker | — |
| 3d | aws | `aws sts get-caller-identity` ok; `lightsailctl` no PATH | aws | — |

## Etapa 3e: Aplicações

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 3e | brave | `brave` abre e sincroniza | brave | — |
| 3e | dolphin | `Super+Shift+E` abre o Dolphin; monta o D: | dolphin | — |
| 3e | mpv | Toca um vídeo com VA-API (`mpv --hwdec=vaapi`; o log mostra hwdec ativo) | mpv | — |
| 3e | imv | Abre uma pasta de imagens | imv | — |
| 3e | flatpak | `flatpak remotes` lista flathub; um app Flatpak instala e abre | flatpak | — |
| 3e | obsidian-cli | CLI oficial ativado nas configurações; responde no terminal | obsidian-cli | — |

## Etapa 3f: IA

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 3f | hermes | `hermes` responde com o modelo configurado; chaves em `~/.hermes/.env` com `600` | hermes | — |
| 3f | hermes-scratchpad | `Super+A` alterna a janela flutuante `hefos.hermes` sem encerrar a sessão (aceite 4) | hermes-scratchpad | — |
| 3f | hermes-skill | Skill `hefos-system` carregada; o Hermes tira snapshot antes de mudar o sistema | hermes-skill | — |
| 3f | hermes-eventos | Widget `[ ai: modelo ]` muda de estado; mako avisa o fim de tarefa com a janela escondida (hook ou wrapper `hefos-ai` registrado) | hermes-eventos | — |
| 3f | claude-md | `~/.claude/CLAUDE.md` global com o contexto do HefOS | claude-md | — |
| 3f | claude-desktop | `claude-desktop-bin` abre e loga, ou fallback: app do Chrome `--app=https://claude.ai` no Walker | claude-desktop | — |

## Etapa 3g: Setup TUI

| Etapa | Componente | Critério de "funciona" | Journal | Status |
|---|---|---|---|---|
| 3g | gum | `gum --version`; um `gum choose` desenha no estilo TUI | gum | — |
| 3g | hefos-setup | Protótipo roda os 8 passos à mão e grava `~/.local/state/hefos/setup.done` | hefos-setup | — |
