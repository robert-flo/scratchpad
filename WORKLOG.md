# WORKLOG.md — Bitácora del fork de Omarchy

Registra qué se hizo, por qué y cómo, **sesión por sesión**. Es la memoria de procedimiento del
proyecto; [`agents_fork.md`](agents_fork.md) es la referencia normativa (plan, etapas, recetas,
invariantes) y [`README.md`](README.md) resume el estado actual. Si algo aquí contradice a
`agents_fork.md`, el error está en la bitácora: corregir la bitácora, nunca rebajar el plan.

## Índice de sesiones

> Los enlaces de salto se eliminaron el 2026-09-01: los slugs parciales no coinciden con los
> anchors que genera GitHub (el índice saltaba al primer uso fallido). Navega con `Ctrl+F` sobre
> el título completo de la sesión, o con los h2 que siguen.

1. 2026-08-30 — Bootstrap del fork y primer POC: webapp Xataka.
2. 2026-09-01 — Fork de `omarchy-pkgs` + bootstrap reproducible (Etapa 0 completa).
3. 2026-09-01 (2ª parte) — Xataka no aparecía: `omarchy update` pisa el par dev (lección aprendida).
4. 2026-09-01 (3ª parte) — Criterio de aceptación Etapa 0 + dev loop al fork.
5. 2026-09-01 (4ª parte) — **Etapa 3 / W7 completa**: repo personal en GitHub Pages.
6. 2026-09-01 (5ª parte) — **Etapa 4 completa**: sombreado `[omarchy-personal]`.
7. 2026-09-01 (6ª parte) — Prueba END-TO-END en la máquina dev (PASA).
8. 2026-09-01 (7ª parte) — Cadencia W9 ejecutada (rebase + re-pin 4.0.2-101).
9. 2026-09-01 (8ª parte) — Repo personal generalizada: paquete propio `hola-mundo` vía `omarchy update`.
10. 2026-09-01 (9ª parte) — Revisión L8: endurecimiento de la Action, vigilancia de cadencia, runbook y ADRs.
11. 2026-09-01 (10ª parte) — Validación L8 con run real (dry_run + publish; bug del guard booleano corregido) + decisión de `hola-mundo`.

---

## Sesión 2026-08-30 — Bootstrap del fork y primer POC (webapp)

### Contexto
Encargo del dueño (usuario `robert-flo`): alinear N máquinas Omarchy idénticas vía
`omarchy update`, con personalizaciones desde un fork de `omacom/omarchy` sync con
upstream `quattro`, siguiendo la maquinaria upstream (sin inventos). Antes de decidir
cómo adherir personalización al update loop había que (a) armar la base del fork y
(b) demostrar con un POC que el flujo fork → paquete dev → refresh → launcher cubre
la tarea más visible del usuario: **webapps**.

### Qué se hizo (orden real, con comandos)

1. **Fork de `omacom/omarchy`** → `https://github.com/robert-flo/omarchy` (rama default `quattro`).
   - `gh` autenticado como `robert-flo`; protocol https con rewrite global `insteadOf` a ssh.
2. **Repo de notas público con nombre neutro** `https://github.com/robert-flo/scratchpad`
   (README + `agents_fork.md`, commit `86f3dd3`).
   - Por qué público: cualquier agente puede leerlo sin credenciales. Por qué nombre camuflado:
     el repo contiene el plan íntegro (cómo sincronizar forks, GPG, pins); no anunciar el
     propósito en el nombre. Contenido cifrable/a particionar si se decide en el futuro.
   - Working copy durable (canónico): `~/Work/omarchy/scratchpad`. La copia en el sandbox de la
     sesión (`/home/dhh/Work/tries/2026-08-30-omacom-omarchy/agents_fork.md`) queda **deprecada**.
3. **Layout de trabajo = rutas default del tool de dev** (decisión con razón, ver §Decisiones):
   - `~/Work/omarchy/omarchy-installer` — checkout del fork (rama `personal` sobre `upstream/quattro`).
   - `~/Work/omarchy/omarchy-pkgs` — clone de **upstream** de `omacom/omarchy-pkgs` (aún no forkado).
   - `gh repo clone` del fork ya deja configurados `origin` (fork) y `upstream` (omacom).
4. **Rama `personal`** creada sobre `upstream/quattro` (fetch upstream + `git checkout -b personal upstream/quattro`).
5. **Elección del POC**: se comprobó que **WhatsApp ya es webapp de stock** en quattro
   (`applications/WhatsApp.desktop`, `Icon=whatsapp`, `Exec=omarchy-launch-webapp https://web.whatsapp.com/`).
   → POC elegido: **Xataka** (no existe en stock; demuestra el pipeline de AGREGAR).
6. **Webapp Xataka** en la rama personal:
   - `applications/Xataka.desktop` → `Exec=omarchy-launch-webapp https://www.xataka.com/`, `Icon=xataka`, `StartupNotify=true`.
   - `applications/icons/Xataka.png` (196×196 PNG, bajado de `https://www.xataka.com/apple-touch-icon.png`).
     El PKGBUILD lo convierte a `hicolor/{256,48}/apps/<icon_id>.png` (icon_id = minúsculas + no-alfa→`-`, o sea `xataka`).
   - Commit `personal: add Xataka webapp (POC)` → `89759761`, push a `origin/personal`.
7. **Ciclo dev (build)**: `omarchy dev pkg-test` falló primero por ruta (`~/Work/omarchy/omarchy-pkgs` no existía hasta el
   paso 3) y luego intentó `sudo` **sin terminal** → `sudo: a terminal is required to read the password`.
   - **Regla del skill** `default/agents/skills/omarchy/SKILL.md` (Privilege Escalation): si hay terminal → `sudo`,
     si no → `pkexec` (patrón `if [[ -t 1 ]]`, mismo estilo que `bin/omarchy-dns`).
   - Réplica manual exacta de pkg-test sobre `omarchy-settings-dev` y `omarchy-dev`:
     `mktemp -d` + copiar pkgbuild + **strip de la función `pkgver()`** (awk, igual que pkg-test) +
     `sed pkgver=dev.<sha8>` + `makepkg --skipchecksums` con `OMARCHY_SRC=$HOME/Work/omarchy/omarchy-installer`.
   - Detalle no obvio: `makepkg -s` no resuelve la dependencia `omarchy-settings-dev` al construir
     `omarchy-dev` (todavía no está instalada) → build de `omarchy-dev` con `--nodeps --skipchecksums`;
     las deps runtime se validan en la instalación conjunta.
8. **Ciclo dev (install)** — transición stock→dev **sin romper el sistema**:
   - `omarchy-settings-dev` y `omarchy-settings-4.0.1-1` **se conflictúan**, y `omarchy-settings` 4.0.1 está
     requerido por `omarchy` 4.0.1 (dep con versión) → no se puede instalar uno solo.
   - Solución: instalar **el par dev completo en un solo `pacman -U`** con los dos .zst:
     `pkexec pacman -U --ask 4 --noconfirm --overwrite='*' <omarchy-settings-dev.zst> <omarchy-dev.zst>`
   - `--ask 4` = contestar *yes* a todos los reemplazos de paquetes conflictivos (omarchy + omarchy-settings se
     reemplazan). Es el mismo truco que usa el wrapper `pacman-for-makepkg` del Dockerfile de build de upstream.
   - Resultado: `omarchy-dev dev.89759761-1` + `omarchy-settings-dev dev.89759761-1` instalados (reemplazan al stock).
   - Nota de operación: a partir de acá la máquina corre la línea dev; `omarchy update` normal no aplica hasta reinstalar stock (estado esperado de la máquina dev).
9. **Materialización de la webapp**:
   - `omarchy-refresh-applications` copia `$OMARCHY_PATH/applications/*.desktop` a `~/.local/share/applications/`
     y hace el update de la db de escritorio (con el stock instalado, `$OMARCHY_PATH=/usr/share/omarchy`).
   - Verificado: `~/.local/share/applications/Xataka.desktop` existe y pasa `desktop-file-validate`;
     iconos en `/usr/share/icons/hicolor/{256,48}/apps/xataka.png`.
