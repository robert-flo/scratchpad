# agents_fork.md — Plan de fork personal de Omarchy

Guía maestra para cualquier agente que trabaje en este proyecto. Captura la intención, el planeamiento a largo plazo, el modelo mental de cómo funciona Omarchy upstream, la hoja de ruta por etapas y las recetas exactas de cada flujo de personalización. Leer completo antes de tocar nada; no adivinar procedimientos.

## 0. Encargo y contexto (por qué existe este documento)

El dueño de este proyecto usa **N máquinas con Omarchy** instalado desde la ISO oficial de omarchy.org. Quiere que todas las máquinas sean **sistemas idénticos y mantenidos automáticamente por `omarchy update`**, con sus personalizaciones personales aplicadas por encima de un Omarchy vanilla.

La estrategia elegida, de común acuerdo en las conversaciones previas:

1. **Forkear el repo fuente** `omacom/omarchy` y mantenerlo **sync con upstream `quattro`**.
2. Todas las personalizaciones viven como **cambios de fuente en el fork** (no como parches de instalación ni scripts sueltos por máquina).
3. Aplicar las personalizaciones **empacadas como paquetes pacman propios**, publicadas en un **repo pacman personal alojado en GitHub Pages**, que las máquinas consumen a través del flujo normal `omarchy update`.
4. **Seguir el flujo upstream al pie de la letra.** No inventar mecanismos propios. El objetivo secundario es **contribuir de vuelta upstream** en el futuro, así que toda personalización debe tener la MISMA forma que un cambio aceptable en un PR a `quattro`.

Decisiones ya fijadas (Q&A previo):

- Hosting del repo pacman personal: **GitHub Pages** (repo tipo `<user>/omarchy-personal-repo`, branch `gh-pages`), **con GitHub Actions como build host**: el pipeline de `omarchy-pkgs` (build → sign → promote → clean → update-repo) corre íntegro en el runner de la Action, replicando la maquinaria de upstream; la única desviación permitida es la capa final de entrega (push a `gh-pages` en vez de `sync-repo`/rclone, porque Pages no acepta rclone). Ver §1.8 y W7.
- Canal a publicar: **solo `stable`** (no se replican edge/rc ni el walk de promoción). Decisión explícita del dueño.
- CI del fork de `omarchy-pkgs` (`.github/workflows/`): **replicar los 4 workflows de upstream** (`test.yml`, `sync-aur.yml`, `sync-upstream.yml`, `sync-rebuilds.yml`) con ajustes mínimos documentados (§1.8). Como el repo personal solo contiene el par (source local), lo más valioso es `test.yml` (self-tests); los tres de sync quedan inertes salvo que se agreguen paquetes AUR/upstream con personalización local.
- Ejecutables en `~/.local/bin`: **mezcla** — los encajables se publican como comandos `omarchy-*` (van a `/usr/bin` solos); los scripts de usuario que deben vivir en `~/.local/bin` se siembran vía `/etc/skel` desde el paquete `omarchy-settings`.
- **Ya existe clave GPG** para firmar el repo de paquetes (y para git).
- Modelo de repos en máquinas: **sombreado parcial** — `[omarchy-personal]` (solo el par `omarchy` + `omarchy-settings` + extras personales) listado ANTES del `[omarchy]` oficial en `/etc/pacman.conf`. El mirror oficial `pkgs.omarchy.org` sigue proveyendo el resto del ecosistema (~todos los demás paquetes). No se rehostea todo.

### 0.1 Estado actual del proyecto (2026-08-30) — la bitácora con el paso a paso está en `WORKLOG.md`

- Forks: `robert-flo/omarchy` (sí, rama `personal` sobre `upstream/quattro`, commit `89759761`);
  `robert-flo/omarchy-pkgs` **NO hecho aún** — solo clone de upstream en `~/Work/omarchy/omarchy-pkgs` (para el dev loop).
- Layout dev (defaults del tool; razón en WORKLOG, "Decisiones registradas"): `~/Work/omarchy/omarchy-installer` (fork), `~/Work/omarchy/omarchy-pkgs` (upstream).
- Machine dev: `omarchy-dev` + `omarchy-settings-dev` `dev.89759761-1` (reemplazaron al stock; máquina en línea dev).
- POC webapp: **Xataka** (`applications/Xataka.desktop` + `applications/icons/Xataka.png`) en `personal`;
  materializado con `omarchy-refresh-applications`; ventana Chrome modo app abierta y verificada
  (`chrome-www.xataka.com__-Default`). El patrón queda demostrado para iterar las ~55 webapps del dueño.
- Decisiones de este hito que matizan el plan: ver "Decisiones registradas" en WORKLOG (ruta default del tool,
  POC Xataka, repo de notas público con nombre neutro, `pkexec` sin TTY, `--ask 4` en `pacman -U`).
- Repositorios de notas: working copy canónico `~/Work/omarchy/scratchpad`.

### 0.2 Próximos pasos (orden de ejecución, estado 2026-08-30)

Este es el único criterio de avance; ejecutar en orden, un paso a la vez. Cada paso referencia
su receta en el plan (las "W#" y los apartados citados). Tras cada paso, actualizar `WORKLOG.md`
y este bloque de estado antes de continuar.

1. **Forkear `omacom/omarchy-pkgs` → `robert-flo/omarchy-pkgs`** (rama `master`), con
   `git remote add upstream git@github.com:omacom/omarchy-pkgs.git` en el checkout local
   (Etapa 0 — último ítem pendiente del bootstrap).
2. **Puntar el dev loop al fork**: en `~/Work/omarchy/omarchy-pkgs`, el `origin` pasa a ser el
   fork; `OMARCHY_UPSTREAM_URL` se apunta a `https://github.com/robert-flo/omarchy.git`.
   Validar que `omarchy dev pkg-test` (los dos paquetes) compila e instala desde el fork.
3. **Etapa 3 / W7 — entregable `omarchy-personal-repo`**:
   - Crear repo `<user>/omarchy-personal-repo`, branch `gh-pages`, hosting Pages desde ese branch.
   - Escribir `.github/workflows/release-personal.yml` (receta completa en W7): checkout de los 3
     repos → pin del par (`omarchy-pkgs release --no-push`, `OMARCHY_UPSTREAM_URL` al fork) →
     `bin/repo build/sign/promote-build/update-repo --mirror stable` → convertir los symlinks de la
     db en copias y firmarlos → push a `gh-pages`.
   - Replicar los 4 workflows de upstream: `test.yml` activo; `sync-aur.yml` / `sync-upstream.yml`
     / `sync-rebuilds.yml` inertes (solo el par, sin AUR/upstream extra). §1.8.
   - Único cambio permitido a `bin/`/`build/`: en `build/Dockerfile`, **no eliminar** la entrada
     `[omarchy] Server = https://pkgs.omarchy.org/stable/$arch` cuando `MIRROR=stable` (necesaria
     para resolver depends del par contra el repositorio oficial). W7 paso 3.
   - Secrets de la repo: `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`.
