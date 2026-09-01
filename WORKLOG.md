# WORKLOG.md — Bitácora del fork de Omarchy

Este archivo registra qué se hizo, por qué y cómo, sesión por sesión. Es la memoria de
procedimiento del proyecto; `agents_fork.md` es la referencia normativa (plan, etapas,
recetas, invariantes). Si algo aquí contradice a `agents_fork.md`, el error está en la
bitácora: corregir la bitácora, nunca rebajar el plan.

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
3. Rol del archivo `omarchy-personal-repo.pub.asc`: documentar su guardado definitivo
   (p. ej. en el scratchpad) fuera de `/tmp/opencode`.
