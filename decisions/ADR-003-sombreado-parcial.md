# ADR-003 — Sombreado parcial: `[omarchy-personal]` antes de `[omarchy]`

- **Estado:** Aceptada
- **Fecha / hito:** Etapa 4 (WORKLOG 5ª parte)

## Contexto

Las personalizaciones del usuario viajan como paquetes propios. El mirror oficial
`pkgs.omarchy.org` sigue siendo la casa del ecosistema (centenares de paquetes); reconstruir todo
en el repo personal ("build all local") no tiene sentido y además los `pinned` no buildean a
`stable`.

La semántica de pacman: a igual nivel de versión, **gana la versión más alta; a versión igual, el
repo listado primero**.

## Decisión

- **Sombreado parcial**: en cada máquina, `[omarchy-personal]` listado ANTES de `[omarchy]` en
  `/etc/pacman.conf`.
- Nutriente: garantizarlo llevándolo DENTRO de la fuente del fork
  (`default/pacman/pacman-stable.conf`), no por edición per-máquina — así `omarchy refresh pacman`
  lo restaura en cualquier máquina.
- El mirrlo oficial sigue proveyendo el resto.

## Consecuencias

- El par y los extras personales se resuelven desde el repo personal cuando el repo personal tiene
  versión >= del oficial (regla §5.3, ADR-004).
- Si el par personal queda detrás del oficial, `omarchy update` instala el oficial y la
  personalización se pierde (hasta la próxima republicación). Ese es el riesgo que cubren el guard
  §5.3 y la vigilancia de cadencia (RUNBOOK F4).
- La sección no lleva `SigLevel` propio → hereda `Required DatabaseOptional` → **confiar la clave
  antes** de `omarchy refresh pacman` (W8 paso 1/`docs/02`).

## Fuentes

- `agents_fork.md` §0.2, §5.2, §5.3 y Etapa 4.
- WORKLOG 5ª parte (sombreado) y 6ª parte (end-to-end).
- `docs/01-conceptos.md` (explicación usuario-final).