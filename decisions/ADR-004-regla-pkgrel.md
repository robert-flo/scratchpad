# ADR-004 — Regla §5.3: `pkgrel` base alta + incremento por republicación

- **Estado:** Aceptada (mecánica de aplicación actualizada por la revisión L8, 2026-09-01)
- **Fecha / hito:** regla original en 7ª parte (cadencia W9); autoderivación en la revisión L8

## Contexto

pacman elige por `vercmp`: gana el `pkgver` más alto; a `pkgver` igual, el `pkgrel` más alto. Y el
pipeline de build decide "needs build" por **diferencia de versión**: un cambio de personalización
con el MISMO `pkgver-pkgrel` no reconstruiría nada.

- El `pkgver` del par personal = el tag upstream base de la rama `personal` (lo fija el pin engine,
  lockstep §5.1).
- El `pkgrel` del par oficial de stable es `1` en cada release (p. ej. `4.0.1-1`).

## Decisión

- `pkgrel` personal = **base alta `99`** cuando el `pkgver` es nuevo, e **incremento de +1 por cada
  republicación del mismo `pkgver`** (99 → 100 → 101 …).
- Aplicación (mecánica L8): **autoderivada por la Action** — se lee el estado previo commitado del
  PKGBUILD del par (`pkgver`/`pkgrel`) y, tras el pin engine (que resetea `pkgrel` a 1), se aplica:
  - `pkgver` nuevo → `99`;
  - mismo `pkgver` → última republicada + 1.
  - Queda un override manual `-f pkgrel=<n>` para emergencias (p. ej. perdida/rotación de clave
    o reparar una republicación no deseada).
- Solo afecta al subconjunto `pinned` (el par lockstep). Un paquete genérico (p. ej. `hola-mundo`)
  usa el `pkgrel` normal de su PKGBUILD.

## Consecuencias

- A `pkgver` igual, `vercmp` gana siempre el personal (`4.0.1-99` > `4.0.1-1`).
- "Needs build" se dispara en cada republicación porque cambia `pkgrel`.
- **Recuperación automática** (lag): si una máquina quedó en el par oficial, republicar el personal
  con `pkgver >=` y `pkgrel` creciente la devuelve al personal en el próximo `update`.
- En el pasado el `pkgrel` se pasaba a mano por input (y el run `33582420572` demostró que un
  error al dispatch podía publicar mal); hoy no se puede olvidar ni repetir el número por accidente.

## Fuentes

- `agents_fork.md` §5.3 (la regla) y W7 (aplicación).
- WORKLOG 7ª parte (republicación 4.0.2-100 → 4.0.2-101) y 8ª parte (generalización `personal: true`).