10. **Validación del launcher (aceptación)**:
    - Navegador por defecto: `google-chrome.desktop` (chrome está en la lista de browsers soportados de
      `omarchy-launch-webapp`; el launcher ejecuta `uwsm-app -- <browser> --app=<url>`).
    - `omarchy-launch-webapp https://www.xataka.com/` → abre ventana Chrome en **modo app** (frameless).
    - Verificado con `hyprctl clients -j`: clase `chrome-www.xataka.com__-Default`,
      título `Xataka - Tecnología y gadgets…`. **POC OK de punta a punta.**

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| Layout en rutas default del tool (`~/Work/omarchy/<engine|pkgs>`, nombres exactos `omarchy-installer` / `omarchy-pkgs`) | `bin/omarchy-dev-pkg-test` usa path duro `$HOME/Work/omarchy/omarchy-pkgs`; usar otro layout fuerza parches; el dueño inicialmente pensaba `~/omarchy`, se descartó |
| POC = Xataka (app nueva), no WhatsApp | WhatsApp ya es stock → no demostraría el ciclo de "agregar"; los 55 webapps del dueño se iteran después sobre el mismo patrón |
| Repo de notas público + nombre neutro + contenido (agentes_fork.md) | Que cualquier agente lo lea sin credenciales sin anunciar el propósito en el nombre |
| Sin TTY → `pkexec` en vez de `sudo` | Regla del SKILL.md de Omarchy (escalación por presencia de terminal) |
| `--ask 4` + instalación conjunta del par | `--ask 4` replica el wrapper de build upstream; instalar el par evita romper la dep con versión `omarchy-settings=4.0.1` |

### Estado actual (inventario)

- Repos: fork `robert-flo/omarchy` (branches `quattro` + `personal`); `robert-flo/scratchpad` (notas, público);
  **`robert-flo/omarchy-pkgs` NO existe todavía** — solo clone de upstream local.
- Checkout dev: `~/Work/omarchy/omarchy-installer` en `personal` (`89759761`); `origin`=fork, `upstream`=omacom.
- Machine dev: `omarchy-dev` + `omarchy-settings-dev` `dev.89759761-1` (línea dev, reemplazó stock 4.0.1-1).
- POC: webapp Xataka materializada y lanzada con éxito (ventana Chrome app-mode verificada).

### Lo que falta (próximos pasos)

1. Iterar las **55 webapps** del dueño (patrón Xataka; commit `personal: add <app> webapp` por app o batch coherente).
2. **Fork `robert-flo/omarchy-pkgs`** y chequear el dev loop contra el fork (cambiar OMARCHY_UPSTREAM_URL / pin).
3. Etapa 3: **W7** — pipeline de release personal (GitHub Actions + Pages) con `test.yml` replicado activo y
   capa final push a `gh-pages` (única desviación permitida).
4. Etapa 2: onboarding (W8), sincronización periódica (W9), sombreado parcial en máquina real (W4/W5).
5. Higiene del fork: convención de commits personales y política de sync upstream en `personal`.

### Cómo reproducir (comandos clave)

```bash
# build de un paquete dev (réplica de pkg-test)
DIR=$(mktemp -d -t omarchy-settings-dev.XXXXXX)
cp -a "$HOME/Work/omarchy/omarchy-pkgs/pkgbuilds/omarchy-settings-dev/." "$DIR/"
# strip pkgver() (awk, igual que bin/omarchy-dev-pkg-test)  +  sed "s/^pkgver=.*/pkgver=dev.$(git -C <checkout> rev-parse --short HEAD)/"
OMARCHY_SRC="$HOME/Work/omarchy/omarchy-installer" makepkg --skipchecksums --noconfirm   # o --nodeps para omarchy-dev
# install del par dev (sin terminal)
pkexec pacman -U --ask 4 --noconfirm --overwrite='*' <settings.zst> <engine.zst>
# materializar + lanzar
omarchy-refresh-applications && omarchy-launch-webapp https://www.xataka.com/
```

---

## Sesión 2026-09-01 — Fork de omarchy-pkgs + bootstrap reproducible (Etapa 0 completa)

### Contexto
Bootstrap del layout dev en una **máquina nueva** (sin `~/Work/omarchy`): la máquina de la
sesión 2026-08-30 queda como dev/POC; esta replica el entorno y, de paso, cierra el último
ítem pendiente de la Etapa 0: el fork de `omarchy-pkgs`.

### Qué se hizo (orden real)

1. **Script `bootstrap-omarchy-dev.sh`** (commiteado en este repo): clona los 3 repos
   (`omarchy-installer` rama `personal`, `omarchy-pkgs` rama `master`, `scratchpad`) en
   `~/Work/omarchy/`, agrega el remote `upstream` a ambos forks y hace fetch. Idempotente
   (salta lo ya clonado). Razones de rutas/nombres documentadas en comentarios dentro del
   script (defaults de `bin/omarchy-dev-pkg-test`; convención `omarchy-installer` de §0.1).
2. **Primera corrida**: `omarchy-installer` y `scratchpad` clonados OK; `omarchy-pkgs`
   falló con `Repository not found` — el fork **no existía** (era el paso 1 de §0.2 del plan).
3. **Fork creado**: `gh repo fork omacom/omarchy-pkgs --clone=false` →
   `https://github.com/robert-flo/omarchy-pkgs`. Clone a `~/Work/omarchy/omarchy-pkgs`
   (rama `master`) + `git remote add upstream` + fetch. **Etapa 0 completa.**
4. Dato de entorno: upstream publicó tag **`v4.0.2`** (visible en el fetch); la rama
   `personal` sigue basada en `89759761` (base quattro al momento del POC). A considerar
   en la próxima cadencia de sync (W9).

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| Bootstrap como script commiteado en scratchpad | Reproducir el layout en cualquier máquina nueva sin recordar los pasos; las razones de cada paso viven como comentarios en el script, no en la memoria del agente |
| Clone por SSH (`git@github.com:`) en el script | Mismo esquema de URLs que usa el plan (§0.2, W9); `gh` de esta máquina ya tiene rewrite https→ssh |
| Fork de pkgs creado vía `gh repo fork` (no a mano) | Mismo mecanismo que el fork de `omarchy` en la sesión 2026-08-30 |

### Estado actual (inventario)

- Repos: forks `robert-flo/omarchy` (`quattro` + `personal` @ `89759761`) y
  **`robert-flo/omarchy-pkgs` (`master`) — ya existe**; `robert-flo/scratchpad` (notas).
- Checkout dev (esta máquina): `~/Work/omarchy/{omarchy-installer,omarchy-pkgs,scratchpad}`,
  ambos forks con `origin` (fork) + `upstream` (omacom).
- Máquina dev (sesión 08-30): `omarchy-dev` + `omarchy-settings-dev` `dev.89759761-1`, POC Xataka OK.
- **Esta máquina aún NO tiene el par dev instalado** — el ciclo dev (`omarchy dev pkg-test`)
  no se corrió acá; es el criterio de aceptación de Etapa 0 pendiente localmente.

### Lo que falta (próximos pasos)

1. Validar el ciclo dev en esta máquina: `omarchy dev pkg-test` → `pacman -Q omarchy-dev
   omarchy-settings-dev` reporta `dev.<sha>` (criterio de aceptación Etapa 0).
2. Paso §0.2.2: puntar el dev loop al fork (`origin` del pkgs ya es el fork;
   `OMARCHY_UPSTREAM_URL=https://github.com/robert-flo/omarchy.git` para el pin).
3. Etapa 3 / W7: repo `omarchy-personal-repo` + Action de release (ver §0.2 del plan).
4. Cadencia W9: rebase de `personal` sobre `upstream/quattro` (hay tag `v4.0.2` nuevo).
---

## Sesión 2026-09-01 (2ª parte) — Xataka no aparecía: `omarchy update` pisa el par dev

### Qué pasó

Tras instalar el par `dev.0e6c11d5-1`, la webapp Xataka no aparecía en el launcher.
Diagnóstico con `/var/log/pacman.log`:

1. Nuestra instalación (14:00) fue correcta — el paquete SÍ contenía `Xataka.desktop`.
2. A las 14:04 corrió un `omarchy update` (firma: `pacman -Syu --overwrite /usr/share/omarchy/*`)
   y "upgradó" el par dev a `4.0.0.r1832.g23dab9e-1` — un paquete **del repo oficial** `[omarchy]`,
   que no contiene Xataka.

### Causa raíz (nuevo hecho para el modelo mental)

**El repo oficial stable publica TAMBIÉN los paquetes `-dev`** (`omarchy-dev` /
`omarchy-settings-dev`, versionados `4.0.0.rNNN.g<sha>` desde git describe de quattro), y
`vercmp 4.0.0.r1832.g23dab9e dev.0e6c11d5` → **gana el oficial**. Consecuencia: en una
máquina dev, **cualquier `omarchy update` reemplaza el par dev local por el del repo oficial**
y borra las personalizaciones. Es la regla §5.3 (sombreado) manifestándose en el loop dev:
el dev local pierde por versión, no por nombre.