4. **Etapa 4 — sombreado parcial**: en el fork de `omarchy` (rama `personal`), agregar
   `[omarchy-personal]` **antes** de `[omarchy]` en `default/pacman/pacman-stable.conf` (§5.4);
   publicar el par con la regla de versión de §5.3 (pkgrel base 99, incremento por republicanación).
   Commit `personal: ...` y pull request planificado de vuelta a `quattro`.
5. **Prueba end-to-end**: reinstalar el par `omarchy` / `omarchy-settings` stock en la máquina dev,
   correr `omarchy update` y verificar que el par se toma de `[omarchy-personal]` (nuestro fork) y el
   resto del ecosistema de upstream. Criterio de éxito: `omarchy update` normal, sin pasos extra,
   deja las ~55 webapps y la personalización del fork instaladas.
6. **Después del hito**: iterar las ~55 webapps del dueño (patrón de `webapp-workflow.md`); onboarding
   de máquinas reales (Etapa 5); cadencia de sync con upstream (Etapa 6) cuando haya máquinas en uso.

## 1. Modelo mental de Omarchy upstream (hechos que un agente debe saber)

Estos hechos fueron verificados leyendo el código; no dan lugar a interpretación.

### 1.1 Dos repositorios, dos paquetes

- **`omacom/omarchy`** — el código fuente (este repo): `bin/`, `default/`, `config/`, `applications/`, `themes/`, `shell/`, `migrations/`, `install/`, `docs/`, `manual/`.
- **`omacom/omarchy-pkgs`** — los PKGBUILDs, uno por paquete, bajo `pkgbuilds/<paquete>/` con metadatos en `.omarchy/package.json`. Además contiene toda la maquinaria de build/release (`bin/repo`, `bin/omarchy-release`, `bin/omarchy-pkgs`). Detallado en `docs/file-layout.md`.

Del repo fuente se construyen exactamente **dos** paquetes que se reparten el árbol:

| Paquete | Qué empaqueta | Dónde instala |
| --- | --- | --- |
| `omarchy` | `bin/*` (todo menos `omarchy-debug`, `omarchy-debug-idle`, `omarchy-upload-log`), `install/`, `themes/`, `migrations/`, `shell/`, `version`, hooks de libalpm | `/usr/bin/omarchy-*` + symlinks `/usr/share/omarchy/bin/`, `/usr/share/omarchy/{install,themes,migrations,shell,version}` |
| `omarchy-settings` | `config/`, `default/`, `applications/`, `etc/`, iconos, branding, 3 bins de debug | `/etc/skel/.config`, `/usr/share/omarchy/config`, `/usr/share/omarchy/default`, `/usr/share/omarchy/applications`, `/etc/skel/.local/share/applications`, `/usr/share/icons/hicolor/{48,256}/apps`, `/etc/**` (drop-ins propios), `/usr/bin/omarchy-{debug,debug-idle,upload-log}` |

**Regla de lockstep:** ambos paquetes se construyen SIEMPRE desde el mismo commit de la fuente y comparten `_tag`/`_commit`/`pkgver`/`sha256sums` idénticos. `omarchy` depende de `omarchy-settings=${pkgver}` **exacto**. Violar esto rompe la instalación. El motor que lo impone upstream es `bin/omarchy-pkgs release` en `omarchy-pkgs`.

### 1.2 El mecanismo de build local (la clave de todo)

Ambos PKGBUILDs soportan build desde un checkout local:

```bash
# Cuando OMARCHY_SRC está seteado, source=() queda vacío y se copia todo el checkout.
OMARCHY_SRC=/ruta/al/checkout makepkg -s --skipchecksums
```

La herramienta oficial de dev es `omarchy dev pkg-test` (`bin/omarchy-dev-pkg-test`), que:

- Lee los PKGBUILDs de `${OMARCHY_PKGBUILDS_DIR:-~/Work/omarchy/omarchy-pkgs/pkgbuilds}/<paquete>/`.
- Construye **`omarchy-dev`** y **`omarchy-settings-dev`** (nombres con sufijo `-dev`) desde el checkout que le pases, con `pkgver=dev.<short-sha>[.dirty]`.
- Instala con `sudo pacman -U --noconfirm --overwrite='*'`.

Metadatos: no escribe ningún PKGBUILD nuevo. Es solo la rueda de desarrollo.

### 1.3 Cómo van las webapps (la evolución que confundía al inicio)

En **Omarchy 3** las webapps se **generaban** por script (`install/packaging/webapps.sh`, una línea `omarchy-webapp-install "Nombre" URL icono ...` por app) y `omarchy-refresh-applications` los ejecutaba creando `.desktop` sobre la marcha. Ese mecanismo se **eliminó** en `75cb4f71` ("Make setup ISO-only", mayo 2026).

Desde **quattro**, cada webapp es un **archivo estático commiteado**:

- `applications/<Nombre>.desktop` (p. ej. `applications/YouTube.desktop`).
- Icono en `applications/icons/<Nombre>.png` (o `.svg`).

El PKGBUILD de `omarchy-settings` los captura por **globo**, así que **cualquier `.desktop` o icono que agregues a la fuente entra al paquete sin tocar el PKGBUILD**:

- `cp -a applications/.` → `/usr/share/omarchy/applications/`
- `applications/*.desktop` → `/etc/skel/.local/share/applications/`
- `applications/icons/*` → con ImageMagick a `hicolor/256x256/apps/<icon_id>.png` y `hicolor/48x48/apps/<icon_id>.png`, donde `icon_id` es el nombre **minúsculo con `-` por separador** (ej.: `Google Photos.png` → `google-photos`). El `Icon=` del `.desktop` debe usar ese `icon_id`.

`omarchy-refresh-applications` copia `$OMARCHY_PATH/applications/*.desktop` a `~/.local/share/applications/` del usuario actual y corre `update-desktop-database`. Es lo único que necesita el launcher para mostrar la app nueva.

### 1.4 Cómo se materializan los configs por usuario

- **`/etc/skel`** solo se siembra en la **creación del usuario** (`useradd -m`). Cambiar el paquete no toca a usuarios existentes.
- Usuarios existentes resincronizan con:
  - `omarchy refresh config <relpath>` → copia `$OMARCHY_PATH/config/<relpath>` a `~/.config/<relpath>` (con backup).
  - `omarchy refresh shell`, `omarchy refresh hyprland`, etc. → refrescan un componente completo.
  - `omarchy reinstall-configs` → re-copia `/etc/skel` completo sobre `$HOME` (nuclear, destructivo).
