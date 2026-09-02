# RUNBOOK.md — Guía de fallos y recuperación del repo personal

Para el mantenedor/agente (misma audiencia que `agents_fork.md`). Qué hacer **cuando algo
falla** en la publicación del repositorio personal de paquetes, en la cadencia o en una máquina.
Si no estás ante un fallo, esta guía también define la **operación preventiva** (re-publicación de
cadencia vía `release-personal.yml` y vigilancia automática de cadencia).

Referencias: `agents_fork.md` W7 (publicación) y W9 (cadencia), `docs/05-mantener.md` (versión
usuario-final del mantenedor), `WORKLOG.md` (bitácora de cada incidente real).

---

## 1. Cómo funciona la publicación (en 10 segundos)

- La Action `release-personal.yml` (en `robert-flo/omarchy-pkgs`) recolecta los PKGBUILD con
  `"personal": true`, pinea el par lockstep al tag base de `personal`, **deriva el `pkgrel` solo**
  (§5.3: mismo `pkgver` → última republicada +1; `pkgver` nuevo → 99), builda/signa/promueve/limpia
  y **commitea a `gh-pages`** de `omarchy-personal-repo`.
- Dispatch SIEMPRE con `--ref personal`; si llegara desde otra rama la Action **aborta sola** (guard
  fail-fast, no hay daño).
- `dry_run=true` = ensayo completo **sin publicar** (ni pin commitado en `personal` ni push a
  `gh-pages`). Úsalo antes de publicaciones delicadas.
- Concurrency: dos dispatches del grupo `release-personal` corren en cola (nunca intercalados).

## 2. Estrategia de rollback declarada (LÉEME ANTES DE ENTRAR EN PÁNICO)

**Regla general: roll-forward, no rollback.** El repositorio publicado vive en `clean-repo` poda:
solo queda la última versión de cada paquete. **No se puede "despublicar" a una versión anterior**;
si publicas algo mal, reparas publicando **otra versión por encima** (mismo `pkgver` + `pkgrel`
incrementado, o `pkgver` nuevo).

Casillas de recaídas puntuales (solamente si una MÁQUINA quedó rota y no puedes esperar al next
`pkgrel`):

| Situación | Herramienta | Cuándo |
|---|---|---|
| Reparar una máquina puntual con un artefacto bueno | `pacman -U` del `.zst` + `.sig` **del historial de `gh-pages`** | la máquina no converge tras el update |
| Volver a un paquete público anterior | buscar commit viejo en `git log gh-pages` → `git show <sha>:stable/x86_64/<pkg>-<ver>.pkg.tar.zst` | emergencia real, con cmd manual |

En ambos casos la siguiente publicación deja el repo en roll-forward otra vez.

## 3. Modos de fallo conocidos y su respuesta

### F1 — Dispatch sin `--ref` (o desde rama equivocada)
Incidente real: run `33582420572` republicó con la copia de `master`. **Hoy es inofensivo**: el
guard fail-fast aborta si `github.ref != refs/heads/personal`.
- Síntoma: run termina rojo en el primer paso con "FORK ABORT".
- Respuesta: re-disparar con `--ref personal`. Nada quedó publicado (el guard es anterior a todo paso que escriba).

### F2 — `pkgrel` equivocado (sub/sobre-contar republicaciones)
Incidente previo: el dueño dispatchaba `-f pkgrel=<n>` a mano y podía repetir el mismo número
(par quedaba en `4.0.2-101` en runs distintos). **Hoy es automático**: la Action lee el estado
previo commitado del PKGBUILD del par y aplica §5.3 (mismo `pkgver` → +1; `pkgver` nuevo → 99).
- Si aún así quieres forzar: `-f pkgrel=<n>` sigue existiendo como override (emergencias).
- Síntoma de error: par "no pesca" el cambio en alguna máquina (pkgrel igual = no rebuild).
- Respuesta: re-dispatch sin `-f pkgrel` (derivará +1) y `omarchy update` en la máquina.

### F3 — Publicación mala (artefacto/db/firma corruptos, o push a Pages falló)
- Síntoma: el paso "Validar publicación en GitHub Pages" falla, o `pacman -Sy` en una máquina da
  error de firma/datos.
- Respuesta:
  1. **Diagnóstico:** `git -C <clone-gh-pages> log --oneline -3` (¿fue el push?) y
     `curl -fsSI https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/<db|.pkg>`.
  2. **Ensayar antes de volver a publicar:** `-f dry_run=true` (buildea/signa/valida local, no
     toca nada remoto). Si el ensayo pasa, re-publica normal.
  3. Si la db quedó firmada con clave equivocada o el alias de sección falta → re-publicar
     (mismo `pkgver`, `pkgrel+1`); el alias `omarchy-personal.db`/`.files`(+`.sig`) se regenera en
     el paso de publish (Etapa 4).
  4. Aviso: las máquinas con la clave ya confiada solo fallan con "signature from unknown trust" si
     rotaste la clave — ver F6.

### F4 — Lag de cadencia (upstream publica y el fork no)
- Síntoma: `sync-check.yml` (cron diario) abre issue `[Cadencia] …`; o la db de una máquina muestra
  el par OFICIAL (pacman, a pkgrel igual/igual o mayor, gana el oficial → **desaparece la
  personalización**).
- Riesgo mecánico (B2): el guard §5.3 solo protege cuando DISPARAS la Action; no avisa por sí solo.
  La vigilancia es el cron + la rutina mensual de W9.