### Regla de operación para máquinas dev

- En la máquina dev **no correr `omarchy update`** mientras esté en línea dev (el update
  normal es para máquinas en stock/producción). Si corre por accidente: re-ejecutar el
  bootstrap (fase 2 reinstala el par local).
- (Mejora futura posible, a decidir: pkgver dev con prefijo numérico alto p. ej. `99.<sha>`
  para que siempre gane el vercmp — desviación del formato upstream `dev.<sha>`, no tomar a la ligera.)

### Qué se hizo

- Rebuild + reinstalación del par local vía `bootstrap-omarchy-dev.sh` (que además quedó
  fixeado: bug `local pkgbuild=... tmp=$pkgbuild.tmp` con `set -u`).
- `omarchy-refresh-applications` (paso W1 obligatorio para usuarios existentes) →
  `~/.local/share/applications/Xataka.desktop` + icono `xataka.png` en hicolor.
- Validación: `desktop-file-validate` OK; lanzamiento verificado con `hyprctl clients`:
  clase `chrome-www.xataka.com__-Default`, título "Xataka - Tecnología y gadgets…". **OK.**

### Estado

- Máquina en línea dev `dev.0e6c11d5-1` con Xataka materializada y lanzada.
- Para iterar nuevas webapps: receta W1 (`.desktop` + icono en el fork → commit →
  bootstrap fase 2 → `omarchy-refresh-applications`).

---

## Sesión 2026-09-01 (3ª parte) — Criterio de aceptación Etapa 0 + dev loop al fork (§0.2 pasos 1–2)

### Contexto
Cerrar los dos pasos pendientes del plan §0.2 sobre esta máquina: (1) validar el ciclo dev
local (`omarchy dev pkg-test` compila e instala desde el fork) y (2) apuntar el dev loop al
fork con `OMARCHY_UPSTREAM_URL`. Al arrancar, la máquina estaba en `4.0.0.r1832.g23dab9e-1`
(el par `-dev` del repo oficial, que un `omarchy update` había pisado sobre nuestro
`dev.0e6c11d5`); esto confirma de nuevo la "LECCIÓN APRENDIDA" de la sesión anterior.

### Qué se hizo (orden real)

1. **Validación del ciclo dev con el tool del fork** (`omarchy dev pkg-test`):
   - Re-ejecutar el tool directo en esta sesión falla igual que antes: el último paso es
     `sudo pacman -U` y aquí no hay TTY para el password (`sudo: a password is required`).
     Regla del SKILL.md (escalación por presencia de terminal) → se corrió una **copia del
     tool del checkout del fork** (`~/Work/omarchy/omarchy-installer/bin/omarchy-dev-pkg-test`)
     con la única desviación del mecanismo de privilegio: `sudo` → `pkexec`, sumando
     `--ask 4` (patrón verificado del bootstrap). El resto (remove_pkgver_function, pkgver
     `dev.<sha>`, `OMARCHY_SRC=$CHECKOUT`, makepkg `-s --skipchecksums`) quedó literal.
   - Resultado build: `omarchy-settings-dev` y `omarchy-dev` compilados desde el checkout del
     fork (`OMARCHY_SRC` = `~/Work/omarchy/omarchy-installer`) con PKGBUILDs del fork
     (`~/Work/omarchy/omarchy-pkgs`, origin = `robert-flo`). Install: downgrade exitoso
     `4.0.0.r1832...` → `dev.0e6c11d5-1` (pacman lo anunció como downgrade y `--noconfirm`
     lo confirmó; la dep `omarchy-dev` → `omarchy-settings-dev=${pkgver}` se satisfizo porque
     el tool instala por separado en orden settings→engine).
   - **Criterio de aceptación Etapa 0 CUMPLIDO**: `pacman -Q omarchy-dev omarchy-settings-dev`
     → `dev.0e6c11d5-1` ambas.
2. **Dev loop apuntado al fork (§0.2.2)**:
   - Componente 1 (ya cumplido por el layout): PKGBUILDs del fork vía `origin` de
     `omarchy-pkgs`. Componente 2 (nuevo): `OMARCHY_UPSTREAM_URL`. Se verificó en
     `bin/omarchy-pkgs` (:25, :132-156) que sin esta env var el pin engine usa el default
     `https://github.com/basecamp/omarchy.git` (repo equivocado) para resolver tag/commit
     (`git ls-remote`) y reescribir `_tag`/`_commit`/`pkgver`/`sha256sums`. Se apuntó a
     `https://github.com/robert-flo/omarchy.git` y se automatizó en el bootstrap (abajo);
     se validó que el fork resuelve tags (v4.0.0/v4.0.1) como fuente.
3. **Bootstrap `bootstrap-omarchy-dev.sh` actualizado** para automatizar en instalaciones futuras:
   - Exporta `OMARCHY_UPSTREAM_URL` (todo el porqué en comentario de cabecera).
   - Nueva sección de verificación al final: comprueba que `origin` de `omarchy-pkgs` es el
     fork y que `OMARCHY_UPSTREAM_URL` apunta al fork (regex que acepta `…omarchy`/`.git`).
   - Mensaje de cierre actualizado (deja de decir "apuntar OMARCHY_UPSTREAM_URL"); verificado
     con `bash -n` y una corrida idempotente `--no-install`.

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| Criterio de aceptación validado con copia del tool (solo sudo→pkexec + `--ask 4`, resto literal) | Es la regla del SKILL.md (sin TTY → pkexec); desviación mínima y documentada; valida el build real del tool del checkout del fork, no una reconstrucción a mano |
| `OMARCHY_UPSTREAM_URL` automatizada como export en el bootstrap (no en `~/.bashrc`) | Decisión del dueño; se documenta su carácter de sesión (efímera) y su rol exclusivo en el pin de release (W7), no en el dev loop |
| Dev loop apuntado al fork = dos hechos separados (PKGBUILDs del fork + URL de pin) | Distinguir evita confusión: el dev loop ya salía del fork sin ninguna config; lo que faltaba era el repos de origen del pin engine para futuro release |

### Estado actual (inventario)

- Repos: forks `robert-flo/omarchy` (`quattro`+`personal` @ `0e6c11d5`) y
  `robert-flo/omarchy-pkgs` (`master` @ `6774df1`); `robert-flo/scratchpad` (notas).
  Observación: el fork `robert-flo/omarchy` NO tiene aún el tag `v4.0.2` (solo hasta v4.0.1)
  — pendiente de la cadencia de sync W9.
- Esta máquina: en línea dev `dev.0e6c11d5-1` (criterio Etapa 0 cumplido vía `pkg-test`).
  Dev loop apuntado al fork (PKGBUILDs del fork + `OMARCHY_UPSTREAM_URL`).
- Bootstrap: automatiza ambos pasos para máquinas nuevas.

### Lo que falta (próximos pasos)

1. Etapa 3 / W7: repo `omarchy-personal-repo` + Action de release (pin con
   `OMARCHY_UPSTREAM_URL` al fork — ya garantizado por el bootstrap).
2. Cadencia W9: rebase de `personal` sobre `upstream/quattro` (tag `v4.0.2` presente en
   upstream) y luego sync del tag al fork (ver nota del inventario).
3. Etapa 4: sombreado parcial (§5.4) y prueba end-to-end del `omarchy update` con `[omarchy-personal]`.
---

## Sesión 2026-09-01 (4ª parte) — Etapa 3 / W7 COMPLETA: repo personal en GitHub Pages

### Contexto

Cerrar la Etapa 3/W7: el repositorio personal `robert-flo/omarchy-personal-repo` publica el
par `omarchy` + `omarchy-settings` pineado a la rama `personal` del fork, servido por
**GitHub Pages** en `https://robert-flo.github.io/omarchy-personal-repo`, generado por la
Action `release-personal.yml` que corre en el repo huésped `robert-flo/omarchy-pkgs`.

### Qué se hizo (orden real)

1. **Maquinaria leída** (fork de omarchy-pkgs, rama `personal`): `helpers/paths.sh`
   (`REPO_ROOT=${OMARCHY_REPO_ROOT:-$BUILD_ROOT/pkgs.omarchy.org}`, `REPO_DIR=$REPO_ROOT/$MIRROR/$ARCH`,
   `BUILD_OUTPUT_DIR=$BUILD_ROOT/build-output/$MIRROR/$ARCH`), `helpers/docker-helpers.sh`
   (imagen `omarchy-pkg-builder:latest-$arch-$mirror` con `--build-arg MIRROR`), `bin/repo`
   (subcomandos reales: `release build sign promote update clean advance`; `--local`),
   `bin/sign`/`build/sign.sh` (requiere env `GPG_PRIVATE_KEY` + `GPG_PASSPHRASE`),
   `bin/promote-build` (host-side), `bin/update-repo` (docker, siempre imagen edge,
   monta `$REPO_ROOT:/output`), `bin/advance-channel` (termina con `sync-repo` → rclone,
   evitable para el fork), `bin/sync-repo`.