- En un install empaquetado, `$OMARCHY_PATH=/usr/share/omarchy`.

### 1.5 Canales y configuración de pacman

- `omarchy-channel-set <stable|rc|edge|dev>` reemplaza `/etc/pacman.conf` y `/etc/pacman.d/mirrorlist` por las versiones shippadas en `default/pacman/pacman-<canal>.conf` y `default/pacman/mirrorlist-<canal>`, y después instala el par del canal.
- El `pacman-stable.conf` shippado define `[core] [extra] [multilib]` (vía mirrorlist de Arch) y `[omarchy] Server = https://pkgs.omarchy.org/stable/$arch`.
- **Consecuencia estratégica:** como el fork shippea `default/pacman/*.conf`, podemos **repointar/insertar el repo personal ahí mismo** y `omarchy-refresh-pacman` / `omarchy-channel-set` propagarán el cambio a todas las máquinas por el camino oficial.

### 1.6 Set de paquetes del sistema

- `install/omarchy-base.packages` y `install/omarchy-other.packages` son las listas que pacstrapa la ISO (y que lee el builder de ISO para el mirror offline).
- Para **reconciliar una máquina existente** contra esa lista, existe `omarchy reinstall pkgs` (`bin/omarchy-reinstall-pkgs`): refresca pacman al canal, hace `pacman -Suu` y luego `pacman -Syu --noconfirm --needed $(<omarchy-base.packages)`. **Este es el mecanismo para mantener el set de paquetes idéntico entre máquinas.**

### 1.7 Prioridad de repos y firma

- pacman elige la **versión más alta** de un paquete entre todos los repos que lo proveen; a **versión igual**, gana el repo **listado primero** en `pacman.conf`.
- El repo oficial se verifica con la clave de `omarchy-keyring` (firmado con la clave de omarchy, que NO tenemos).
- El repo personal necesita su **propia clave GPG**, que se agrega y firma localmente en cada máquina con `pacman-key --add` + `pacman-key --lsign-key`.

### 1.8 La maquinaria de build/release de upstream (`omarchy-pkgs`)

Para replicar la Etapa 3 "como upstream" hay que conocer cómo arma y publica el repo el propio equipo de Omarchy. Verificado en `omacom/omarchy-pkgs` (fork a la fecha: branch `master`, workflows `test.yml`/`sync-aur.yml`/`sync-upstream.yml`/`sync-rebuilds.yml`, units `omarchy-check-versions` + `omarchy-auto-release-{edge,rc,stable}`).

**Modelo de ejecución.** Hay un único "repository host" (VPS propio). `bin/repo` es un meta-command con *remote control*: si existe `OMARCHY_REPO_HOST` o `.repo-host`, los comandos publicables (release, build, sign, promote, update, clean, advance, sync, timers) se ejecutan en el host sobre `/root/omarchy-pkgs` vía SSH (`bin/repo` :20-58). En cualquier checkout sin host configurado, todo corre local (`--local` idem). Nosotros **no** usamos el remote control: en el runner de GitHub Actions no hay `.repo-host`, así que `bin/repo` corre local sin cambios.

**Pipeline.** Cada comando usa contenedores Docker construidos de `build/Dockerfile` con `--build-arg MIRROR=<canal>` (imagen `omarchy-pkg-builder:latest-<arch>-<mirror>`). Resumen por comando:

- `build` (`bin/build` + `build/build.sh`): limpia `build-output/`, construye la imagen, y dentro del contenedor importa claves de verificación, hace `pacman -Syu`, agrega `[omarchy-build] file://build-output` (y `[omarchy] file://pkgs.omarchy.org/...` si ya existe db), corre makepkg por paquete según `.omarchy/package.json` (`release_ring`/`skip_build`). Determina "needs build" comparando versión PKGBUILD vs db local.
- `sign` (`bin/sign` + `build/sign.sh`): el contenedor importa la clave de firma desde las env `GPG_PRIVATE_KEY` y `GPG_PASSPHRASE` (pasadas por el host; **encajan 1:1 con secrets de una Action**) y firma cada `.pkg.tar.zst`.
- `promote-build`: copia `build-output/<mirror>/<arch>` → `pkgs.omarchy.org/<mirror>/<arch>` (árbol de producción, `REPO_ROOT`; configurable con `OMARCHY_REPO_ROOT`).
- `update-repo` (`build/update-repo.sh`): repo-add de la última versión de cada paquete → `omarchy.db.tar.zst` + symlinks `omarchy.db`/`omarchy.files`.
- `clean-repo`: poda versiones viejas. `advance`/`migrate`: promocionan de edge a rc a stable.
- `sync-repo` (`bin/sync-repo`): sube el árbol con **rclone** a `pkgs.omarchy.org:omarchy-pkgs`. **Esta es la única etapa que no replicamos como está**: GitHub Pages es un repo git fijo y no acepta rclone. La reemplazamos por commit+push del árbol producido (W7).
- El orquestador completo es `release` (`bin/release`): build → sign → promote → clean → update → sync. En la Action lo descomponemos en sus pasos para reemplazar solo el último (sync) por el push a Pages.

**Pin del par / release.** Los PKGBUILDs del par llevan `pkgver` y las variables `_tag`, `_commit` y `sha256sums` idénticas en ambos; el `source=` por defecto es `git+https://github.com/<org>/omarchy.git#commit=${_commit}` (el PKGBUILD clona de GitHub el commit pineado; solo si `OMARCHY_SRC` está seteado usa un checkout local en `prepare()`). `bin/omarchy-pkgs release` es el **pin engine**: reescribe ambos PKGBUILDs en lockstep (mismo `_tag`/`_commit`/`pkgver`/`sha256sums`), commitea, pushea y dispara el build host (`--no-push` para no disparar; `OMARCHY_UPSTREAM_URL` para apuntar a otro remoto/org). Convención de versión: finales `X.Y.Z` desde tag `vX.Y.Z`; rc como forma pegada `X.Y.ZrcN`; `pkgrel` se resetea a 1 en cada cambio de pkgver.

**Cron del host.** `omarchy-check-versions.timer` (cada 5 min) detecta versiones nuevas y pide build; `omarchy-auto-release-<canal>.timer` (cada 5 min) ejecuta el release por canal con guard de cola, lock no-bloqueante y backoff exponencial (`bin/auto-release`). En nuestro modelo esto no aplica (no hay VPS): el equivalente es la **Action bajo demanda** tras cada sync con upstream (W9). Las units y `bin/check-versions`/`auto-release`/`advance`/`timers` se conservan en el fork por fidelidad pero no se usan.

