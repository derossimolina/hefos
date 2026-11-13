# ghostty
- Data:
- Critério de "funciona": Abre com JetBrainsMono Nerd Font; `ghostty +show-config` sem erro
- Snapshot: <número/descrição>
## Comandos

(sugestão — conferir na hora)

```bash
sudo snapper -c root create -d "antes: ghostty"
sudo pacman -S ghostty ttf-jetbrains-mono-nerd
mkdir -p ~/.config/ghostty
printf "font-family = JetBrainsMono Nerd Font\n" >> ~/.config/ghostty/config
ghostty +show-config | head
# Hyprland: bind = SUPER, Return, exec, ghostty  (em ~/.config/hypr/hyprland.conf)
```
## Configs alteradas
## Problemas e soluções
## Resultado