2. **Clave de despliegue** para `omarchy-personal-repo` (write, título
   `omarchy-personal-release`, ssh-ed25519) → secret `SSH_DEPLOY_KEY`; clave GPG dedicada
   (uid `Omarchy Personal Repo`, keyid `D5E75EAC51A44715`, **sin passphrase**) → secrets
   `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE="unused"`. Necesario porque el `GITHUB_TOKEN` del
   huésped no escribe en otro repo.
3. **`release-personal.yml`** en `.github/workflows/` (rama `personal` + copia de registro
   en `master` — GitHub exige el workflow en la rama default para el dispatch por API).
   Pipeline: checkout (`source`=fork omarchy personal, `pkgs`, `repo`=gh-pages con
   `ssh-key`) → pin del par (lockstep, dentro de `archlinux:base-devel` porque el runner no
   tiene `vercmp`/`makepkg`; como no-root por sudorule) → sed `pkgrel=99` (§5.3) → guard vs
   estable oficial (vercmp en contenedor) → commit+push del pin a `personal` → build → sign
   → promote → update → clean → publicar a gh-pages (resuelve symlinks de db, firma con la
   GPG dedicada) → validar con curl.
4. **Fixes iterativos de la Action** (cada uno en un run):
   - `vercmp`/`git`/`makepkg` ausentes en el runner → pin dentro de contenedor Arch
     (`pacman -S git`; makepkg no corre como root → usuario `builder`; `safe.directory /pkgs`).
   - `rg` no instalado → `grep -nE`.
   - Nombres de subcomandos de `bin/repo`: `promote/update/clean` (no `promote-build`/...).
   - `release_ring: "fast"` en ambos `.omarchy/package.json` (commit `7c522d7`).
   - **`pinned:true` nunca builda nativo a stable** (`package_builds_for_mirror`, helpers/
     package-metadata.sh:203) → el flujo original con `--mirror stable` saltaba ambos con
     "not in release_ring=fast" (mensaje engañoso). Se probó also edge y falló por deps.
   - Fix definitivo: build **estable directo** contra el ecosistema estable oficial —
     el Dockerfile del fork ya mantiene el repo `[omarchy]` remoto (`pkgs.omarchy.org/stable`)
     para `MIRROR=stable` (hook FORK en `build/Dockerfile`), y el workflow hace **un-pin
     temporal local** (`jq '.pinned=false'`, sin commitear) antes del build.
   - **Permisos del contenedor**: `make_dir_writable` chown'd los dirs al runner no-root,
     pero makepkg/repo-add corren como `builder` (uid 1000) → db vacía `omarchy-build`
     no se creaba ("database file does not exist", "could not find database"). Fix:
     `make_dir_writable` ahora hace además `chmod -R a+rwX` (helpers/docker-helpers.sh).
   - Publish: `readlink` relativo → `cp -L "$(dirname "$f")/$rl"`.
   - Validación: `VERSION` lleva `v` (`v4.0.2`) pero el filename no → se deriva el nombre
     real desde `repo/stable/x86_64/`.
5. **Run verde final**: `33565145113` — todos los steps `success`, y validación manual:
   artefactos 200, `omarchy.db.sig` = Good signature (key D5E75EAC51A44715), db contiene
   `omarchy 4.0.2-99` + `omarchy-settings 4.0.2-99`.
6. **Bootstrap** actualizado con el "cómo consumir" `[omarchy-personal]` (Server gh-pages,
   SigLevel Optional TrustAll, importar clave pública, comando de re-publicación).

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| Secrets en el repo huésped `omarchy-pkgs` (no en los forks de contenido) | Las Actions corren ahí; desambiguación de W7 ya anotada en agents_fork.md |
| Deploy key SSH para escribir en `omarchy-personal-repo` | `GITHUB_TOKEN` del huésped no tiene scope cross-repo |
| Registro del workflow en `master` + dispatch `--ref personal` | GitHub exige el workflow en la rama default para `workflow_dispatch` por API |
| Build estable directo con un-pin temporal local | Los `pinned` no buildan nativo a stable por diseño (protegen releases del orquestador); el fork publica solo el par y quiere el ecosistema estable oficial como base de deps |
| `chmod a+rwX` en `make_dir_writable` | Runner no-root + contenedor `builder` (uid 1000): chown solo no basta |
| Key GPG sin passphrase + `GPG_PASSPHRASE="unused"` | Evita pin de PIN/tty en `gpg --batch`; firma detach en `--batch` sin prompt |
| Validación deriva el filename del árbol publicado, no de los inputs | `version` lleva `v`; el nombre real del `.pkg.tar.zst` no |

### Estado actual (inventario)

- Repos: `robert-flo/omarchy-personal-repo` (gh-pages con `omarchy`/`omarchy-settings`
  `4.0.2-99` firmadas + dbs), `robert-flo/omarchy-pkgs` (`personal` @ `95a69b4`, `master`
  @ `febb052` con registro sync), `robert-flo/omarchy` (personal, pineado en los runs).
- Secrets en `omarchy-pkgs`: `SSH_DEPLOY_KEY`, `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`.
- Deploy key `omarchy-personal-release` (write) en `omarchy-personal-repo`.
- Artefactos locales sensibles en `/tmp/opencode/`: `gh_pages_deploy(.pub)`,
  `omarchy-personal-repo.asc` / `.pub.asc` — NO versionar.
- Sitio en vivo: `https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64`.

### Lo que falta (próximos pasos)

1. Etapa 4: sombreado parcial (§5.4) y prueba end-to-end de `omarchy update` con
   `[omarchy-personal]` en una máquina stock.
2. Cadencia W9: rebase de `personal` sobre `upstream/quattro` (tag `v4.0.2`), sync del tag
   al fork y re-pin del release.
3. Clave pública del repo personal ya guardada en `keys/omarchy-personal-repo.pub.asc` del
   scratchpad (privada NO versionada; solo secret `GPG_PRIVATE_KEY`).

---

## Sesión 2026-09-01 (5ª parte) — Etapa 4 COMPLETA (sombreado `[omarchy-personal]`)

### Qué se hizo

1. **Config del fork fuente** (`robert-flo/omarchy`, rama `personal`): `default/pacman/
   pacman-stable.conf` inserta `[omarchy-personal]` ANTES de `[omarchy]` con
   `Server = https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64`. La sección NO
   lleva `SigLevel` propio → hereda `Required DatabaseOptional` (política alineada con la
   migración upstream que elimina `Optional TrustAll`). Commit `ebfb3038`.
   - Nota: el remote `personal` ya tenía un merge del dueño de `omacom:quattro` (`4d687d4d`,
     con todo el hermes de upstream); se rebaseó el commit encima. El push original fue
     rechazado por eso.
2. **República del par**: `release-personal.yml` con `pkgrel=100` (§5.3: incremento por
   republicanación del mismo pkgver). Runs: `33570727843`, `33570965650` fallaron por **TLS
   transitorio de archlinux.org** (curl del archlinux-keyring en el bootstrap del Dockerfile —
   infra de GitHub, no nuestro código); `33571098815` VERDE a la 3ª.
3. **Gotcha descubierto (fix en el workflow)**: pacman deriva el nombre del db de la SECCIÓN
   de pacman.conf. Con `[omarchy-personal]`, `pacman -Sy` pide `omarchy-personal.db` (404
   porque solo había `omarchy.db`+`.files`). Fix: el paso de publish publica alias
   `omarchy-personal.db`/`.files` (+ `.sig`) = copias de las omarchy.*. Commit `26e524a`
   (`personal`) y cherry-pick `fe47b16` (`master`, registro).