**Detalle crítico para nuestro fork (dependencias de build).** `build/build.sh` resuelve los depends/makedepends del par solo contra `[core]/[extra]`, `[omarchy-build]` y `[omarchy] file://FINAL_OUTPUT_DIR`. Upstream re-construye TODOS los paquetes del ecosistema (quickshell, hyprland, limine...) en cada corrida, así que `makepkg -s` los encuentra en `[omarchy-build]`. Nuestro repo personal NO reconstruye el ecosistema → para resolver `quickshell`/`hyprland`/etc. la imagen del contenedor debe ver el repo **oficial** `pkgs.omarchy.org/stable`. `build/Dockerfile` ya instala `[omarchy] Server = https://pkgs.omarchy.org/<mirror>/$arch` temporalmente para bajar `omarchy-keyring` y luego lo **elimina** (sed final). El único cambio a `bin/`/`build/` documentado del fork es **no eliminar esa sección** cuando `MIRROR=stable` (replicando exactamente lo que el propio Dockerfile ya escribe), de modo que el build del par resuelva depends contra el oficial. Ver W7 paso 3.

## 2. Hoja de ruta: TODO maestro de etapas

Estados intermedios hasta el estado final, que es: **en cada máquina, `omarchy update` mantiene el sistema idéntico y personal, sin intervención manual**.

### Etapa 0 — Bootstrap del entorno

- [ ] Crear forks en GitHub: `<user>/omarchy` y `<user>/omarchy-pkgs`.
- [ ] Layout local (usar las rutas por defecto de `omarchy dev pkg-test` para que corra sin argumentos):
  - `~/Work/omarchy/omarchy-installer/` → fork fuente, rama `quattro` base.
  - `~/Work/omarchy/omarchy-pkgs/` → fork de pkgs (los PKGBUILDs solo se tocan para el `source=` al fork y el bump de pin/pkgrel; la maquinaria se mantiene intacta, §1.8).
- [ ] En el fork fuente: `git remote add upstream git@github.com:omacom/omarchy.git`, y crear la rama personal (`personal`, ver §7.1) arriba de `upstream/quattro`.
- [ ] En el fork de pkgs: `git remote add upstream git@github.com:omacom/omarchy-pkgs.git`.
- [ ] Verificar el ciclo dev en la máquina de desarrollo: `omarchy dev pkg-test` construye e instala `omarchy-settings-dev` + `omarchy-dev`.
- **Criterio de aceptación:** `pacman -Q omarchy-dev omarchy-settings-dev` reporta `dev.<sha>`, y la máquina sigue funcional.

### Etapa 1 — Probar el ciclo completo con una webapp mínima

- [ ] Agregar una webapp de prueba al fork (receta W1 abajo).
- [ ] `omarchy dev pkg-test` (rebuild del par dev).
- [ ] `omarchy-refresh-applications` para materializar el `.desktop` en el usuario actual.
- **Criterio de aceptación:** la app aparece en el launcher (`Super+Space`) y abre en la ventana webapp frameless.

### Etapa 2 — Cosecha de personalizaciones

- [ ] Inventariar cada personalización deseada y portarla a su ubicación en la fuente según las recetas W1–W6 de la §4.
- [ ] Cada una validada con `omarchy dev pkg-test` + su refresh correspondiente.
- **Criterio de aceptación:** `omarchy reinstall-configs` + `omarchy reinstall pkgs` en la máquina de dev reproducen el estado deseado completo.

### Etapa 3 — Repo de paquetes personal en GitHub Pages, build host = GitHub Actions

Replica la maquinaria de upstream (bin/repo, §1.8) corriendo entera en una Action; solo cambia el destino final (gh-pages en vez de rclone). **Decisión del dueño lo incluye**: solo canal `stable`, sin VPS.

- [ ] Crear repos en GitHub: `<user>/omarchy-personal-repo` (branch `gh-pages`, hosting Pages desde ese branch, sin site público o site servido desde el branch) y los forks `<user>/omarchy` y `<user>/omarchy-pkgs`.
- [ ] En el fork de `omarchy-pkgs` (rama `personal` arriba de `upstream/master`):
  - Cambiar en ambos PKGBUILDs el `source=` a `git+https://github.com/<user>/omarchy.git#commit=${_commit}` (única edición permanente del `source=`; el pin de commit lo mantiene el engine).
  - Editar `build/Dockerfile` para **no eliminar** la sección `[omarchy] Server = https://pkgs.omarchy.org/stable/$arch` al final de la etapa 2 (§1.8, detalle crítico). Registrar como el único cambio a `bin/`/`build/`.
  - Replicar los 4 workflows de upstream con ajustes mínimos: `test.yml` igual; `sync-aur.yml`, `sync-upstream.yml`, `sync-rebuilds.yml` iguales pero revisando `reviewers:` (quitar el de upstream) y conservando el guard de Basecamp (inert sin el secret).
- [ ] Escribir el workflow de release `.github/workflows/release-personal.yml` (paso a paso en W7): checkout de los 3 repos → pin del par (`omarchy-pkgs release --no-push`, con `OMARCHY_UPSTREAM_URL` al fork) → `bin/repo build/sign/promote-build/update-repo` con `--mirror stable` → convertir symlinks de la db en copias + firmarlas → push a `gh-pages`. Secrets de la repo: `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`.
- [ ] Exportar la clave GPG pública para instalarla en las máquinas (W8 paso 1).
- [ ] Primer run manual del workflow.
- **Criterio de aceptación:** desde un navegador, `https://<user>.github.io/omarchy-personal-repo/stable/x86_64/omarchy.db`, `omarchy.db.sig`, `omarchy.files` y los `.pkg.tar.zst` + `.sig` del par resuelven (archivos reales, NO symlinks); el run de la Action termina verde con el paso de push.

### Etapa 4 — Sombreado vía el pacman.conf del fork

- [ ] En el fork fuente, insertar `[omarchy-personal]` **antes** de `[omarchy]` en `default/pacman/pacman-stable.conf` (solo `stable`; decisión tomada).
- [ ] Publicar el par personal corriendo la Action (receta W7) con la regla de versión de §5.3.
- [ ] En la máquina de dev: `omarchy refresh pacman` y verificar con `pacman -Syyu --print` que el par se resuelve desde `[omarchy-personal]`.
- **Criterio de aceptación:** un check dry-run muestra que `omarchy` y `omarchy-settings` "suben" a la versión personal (no a la oficial).

### Etapa 5 — Onboarding de máquinas

- [ ] Redactar y ejecutar el procedimiento de §6 (ISO oficial → confiar clave → bootstrap del par → refresh pacman → `omarchy update` → `omarchy reinstall pkgs` → `omarchy reinstall-configs`).
- [ ] Probar en una segunda máquina piloto.
- [ ] (Opcional, no inventado: con forma de `bin/omarchy-install-*`) un comando de provisioning que automatice los pasos 2–4.
- **Criterio de aceptación:** dos máquinas convergen al mismo estado y `omarchy update` en ambas no reporta diferencias de personalización.

