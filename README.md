# scratchpad

Personal notes, ideas, half-baked experiments, and scratch work.

Agents: see [agents_fork.md](agents_fork.md) for the long-running project plan.

## Estado (2026-09-01)

Fork personal de Omarchy: **Etapa 0** (bootstrap dev + dev loop al fork), **Etapa 3 / W7**
(repo personal en GitHub Pages) y **Etapa 4** (sombreado `[omarchy-personal]` en el
`pacman-stable.conf` del fork) completas, **Etapa 4 probada end-to-end** en la máquina dev:
`pacman -S` instaló `omarchy-personal/omarchy` + `omarchy-settings` **4.0.2-100**, `omarchy
refresh pacman` dejó el pacman.conf del fork, y `omarchy update -y` convergió (RC=0). El par
**4.0.2-100** está publicado y firmado en https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64
(Action `release-personal.yml` en `robert-flo/omarchy-pkgs`, run verde `33571098815`).

- Bitácora paso a paso: [WORKLOG.md](WORKLOG.md)
- Plan y estado de etapas: [agents_fork.md](agents_fork.md)
- Clave pública del repo personal (privada NO versionada): `keys/omarchy-personal-repo.pub.asc`
- Próximo: cadencia W9 (rebase de `personal` sobre `upstream/quattro` + sync del tag `v4.0.2`) e iterar las webapps del dueño.
