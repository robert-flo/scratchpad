# ADR-005 — La repo publica TODOS los PKGBUILD con `"personal": true`

- **Estado:** Aceptada
- **Fecha / hito:** 8ª parte (generalización, WORKLOG 8ª parte)

## Contexto

El repo personal empezó hardcodeando el par `omarchy`/`omarchy-settings`. El usuario quiere añadir
paquetes propios (webapps asociadas, utilidades, herramientas) al mismo flujo de `omarchy update`
sin tocar la Action cada vez.

## Decisión

- La Action recolecta **todos** los directo `pkgbuilds/*/` cuyo `.omarchy/package.json` tenga
  `"personal": true` y publica exactamente ese conjunto.
- El par (pinned/lockstep) sigue tratándose aparte con su regla §5.3 (ADR-004); un paquete genérico
  buildea tal cual su PKGBUILD.
- Para añadir un paquete personal futuro: commitear `pkgbuilds/<pkg>/PKGBUILD` +
  `.omarchy/package.json` (`source: local`, `release_ring: fast`, `"personal": true`), push a
  `personal`, y re-dispatch. La máquina que lo tenga instalado lo mantendrá por `omarchy update`.

## Consecuencias

- PoC `hola-mundo` fue el banco de pruebas (0.1.0-1 → 0.1.0-2 por bump de su pkgrel).
- `omarchy update` **actualiza** paquetes ya instalados pero **no instala** otros nuevos: un extra
  personal se instala una vez por máquina con `pacman -S <pkg>` (o se añade a
  `install/omarchy-base.packages` para onboarding masivo).

## Fuentes

- `agents_fork.md` W7 y ciclo de vida de un paquete personal (8ª parte).
- WORKLOG 8ª parte (dispatch sin `--ref` falló; con `--ref personal` OK).