### Etapa 6 — Cadencia de sync con upstream y operación

- [ ] Fijar el procedimiento de sync (receta W9): cada `git fetch upstream` → detectar nuevos tags/releases → rebase de la rama personal → correr la Action (que re-pinea y republica el par).
- [ ] El guard de versión (§5.3) vive como paso de la Action (aborta si el par personal quedó por detrás del stable oficial).
- [ ] Checklist post-sync documentado.
- **Criterio de aceptación:** a lo largo de 2 ciclos de release upstream, las máquinas se mantienen personales, al día y sin pérdida de personalizaciones.

### Etapa 7 — Camino a contribuir

- [ ] Higiene de commits personales (§7.1) para poder PRear features sueltas a `quattro`.
- [ ] (Opcional, plan futuro) ISO propio construido desde el fork para instalaciones 100% desatendidas.
- **Criterio de aceptación:** al menos un cambio del fork portado upstream sin fricción y sin arrastrar el resto de personalizaciones.

## 3. Principios rectores (no negociables)

1. **Nada de inventos.** Antes de crear cualquier mecanismo, buscar si ya existe uno upstream. La tabla canónica es `docs/file-layout.md:341` ("Quick reference: where does X live?"). Si un flujo parece requerir algo nuevo, es señal de que NO estamos siguiendo el modelo upstream y hay que re-preguntar.
2. **Toda personalización es un cambio de fuente** en el fork, con la forma exactamente de un PR aceptable: `applications/`, `config/`, `bin/`, `themes/`, `install/`, `migrations/`, etc. Nunca un script per-máquina suelto.
3. **El par `omarchy`/`omarchy-settings` siempre se publica en lockstep** desde el mismo commit y al mismo `pkgver` (§5.3).
4. **Mantener el repo personal por delante del mirror oficial** en versión para el par; si no, `omarchy update` instalaría el par oficial y borraría personalizaciones.
5. **`/etc/skel` solo siembra usuarios nuevos.** En máquinas con usuarios existentes, materializar con `omarchy refresh ...` / `omarchy reinstall-*`.
6. **No tocar `/usr/share/omarchy/` a mano en ninguna máquina** de forma manual; todo lo que vive ahí lo pone el paquete.
7. Los comandos en `bin/` requieren metadatos `# omarchy:summary=` etc. Ver `agents/skills/command-metadata.md`; `test/cli` valida routing y metadatos.
8. **El pipeline de publicación replica el de upstream (§1.8)** — los mismos scripts `bin/repo build/sign/promote-build/update-repo` y el mismo pin engine `bin/omarchy-pkgs`— y la CI se replica como la de upstream. La única desviación permitida es la capa final de entrega: push a `gh-pages` en vez de `sync-repo`/rclone. Cualquier otra adaptación se justifica y documenta en §1.8 / W7 antes de tocarla.

## 4. Recetas de personalización (flujos exactos, sin adivinar)

Cada receta indica: qué archivos crear, qué comandos correr, y cómo validar. El ciclo de desarrollo iterativo es siempre: **editar fuente → `omarchy dev pkg-test` → refresh del componente → validar**. El ciclo de publicación es la receta W7.

### W1 — Agregar una webapp

1. Crear `applications/<Nombre>.desktop`:

   ```ini
   [Desktop Entry]
   Version=1.0
   Name=<Nombre>
   Exec=omarchy-launch-webapp https://<dominio>/
   Terminal=false
   Type=Application
   Icon=<icon_id>
   StartupNotify=true
   ```

   - El `Exec` puede ser `omarchy-launch-webapp <url>` o un handler propio (ver `applications/HEY.desktop` y `applications/Zoom.desktop` para handlers de esquema).
   - Si maneja un esquema (mailto, zoommtg...), agregar `MimeType=x-scheme-handler/<esquema>` y, si corresponde, registrarlo con `xdg-mime default <Nombre>.desktop <esquema>` (así lo hace `omarchy-provision-user` con HEY).
   - Ejemplos de referencia: `applications/YouTube.desktop`, `applications/X.desktop`.
2. Agregar el icono en `applications/icons/<Nombre>.png` (o `.svg`). El `<icon_id>` usado en `Icon=` es el nombre **minúsculo**, no-alfanuméricos → `-` (lo hace el PKGBUILD con `magick`; ver §1.3). Ej.: `applications/icons/Google Photos.png` → `Icon=google-photos`.
   - Por defecto, `omarchy-webapp-install` (interactivo) NO es el camino para tu fork: el camino es el `.desktop` commiteado.
3. Ciclo dev:
   - `omarchy dev pkg-test` (reconstruye el par dev) — o directamente `omarchy dev pkg-test omarchy-settings`.
   - `omarchy-refresh-applications` → copia los `.desktop` al usuario actual y refresca la base de datos del launcher.
4. **Validar:** el launcher (`Super+Space`) lista la app; abrirla y revisar que la ventana es la webapp frameless y que arranca con `omarchy-launch-webapp`.

OJO (error común): reconstruir el paquete NO materializa el `.desktop` en un usuario que ya existe; hay que correr `omarchy-refresh-applications`.

### W2 — Agregar un comando `omarchy-*`

1. Crear `bin/omarchy-<grupo>-<verbo>` con shebang `#!/bin/bash` y los metadatos `# omarchy:summary=`, `# omarchy:args=`, etc. Seguir **`agents/skills/command-metadata.md`** y las convenciones de estilo de `AGENTS.md` (shell, `[[ ]]`, etc.).
2. Si es un grupo nuevo que los usuarios deben poder descubrir, registrar en `GROUP_DESCRIPTIONS` en `bin/omarchy`. Mientras tanto es valioso mirar cómo está definido cada grupo.
3. El PKGBUILD de `omarchy` captura `bin/*` por globo → **no tocar PKGBUILD**. Rebuild: `omarchy dev pkg-test omarchy`.
4. Escribir/actualizar un test de CLI si corresponde (ver `test/cli` y `test/shell.d/base-test.sh`). Correr los tests del área cambiada antes de publicar (`./test/all`, ver `docs/testing.md`).
5. **Validar:** `omarchy <grupo> <verbo> --help` y la ejecución básica. `pacman -Ql omarchy-dev | grep mi-comando` confirma que quedó instalado en `/usr/bin`.

### W3 — Ejecutables en `~/.local/bin` (la mezcla)

Dos casos, elegidos en el Q&A:

**Caso A — el script encaja como comando del sistema:** publicarlo como `bin/omarchy-*` (W2). Va a `/usr/bin`, en PATH en todas las sesiones, se empaqueta solo, y es directamente contribuible. **Este es el caso recomendado por defecto.**