- Respuesta (roll-forward): ver RUNBOOK §4 — rebase + re-publicación con el nuevo `pkgver`.
- Mientras tanto, por máquina: NO hagas `omarchy update` con el repo oficial por encima si no puedes
  republicar en el día; si ya sucedió, republica y el próximo update regresa al par personal (la
  "recuperación automática" de §5.3).

### F5 — Fallos transitorios de red (TLS de `archlinux.org`, rate limit de gh)
Incidente real: TLS transitorio en runs de Etapa 4 (`33570727843`/`33570965650`), resuelto
re-disparando el workflow (el pin engine re-toma desde el estado commitado).
- Respuesta: si el run falló en la parte de descargas, **re-disparar tal cual** (idempotente: el
  pin ya estaría en `personal`). Si falló DESPUÉS de publicar, ver F3.

### F6 — Rotación / pérdida de la clave GPG o de la deploy key (S1)
Documentado en `decisions/ADR-006-claves.md` (rotación y DR). Resumen práctico:
- **Pérdida de `GPG_PRIVATE_KEY`:** generar clave nueva, publicar la `.asc` nueva en
  `keys/omarchy-personal-repo.pub.asc`, y en CADA máquina `pacman-key --add` + `--lsign-key` de la
  clave nueva ANTES de cualquier update (si no, el update fallará con Unknown trust y NO rompe: el
  paquete queda instalado como está, las futuras firmas no validan).
- **Pérdida de `SSH_DEPLOY_KEY`:** regenerar en `omarchy-personal-repo` (Settings → Deploy keys) y
  actualizar el secret en `omarchy-pkgs`.
- **Regla fija:** la clave PRIVADA solo vive como secret (`GPG_PRIVATE_KEY`, `SSH_DEPLOY_KEY`).
  Nunca commitearla (el repo es público). Cualquier sospecha de filtración = rotación inmediata
  (F6) + aviso en README del repo afectado.

### F7 — Rescate por máquina (bootstrapping manual después de incidencias)
Si una máquina quedó en el par oficial y quieres volver al personal SIN esperar el próximo update:
1. Descargar el `.pkg.tar.zst` (+ `.sig`) actual del par desde
   `https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/`.
2. `sudo pacman -U --noconfirm ./omarchy-<ver>-<arch>.pkg.tar.zst ./omarchy-settings-<ver>-<arch>.pkg.tar.zst`.
3. `sudo omarchy refresh pacman` (o verificar `pacman-conf` orden de secciones) y `omarchy update -y`.
Después, la máquina sigue en cadencia normal. (El flujo completo de onboarding es W8 /
`docs/02-instalar-una-maquina.md`; esta es la versión "reparar".

### F8 — Quirk de `sudo -v` en `omarchy update` viejos (no destructivo)
En la versión 4.0.2 / rama personal, `omarchy update` puede pedir `sudo -v` antes de empezar (falla
en sesiones sin TTY). Respuesta: ejecutar con TTY, o `sudo -v` previo, o `pkexec` para builds dev.
No es un fallo del repo: es del cliente `omarchy` en máquinas sin nota de credencial. Ver
`docs/03-uso-diario.md`.

## 4. Operación preventiva (mantener sano antes de que falle)

### 4.1 Re-publicación de cadencia
Manual: rebase de `personal` sobre `upstream/quattro` (W9) → push → re-dispatch de la Action con el
`pkgver` nuevo. Sin `-f pkgrel`: se deriva. Con dudas, primero `-f dry_run=true`.

```bash
# en ~/Work/omarchy/omarchy-installer (rama personal)
git fetch upstream && git rebase upstream/quattro
git push origin personal
# en ~/Work/omarchy/omarchy-pkgs
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v<tag-upstream>
# opcional: ensayo sin tocar nada
#   ... -f version=v<tag> -f dry_run=true
```

Checklist post-sync (cadencia), formalizado de WORKLOG 7ª parte:
1. [ ] Rebase lineal sin conflictos (`git rebase upstream/quattro`).
2. [ ] `git push origin personal`.
3. [ ] Dispatch con `--ref personal` y el `pkgver` nuevo.
4. [ ] Run verde y "Validar publicación" OK (Pages sirve el par nuevo + alias de sección + `.sig`).
5. [ ] En la máquina dev: `omarchy update -y`; `pacman -Q omarchy omarchy-settings` → versión personal.
6. [ ] `sync-check.yml` no abre nuevo issue `[Cadencia]` (o se cierra solo al día siguiente).

### 4.2 Vigilancia (qué mira por ti)
- `sync-check.yml` (cron diario 06:30 UTC): compara tag upstream vs pin; abre/cierra issue
  `[Cadencia]`. Está registrado en `personal` (fuente) y `master` (para que GitHub lo programe).
- El paso "Guard §5.3" de la Action: aborta si el par quedara por detrás del estable oficial.
- El paso "Validar publicación en GitHub Pages" tras cada push: margen 60×20 s.

### 4.3 Fuente única de estado
`README.md` → tabla "Estado" (par y paquetes publicados). No inventar versiones: leerla de ahí.

## 5. Enlaces útiles para un incidente

| Recurso | Uso |
|---|---|
| `agents_fork.md` §5.3 | la regla del sombreado (por qué existe el pkgrel alto) |
| `agents_fork.md` W7 | mecánica completa de la publicación |
| `agents_fork.md` W9 | rebase/re-publicación |
| `docs/05-mantener.md` | versión usuario-final del mantenedor (publicar, seguir upstream) |
| `WORKLOG.md` 7ª parte | bitácora de la cadencia manual 4.0.2-100 → 4.0.2-101 |
| `decisions/` | ADRs (hosting, sombreado, pkgrel §5.3, claves, entorno de build) |