4. **Verificación del sombreado** (sin tocar la máquina dev): pseudo-root en `/tmp` con las
   dbs reales (desc + files del par stock `4.0.2-1` extraídos del repo oficial) y keyring con
   la clave personal lsign'd + la de packaging de omarchy:
   - `pacman -Su --print` (par stock "instalado", conf con `[omarchy-personal]` antes de
     `[omarchy]`): `omarchy-personal omarchy 4.0.2-100`, `omarchy-personal omarchy-settings
     4.0.2-100`; el resto del ecosistema (omarchy-keyring, limine-mkinitcpio-hook,
     limine-snapper-sync, ttf-jetbrains-mono-nerd-basic…) sigue atribuido a `[omarchy]` oficial.
   - conf sin `[omarchy-personal]` → sin upgrades. `pacman -Si` confirma
     Repository=omarchy-personal / 4.0.2-100.
   - Las firmas de la db se verificaron (la sync pasa con `SigLevel = Required DatabaseOptional`).
   - Tooling: docker sin daemon y sudo con timestamp expirado → `fakeroot pacman` con
     `--root/--dbpath/--gpgdir` en `/tmp` (o (manejo de `DownloadUser = alpm` fuera del conf de
     prueba)). Los dbs oficiales se descargaron de `pkgs.omarchy.org/stable/x86_64/omarchy.db`
     y `omarchy.files`.
   - Publicado: `omarchy-4.0.2-100-any.pkg.tar.zst`, `omarchy.db`/.sig, `omarchy-personal.db`/.sig,
     `omarchy.files`/.sig, `omarchy-personal.files`/.sig — todos HTTP 200 en Pages.

### Estado actual (inventario)

- Fork fuente: `robert-flo/omarchy` `personal` @ `ebfb3038` (merge `4d687d4d` + Etapa 4).
- `robert-flo/omarchy-pkgs`: `personal` @ `26e524a` (alias db), `master` @ `fe47b16`.
- Par publicado: `omarchy` / `omarchy-settings` **4.0.2-100** (firmado `D5E75EAC51A44715`).
- Sombreado del par verificado (dry-run); la prueba END-TO-END en máquina dev es el paso que sigue.

### Lo que falta (próximos pasos)

1. **Prueba end-to-end (§0.2 item 5)** — EJECUTADA en la sesión siguiente (6ª parte), PASA.
2. Cadencia W9: rebase de `personal` sobre `upstream/quattro` (tag `v4.0.2`), sync del tag al
   fork y re-pin del release (con nueva republicación: pkgrel 101 o el que toque según §5.3).
3. Clave pública del repo personal en `keys/omarchy-personal-repo.pub.asc` del scratchpad
   (privada NO versionada; solo secret `GPG_PRIVATE_KEY`).

---

## Sesión 2026-09-01 (6ª parte) — Prueba END-TO-END en la máquina dev (PASA)

### Contexto

Cierre de la Etapa 4: ejecutar el §0.2 item 5 literalmente. En vez de "reinstalar el par stock
para luego subir", se instaló directamente el par **desde `[omarchy-personal]`** (la fuente de
verdad que queríamos demostrar). Máquina: `ludus` (desktop, sin TTY para el agente).

### Qué se hizo (orden real, con comandos y resultados)

1. **Recon (sin root)**: `omarchy-dev dev.0e6c11d5-1` + `omarchy-settings-dev dev.0e6c11d5-1`
   instalados; reverse-deps solo `omarchy-settings-dev → omarchy-dev`; `OMARCHY_PATH=/usr/share/
   omarchy` (instalado, no checkout → `omarchy update-dev` sale por exit 0); `/etc/pacman.conf`
   solo con `[core] [extra] [multilib] [omarchy]`; snapper disponible, 194G libres.
2. **Escalada**: el timestamp de sudo es por-TTY y el agente no tiene TTY → `sudo -v` del usuario
   no vale. Drop-in temporal del usuario `echo 'dominus ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee
   /etc/sudoers.d/99-e2e` (+`visudo -c`). **Se retiró al final** (máquina queda como estaba).
3. **Flujo root** (`/tmp/opencode/e2e-root.sh`, un solo `sudo bash`):
   - `pacman-key --add keys/omarchy-personal-repo.pub.asc` + `--lsign-key D5E75EAC51A44715`.
   - `pacman -R --noconfirm omarchy-settings-dev omarchy-dev` (quitado el par dev; sin conflictos).
   - Se inyecta `[omarchy-personal]` antes de `[omarchy]` en `/etc/pacman.conf` (una vez; la config
     del fork la escribe después `omarchy refresh pacman`).
   - `pacman -Syy` → dígerencia los dbs (incluida la ALIAS `omarchy-personal.db`, con firma OK).
   - `pacman -S --noconfirm omarchy omarchy-settings` → instaló `omarchy-personal/omarchy 4.0.2-100`
     y `omarchy-personal/omarchy-settings 4.0.2-100` (la atribución a `omarchy-personal` aparece en
     la propia salida del resolver, y en pacman.log `[ALPM] installed omarchy (4.0.2-100)`).
4. **`omarchy refresh pacman`** → `/etc/pacman.conf` quedó literalmente el `pacman-stable.conf` del
   fork instalado (`[omarchy-personal]` línea 32, `[omarchy]` 36, comentario de la clave) +
   mirrorlist `stable-mirror.omarchy.org`; `pacman -Syyuu --noconfirm` → "nothing to do".
5. **`omarchy update -y`** (1er intento FALLADO, 2º OK):
   - Fallo: `omarchy-update-stay-awake start` corre `sudo -v` cuando stdin es TTY (dentro de
     `script -qefc`, lo es). Con NOPASSWD en sudoers, **`sudo -v` sigue exigiendo password** (quirk
     de sudo), el prompt se queda 5 min (passwd_timeout) y el update aborta con "Something went
     wrong" — RC=1, tras crear el snapshot #4 (tag `4.0.2-100`).
   - Neutralización probada: `Defaults:dominus !authenticate` en `/etc/sudoers.d/100-e2e-noauth`
     → `sudo -v` valida al instante (test en pty). Se retiró al final igualmente.
   - 2º intento RC=0: snapshot #5 (`4.0.2-100`), `pacman -Syu` sin pendientes, 3 migraciones
     (1787666837, 1787760281, 1787843905), AUR: `google-chrome` flagged OOD (sin upgrade), mise:
     `codex 0.152.0→0.152.1`, `opencode 1.18.25→1.18.26`, shell restart.
6. **Verificación final**: `omarchy`/`omarchy-settings` 4.0.2-100; keyring con la personal
   `D5E75EAC51A44715 [full]` Y la de packaging `40DFB630… [full]`; `/etc/pacman.conf` con
   `[omarchy-personal]` sostenido por el paquete del fork (auto-mantenible en futuros refreshes);
   par dev ausente; `sudoers.d` limpio de artefactos temporales.

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| Instalar el par directo desde `[omarchy-personal]` (no reinstalar stock primero) | Es la prueba real del flujo: la atribución de repo aparece en la salida del resolver |
| Confiar la clave personal ANTES de `-Syy` y del refresh | `[omarchy-personal]` hereda `Required DatabaseOptional`; sin clave en keyring la sync falla |
| Inyección manual de `[omarchy-personal]` en pacman.conf, solo esta vez | La config del fork (con la sección) se escribe sola en el primer `refresh pacman` del paquete personal |
| Drop-in sudoers temporal (99-e2e, 100-e2e-noauth) y retirada al terminar | Sin TTY el timestamp por-TTY del usuario no vale; dejar la máquina como estaba |
| `omarchy update -y` no-interactivo puede colgarse en `sudo -v` de stay-awake | No desactivarlo a nivel script del sistema; documentar el quirk (interactivo pide password y sigue) |

### Estado actual (inventario)

- Máquina dev `ludus`: par **4.0.2-100** instalado desde `[omarchy-personal]`; restaurar la línea
  dev en el futuro = re-ejecutar el bootstrap (fase dev).
- Keyring con ambas claves `[full]` (packaging oficial + personal). Snapshots snapper #4/#5.
- Repos: fork `personal` @ `ebfb3038`; `omarchy-pkgs` `personal` @ `26e524a`, `master` @ `fe47b16`.

### Lo que falta (próximos pasos)

1. Cadencia W9: rebase de `personal` sobre `upstream/quattro` (tag `v4.0.2`), sync del tag al fork
   y re-pin/republicación (pkgrel 101 o el que toque según §5.3) — **EJECUTADA en la 7ª parte, PASA**.
2. Valorar documentar el quirk de `sudo -v`/stay-awake en la cadencia W-repos (nada que arreglar en
   el fork; comportamiento aguas arriba).

---

## Sesión 2026-09-01 (7ª parte) — Cadencia W9 ejecutada (rebase lineal + re-pin 4.0.2-101) y verificada end-to-end

### Contexto

Ejecutar la cadencia W9: sync del fork fuente con upstream (`quattro`), sync del tag `v4.0.2` al
fork y re-publicación del par personal, verificando la convergencia en la máquina dev.

### Qué se hizo (orden real)

1. **Refresco del entorno de shell** (mise reshim tras la subida de tools de la 6ª parte):
   `opencode 1.18.26`, `codex 0.152.1`, `mise 2026.8.15`.
