# scratchpad

Personal notes, ideas, half-baked experiments, and scratch work.

Agents: see [agents_fork.md](agents_fork.md) for the long-running project plan.

## Estado (2026-09-01)

Fork personal de Omarchy: **Etapa 0** (bootstrap dev + dev loop al fork), **Etapa 3 / W7**
(repo personal en GitHub Pages) y **Etapa 4** (sombreado `[omarchy-personal]` en el
`pacman-stable.conf` del fork) completas. El par `omarchy`/`omarchy-settings` **4.0.2-100**
está publicado y firmado en https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64
(Action `release-personal.yml` en `robert-flo/omarchy-pkgs`, run verde `33571098815`). El
sombreado del par se comprobó con `pacman -Su --print` (el dry-run "sube" `omarchy`/`omarchy-settings`
a `4.0.2-100` desde `[omarchy-personal]`; el resto del ecosistema sigue en `[omarchy]` oficial).

- Bitácora paso a paso: [WORKLOG.md](WORKLOG.md)
- Plan y estado de etapas: [agents_fork.md](agents_fork.md)
- Clave pública del repo personal (privada NO versionada): `keys/omarchy-personal-repo.pub.asc`
- Próximo: prueba end-to-end de `omarchy update` con `[omarchy-personal]` en la máquina dev (§0.2 item 5).
