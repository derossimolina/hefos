# chrome
- Data:
- Critério de "funciona": `google-chrome-stable` abre, faz login na conta e sincroniza senhas e favoritos
- Snapshot: <número/descrição>
## Comandos

(sugestão — conferir na hora)

```bash
sudo snapper -c root create -d "antes: chrome"
yay -S google-chrome
google-chrome-stable
# Wayland nativo + VA-API: ~/.config/chrome-flags.conf
#   --ozone-platform-hint=auto
#   --enable-features=AcceleratedVideoDecodeLinuxGL
```
## Configs alteradas
## Problemas e soluções
## Resultado