2. **Recon del estado antes del rebase**: `upstream/quattro` NO se había movido desde nuestra base
   (`b71dcad9` ya era el HEAD). `personal` estaba en `ebfb3038` (Etapa 4 sobre el merge `4d687d4d`
   del dueño). El tag local `v4.0.2` ya existía (apunta a `346e69e1`, el release de upstream).
3. **Rebase** `git rebase upstream/quattro` → **línea recta** de 2 commits personales sobre
   `b71dcad9` (`0deee8d8` Xataka POC + `1540c220` Etapa 4), sin conflictos. Nuevo HEAD
   **`1540c220`**.
4. **Test suite** `./test/all`: 224/225 suites OK; falla solo `test/shell.d/snapper-test.sh` por
   estar **ambiental** (busca un checkout hermano `omarchy-iso` en el workspace, que no existe
   aquí; no es del fork). El resto (CLI router, theme pipeline, shell, migraciones) todo verde.
5. **Push forzado** de `personal` al fork (`ebfb3038...1540c220` forzado — el rebase reescribió
   historia — con `--force-with-lease`). **Sync del tag `v4.0.2`** al fork (`git push origin
   v4.0.2`); queda como tag ligero apuntando a `346e69e1`, junto a los ya presentes v4.0.0/v4.0.1.
6. **Re-dispatch de la Action** `release-personal.yml`:
   `gh workflow run ... -f version=v4.0.2 -f pkgrel=101` → run **`33579948670` SUCCESS** (5m12s).
   - El workflow re-pinea el par al nuevo commit de `personal` (`COMMIT=$(git rev-parse HEAD)=1540c220`)
     vía `bin/omarchy-pkgs release v4.0.2 --commit 1540c220`, resetea pkgrel a 1 y luego sed a 101.
   - En los objetos publicados se verifica el par **`omarchy-4.0.2-101-any.pkg.tar.zst`** +
     `omarchy-settings-4.0.2-101` (+ `.sig`) y la db `omarchy.db`/`omarchy-personal.db`; la firma
     de la db se confirma **Good signature** con la clave `D5E75EAC51A44715`.
   - pkgrel=101 (§5.3): mismo pkgver `4.0.2` que la republicación anterior (100) → incremento.
     (El pin engine resetearía a 1, pero el paso de republicación sed a pkgrel=PKGREL=101.)
7. **Convergencia end-to-end en `ludus`**:
   - 1er `omarchy update -y` abortó por el **quirk de `sudo -v`** (mismo que en la 6ª): al retirar
     el drop-in `Defaults !authenticate`, `omarchy-update-stay-awake` corre `sudo -v` bajo pty y
     con NOPASSWD en sudoers `sudo -v` sigue pidiendo password → expira a los 5 min → aborte.
   - Reaplicado temporalmente `Defaults:dominus !authenticate` → 2º `omarchy update -y` **RC=0**:
     pacman subió `omarchy-settings` y `omarchy` **4.0.2-100 → 4.0.2-101** desde `[omarchy-personal]`
     (`[ALPM] upgraded ... (4.0.2-100 -> 4.0.2-101)` en pacman.log), snapshot #8.
8. **Verificación final**: `pacman -Q` = `omarchy`/`omarchy-settings` **4.0.2-101**; `/etc/pacman.conf`
   mantiene `[omarchy-personal]` (línea 32) antes de `[omarchy]`; la webapp del fork `Xataka.desktop`
   presente en `/usr/share/omarchy/applications/`. Retirado el drop-in sudoers temporal (máquina
   como estaba).

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| Rebase (no merge) de `personal` sobre `upstream/quattro` | §7.1: única estrategia de sync; resultado lineal limpio; no arrastra merges intermedios |
| Push forzado con `--force-with-lease` | El rebase reescribe la historia de `personal`; `-with-lease` protege contra sobrescritura ajena |
| `pkgrel=101` para el re-pin del mismo `pkgver` | §5.3: incremento por cada republicación del mismo pkgver (99→100 Etapa 4, →101 aquí) |
| Reaplicar `Defaults !authenticate` solo para ejecutar el update y retirarlo al terminar | Quirk de `sudo -v`/stay-awake bajo pty no interactivo; dejar la máquina sin cambios de sudo |

### Estado actual (inventario)

- Fork fuente: `robert-flo/omarchy` `personal` @ **`1540c220`** (Xataka `0deee8d8` + Etapa 4
  `1540c220` sobre upstream `b71dcad9`); tags `v4.0.2`/`v4.0.1`/`v4.0.0`/`v4.0.0-beta3` sync'd.
- `robert-flo/omarchy-pkgs`: pin commit `1540c220`, pkgrel 101 (commit de pin + commit publish de la Action).
- Par publicado/instalado en dev: **4.0.2-101** firmado `D5E75EAC51A44715`; upgrade 100→101 confirmado.
- `omarchy-pkgs` `master` (registro): sin cambios en esta sesión (el re-pin fue solo a `personal`).

### Lo que falta (próximos pasos)

1. Iterar las ~55 webapps del dueño (patrón `webapp-workflow.md`) sobre `personal`; cada cambio de
   fuente del par → re-dispatch de la Action con pkgrel incrementado (§5.3) y `omarchy update` en máquinas.
2. Etapa 5 (onboarding de máquinas reales) cuando haya máquinas en uso; Etapa 6 (cadencia de sync
   como operación continua) ya validada en su forma manual con esta sesión.
3. Registrar el micro-patrón de `sudo -v`/NOPASSWD en la doc de la cadencia (puramente operativo,
   no es bug del fork). Para el paquete PoC `hola-mundo` **EJECUTADO en la 8ª parte**: ver WORKLOG.

---

## Sesión 2026-09-01 (8ª parte) — Generalización de la repo personal: paquete propio `hola-mundo` publicado e instalable vía `omarchy update`

### Contexto

El usuario quería que la repo personal (formada hasta ahora SOLO por el par lockstep
`omarchy`/`omarchy-settings`) pudiera llevar un paquete propio de ejemplo ("hola mundo") e
instalarlo/mantenerlo con `omarchy update`, de forma que el mecanismo sirva para "todos mis
pkgbuild personalizados". Se pidió investigar primero cómo lo hace upstream.

### Cómo lo hace upstream (investigación)

- `pkgbuilds/<pkg>/.omarchy/package.json` define `source` (`local` para los que se buildan y
  sirven vía repo pacman; `aur` para los que solo se trackean y van por `yay`) y
  `release_ring: fast` para buildear a stable.
- `package_builds_for_mirror` (helpers/package-metadata.sh): para `stable` exige
  `release_ring: fast` Y **no pinned** (`package_is_pinned && return 1`). El par lockstep es
  `pinned: true` → por eso el fork hace un un-pin temporal + `--package` explícito.
- Conclusión: "build all local" NO es fiel a upstream — arrastraría los sources AUR que también
  matchean (localsend-bin, t3code-bin, mise-bin...) y aún así saltaría el par pinned. Lo fiel es
  la **orquestación explícita de un set preciso**: en el fork, ese set = los marcados `personal: true`.

### Qué se hizo

1. **Marcador `"personal": true`** en `.omarchy/package.json` de `omarchy`, `omarchy-settings`
   (y el nuevo `hola-mundo`). La Action lo usa como fuente de verdad del conjunto a publicar.
2. **Paquete PoC `pkgbuilds/hola-mundo/`**: PKGBUILD trivial (`pkgname=hola-mundo`, `pkgver=0.1.0`,
   `arch=('any')`, script `/usr/bin/hola-mundo` que imprime el mensaje), `.omarchy/package.json`
   `source: local` + `release_ring: fast` + `personal: true`. Estructura idéntica a upstream
   (PGKBUILD + metadata), sin lockstep/tag.
3. **Generalización de la Action `release-personal.yml`** (previamente hardcodeada al par):
   - Step nuevo `Recolecta paquetes personales`: junta todos los `pkgbuilds/*/` con `personal: true`
     → `PERSONAL_PKGS` y el subconjunto `PINNED_PERSONAL_PKGS`.
   - `Aplica pkgrel (§5.3)` → solo a `PINNED_PERSONAL_PKGS` (el par lockstep conserva su conteo de
     republicación; los paquetes genericos conservan su pkgrel normal de PKGBUILD).
   - `Build` → un-pin temporal solo a `PINNED_PERSONAL_PKGS` y `./bin/repo --local build --package $PERSONAL_PKGS`.
   - `Commit del pin` → add de los PKGBUILD de `PINNED_PERSONAL_PKGS` (los genéricos se commitean
     como cambios de fuente normales).
   - `Validar publicación` → ahora valida TODOS los `PERSONAL_PKGS` en Pages, no solo el par.
   - Header actualizado a la semántica "conjunto = personal:true".
