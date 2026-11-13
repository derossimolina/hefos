# git-gh
- Data:
- Critério de "funciona": `gh auth status` ok; `ssh -T git@github.com` autentica; `git push` num repo de teste
- Snapshot: <número/descrição>
## Comandos

(sugestão — conferir na hora)

```bash
sudo snapper -c root create -d "antes: git-gh"
sudo pacman -S git github-cli openssh
git config --global user.name "Jerônimo de Rossi"
git config --global user.email "<e-mail do GitHub>"
git config --global init.defaultBranch main
ssh-keygen -t ed25519 -C "hefos"
gh auth login            # GitHub.com, SSH, enviar a chave nova, login pelo navegador
gh auth status
ssh -T git@github.com
# Depois: clonar o hefos e commitar os journals base/yay/ghostty/git-gh
```
## Configs alteradas
## Problemas e soluções
## Resultado
