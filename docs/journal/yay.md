# yay
- Data:
- Critério de "funciona": `yay --version` responde; `yay -Ss google-chrome` lista o pacote
- Snapshot: <número/descrição>
## Comandos

(sugestão — conferir na hora)

```bash
sudo snapper -c root create -d "antes: yay"
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
cd /tmp/yay-bin && makepkg -si
yay --version
```
## Configs alteradas
## Problemas e soluções
## Resultado