**Caso B — debe quedarse en `~/.local/bin` (script de usuario):**
1. En el fork fuente, agregar el script bajo `default/local-bin/<nombre>` (nuevo árbol en el fork; mantiene el resto del flujo). El `env-bootstrap` ya agrega `~/.local/bin` al PATH (`docs/file-layout.md`), así que materializado ahí, es ejecutable.
2. En el fork de `omarchy-pkgs`, en el PKGBUILD de `omarchy-settings`, agregar una línea de instalación por archivo, siguiendo el patrón existente de `/etc/skel` (ver cómo se instalan `default/nautilus-python/extensions/*.py`):
   ```bash
   install -Dm755 default/local-bin/<nombre> "$pkgdir/etc/skel/.local/bin/<nombre>"
   ```
   Este es el patrón upstream para archivos de usuario estáticos; no es un invento.
3. Usuarios nuevos lo reciben al crearse. Usuarios existentes: `omarchy reinstall-configs`.
4. **Validar:** en un usuario nuevo (o tras `reinstall-configs`), `<nombre>` resuelve desde el shell.

Alternativa dev (solo dev-link, sin rebuild): con `omarchy dev link`, copiarlo a `~/.local/bin` a mano mientras se itera — pero la fuente de verdad del repo sigue siendo `default/local-bin/`.

### W4 — Modificar configs de usuario (`~/.config`)

1. El archivo vive en `config/<app>/<archivo>` del fork (espeja `~/.config`). Ej.: `config/hypr/bindings.lua`, `config/omarchy/shell.json`.
2. El paquete `omarchy-settings` los siembra a `/etc/skel/.config` (usuarios nuevos) y `/usr/share/omarchy/config` (resync de existentes).
3. Para aplicar a un usuario existente: `omarchy refresh config <relpath>` (p. ej. `omarchy refresh config hypr/bindings.lua`), `omarchy refresh shell`, `omarchy refresh hyprland`, etc. Cada refresh hace backup antes de copiar.
4. Nota: en dev, `omarchy dev link` deja `$OMARCHY_PATH` apuntando al checkout, así que los refresh leen del fork directamente.
5. **Validar:** `hyprctl configerrors` tras tocar hypr; reabrir el bar para shell.json (hot-reload); errores del comando si el refresh falla.

### W5 — Agregar/modificar un tema

1. Tema de stock (para todas las máquinas): crear `themes/<nombre>/` con sus `colors.toml` y, si usa colores temáticos en templates, `default/themed/*.tpl`. El paquete `omarchy` shippea `themes/` → rebuild `omarchy dev pkg-test omarchy`.
2. Aplicar con `omarchy theme set <nombre>`; guard e invalidadción de tema viven en la doc de theming (`docs/theming.md`).
3. Un tema personal que no vas a repartir: `~/.config/omarchy/themes/<nombre>/` (fuera del fork). Como el objetivo es "todas las máquinas idénticas", la norma es: **en el fork**.
4. **Validar:** `omarchy theme set` sin errores y el esquema visual cambia en el bar/ventanas (ver `agents/skills/visual-verification.md`).

### W6 — Set de paquetes del sistema (máquinas idénticas)

1. Agregar/remover paquetes en `install/omarchy-base.packages` (set base) y/o `install/omarchy-other.packages`.
2. La ISO nueva que instale desde el fork pacstraps esas listas. Para **máquinas existentes**:
   - `omarchy reinstall pkgs` instala `--needed` TODO lo listado en `base.packages` y alinea versiones al canal.
   - Un paquete solo desinstalado: `omarchy pkg drop` (o `omarchy pkg drop --list`), pero recordar que si sigue en `base.packages`, `omarchy reinstall pkgs` (o una reinstalación) lo vuelve a traer. Decidir si el paquete "no deseado" sale tambien de la lista del fork.
3. Si el paquete lo hospeda Omarchy/no está en Arch/AUR y querés que entre al flujo oficial, seguí `omarchy-pkgs` (`bin/add-package ... --local`), no inventes un repositorio aparte.
4. **Validar:** `omarchy update` + `omarchy reinstall pkgs` en una máquina y comparar el set con `pacman -Qq` contra otra máquina.

### W7 — Publicar el par personal (la pieza central; GitHub Actions como build host)

Precondiciones: clave GPG existente (`gpg --list-secret-keys`), su privada y passphrase cargadas como **secrets de la repo `omarchy-personal-repo`** con nombres `GPG_PRIVATE_KEY` y `GPG_PASSPHRASE` (los mismos nombres que consume `build/sign.sh` de upstream, §1.8). Forks al día.

El modelo es: la Action replica el pipeline de upstream de punta a punta (`bin/repo`), y su paso final reemplaza `sync-repo`/rclone por un commit+push al branch `gh-pages`. El dueño YA NO publica a mano (el `repo-add`/`gpg` local queda solo como fallback de dev o para depurar).

**Workflow `.github/workflows/release-personal.yml` (job `ubuntu-latest`, `permissions: contents: write`):**

1. **Checkouts** (`actions/checkout@v4`):
   - `<user>/omarchy`, rama `personal` → `./source` (para el pin y el guard de versión).
   - `<user>/omarchy-pkgs`, rama `personal` → `./pkgs`.
   - `<user>/omarchy-personal-repo`, branch `gh-pages` → `./repo` (el árbol de publicación; `OMARCHY_REPO_ROOT`).
2. **Pin del par en lockstep** (replica el release de upstream; `--no-push` porque aquí no hay build host que disparar):
   ```bash
   cd "$GITHUB_WORKSPACE/pkgs"
   OMARCHY_UPSTREAM_URL="https://github.com/<user>/omarchy.git" \
     ./bin/omarchy-pkgs release <vX.Y.Z> --commit "$(git -C "$GITHUB_WORKSPACE/source" rev-parse HEAD)" --no-push --yes
   ```
   `omarchy-pkgs` reescribe ambos PKGBUILDs (mismo `_commit`/`pkgver`/`sha256sums`). Después re-aplicar la **regla §5.3**: pkgrel `99` al pkgver nuevo (el engine lo resetea a 1) e incrementarlo (`99,100,...`) en cada republicación. Commitear el bump de PIN/PKGREL de vuelta a la rama `personal` del fork de pkgs.
3. **Build** (§1.8, con la imagen `MIRROR=stable`): el contenedor resuelve los depends del par contra `pkgs.omarchy.org/stable` gracias al cambio del Dockerfile.
   ```bash
   export OMARCHY_REPO_ROOT="$GITHUB_WORKSPACE/repo"
   rm -rf "$OMARCHY_REPO_ROOT/stable"          # árbol limpio y sin [omarchy] file:// duplicado
   ./bin/repo --local build --mirror stable --arch x86_64 --package omarchy omarchy-settings
   ```
