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