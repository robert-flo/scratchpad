# ADR-006 — Claves GPG y deploy key: modelo de confianza, rotación y DR

- **Estado:** Aceptada
- **Fecha / hito:** original en 4ª parte (Etapa 3); rotación/DR formalizados en la revisión L8 (S1)

## Contexto

El repo personal firma artefactos y db (clave GPG dedicada) y la Action escribe en `gh-pages` con
una deploy key SSH. El proyecto es **público** (fork de un repo abierto, mismo reposo en GitHub
bajo cuenta personal): la clave privada NO debe aparecer jamás en git, y hay que saber qué hacer si
se pierde o se filtra.

## Decisión

- **Una clave GPG dedicada para el repo** (`D5E75EAC51A44715`, sin passphrase por estar
  exclusivamente en el CI runner como secret; ver riesgos abajo).
  - Privada SOLO en el secret `GPG_PRIVATE_KEY` de `omarchy-pkgs`.
  - Pública en `keys/omarchy-personal-repo.pub.asc` del scratchpad (para confiar en máquinas).
- **Deploy key SSH** write a `omarchy-personal-repo` en el secret `SSH_DEPLOY_KEY` (mismo repo de
  secrets). Sin passphrase (corre en CI).
- Rotación planificada (DR):
  1. Generar par nuevo (GPG o SSH según corresponda).
  2. Publicar la pública nueva + **actualizar `keys/`** del scratchpad.
  3. En TODAS las máquinas: `pacman-key --add <clave-nueva>` + `--lsign-key` ANTES de cualquier
     update (si no, los paquetes de la clave nueva no validan; lo que esté instalado sigue OK).
  4. Actualizar el secret en `omarchy-pkgs` (nunca en git).
  5. Re-publicar el par (mismo `pkgver`, `pkgrel+1`) para que las firmas nuevas cubran una versión.
  6. Revocar/anular la clave anterior (publicar revocación GPG; quitar la deploy key en los
     settings del repo publicador).
- Filtración → rotación inmediata (pasos 1–6) como mínimo; avisar en el README del repo afectado.

## Consecuencias

- Sin clave dedicada privada en git, el único modo de ataque es el secret del repo (controlado).
- Paso "sin passphrase" = coste asumido de CI automático; mitigación: la clave solo firma paquetes
  del repo personal, la deploy key solo escribe en `gh-pages` de `omarchy-personal-repo`
  (scope mínimo y secreto separado).
- Recordatorio operativo: si una publicación usa una clave distinta a confiada en máquinas → F6 del
  RUNBOOK (fallo de firma esperado y recuperable).

## Fuentes

- `agents_fork.md` W7 precondiciones y §7.2 (nunca commitear claves privadas).
- `RUNBOOK.md` §3.F6 (respuesta operativa).