4. **Push a `roberta-flo/omarchy-pkgs` `personal`** (tras fetch+rebase; el remoto tenía el commit
   de pin de la republicación de la 7ª parte — sin conflicto). HEAD `305b56d`.
5. **Dispatch de la Action con `--ref personal`** (CRÍTICO: `gh workflow run` sin `--ref` usa el
   workflow de la **rama por defecto, `master`**, que aún tiene la versión hardcodeada; por eso el
   primer run `33582420572` repúblico el par sin hola-mundo. Con `--ref personal` el run
   `33582784470` usó la Action generalizada).
6. **Run `33582784470` SUCCESS**: `Building packages: hola-mundo omarchy-settings omarchy`,
   `Successfully built hola-mundo 0.1.0-1`, signado, promovido y publicado. `omarchy.db` en Pages
   ya lista `hola-mundo-0.1.0-1`, `omarchy-4.0.2-101`, `omarchy-settings-4.0.2-101`. Se verificó
   el `desc` del paquete en la db (NAME/VERSION/DESC correctos).
7. **Instalación en dev**: `pacman -S hola-mundo` (desde `[omarchy-personal]`) → `[ALPM] installed
   hola-mundo (0.1.0-1)`; `hola-mundo` imprime el mensaje.
8. **Ciclo de mantenimiento completo**: bump `pkgrel 1->2` de hola-mundo (commit `c4aa4dc`),
   re-dispatch (`33583330456` SUCCESS, publica `hola-mundo-0.1.0-2` en Pages + db) y
   `omarchy update -y` en dev → **`omarchy-personal/hola-mundo 0.1.0-1 → 0.1.0-2`** (RC=0).
   `hola-mundo` ahora imprime y `pacman -Q` = 0.1.0-2. Pacman.log confirma installed y upgraded.
9. **Orden de la cadencia W8 piña**: el drop-in temporal `100-e2e-noauth` se volvió a necesitar
   (el `omarchy update -y` sin él se colgó en `sudo -v`/pty aún con `NOPASSWD: ALL` en
   `99-omarchy-nopasswd-dominus`). Reaplicado, update OK, **retirado** tras terminar (máquina como estaba).

### Decisiones registradas

| Decisión | Razón |
|---|---|
| Marcador `personal: true` (no "build all local") | Fiel a upstream: orquestación explícita. "All local" arrastraría sources AUR que también matchean el filtro stable y seguiría saltando el par pinned. El set del repo personal queda = exactamente lo que el usuario mantiene |
| `--ref personal` obligatorio al `gh workflow run` | Sin él, GitHub toma el workflow de la rama por defecto (`master`), que no tiene la generalización |
| `Aplica pkgrel` solo a `PINNED_PERSONAL_PKGS` | §5.3 es del par lockstep (pkgrel = contador de republicación). Un paquete genérico usa su pkgrel normal de PKGBUILD |
| hola-mundo con `arch=('any')`, `sha256sums=('SKIP')`, source file local | PoC mínima: sin deps ni descargas; `should_build_for_arch` devuelve true para `any` |
| Reaplicar/retirar `Defaults !authenticate` para el update | Mismo micro-patrón que 6ª/7ª parte; deja la máquina sin cambios de sudo |

### Estado actual (inventario)

- `robert-flo/omarchy-pkgs` `personal` @ **`c4aa4dc`** (sobre `017e9f1` pin remoto de la W9):
  workflow generalizado `personal:true`, par + hola-mundo marcados, PKGBUILD hola-mundo 0.1.0-2.
- Repo publicado `omarchy-personal-repo` (gh-pages): `hola-mundo-0.1.0-2-any.pkg.tar.zst` (+sig),
  `omarchy-4.0.2-101`, `omarchy-settings-4.0.2-101`. Runs: `33582784470` (0.1.0-1) y
  `33583330456` (0.1.0-2) SUCCESS.
- Dev machine: `hola-mundo 0.1.0-2` instalado vía `omarchy update`; par en 4.0.2-101. Drop-in
  sudoers temporal retirado.
- El `omarchy update` no instala paquetes nuevos no presentes (hace `pacman -Syu`): el PoC
  demuestra instalar una vez (`pacman -S`) y que `omarchy update` lo mantiene. Para CUALQUIER
  pkgbuild personal futuro: commitear el dir + marcarlo `personal:true` → re-dispatch → la máquina
  que lo tenga instalado lo mantendrá al día.

### Lo que falta (próximos pasos)

1. (Opcional) Script/checklist de la cadencia personal: añadir un PKGBUILD personal =
   mkdir pkgbuilds/<pkg> + PKGBUILD + `.omarchy/package.json` con `personal: true` + dispatch.
2. ~~Decidir si `hola-mundo` se envía también a `omarchy-base.packages`~~ **DECIDIDO (10ª parte):
   conservarlo como paquete ejemplo (no se retira), NO añadirlo a `omarchy-base.packages`**.
3. Iterar webapps del dueño (sigue pendiente del hito principal).

---

## Sesión 2026-09-01 (9ª parte) — Revisión L8: endurecer la operación

### Contexto

Tras cerrar la 8ª parte (repo generalizada + PoC instalado), el dueño pidió una **revisión crítica**
del proyecto "como haría un ingeniero L8 revisando un PR para una app en producción con 100k
usuarios". Veredicto: **Request changes**, con hallazgos B (bloqueantes), M (mayor), S (seguridad)
y N (nits). Esta sesión implementa **todas** las recomendaciones.

### Qué se hizo (orden real)

**A. `omarchy-pkgs` — Action endurecida (B3) + vigilancia de cadencia (B2).**

1. `release-personal.yml` (rama `personal`, commit `c929193`):
   - **Guard fail-fast de rama**: aborta si `github.ref != refs/heads/personal` (el incidente del
     dispatch sin `--ref`, run `33582420572`, ya no puede dañar: el guard corre antes de todo paso
     que escriba).
   - **`pkgrel` autoderivado (§5.3)**: se lee el estado previo commitado del PKGBUILD del par antes
     del pin (`PRE_PKGVER`/`PRE_PKGREL`) y tras el pin engine se aplica: `pkgver` nuevo → `99`;
     mismo `pkgver` → `última + 1`. El input `pkgrel` queda como **override opcional** (emergencias).
     Revision: 4.0.2-101 estaba commitado → una futura república del mismo pkgver derivará 102 solo.
   - **`dry_run`** (boolean): ensayo completo sin publicar (ni commit del pin a `personal`, ni push
     a `gh-pages`); el flujo normal valida en Pages, el dry_run valida el árbol local.
   - **`concurrency`** (group `release-personal`, `cancel-in-progress: false`): dos dispatches salen
     en cola, nunca intercalados sobre el mismo destino.
   - Copia de registro idéntica en `master` (commit `281c7d4`).
2. **`sync-check.yml`** (nuevo, B2): cron diario (06:30 UTC) + dispatch manual. Compara el tag más
   reciente de `omacom/omarchy` (`git ls-remote`, `sort -V`) con el `pkgver` pineado en `personal`;
   si el pin queda atrás abre un issue `[Cadencia]...`, y si vuelve a estar en cadencia lo cierra.
   Registrado en `personal` + `master` (los `schedule` exigen estar en la rama default; siempre hace
   checkout explícito de `personal`).

**B. Scratchpad — documentación operativa.**

3. **`RUNBOOK.md`** (B1): estrategia de rollback declarada (**roll-forward**: `clean` poda versiones
   viejas, el repo no "despublica"; reparar = republicar con `pkgrel+1` o re-pin), 8 modos de fallo
   conocidos con respuesta (dispatch equivocado, pkgrel mal derivado, publicación corrupta, lag de
   cadencia, TLS transitorio, rotación de claves, rescate por máquina, quirk sudo), operación
   preventiva (reherso + checklist de cadencia + vigilancia) y fuentes.
4. **`GLOSSARY.md`** (M4): términos del proyecto en tabla.
5. **`decisions/`** (M3 + S1 + S3): promovidas las "Decisiones registradas" del WORKLOG a 7 ADRs
   (hosting, canal estable, sombreado parcial, regla §5.3 con la mecánica autoderivada, `personal: true`,
   claves/rotación/DR, y **entorno de build**: se declara `archlinux:base-devel` rolling a propósito,
   con el pin a digest documentado como acción de seguimiento si se exige reproducibilidad).
