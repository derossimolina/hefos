# Runbook de migração: Windows 10 → Arch (HefOS)

Spec: [§8 Estratégia de construção e migração](../superpowers/specs/2026-11-07-hefos-design.md#8-estratégia-de-construção-e-migração).

## Máquina de referência (levantada em 2026-11-13)

| Item | Valor |
|---|---|
| CPU / RAM / GPU | Intel i3-6006U · 12 GB · Intel HD 520 |
| Firmware | UEFI |
| Disco 0 (C:) | **Patriot Burst Elite 120GB** (111,8 GB, GPT). **Alvo do Dia D: será apagado** |
| Disco 1 (D:, "Backup") | **WDC WD10SPZX** (931,5 GB, MBR, NTFS). **Não tocar.** Fica intacto e é montado no Arch |
| Controlador | **Modo RAID (Intel RST)**: precisa virar **AHCI** na BIOS no Dia D (ver 1.1) |
| Pendrive | SanDisk Cruzer Fit 8 GB com **Ventoy**: `archlinux-x86_64.iso` (2026.11.01, SHA256 conferido em 2026-11-13) e `Win10_22H2_BrazilianPortuguese_x64v1.iso` |

O D: é um disco separado e sobrevive ao Dia D, mas **não conta como backup dele mesmo**: o que está no D: também precisa estar no disco externo e na nuvem.

---

## Etapa 0: Backup (no Windows)

Pronto quando: o inventário termina com `PENDENTES: 0` e todos os itens abaixo estão marcados.

- [ ] Rodar o inventário: `powershell -NoProfile -File docs/migration/windows-inventory.ps1` (ver [README](README.md)).
- [ ] Resolver cada repo pendente: commit + push, criar remote no GitHub (`gh repo create --private --source . --push`) ou anotar abaixo, em "Exceções", que ele vai só para o disco externo.
- [ ] Copiar o vault do Obsidian (`D:\new_obsidian`) e os documentos para o **disco externo** e para a **nuvem**. Conferir abrindo três arquivos aleatórios de cada cópia.
- [ ] Copiar `~/.ssh`, `~/.aws`, `~/.claude` e `~/.gitconfig` para o disco externo, numa pasta separada e **fora de qualquer nuvem pública**.
- [ ] Ligar a sincronização de conta no Chrome e no Brave. Conferir senhas e favoritos em outro dispositivo ou em `passwords.google.com`.
- [ ] Anotar a senha do Wi-Fi e os dados de 2FA (apps autenticadores e códigos de recuperação) fora do computador.
- [ ] **Desligar a Inicialização Rápida e a hibernação** (`powercfg /h off` num terminal de administrador). Sem isso, o NTFS do D: fica "sujo" e o Linux monta só leitura ou recusa.
- [ ] Pendrive do Arch: `Get-FileHash E:\archlinux-x86_64.iso` igual ao `sha256sums.txt` oficial. ✓ feito em 2026-11-13 (2026.11.01). Se baixar um ISO mais novo, conferir de novo.
- [ ] Pendrive de recuperação do Windows 10: o ISO já está no Ventoy. Conferir que o Ventoy dá boot nele (só até a primeira tela, sem instalar).
- [ ] Testar o boot do Arch pelo Ventoy (ver 1.1 e 1.2) **sem instalar**: confirma que o pendrive funciona e que o Wi-Fi é reconhecido (`iwctl device list`).
- [ ] Rodar o inventário de novo: `PENDENTES: 0`. **Só então marcar o Dia D.**

### Exceções (repos que vão só para o disco externo)

| Repositório | Motivo | Copiado em |
|---|---|---|
| `D:\Projetos Código\sheepdog` | `.git` quebrado (sem objetos); só `public/favicon.svg`. Remote original: `jeronimo-molina/sheepdog-site` | |

### Arquivos fora do git (vão no backup do D:, não no GitHub)

| Onde | O quê | Motivo |
|---|---|---|
| `D:\projects\tiktok\public\v*` | Vídeos brutos (~800 MB) | Ignorados pelo `.gitignore` do repo |
| `D:\projects\caxias3d\_cache_tse\` | Zips do TSE (~650 MB) | Acima do limite de 100 MB do GitHub; podem ser baixados de novo do TSE |
| `D:\HugoBlog\themes\{risotto,shibui,terminal}` | Temas de terceiros não usados | Clonáveis de novo; ajustes locais em `_patches/` |

### Resolvido em 2026-11-13

- `D:\Obsidian`: a história local não tem nenhum commit em comum com `obsidian_new/main` (vault arquivado). Os 167 commits locais foram para a branch `arquivo-windows-2026-11-13` do mesmo repo, sem sobrescrever a `main`.
- `D:\HugoBlog`: o remote antigo (`derossimolina.github.io`) não existe mais. Publicado no repo privado `derossimolina/hugoblog`.
- `contexto-graficos` e `tiktok`: novos repos privados no GitHub.
- `eleicoes_pib`: `.claude/` e `output/raiox_nacional.log` ignorados localmente (`.git/info/exclude`).

---

## Etapa 1: Dia D

Pronto quando: o Hyprland abre, `ping archlinux.org` responde e `snapper list` mostra o snapshot "base: archinstall".

Reserve um dia inteiro. Tenha o celular à mão para consultar este runbook (ele está no GitHub).

### 1.1 BIOS/UEFI

1. Entrar no setup da BIOS (F2, Del ou Esc, depende do fabricante).
2. **SATA Mode / Storage: RAID (Intel RST) → AHCI.** Sem isso, o instalador pode não ver o SSD. Depois dessa troca, o Windows **para de dar boot** até você voltar para RAID. Isso é esperado: se o Dia D for abortado antes do passo 1.4, volte para RAID e o Windows funciona como antes.
3. **Secure Boot: desligado** (o ISO do Arch não é assinado).
4. Boot mode: UEFI (sem CSM/Legacy).
5. Salvar e sair dando boot pelo pendrive (menu de boot: F12, F9 ou Esc).

### 1.2 Live ISO

1. No Ventoy, escolher `archlinux-x86_64.iso`. Se travar, tentar de novo em "GRUB2 mode".
2. Teclado: `loadkeys br-abnt2` (ou `us-acentos` se o teclado for americano).
3. Wi-Fi:
   ```
   iwctl
   [iwd]# device list
   [iwd]# station wlan0 scan
   [iwd]# station wlan0 get-networks
   [iwd]# station wlan0 connect "<SSID>"
   [iwd]# exit
   ping -c 3 archlinux.org
   ```
4. Conferir o firmware UEFI: `ls /sys/firmware/efi/efivars` precisa listar arquivos.
5. **Identificar o disco-alvo:**
   ```
   lsblk -o NAME,MODEL,SIZE,TYPE,FSTYPE
   ```
   O alvo é o **Patriot Burst Elite 120GB (~111,8G)**. O **WDC WD10SPZX (~931,5G)** é o D: e **não pode ser selecionado**. Anote os dois nomes (`sda`, `sdb`, `nvme0n1`...): eles mudam entre boots.
6. Atualizar o instalador: `pacman -Sy archinstall` (opcional, recomendado se o ISO tiver mais de um mês).

### 1.3 archinstall

`archinstall` e, no menu principal (archinstall 4.5; os rótulos podem mudar um pouco, então **confira na hora**):

| Menu | Escolha |
|---|---|
| Archinstall language | English ou Português |
| Locales | Keyboard `br-abnt2` (ou `us-acentos`) · Locale `pt_BR.UTF-8` · Encoding `UTF-8` |
| Mirrors and repositories | Região **Brazil** (e Worldwide como reserva) |
| Disk configuration | "Use a best-effort default partition layout" → selecionar **só o Patriot 120GB** → **btrfs** → aceitar os subvolumes padrão → compressão **zstd** se perguntar · **Btrfs snapshots: snapper** · **Disk encryption: LUKS** (laptop) com senha forte, digitada com o layout certo |
| Swap | **zram** (algoritmo zstd) |
| Bootloader | **Limine** · UKI: não (mais simples para o `limine-snapper-sync` na etapa 3a). Se o Limine não aparecer ou falhar: **GRUB** (migrar na 3a) |
| Kernels | `linux` **e** `linux-lts` (o LTS é a rede de segurança se um kernel novo quebrar) |
| Additional firmware | Sim. Se houver opção de áudio, incluir `sof-firmware` |
| Hostname | `hefos` |
| Authentication | Root sem senha (desabilitado) · usuário `jeronimo` (ou o de sempre) com **sudo** |
| Profile | Desktop → **Hyprland** · Seat access: **systemd-logind** (polkit) · Graphics driver: **Intel (open-source)** · Greeter: o padrão (sddm). Troca por greetd/tuigreet na etapa 3b |
| Applications | Áudio **PipeWire** · Bluetooth **sim** |
| Network configuration | **NetworkManager com backend iwd** (opção `NM_IWD`). Se não existir: NetworkManager simples (troca de backend na 3c) |
| Pacman | Downloads paralelos: 5 · Habilitar `multilib`: não precisa |
| Additional packages | `git base-devel nano firefox ntfs-3g` (Firefox é o navegador provisório até o Chrome entrar na etapa 2) |
| Timezone | `America/Sao_Paulo` |
| Automatic time sync (NTP) | Sim |

Antes de **Install**: abrir **Disk configuration** de novo e conferir que **só o Patriot** aparece como alvo. Então **Save configuration** (em `/root`) e **Install**.

> **Ponto sem volta.** A partir do Install, o Windows está apagado. Para abortar, escolha Abort antes disso.

Ao final, quando o archinstall perguntar se quer fazer chroot: **sim**, para conferir:
```
cat /etc/fstab                # subvolumes @, @home, @log, @pkg, (@snapshots ou .snapshots) com compress=zstd
snapper list-configs          # deve existir a config "root"
exit
```
Depois `reboot` e tirar o pendrive.

### 1.4 Primeiro boot

1. Limine → Arch → senha do LUKS → sddm → sessão Hyprland (`Super+Q` abre o kitty no padrão do archinstall).
2. Rede: `nmtui` (ou `nmcli dev wifi connect "<SSID>" --ask`). Teste: `ping -c 3 archlinux.org`.
3. Snapper: se `sudo snapper list-configs` não mostrar `root`, criar com `sudo snapper -c root create-config /`.
4. **Primeiro snapshot:** `sudo snapper -c root create -d "base: archinstall"` e conferir com `sudo snapper list`.
5. Montar o D: **só leitura** para começar:
   ```
   lsblk -o NAME,MODEL,SIZE,FSTYPE,LABEL     # partição NTFS de ~931G, label "Backup"
   sudo mkdir -p /mnt/backup
   sudo mount -t ntfs3 -o ro /dev/<particao> /mnt/backup
   ```
   A montagem permanente (fstab, leitura e escrita) fica para a etapa 2, depois de restaurar os dados.
6. Registrar em `docs/journal/base.md` as escolhas reais de cada menu e as diferenças em relação a este runbook (o commit fica para depois do `git-gh`, na etapa 2).

Etapa 2 em diante: ver [ROADMAP](../journal/ROADMAP.md).

---

## Plano B

| Cenário | O que fazer |
|---|---|
| **Dia D falhou antes da etapa 2** (sem boot, sem rede, Hyprland não abre) | Boot pelo Ventoy de novo e reinstalar a base com o `archinstall` (dá para carregar a config salva). Os dados estão no backup e no D:. |
| **Algo quebrou depois** | Escolher um snapshot anterior no menu do Limine (depois da etapa 3a) ou `sudo snapper rollback <n>` + reboot. Kernel novo quebrou: escolher `linux-lts` no menu de boot. |
| **Último recurso** | Reinstalar o Windows 10 pelo ISO no Ventoy (voltar a BIOS para o modo desejado antes). Restaurar do disco externo. |
| **Disco de backup** | O disco externo fica **intocado por 30 dias** após o Dia D: nada de reaproveitar nem formatar. |
