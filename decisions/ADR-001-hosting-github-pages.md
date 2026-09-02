# ADR-001 — Hosting del repo pacman personal: GitHub Pages + GitHub Actions

- **Estado:** Aceptada
- **Fecha / hito:** Etapa 3 (WORKLOG 4ª parte, 2026-09-01)

## Contexto

El sistema personal necesita un repo pacman propio que las máquinas consuman por el flujo normal
`omarchy update`. Queremos build host CI (no el portátil) y entrega estática con HTTPS, sin
infraestructura propia (sin VPS, sin rclone/S3, sin servidor de archivos propio).

## Decisión

- Repo publicador: `robert-flo/omarchy-personal-repo`, branch `gh-pages` (un repo de solo `stable`).
- Build host: GitHub Actions en `robert-flo/omarchy-pkgs` replicando el pipeline de `omarchy-pkgs`
  (`build → sign → promote → update → clean`) de punta a punta.
- **Única desviación operativa** vs upstream: el entregable final es un commit+push a `gh-pages`
  en vez de `sync-repo`/rclone (Pages no acepta push por SSH/rclone).
- Consecuencia mecánica: el runner necesita escribir en `omarchy-personal-repo` → deploy key SSH
  (`SSH_DEPLOY_KEY`, write) en vez del `GITHUB_TOKEN` del huésped (que no escribe en otro repo).

## Consecuencias

- Coste: los builds dependen de runners de GitHub; sin runner no hay release (normalmente irrelevante
  para un proyecto personal de N máquinas).
- Publicar = girar el workflow; hay un `dry_run=true` para ensayar sin publicar (L8).
- GitHub Pages sirve los `.pkg.tar.zst` como archivo estático plano; no hay symlinks permitidos
  (los `omarchy.db`/`.files` se resuelven a copias reales), se firman db y artefactos.
- La URL canónica es `https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/…`.

## Fuentes

- `agents_fork.md` §0.2 y W7.
- WORKLOG 4ª parte (run verde inicial `33565145113`).

## Alternativas descartadas

- Hosting en la máquina dev / NAS doméstico: sin disponibilidad garantizada, furioso para el
  modelo "N máquinas con update automático".
- OCI (GHCR/Kontainer) como repo pacman: no es el mecanismo de upstream (Arch usa servidor HTTP
  + db pacman); introduciría su propia complejidad.