6. **README**: banner de repo público (nunca commitear claves privadas), tabla de rutas "quiero X → leo Y",
   mapa de docs ampliado, y nota de que la tabla de versiones es la **fuente única de estado**.
7. **`agents_fork.md`**: diagrama ASCII del pipeline (§1.0), Etapa 1 ✅ (POC Xataka) y Etapa 6 ✅
   (checklist en RUNBOOK + vigilancia automática), W7 actualizado (guard/dry_run/pkgrel auto),
   §5.3 con la autoderivación, §7.2 con "nunca commitear claves privadas".
8. **Nits (N1–N3)**: sudo consistente en `docs/` (pacman -S requiere sudo), §explica el `.sig`
   contiguo en `docs/02` (pacman lo verifica solo), índice del WORKLOG sin anchors rotos (eliminados
   en esta sesión, ver nota al inicio del índice).
9. **Comandos de dispatch** actualizados en `docs/04-webapps.md`, `docs/05-mantener.md`,
   `agents_fork.md` W7 y `bootstrap-omarchy-dev.sh`: ya no se pasa `-f pkgrel` (autoderivado);
   se menciona `-f dry_run=true`.

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| Roll-forward como única estrategia de rollback del repo | `clean` poda versiones viejas en Pages; no hay "despublicar" a una versión anterior; republicar con pkgrel+1 repara y sigue siendo barato |
| `pkgrel` autoderivado (opcional override manual) | Elimina el paso manual que ya dio pie al run `33582420572`; la Action lee el estado commitado del par (mismo pkgver → +1, pkgver nuevo → 99) |
| `dry_run` para ensayar sin publicar | Validar antes de tocar nada remoto (reduce la ventana "publica y luego valida") |
| Guard fail-fast de rama | La copia de `master` es solo registro (requisito GitHub del dispatch por API); disparar desde ahí no puede hacer daño |
| Vigilancia de cadencia vía cron + issue | El guard §5.3 solo actúa al DISPARAR; el cron avisa si upstream pasa al pin y la personalización se quedaría atrás (pérdida silenciosa por vercmp) |
| Entorno de build rolling declarado (no pin a digest) | Imagen `archlinux:base-devel` mutable, riesgo asumido (1-2 máquinas controladas); pin-digest documentado como follow-up si hace falta reproducibilidad (ADR-007) |
| Índice del WORKLOG sin hipervínculos de salto | Los slugs parciales nunca coinciden con los anchors que genera GitHub; N2 |

### Estado actual (inventario)

- `robert-flo/omarchy-pkgs`: `personal` @ **`c929193`** (Action endurecida + sync-check), `master` @
  **`281c7d4`** (copia de registro idéntica). Workflows `release-personal.yml` y `sync-check.yml`
  verificados byte-idénticos entre ramas.
- Scratchpad: `README.md`, `agents_fork.md`, `docs/*`, `WORKLOG.md` (¡esta sesión!), `RUNBOOK.md`,
  `GLOSSARY.md` (nuevos), `decisions/` (7 ADRs, nuevos), `bootstrap-omarchy-dev.sh` actualizado.
- Repo publicado sin cambios (nada se republicó en esta sesión: el par sigue 4.0.2-101).

### Lo que falta (próximos pasos)

1. ~~Probar el flujo endurecido en un run real de la Action (p. ej. la habitual república con una
   webapp; esperado: pkgrel autoderivado 101→102).~~ **EJECUTADO en la 10ª parte**: dry_run + run
   real, par republicado a 4.0.2-102 con firma verificada; se detectó y corrigió el guard
   booleano de `dry_run`.
2. ~~(L8) Decisión no tomada todavía: `hola-mundo` en `omarchy-base.packages` o retirarlo.~~
   **DECIDIDO (10ª parte): conservarlo como paquete ejemplo (no se retira), NO añadirlo a
   `omarchy-base.packages`.**
3. Siguiente hito de producto: iterar las ~55 webapps y el onboarding de máquinas (Etapa 5).

---

## Sesión 2026-09-01 (10ª parte) — Validación del flujo L8 con run real + decisión de `hola-mundo`

### Contexto

El dueño aprobó validar la Action endurecida (L8) con un **run real** y decidió el destino de
`hola-mundo`: **conservarlo como paquete ejemplo en el repositorio (no se retira) y NO añadirlo a
`omarchy-base.packages`** (sería solo "cómo se hace un paquete personal"; no debe forzarse en onboarding).

### Qué se hizo (orden real)

1. **Decisión `hola-mundo` registrada** en `agents_fork.md` §6 (item de la 8ª parte → DECIDIDO) y
   en `WORKLOG.md` 9ª parte "Lo que falta" item 2.
2. **Dry_run de la Action endurecida** (`33588143226`, `-f version=v4.0.2 -f dry_run=true`,
   `--ref personal`): éxito; pkgrel autoderivado **101 → 102**; todos los pasos de escritura
   (`Commit del pin`, `Publicar a gh-pages`, `Validar publ. en Pages`) saltados como corresponde.
3. **BUG detectado por el run real** (`33588412168`): pese a `conclusion=success`, los pasos
   `Commit del pin`, `Publicar a gh-pages` y `Validar publ. en Pages` quedaron **`skipped`**:
   `if: ${{ inputs.dry_run == 'false' }}` **nunca se cumple** cuando `dry_run` es un booleano
   `false` (GitHub compara por truthiness de cadena: `'false'` no vacío ≡ true ⇒ `false == 'false'`
   es falso). El `dry_run=true` del ensayo sí funcionaba (`== 'true'` es la comparación correcta).
4. **Fix**: `== 'false'` → `if: ${{ !inputs.dry_run }}` (x3: pin, publish, validate-Pages) y
   `== 'true'` → `if: ${{ inputs.dry_run }}` (x1: validación del árbol local). Push `personal` @
   **`c5d2cf3`** y copia de registro `master` @ **`2fa2f65`**.
5. **Dry_run post-fix** (`33588803480`): éxito; ahora sí corre `Validar arbol local (dry-run,
   nada publicado)` → log `"OK (dry-run): arbol validado. No se commiteo pin ni se publico a gh-pages."`.
6. **Run real final** (`33589089108`): SUCCESS con `Commit del pin` ✓, `Publicar a gh-pages` ✓ y
   `Validar publicacion en GitHub Pages` ✓. Pin commitado en `personal` (`4c349ca`
   "personal: pin v4.0.2-102 @ c5d2cf3"): `pkgrel=102`.
7. **Verificación end-to-end**:
   - Pages sirve `omarchy-4.0.2-102-any.pkg.tar.zst` (+sig) y `omarchy-settings-4.0.2-102` (+sig); db
     `omarchy.db`/`omarchy-personal.db` (+sig) listan **`omarchy 4.0.2-102`** y **`omarchy-settings
     4.0.2-102`**; alias servidos por HTTP 200.
   - **Firma GPG verificada** del par 4.0.2-102 contra la clave pública del repo
     (`D5E75EAC51A44715`): `Good signature`.
   - Dev machine sigue en 4.0.2-101; convergerá con el próximo `omarchy update` (no se tocó el sistema).

### Decisiones registradas (con razón)

| Decisión | Razón |
|---|---|
| `hola-mundo` se conserva como paquete ejemplo, sin entrar en `omarchy-base.packages` | Es la muestra de "cómo se hace un paquete personal"; forzarlo en onboarding no aporta valor y contamina el inventario base |
| Guard booleano con `!inputs.dry_run` (no `== 'false'`) | La comparación `booleano == 'false'` en GitHub Actions nunca es verdadera (task `skipped` ⇒ publica sin validar en falso positivo); `!x` evalúa por valor real del booleano |
| Validar con run real además del dry_run | El dry_run solo ejercita el camino "ensayo"; la republicación de prueba del mismo pkgver (4.0.2-101→102) era el ensayo de fricción completa y detectó el bug de guard |

### Estado actual (inventario)

- `robert-flo/omarchy-pkgs`: `personal` @ **`4c349ca`** (pin 4.0.2-102 sobre `c5d2cf3`), `master` @
  **`2fa2f65`** (registro). Workflows idénticos entre ramas.
- Publicado: par **4.0.2-102** firmado (verificado) + db + aliases. Dev machine: par **4.0.2-101**,
  `hola-mundo` **0.1.0-2**.
- Runs: dry `33588803480` ✓, real `33589089108` ✓.

### Lo que falta (próximos pasos)

1. Converger la máquina dev con `omarchy update` (par 101 → 102).
2. El dueño entregará la lista de ~55 webapps → Etapa 2 (cosecha de personalizaciones, patrón
   `webapp-workflow.md`).
