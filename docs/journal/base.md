# base
- Data:
- Critério de "funciona": Hyprland abre; `ping -c 3 archlinux.org` responde; `sudo snapper list` mostra "base: archinstall"
- Snapshot: <número/descrição>
## Comandos

(sugestão — conferir na hora)

```bash
# Sem snapshot "antes": é a instalação. Seguir docs/migration/runbook.md, etapa 1.
# Registrar abaixo a escolha real de cada menu do archinstall e as diferenças do runbook.
sudo snapper -c root create -d "base: archinstall"
sudo snapper list
```
## Configs alteradas
## Problemas e soluções
## Resultado