4. **Guard de versión antes de firmar/promover** (§5.3): comparar `vercmp` del pkgver+pkgrel del PKGBUILD contra el pkgver+pkgrel **oficial actual** en `https://pkgs.omarchy.org/stable/x86_64/omarchy.db.tar.zst`; abortar si el personal quedó por detrás.
5. **Firmar** (los env var llegan del runner a Docker, 1:1 con upstream):
   ```bash
   ./bin/repo --local sign --mirror stable --arch x86_64     # usa GPG_PRIVATE_KEY/GPG_PASSPHRASE
   ```
6. **Promover y actualizar la db**:
   ```bash
   ./bin/repo --local promote-build --mirror stable --arch x86_64
   ./bin/repo --local update-repo --mirror stable --arch x86_64     # crea omarchy.db(.tar.zst) + omarchy.files (symlinks)
   ./bin/repo --local clean-repo --mirror stable --arch x86_64      # poda versiones viejas
   ```
7. **Publicar al branch `gh-pages`** (reemplaza `sync-repo` — única desviación, §1.8):
   - En `$OMARCHY_REPO_ROOT/stable/x86_64/`, convertir los symlinks `omarchy.db` y `omarchy.files` en **copias** (GitHub Pages no sirve symlinks) y firmarlas: `gpg --batch --detach-sign --output omarchy.db.sig omarchy.db` (idem `.files`).
   - `git add -A && git commit -m "publish: <versión>` (autor neutral) y `git push origin gh-pages`.
8. **Validar sin tocar el sistema:** en un contenedor throwaway, `curl` de `https://<user>.github.io/omarchy-personal-repo/stable/x86_64/omarchy.db` y de un `.pkg.tar.zst` + `.sig`, y (opcional) `pacman -Syy` contra una lista de repos que incluya `[omarchy-personal]`.

**Trigger:** `workflow_dispatch` (manual), porque la cadencia está atada al sync con upstream (W9), no a un cron. Igual que el cron del host upstream (5 min) no aplica sin VPS, §1.8.

**Fallback de dev (sin Action):** el flujo original sigue sirviendo para iterar — build local con `OMARCHY_SRC` (`cd pkgbuilds/omarchy[-settings] && OMARCHY_SRC=~/Work/omarchy/omarchy-installer makepkg -s --noconfirm`), firmas `gpg --detach-sign`, `repo-add --sign`, nombres estáticos y push a `gh-pages` — pero la fuente de verdad operativa es la Action.

### W8 — Aplicar personalizaciones a una máquina nueva (onboarding)

Máquina x86_64, sin tocar, instalada con la ISO oficial estable de omarchy.org:

1. **Trust de la clave personal:**

   ```bash
   pacman-key --add <clave-personal.asc>
   pacman-key --lsign-key <KEYID-personal>
   ```

2. **Bootstrap del par personal** (hasta que el pacman.conf del sistema tenga el repo): descargar el par `.pkg.tar.zst` (+ `.sig`) del GitHub Pages y `sudo pacman -U` de ambos juntos (misma versión). Con esto el sistema queda en el par personal.
3. **`omarchy refresh pacman`** → copia el `pacman.conf` y mirrorlist **del fork** (que ya incluye `[omarchy-personal]` ANTES de `[omarchy]`), y actualiza. Ahora el repo personal es prioridad.
4. **`omarchy update`** → convergencia completa (paquetes + migraciones + hooks); verifica que `omarchy`/`omarchy-settings` upgraden (el guard §5.3 garantiza que se elijan los personales).
5. **`omarchy reinstall pkgs`** → reconcilia el set con `install/omarchy-base.packages` del fork (máquinas idénticas).
6. **`omarchy reinstall-configs`** (opcional si ya existe el primer usuario, o antes de crear usuarios) → materializa `/etc/skel` personalizado en `$HOME`.
7. **Validar:** `pacman -Q omarchy omarchy-settings` reportan la versión personal; `omarchy-debug --no-sudo --print` sin errores; la webapp de prueba aparece en el launcher; `omarchy version` sin sorpresas.

Nota: los pasos 1–4 son repetibles/automatizables como comando `bin/omarchy-install-*` con la forma de los installers existentes (ej. `omarchy-install-service-tailscale`), NO como script suelto. Dejarlo como mejora de la Etapa 5.

### W9 — Sincronizar el fork con upstream y republicar

Cadencia recomendada: tras cada release upstream (tag `vX.Y.Z` en `quattro`), o cuando `omarchy update` en la máquina dev lo anuncie.

1. En `~/Work/omarchy/omarchy-installer`:
   ```bash
   git fetch upstream
   git rebase upstream/quattro   # sobre la rama personal
   ```
2. Resolver conflictos si los hubiera (idealmente nunca: las personalizaciones deben tocar archivos que upstream no mueve seguido; si un archivo tuyo choca, revisar si tu cambio conviene upstream).
3. Ejecutar los tests (`./test/all`; ver `docs/testing.md`), hacer `git push` de la rama `personal` al fork y **correr la Action de release** (W7) con el `pkgver` del tag recién rebasado. La Action ejecuta el pin en lockstep, el guard de versión y la república en `gh-pages`.
4. Verificación posterior a la republicación (opcional si la Action ya comparó con `vercmp`):
   ```bash
   # en una máquina con ambos repos:
   sudo pacman -Syy --print-format '%r %n %v' 2>/dev/null | grep -E '^(omarchy|omarchy-personal) (omarchy|omarchy-settings)'
   ```
   O más simple: `omarchy update -y` (no preguntar) y luego `pacman -Q omarchy | grep <versión-personal>`.
5. En cada máquina: `omarchy update` (y `omarchy reinstall pkgs` si cambió la lista de paquetes).

### W10 — Migraciones (cambios únicos en máquinas existentes)

Cuando una personalización debe tocar un estado existente (no solo archivos de fuente), el mecanismo upstream son las migraciones: `migrations/<unix-timestamp>.sh`, corren por usuario vía `omarchy-migrate` (marcadores en `~/.local/state/omarchy/migrations/`). Nuevas migraciones siguen **`agents/skills/migrations.md`**. Reglas: idempotentes, corren como el usuario, trabajo privilegiado por helper, una sola reparación por archivo. Se vinculan a versiones de paquete: una máquina que actualiza de tu par viejo al nuevo corre las migraciones nuevas.

## 5. Invariantes de versión y operación

### 5.1 Lockstep del par

