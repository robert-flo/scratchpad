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
