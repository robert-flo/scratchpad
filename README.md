# scratchpad

Personal notes, ideas, half-baked experiments, and scratch work.

Agents: see [agents_fork.md](agents_fork.md) for the long-running project plan.

## Estado (2026-09-01)

Fork personal de Omarchy: **Etapa 0** (bootstrap dev + dev loop al fork), **Etapa 3 / W7**
(repo personal en GitHub Pages) y **Etapa 4** (sombreado `[omarchy-personal]` en el
`pacman-stable.conf` del fork) completas y **probadas end-to-end** en la máquina dev, y la
**cadencia W9 ejecutada** (rebase + sync de tags + re-release + convergencia). La repo personal
**ya acepta paquetes propios**: la Action publica todos los PKGBUILD con `"personal": true`, y el
PoC `hola-mundo` quedó **instalado y mantenido vía `omarchy update`** (0.1.0-1 → 0.1.0-2). El par
**4.0.2-101** y `hola-mundo` están publicados y firmados en
https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64
(Action `release-personal.yml` en `robert-flo/omarchy-pkgs`; dispatch SIEMPRE con `--ref personal`).

- Bitácora paso a paso: [WORKLOG.md](WORKLOG.md)
- Plan y estado de etapas: [agents_fork.md](agents_fork.md)
- Clave pública del repo personal (privada NO versionada): `keys/omarchy-personal-repo.pub.asc`
- Próximo: iterar las ~55 webapps del dueño (patrón `webapp-workflow.md`) y, cuando haya máquinas en uso, Etapa 5 (onboarding) / Etapa 6 (sync como operación continua).