`omarchy` depende de `omarchy-settings=${pkgver}` exacto. Nunca publicar un par a distinto `pkgver`. `omarchy-pkgs/bin/omarchy-pkgs release` es el **pin engine** que los reescribe acompasados (mismo `_tag`/`_commit`/`pkgver`/`sha256sums`) — en nuestro flujo lo corre la Action (W7 paso 2), con el `source=` del PKGBUILD apuntando al fork del usuario. Recordar que el engine **resetea `pkgrel` a 1** en cada cambio de pkgver; la regla personal de §5.3 (base alta) se re-aplica después del pin, antes del build.

### 5.2 Prioridad del repo personal

pacman: versión más alta gana; a versión igual, el repo listado primero. `[omarchy-personal]` debe quedar ANTES de `[omarchy]`. La única forma segura de garantizarlo en todas las máquinas es que el `default/pacman/pacman-stable.conf` del fork lleve ese orden (§1.5, W8 paso 3).

### 5.3 La regla del sombreado (crítica)

El mirror oficial `pkgs.omarchy.org/stable` publica el par con versión de release (`4.0.1` etc.). Si el par personal queda **por detrás** en versión, `omarchy update` instala el oficial y **las personalizaciones desaparecen** (el paquete oficial no contiene tus archivos). Por eso:

- `pkgver` personal = al tag upstream base de la rama personal (arriba de él, nunca abajo); lo fija el pin engine en lockstep (W7).
- `pkgrel` personal = **base alta** (p. ej. `99`) y se **incrementa en cada republicación del mismo `pkgver`** (99, 100, 101...), porque:
  - a mismo `pkgver` el pkgrel alto gana y el oficial resetea pkgrel a 1 en cada release (oficial `4.0.1-1` vs personal `4.0.1-99` → gana personal), y
  - el build del pipeline decide "needs build" por diferencia de versión: un cambio de personalización con el mismo `pkgver`-`pkgrel` NO se reconstruiría.
- **Recuperación automática:** si alguna vez las máquinas quedan en el par oficial (v100 lag), al republicar el personal con `pkgver` >= y `pkgrel` creciente, pacman las devuelve al par personal en el próximo `omarchy update`. La única pérdida real es la ventana entre release oficial y republicación personal.
- **Cadencia:** rebase + republicación inmediatamente después de sync (W9). Nunca dejar pasar una release upstream sin republicar.
- **Guard operativo:** la Action aborta si `vercmp` del par personal queda por detrás del stable oficial (W7 paso 4); esto automatiza el check manual de W9.

### 5.4 Signing y keyring

- El repo personal usa la clave propia. Cada paquete firmado (`.sig`), db firmado (`omarchy.db.sig`).
- Máquinas: `pacman-key --add` + `--lsign-key` (W8 paso 1).
- En GitHub Pages, entregar tanto `*.db.tar.zst` como `*.db` y `*.files` (copias, no symlinks) y sus firmas (W7 paso 7).

## 6. Tareas menores aún sin resolver (no bloquean el arranque)

- Nombre del repo host de GitHub Pages (sugerido: `<user>/omarchy-personal-repo`). **CI y canal ya decididos** (Action de release bajo demanda; solo `stable`).
- Cuántas máquinas y si serán todas x86_64 (se asume x86_64; aarch64 es posible con el mismo flujo pero build más lento y QEMU, según README de omarchy-pkgs).
- Convención de commits personales (§7.1) a fijar antes de la Etapa 2.
- Decidir si el `agents_fork.md` se mantiene fuera del árbol que se rebasea contra upstream (recomendación: mantenerlo **fuera de git** del fork, o en un repo de notas privado, para no agregar ruido a futuros PRs). En la máquina de trabajo puede quedar como este archivo, sin commitear.

## 7. Estándares del proyecto personal

### 7.1 Higiene git para contribuir después

- Rama personal con nombre fijo (p. ej. `personal`) arriba de `upstream/quattro`.
- Cada personalización en commits con prefijo identificable (`personal: ...`) y acotados a un solo tema, para poder PRear features a `quattro` con `git cherry-pick <commit>` sin arrastrar el resto.
- Nunca editar el `agents_fork.md` dentro de commits que se pretenden upstream.
- `git rebase upstream/quattro` como única estrategia de sync (sin merges intermedios que ensucien el historial).

### 7.2 Qué NO hacer nunca

- No editar `/usr/share/omarchy/` a mano en máquinas (es propiedad del paquete).
- No crear repos/scripts de instalación sueltos por máquina cuando existe el mecanismo de paquete/refresh.
- No publicar el par a distinto `pkgver`.
- No omitir el guard de versión (§5.3) en la publicación (en operación lo impone la Action, W7 paso 4).
- No reintroducir el flujo de generación de webapps del Omarchy 3 (los `.desktop` estáticos son el mecanismo actual).
- No usar `omarchy-webapp-install` interactivo como fuente de verdad para lo que debe ser reproducible; solo como herramienta puntual dev.
- No "arreglar" `bin/`/`build/` de `omarchy-pkgs` por conveniencia: la única desviación de la maquinaria es el Dockerfile (deps oficiales, §1.8) y la entrega final a `gh-pages` (W7 paso 7); el resto del pipeline debe quedar idéntico a upstream para poder rebasear y contribuir.

## 8. Referencias clave del repo

- `docs/file-layout.md:341` — tabla canónica "where does X live" (mapa repo → sistema).
- `AGENTS.md` — convenciones de estilo, comandos, grupos.
- `agents/skills/command-metadata.md` — agregar/cambiar comandos en `bin/`.
- `agents/skills/migrations.md` — autoría de migraciones.
- `docs/theming.md` — temas, backgrounds, fuentes.
- `docs/testing.md` — suites y cómo correrlas.
- `docs/update-process.md` — pipeline de `omarchy update`, canales, guard de pacman.
- `bin/omarchy-dev-pkg-test` — build/install de paquetes desde checkout local.
- `manual/25-web-apps.md` — documentación de usuario de webapps (los `.desktop` de stock se documentan acá).
- `omarchy-pkgs` (repo forkeado; maquinaria §1.8, 8.1):
  - `bin/repo` — meta-command del pipeline (remote control por SSH; `--local`).
  - `bin/build` + `build/build.sh` — build en Docker; `bin/sign` + `build/sign.sh` — firma con `GPG_PRIVATE_KEY`/`GPG_PASSPHRASE`; `bin/promote-build`, `bin/update-repo` + `build/update-repo.sh`, `bin/clean-repo`.
  - `bin/omarchy-pkgs` — pin engine del par (`release --no-push`, `OMARCHY_UPSTREAM_URL`).
  - `build/Dockerfile` — imagen `omarchy-pkg-builder:latest-<arch>-<mirror>` (única edición permitida: mantener `[omarchy]` oficial para deps).
  - `.github/workflows/{test,sync-aur,sync-upstream,sync-rebuilds}.yml` — CI de upstream a replicar.