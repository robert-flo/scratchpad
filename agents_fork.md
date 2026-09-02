# agents_fork.md — Plan maestro: fork personal de Omarchy

Guía **normativa** para cualquier agente o persona que trabaje en este proyecto. Define la
intención, el modelo mental de cómo funciona Omarchy upstream, la hoja de ruta por etapas y las
**recetas exactas** de cada flujo de personalización. Lectura obligatoria completa antes de tocar
nada; **no adivinar procedimientos**.

**Compañeros de lectura:**

- [`WORKLOG.md`](WORKLOG.md) — la bitácora (qué se hizo y por qué). Este plan es la referencia de **cómo**. Si algo del WORKLOG contradice este archivo, está mal en la bitácora.
- [`README.md`](README.md) — estado resumido hoy y mapa de todos los documentos.
- [`docs/`](docs/) — documentación para usuario final (el "cómo" sin el "porqué").

## Índice

| Sección | Contenido |
|---|---|
| §0 | Encargo, decisiones fijadas y estado |
| §1 | Modelo mental de Omarchy upstream |
| §2 | Hoja de ruta por etapas (roadmap) |
| §3 | Principios rectores |
| §4 | Recetas de personalización (W1–W10) |
| §5 | Invariantes de versión y operación |
| §6 | Tareas menores pendientes |
| §7 | Estándares del proyecto personal |
| §8 | Referencias clave del repo |

---

## 0. Encargo, decisiones y estado

### 0.1 El encargo (por qué existe todo esto)

El dueño usa **N máquinas con Omarchy** instalado desde la ISO oficial de omarchy.org. Quiere que
todas sean **sistemas idénticos, mantenidos automáticamente por `omarchy update`**, con sus
personalizaciones aplicadas por encima de un Omarchy vanilla. La estrategia, acordada en las
conversaciones previas:

1. **Forkear el repo fuente** `omacom/omarchy` y mantenerlo **sync con upstream `quattro`**.
2. **Toda personalización es un cambio de fuente en el fork** (nunca un parche de instalación ni un script suelto por máquina).
3. Aplicarlas **empacadas como paquetes pacman propios**, publicadas en un **repo pacman personal alojado en GitHub Pages**, que las máquinas consumen por el flujo normal `omarchy update`.
4. **Seguir el flujo upstream al pie de la letra**, sin inventar mecanismos: el objetivo secundario es **contribuir de vuelta upstream**, así que cada personalización debe tener la MISMA forma que un cambio aceptable en un PR a `quattro`.

### 0.2 Decisiones ya fijadas (Q&A previo)

- **Hosting del repo pacman personal:** GitHub Pages (repo `<user>/omarchy-personal-repo`, branch `gh-pages`), con **GitHub Actions como build host**: el pipeline de `omarchy-pkgs` (build → sign → promote → clean → update-repo) corre íntegro en el runner de la Action, replicando la maquinaria de upstream. La **única desviación permitida** es la capa final de entrega: push a `gh-pages` en vez de `sync-repo`/rclone (Pages no acepta rclone). Ver §1.8 y W7.
- **Canal a publicar:** solo `stable` (no se replican edge/rc ni el walk de promoción).
- **CI del fork de `omarchy-pkgs`:** replicar los 4 workflows de upstream (`test.yml`, `sync-aur.yml`, `sync-upstream.yml`, `sync-rebuilds.yml`) con ajustes mínimos (§1.8). Como el repo personal solo contiene el par (source local), lo valioso es `test.yml`; los tres de sync quedan inertes salvo que se agreguen paquetes AUR/upstream con personalización local.
- **Ejecutables en `~/.local/bin`:** mezcla — los que encajen como comando del sistema se publican como `omarchy-*` (van a `/usr/bin` solos); los scripts de usuario van a `~/.local/bin` sembrados vía `/etc/skel` desde `omarchy-settings` (W3).
- **Ya existe clave GPG** para firmar el repo de paquetes (y para git).
- **Modelo de repos en máquinas:** sombreado parcial — `[omarchy-personal]` (el par `omarchy` + `omarchy-settings` + extras personales) listado ANTES del `[omarchy]` oficial en `/etc/pacman.conf`. El mirror oficial `pkgs.omarchy.org` sigue proveyendo el resto del ecosistema.

### 0.3 Estado actual (2026-09-01) y próximos pasos

El detalle por sesión está en `WORKLOG.md`; el resumen publicado (versiones, runs, enlaces) en
`README.md`. En una línea:

- **Etapas 0, 3 (W7) y 4 completas** y probadas end-to-end; **cadencia W9 ejecutada**; la repo
  personal quedó **generalizada a `personal: true`** con el PoC `hola-mundo` instalado y mantenido
  por `omarchy update`. Par publicado/instalado en dev: **4.0.2-101**; `hola-mundo` **0.1.0-2**.
- **Próximos pasos** (orden de ejecución; cada uno cierra con su receta `W#` y su entrada en WORKLOG):
  1. ~~Fork `omacom/omarchy-pkgs`~~ **HECHO** (Etapa 0): `robert-flo/omarchy-pkgs`, clone en `~/Work/omarchy/omarchy-pkgs`, remote `upstream` configurado.
  2. ~~Puntar el dev loop al fork~~ **HECHO** (validado `omarchy dev pkg-test` → `dev.<sha>`): PKGBUILDs del fork por layout + `OMARCHY_UPSTREAM_URL=https://github.com/robert-flo/omarchy.git` (sin ella el pin engine usaría el default `basecamp/omarchy.git`); automatizado en `bootstrap-omarchy-dev.sh`.
  3. ~~Etapa 3 / W7 — repo personal~~ **HECHO**: `omarchy-personal-repo` (gh-pages) + Action `release-personal.yml` (run verde inicial `33565145113`).
  4. ~~Etapa 4 — sombreado~~ **HECHO**: `[omarchy-personal]` antes de `[omarchy]` en `default/pacman/pacman-stable.conf` del fork (`1540c220`); par republicado a 4.0.2-100 (run `33571098815`).
  5. ~~Prueba end-to-end en la máquina dev~~ **HECHO** (6ª parte del WORKLOG): instalación desde `[omarchy-personal]`, refresh, `omarchy update -y` RC=0.
  6. **PENDIENTE:** iterar las ~55 webapps del dueño (patrón `webapp-workflow.md`, commit `personal: add <app>` por app); onboarding de máquinas reales (Etapa 5); la cadencia W9 ya se practicó manualmente y queda como operación continua.

---

## 1. Modelo mental de Omarchy upstream (hechos verificados)

Hechos leídos del código; no dan lugar a interpretación.

### 1.1 Dos repositorios, dos paquetes

- **`omacom/omarchy`** — el código fuente: `bin/`, `default/`, `config/`, `applications/`, `themes/`, `shell/`, `migrations/`, `install/`, `docs/`, `manual/`.
- **`omacom/omarchy-pkgs`** — los PKGBUILDs, uno por paquete, bajo `pkgbuilds/<paquete>/` con metadatos en `.omarchy/package.json`; además toda la maquinaria de build/release (`bin/repo`, `bin/omarchy-release`, `bin/omarchy-pkgs`).

Del repo fuente se construyen exactamente **dos** paquetes que se reparten el árbol:

| Paquete | Qué empaqueta | Dónde instala |
|---|---|---|
| `omarchy` | `bin/*` (todo menos `omarchy-debug`, `omarchy-debug-idle`, `omarchy-upload-log`), `install/`, `themes/`, `migrations/`, `shell/`, `version`, hooks de libalpm | `/usr/bin/omarchy-*` + symlinks `/usr/share/omarchy/bin/`, `/usr/share/omarchy/{install,themes,migrations,shell,version}` |
| `omarchy-settings` | `config/`, `default/`, `applications/`, `etc/`, iconos, branding, 3 bins de debug | `/etc/skel/.config`, `/usr/share/omarchy/config`, `/usr/share/omarchy/default`, `/usr/share/omarchy/applications`, `/etc/skel/.local/share/applications`, `/usr/share/icons/hicolor/{48,256}/apps`, `/etc/**` (drop-ins propios), `/usr/bin/omarchy-{debug,debug-idle,upload-log}` |

**Regla de lockstep:** ambos paquetes se construyen SIEMPRE desde el mismo commit de la fuente y
comparten `_tag`/`_commit`/`pkgver`/`sha256sums` idénticos. `omarchy` depende de
`omarchy-settings=${pkgver}` **exacto**; violar esto rompe la instalación. El motor que lo impone
upstream es `bin/omarchy-pkgs release` (§1.8).

### 1.2 El mecanismo de build local (la clave de todo)

```bash
# Con OMARCHY_SRC seteado, source=() queda vacío y se copia todo el checkout del fork.
OMARCHY_SRC=/ruta/al/checkout makepkg -s --skipchecksums
```

La herramienta oficial de dev es `omarchy dev pkg-test` (`bin/omarchy-dev-pkg-test`), que:
lee los PKGBUILDs de `${OMARCHY_PKGBUILDS_DIR:-~/Work/omarchy/omarchy-pkgs/pkgbuilds}/<paquete>/`,
construye `omarchy-dev` y `omarchy-settings-dev` (pkgver=`dev.<short-sha>[.dirty]`) desde el
checkout que se le pase, e instala con `sudo pacman -U --noconfirm --overwrite='*'`. No escribe
ningún PKGBUILD nuevo; es solo la rueda de desarrollo. En sesiones sin TTY hay que réplicarlo con
`pkexec` — ver `bootstrap-omarchy-dev.sh`.

### 1.3 Cómo van las webapps (la evolución que confundía al inicio)

En **Omarchy 3** las webapps se **generaban** por script (`install/packaging/webapps.sh`) y
`omarchy-refresh-applications` creaba `.desktop` sobre la marcha. Ese mecanismo se **eliminó** en
`75cb4f71` ("Make setup ISO-only", mayo 2026).

Desde **quattro**, cada webapp es un **archivo estático commiteado**:

- `applications/<Nombre>.desktop` (p. ej. `applications/YouTube.desktop`).
- Icono en `applications/icons/<Nombre>.png` (o `.svg`).

El PKGBUILD de `omarchy-settings` los captura por **globo**, así que **cualquier `.desktop` o icono
que agregues a la fuente entra al paquete sin tocar el PKGBUILD**:

- `cp -a applications/.` → `/usr/share/omarchy/applications/`
- `applications/*.desktop` → `/etc/skel/.local/share/applications/`
- `applications/icons/*` → con ImageMagick a `hicolor/256x256/apps/<icon_id>.png` y
  `hicolor/48x48/apps/<icon_id>.png`; `icon_id` = nombre **minúsculo con `-` por separador**
  (ej.: `Google Photos.png` → `google-photos`). El `Icon=` del `.desktop` debe usar ese `icon_id`.

`omarchy-refresh-applications` copia `$OMARCHY_PATH/applications/*.desktop` a
`~/.local/share/applications/` y corre `update-desktop-database`. Es lo único que necesita el
launcher para mostrar la app nueva. La receta completa está en W1 y en `webapp-workflow.md`.

### 1.4 Cómo se materializan los configs por usuario

- **`/etc/skel`** solo se siembra al **crear el usuario** (`useradd -m`); cambiar el paquete no toca a usuarios existentes.
- Usuarios existentes resincronizan con:
  - `omarchy refresh config <relpath>` — copia `$OMARCHY_PATH/config/<relpath>` a `~/.config/<relpath>` (con backup).
  - `omarchy refresh shell`, `omarchy refresh hyprland`, etc. — refrescan un componente completo.
  - `omarchy reinstall-configs` — re-copia `/etc/skel` completo sobre `$HOME` (nuclear, destructivo).
- En un install empaquetado, `$OMARCHY_PATH=/usr/share/omarchy`.

### 1.5 Canales y configuración de pacman

- `omarchy-channel-set <stable|rc|edge|dev>` reemplaza `/etc/pacman.conf` y
  `/etc/pacman.d/mirrorlist` por las versiones shippadas en `default/pacman/pacman-<canal>.conf` y
  `default/pacman/mirrorlist-<canal>`, y después instala el par del canal.
- El `pacman-stable.conf` shippado define `[core] [extra] [multilib]` (vía mirrorlist de Arch) y
  `[omarchy] Server = https://pkgs.omarchy.org/stable/$arch`.
- **Consecuencia estratégica:** como el fork shippea `default/pacman/*.conf`, podemos
  repointar/insertar el repo personal **ahí mismo** y `omarchy-refresh-pacman` /
  `omarchy-channel-set` propagarán el cambio a todas las máquinas por el camino oficial. Ese es el
  mecanismo de la Etapa 4.

### 1.6 Set de paquetes del sistema

- `install/omarchy-base.packages` y `install/omarchy-other.packages` son las listas que pacstraps
  la ISO.
- Para reconciliar una máquina existente contra esa lista: `omarchy reinstall pkgs`
  (`bin/omarchy-reinstall-pkgs`) — refresca pacman al canal, hace `pacman -Suu` y luego
  `pacman -Syu --noconfirm --needed $(<omarchy-base.packages)`. **Este es el mecanismo para
  mantener el set de paquetes idéntico entre máquinas.**

### 1.7 Prioridad de repos y firma

- pacman elige la **versión más alta** de un paquete entre todos los repos que lo proveen; a
  **versión igual**, gana el repo **listado primero** en `pacman.conf`.
- El repo oficial se verifica con la clave de `omarchy-keyring` (no disponible para nosotros).
- El repo personal necesita su **propia clave GPG**, que se agrega y firma localmente en cada
  máquina con `pacman-key --add` + `pacman-key --lsign-key`.

### 1.8 La maquinaria de build/release de upstream (`omarchy-pkgs`)

Modelo de ejecución y pipeline que replica la Action (W7):

- **Modelo:** hay un único repository host (VPS propio). `bin/repo` es un meta-command con remote
  control: si existe `OMARCHY_REPO_HOST` o `.repo-host`, corre los comandos publicables en el host
  vía SSH (`bin/repo` :20-58); sin host configurado, todo corre local (`--local` idem). **Nosotros
  no usamos remote control:** en el runner de GitHub Actions no hay `.repo-host`, así que
  `bin/repo` corre local sin cambios.
- **Pipeline** (cada comando usa contenedores Docker de `build/Dockerfile` con
  `--build-arg MIRROR=<canal>`; imagen `omarchy-pkg-builder:latest-<arch>-<mirror>`):
  - `build` (`bin/build` + `build/build.sh`): limpia `build-output/`, construye la imagen y, dentro
    del contenedor, importa claves, `pacman -Syu`, agrega `[omarchy-build] file://build-output`,
    corre makepkg por paquete según `.omarchy/package.json` (`release_ring`/`skip_build`). Determina
    "needs build" comparando versión PKGBUILD vs db local.
  - `sign` (`bin/sign` + `build/sign.sh`): importa la clave de firma desde las env
    `GPG_PRIVATE_KEY` / `GPG_PASSPHRASE` (encajan 1:1 con secrets de una Action) y firma cada
    `.pkg.tar.zst`.
  - `promote-build`: copia `build-output/<mirror>/<arch>` → `pkgs.omarchy.org/<mirror>/<arch>`
    (`REPO_ROOT`; configurable con `OMARCHY_REPO_ROOT`).
  - `update-repo` (`build/update-repo.sh`): `repo-add` de la última versión de cada paquete →
    `omarchy.db.tar.zst` + symlinks `omarchy.db`/`omarchy.files`.
  - `clean-repo`: poda versiones viejas. `advance`/`migrate`: promocionan de edge a rc a stable.
  - `sync-repo` (`bin/sync-repo`): sube el árbol con **rclone** a `pkgs.omarchy.org:omarchy-pkgs`.
    **Única etapa que NO replicamos como está:** Pages es un repo git fijo y no acepta rclone. La
    reemplazamos por commit+push del árbol producido (W7).
  - El orquestador completo es `release` (`bin/release`): build → sign → promote → clean → update →
    sync. En la Action lo descomponemos para reemplazar solo el último paso.
- **Pin del par / release:** los PKGBUILDs del par llevan `pkgver` y `_tag`/`_commit`/`sha256sums`
  idénticas; el `source=` por defecto es `git+https://github.com/<org>/omarchy.git#commit=${_commit}`
  (el PKGBUILD clona el commit pineado; solo con `OMARCHY_SRC` usa checkout local).
  `bin/omarchy-pkgs release` es el **pin engine**: reescribe ambos PKGBUILDs en lockstep, commitea,
  pushea y dispara el build host (`--no-push` para no disparar; `OMARCHY_UPSTREAM_URL` apunta a otro
  remoto). Convención: finales `X.Y.Z` desde tag `vX.Y.Z`; rc pegada `X.Y.ZrcN`; `pkgrel` se
  resetea a 1 en cada cambio de pkgver (nuestra regla personal §5.3 se re-aplica después del pin).
- **Cron del host:** `omarchy-check-versions.timer` + `omarchy-auto-release-<canal>.timer` (cada 5
  min, guard de cola y backoff). En nuestro modelo no aplica (no hay VPS): el equivalente es la
  **Action bajo demanda** tras cada sync con upstream (W9). Las units y comandos asociados se
  conservan en el fork por fidelidad pero no se usan.
- **Detalle crítico para nuestro fork (deps de build):** `build/build.sh` resuelve depends/makedepends
  del par solo contra `[core]/[extra]`, `[omarchy-build]` y `[omarchy] file://FINAL_OUTPUT_DIR`.
  Upstream reconstruye TODO el ecosistema en cada corrida, así el build los encuentra en
  `[omarchy-build]`. Nuestro repo personal NO reconstruye el ecosistema → para resolver
  `quickshell`/`hyprland`/etc. la imagen debe ver el repo **oficial** `pkgs.omarchy.org/stable`.
  `build/Dockerfile` ya agrega esa sección temporalmente y luego la **elimina** (sed final). El único
  cambio FORK documentado a `bin/`/`build/` es **no eliminar esa sección** cuando `MIRROR=stable`
  (replicando exactamente lo que el propio Dockerfile ya escribe). Ver W7 paso 4.

---

## 2. Hoja de ruta: etapas hacia el estado final

Estado final: **en cada máquina, `omarchy update` mantiene el sistema idéntico y personal, sin
intervención manual.** Las etapas son acumulativas; cada una cierra con su criterio de aceptación.

### Etapa 0 — Bootstrap del entorno ✅

- [x] Forks en GitHub: `<user>/omarchy` y `<user>/omarchy-pkgs`.
- [x] Layout local con las rutas default del tool: `~/Work/omarchy/omarchy-installer` (fork fuente,
      rama `personal` sobre `upstream/quattro`) y `~/Work/omarchy/omarchy-pkgs` (fork de pkgs;
      los PKGBUILDs se tocan solo para `source=` al fork y el bump de pin/pkgrel; la maquinaria
      queda intacta, §1.8). Automated en `bootstrap-omarchy-dev.sh`.
- [x] Remotes `upstream` en ambos forks; rama personal creada (§7.1).
- [x] Ciclo dev verificado: `omarchy dev pkg-test` construye e instala el par dev.
- **Criterio de aceptación ✅:** `pacman -Q omarchy-dev omarchy-settings-dev` → `dev.<sha>` y la
  máquina sigue funcional (validado: `dev.0e6c11d5-1`).

### Etapa 1 — Probar el ciclo completo con una webapp mínima

- [ ] Agregar una webapp de prueba al fork (receta W1) → `omarchy dev pkg-test` →
      `omarchy-refresh-applications`.
- **Criterio de aceptación:** aparece en el launcher (`Super+Space`) y abre en ventana webapp frameless.
- *(De facto superado por el POC Xataka; queda formalizar como hito si se quiere.)*

### Etapa 2 — Cosecha de personalizaciones

- [ ] Inventariar cada personalización deseada y portarla a su ubicación en la fuente (W1–W6).
- [ ] Validadas con `omarchy dev pkg-test` + su refresh correspondiente.
- **Criterio de aceptación:** `omarchy reinstall-configs` + `omarchy reinstall pkgs` reproducen el estado deseado completo.

### Etapa 3 — Repo de paquetes personal en GitHub Pages, build host = GitHub Actions ✅

Replica la maquinaria de upstream corriendo entera en una Action; solo cambia el destino final
(gh-pages en vez de rclone). Receta completa en W7.

- [x] Repos en GitHub: `<user>/omarchy-personal-repo` (gh-pages) + forks.
- [x] En `omarchy-pkgs` (rama `personal`): `source=` a `git+https://github.com/<user>/omarchy.git#commit=${_commit}`; `build/Dockerfile` sin eliminar `[omarchy]` en `MIRROR=stable` (§1.8).
- [x] Workflow `release-personal.yml` + secrets (`GPG_PRIVATE_KEY`, `GPG_PASSPHRASE`, `SSH_DEPLOY_KEY`).
- [x] Clave pública en `keys/omarchy-personal-repo.pub.asc` (privada NO versionada).
- [x] Primer run verde (`33565145113`).
- **Criterio de aceptación ✅:** `https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/…` resuelve db firmada (Good signature `D5E75EAC51A44715`), `.sig`, `.files` y los `.pkg.tar.zst` del par (archivos reales, no symlinks).

### Etapa 4 — Sombreado vía el pacman.conf del fork ✅

- [x] `[omarchy-personal]` **antes** de `[omarchy]` en `default/pacman/pacman-stable.conf` (solo
      `stable`): servirá a las máquinas la personalización. La sección NO lleva `SigLevel` propio →
      hereda `Required DatabaseOptional` → **la máquina debe confiar la clave ANTES de
      `omarchy refresh pacman`** (`pacman-key --add` + `--lsign-key`, W8 paso 1).
- [x] República del par por la Action con la regla §5.3 (`99`→`100`; runs con TLS transitorio de
      archlinux.org `33570727843`/`33570965650`, verde `33571098815`).
- [x] **Gotcha de la db por sección:** pacman deriva el nombre de la db de la SECCIÓN
      (`[omarchy-personal]` → `omarchy-personal.db`). El paso de publish publica además los aliases
      `omarchy-personal.db`/`.files` (+ `.sig`) (commit `26e524a`).
- [x] Verificación del sombreado dry-run (`pacman -Su --print` con par stock simulado) y
      **END-TO-END en la máquina dev** (`pacman -S` instaló `omarchy-personal/omarchy 4.0.2-100`;
      `omarchy refresh pacman`; `omarchy update -y` RC=0). Detalles y quirk de `sudo -v` en WORKLOG 6ª parte.
- **Criterio de aceptación ✅:** el par "sube" a la versión personal (no a la oficial) y la máquina dev está convergida vía `omarchy update` normal.

### Etapa 5 — Onboarding de máquinas

- [ ] Procedimiento de §/W8 (ISO oficial → confiar clave → bootstrap del par → refresh pacman →
      `omarchy update` → `reinstall pkgs` → `reinstall-configs`) como documento + prueba en una
      segunda máquina piloto.
- [ ] (Opcional) Comando de provisioning tipo `bin/omarchy-install-*` que automatice los pasos 2–4.
- **Criterio de aceptación:** dos máquinas convergen al mismo estado y `omarchy update` no reporta diferencias de personalización.

### Etapa 6 — Cadencia de sync con upstream y operación ✅ (forma manual)

- [x] Procedimiento de sync (W9) **practicado manualmente**: fetch upstream → rebase → sync de tags
      al fork → re-dispatch de la Action (guard §5.3 incluido) → `omarchy update` en máquinas;
      ciclo verificado en la máquina dev (4.0.2-100 → 4.0.2-101, run `33579948670`).
- [x] Guard de versión §5.3 como paso de la Action (aborta si el par personal quedó detrás del stable oficial).
- [ ] Checklist post-sync formalizado como documento (flujo en WORKLOG 7ª parte).
- **Criterio de aceptación:** a lo largo de 2 ciclos de release upstream, las máquinas se mantienen personales y al día.

### Etapa 7 — Camino a contribuir

- [ ] Higiene de commits personales (§7.1) para PRear features sueltas a `quattro`.
- [ ] (Opcional, futuro) ISO propio construida desde el fork para instalaciones 100% desatendidas.
- **Criterio de aceptación:** al menos un cambio del fork portado upstream sin fricción y sin arrastrar el resto.

---

## 3. Principios rectores (no negociables)

1. **Nada de inventos.** Antes de crear cualquier mecanismo, buscar si ya existe uno upstream (tabla
   canónica: `docs/file-layout.md:341`). Si un flujo parece requerir algo nuevo, es señal de que NO
   estamos siguiendo el modelo upstream y hay que re-preguntar.
2. **Toda personalización es un cambio de fuente** en el fork, con la forma exacta de un PR aceptable
   (`applications/`, `config/`, `bin/`, `themes/`, `install/`, `migrations/`, etc.). Nunca un script per-máquina suelto.
3. **El par `omarchy`/`omarchy-settings` siempre se publica en lockstep** desde el mismo commit y al mismo `pkgver` (§5.1).
4. **Mantener el repo personal por delante del mirror oficial** en versión para el par; si no,
   `omarchy update` instalaría el par oficial y borraría personalizaciones (§5.3).
5. **`/etc/skel` solo siembra usuarios nuevos.** En máquinas con usuarios existentes, materializar con `omarchy refresh ...` / `omarchy reinstall-*`.
6. **No tocar `/usr/share/omarchy/` a mano en ninguna máquina.** Todo lo que vive ahí lo pone el paquete.
7. Los comandos en `bin/` requieren metadatos `# omarchy:summary=` etc. (`agents/skills/command-metadata.md`); `test/cli` valida routing y metadatos.
8. **El pipeline de publicación replica el de upstream (§1.8)** — mismos scripts `bin/repo {build,sign,promote,update,clean}` y mismo pin engine `bin/omarchy-pkgs` — y la CI se replica como la de upstream. Única desviación permitida: la capa final de entrega (push a `gh-pages`). Cualquier otra adaptación se justifica y documenta en §1.8 / W7 antes de tocarla.

---

## 4. Recetas de personalización (flujos exactos)

Ciclo dev iterativo: **editar fuente → `omarchy dev pkg-test` → refresh del componente → validar**.
El ciclo de publicación es W7.

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
   - `Exec` puede ser `omarchy-launch-webapp <url>` o un handler propio (`applications/HEY.desktop`, `applications/Zoom.desktop`).
   - Si maneja un esquema (mailto, zoommtg…): `MimeType=x-scheme-handler/<esquema>` y, si corresponde, `xdg-mime default <Nombre>.desktop <esquema>` (así `omarchy-provision-user` con HEY).
2. Icono en `applications/icons/<Nombre>.png` (o `.svg`); `<icon_id>` = minúsculas + no-alfa → `-` (§1.3).
3. Ciclo dev: `omarchy dev pkg-test omarchy-settings` → `omarchy-refresh-applications`.
4. **Validar:** aparece en el launcher; abre en ventana webapp frameless.

> OJO (error común): reconstruir el paquete NO materializa el `.desktop` en un usuario existente; hay que correr `omarchy-refresh-applications`.

Guía consolidada y porqués: [`webapp-workflow.md`](webapp-workflow.md).

### W2 — Agregar un comando `omarchy-*`

1. Crear `bin/omarchy-<grupo>-<verbo>` con shebang `#!/bin/bash` y metadatos `# omarchy:summary=`, `# omarchy:args=`, etc. Seguir **`agents/skills/command-metadata.md`** y `AGENTS.md`.
2. Si es un grupo nuevo, registrarlo en `GROUP_DESCRIPTIONS` de `bin/omarchy`.
3. PKGBUILD de `omarchy` captura `bin/*` por globo → **no tocar PKGBUILD**. Rebuild: `omarchy dev pkg-test omarchy`.
4. Test de CLI si corresponde (`test/cli`, `test/shell.d/base-test.sh`); correr `./test/all` antes de publicar.
5. **Validar:** `omarchy <grupo> <verbo> --help`; `pacman -Ql omarchy-dev | grep mi-comando`.

### W3 — Ejecutables en `~/.local/bin`

- **Caso A (recomendado por defecto):** si encaja como comando del sistema → publicar como `bin/omarchy-*` (W2). Va a `/usr/bin`, empaquetado solo, contribuible directo.
- **Caso B — script de usuario que debe vivir en `~/.local/bin`:**
  1. Ponerlo en `default/local-bin/<nombre>` (árbol nuevo del fork; `env-bootstrap` ya agrega `~/.local/bin` al PATH).
  2. En el PKGBUILD de `omarchy-settings` agregar, por archivo: `install -Dm755 default/local-bin/<nombre> "$pkgdir/etc/skel/.local/bin/<nombre>"` (patrón existente de `/etc/skel`; p. ej. `default/nautilus-python/extensions/*.py`).
  3. Usuarios nuevos lo reciben al crearse; existentes con `omarchy reinstall-configs`.
  4. **Validar:** el comando resuelve desde el shell en un usuario nuevo (o tras `reinstall-configs`).

Alternativa dev (sin rebuild): `omarchy dev link` y copiar a `~/.local/bin` a mano mientras se itera — la fuente de verdad sigue siendo `default/local-bin/`.

### W4 — Modificar configs de usuario (`~/.config`)

1. El archivo vive en `config/<app>/<archivo>` del fork (espeja `~/.config`), p. ej. `config/hypr/bindings.lua`, `config/omarchy/shell.json`.
2. `omarchy-settings` los siembra a `/etc/skel/.config` (nuevos) y `/usr/share/omarchy/config` (resync).
3. Aplicar a un usuario existente: `omarchy refresh config <relpath>` (p. ej. `hypr/bindings.lua`), `omarchy refresh shell`, `omarchy refresh hyprland`, etc. Cada refresh hace backup antes de copiar.
4. Dev: `omarchy dev link` deja `$OMARCHY_PATH` apuntando al checkout, así los refresh leen del fork.
5. **Validar:** `hyprctl configerrors` (hypr); reabrir el bar para shell.json (hot-reload).

### W5 — Agregar/modificar un tema

1. Stock (todas las máquinas): `themes/<nombre>/` con `colors.toml` y, si usa colores temáticos en templates, `default/themed/*.tpl`. El paquete `omarchy` shippea `themes/` → rebuild `omarchy dev pkg-test omarchy`.
2. Aplicar con `omarchy theme set <nombre>` (ver `docs/theming.md`).
3. Tema personal no repartible: `~/.config/omarchy/themes/<nombre>/` (fuera del fork) — pero la norma es **en el fork** (máquinas idénticas).
4. **Validar:** `omarchy theme set` sin errores y el esquema visual cambia.

### W6 — Set de paquetes del sistema (máquinas idénticas)

1. Agregar/remover en `install/omarchy-base.packages` (set base) y/o `install/omarchy-other.packages`.
2. ISO nueva pacstraps esas listas. Para máquinas existentes: `omarchy reinstall pkgs` instala `--needed` TODO lo listado y alinea versiones al canal. Un paquete solo desinstalado: `omarchy pkg drop`, pero si sigue en `base.packages` volverá — decidir si además sale de la lista del fork.
3. Si el paquete no está en Arch/AUR y quiere entrar al flujo oficial: seguir `omarchy-pkgs` (`bin/add-package ... --local`), no inventar un repo aparte.
4. **Validar:** `omarchy update` + `omarchy reinstall pkgs` y comparar `pacman -Qq` entre máquinas.

### W7 — Publicar paquetes personales (la pieza central; GitHub Actions como build host)

**ESTADO: IMPLEMENTADA, VERIFICADA Y GENERALIZADA (2026-09-01).** Desde la 8ª parte la Action **ya
no hardcodea el par**: publica **todos** los PKGBUILD con `"personal": true` en su
`.omarchy/package.json`. Esta receta refleja el estado actual; el proceso de llegada (borradores y
desviaciones) está en WORKLOG 4ª parte (versión original) y 8ª parte (generalización).

Precondiciones verificadas: clave GPG dedicada (keyid `D5E75EAC51A44715`, **sin passphrase**); los
secrets `GPG_PRIVATE_KEY`, `GPG_PASSPHRASE="unused"` y `SSH_DEPLOY_KEY` (deploy key **write** a
`omarchy-personal-repo`, porque el `GITHUB_TOKEN` del huésped no escribe en otro repo) viven en
**`<user>/omarchy-pkgs`** (donde corre la Action), no en `omarchy-personal-repo`. El workflow se
commitea en la rama `personal` **y una copia de registro en `master`** (GitHub exige el workflow en
la rama default para `workflow_dispatch` por API).

> **CRÍTICO — dispatch SIEMPRE con `--ref personal`:** sin él GitHub usa el workflow de la rama por
> defecto (`master`), que es la copia de registro SIN la generalización (lo demostró el run
> `33582420572`, que republicó el par sin `hola-mundo`).

**El modelo:** la Action replica el pipeline de upstream de punta a punta (`bin/repo`) y su paso
final reemplaza `sync-repo`/rclone por un commit+push al branch `gh-pages`. El dueño YA NO publica a mano.

1. **Checkouts** (`actions/checkout@v4`): `omarchy@personal`→`./source`,
   `omarchy-pkgs@personal`→`./pkgs`, `omarchy-personal-repo@gh-pages`→`./repo` (con
   `ssh-key: ${{ secrets.SSH_DEPLOY_KEY }}`).
2. **Pin del par en lockstep** dentro de **`archlinux:base-devel`** como **no-root** (el runner no
   trae `vercmp`/`makepkg`; makepkg rechaza root): `./bin/omarchy-pkgs release <vX.Y.Z> --commit <sha>
   --no-push --yes` por un usuario `builder` (`su builder -c`, checkout montado, `chmod -R a+rwX /pkgs`,
   `safe.directory`). Re-aplicar la **regla §5.3** (`pkgrel=99` + incremento por republicación) **solo
   al subconjunto `pinned`** (el par) y commitear el pin a `personal`.
3. **Guard §5.3** antes de buildar: `vercmp` (contenedor Arch) del pkgver+pkgrel del PKGBUILD contra
   el oficial actual en `pkgs.omarchy.org/stable/x86_64/omarchy.db.tar.zst`.
4. **Recolección del conjunto `personal: true`** y **Build** con imagen `MIRROR=stable`:
   ```bash
   export OMARCHY_REPO_ROOT="$GITHUB_WORKSPACE/repo"
   rm -rf "$OMARCHY_REPO_ROOT/stable"
   # un-pin temporal LOCAL (no se commitea) SOLO al subconjunto pinned (el par)
   for p in $PINNED_PERSONAL_PKGS; do jq '.pinned = false' "pkgbuilds/$p/.omarchy/package.json" > t && mv t "pkgbuilds/$p/.omarchy/package.json"; done
   ./bin/repo --local build --mirror stable --arch x86_64 --package $PERSONAL_PKGS
   ```
   La Action deriva `PERSONAL_PKGS`/`PINNED_PERSONAL_PKGS` con jq sobre todos los `pkgbuilds/*/`.
   **Delta FORK clave:** los paquetes `pinned:true` NUNCA buildan nativo a stable por diseño
   (`package_builds_for_mirror`, `helpers/package-metadata.sh`) y `--mirror stable` además exige
   `release_ring=fast`. La solución no es buildar edge→advance (el repo personal no reconstruye el
   ecosistema): es el **un-pin temporal local** (`pinned:false` vía jq, sin commitear) y buildar
   stable directo, con deps resueltas contra `pkgs.omarchy.org/stable` (el Dockerfile del fork
   mantiene ese `[omarchy]` remoto en `MIRROR=stable`). También fue necesario `chmod -R a+rwX` en
   `make_dir_writable` (`helpers/docker-helpers.sh`): el contenedor corre `makepkg`/`repo-add` como
   `builder` (uid 1000) y el runner no-root solo con chown no alcanza (fallaba
   "database file for 'omarchy-build' does not exist").
5. **Firmar** (1:1 con upstream): `./bin/repo --local sign --mirror stable --arch x86_64`.
6. **Promover, db y poda** (subcomandos reales de `bin/repo`, no los suffixes `-build`/`-repo`):
   `promote`, luego `update`, luego `clean`.
7. **Publicar a `gh-pages`** (única desviación operativa, §1.8): resolver symlinks de la db a copias
   reales (`cp -L "$(dirname "$f")/$(readlink "$f")"`, readlink es relativo) y firmarlas (`*.sig`).
   **Aliases de sección (Etapa 4):** publicar también `omarchy-personal.db`/`.files` (+ `.sig`)
   — pacman deriva el nombre de db de la sección. `git add -A && git commit -m "publish: <v>";
   git push origin gh-pages` (guard: si no hay cambios, saltar el commit).
8. **Validar** con `curl` a `https://<user>.github.io/omarchy-personal-repo/stable/x86_64/…`.
   **Delta:** la validación recorre TODOS los `PERSONAL_PKGS` y deriva el nombre del `.pkg.tar.zst`
   desde el árbol publicado (`ls repo/stable/x86_64/<pkg>*.pkg.tar.zst`), NO desde el input
   `version` (que lleva `v`, y el filename no). Dar margen amplio a que Pages deploye (60×20 s si hace falta).

**Trigger:** `workflow_dispatch` (manual), atado a la cadencia de sync (W9). Re-publicación típica:

```bash
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v4.0.2 -f pkgrel=101
```

> ⚠️ `pkgrel` (§5.3): `99` + 1 por cada republicación del **mismo** `pkgver` (99→100→101…). Aplicado
> solo al par (subconjunto `pinned`); un paquete genérico usa el pkgrel de su PKGBUILD.

**Ciclo de vida de un paquete personal (8ª parte — qué publica y cómo llega a las máquinas):**

- `omarchy update` hace `pacman -Syu` (+AUR `yay -Sua` + mise): **actualiza** los paquetes ya
  instalados, **NO instala** paquetes nuevos no presentes. Un paquete personal nuevo se instala
  **una vez** en cada máquina con `pacman -S <pkg>` (resuelto desde `[omarchy-personal]`); a partir
  de ahí `omarchy update` lo mantiene (verificado: `hola-mundo` instalado `0.1.0-1`, mantenido
  `0.1.0-1 → 0.1.0-2`).
- **Añadir un paquete personal futuro:** crear `pkgbuilds/<pkg>/PKGBUILD` + `.omarchy/package.json`
  con `source: local`, `release_ring: fast` y `"personal": true`; commit + push a `personal`;
  re-dispatch de la Action (`--ref personal`). La máquina que lo tenga instalado lo mantendrá.
- **Reconciliar el set entre máquinas:** `omarchy reinstall pkgs` (lee `omarchy-base.packages` del
  fork, §1.6). Si un paquete personal debe estar en TODAS las máquinas desde el onboarding, añadirlo
  también a `install/omarchy-base.packages` del fork fuente.

**Fallback de dev (sin Action):** el flujo original sigue sirviendo para iterar — build local con
`OMARCHY_SRC`, firmas `gpg --detach-sign`, `repo-add --sign`, push manual a `gh-pages` — pero la
fuente de verdad operativa es la Action.

### W8 — Aplicar personalizaciones a una máquina nueva (onboarding)

Máquina x86_64 sin tocar, instalada con la ISO oficial estable de omarchy.org (version usuario-final en `docs/02-instalar-una-maquina.md`):

1. **Trust de la clave personal:**
   ```bash
   pacman-key --add <clave-personal.asc>
   pacman-key --lsign-key <KEYID-personal>   # D5E75EAC51A44715
   ```
2. **Bootstrap del par personal** (hasta que el pacman.conf del sistema incluya el repo): descargar
   el par `.pkg.tar.zst` (+ `.sig`) del GitHub Pages y `sudo pacman -U` de ambos juntos (misma
   versión). El sistema queda en el par personal.
3. **`omarchy refresh pacman`** → copia el `pacman.conf` y mirrorlist **del fork** (ya con
   `[omarchy-personal]` ANTES de `[omarchy]`) y actualiza; el repo personal pasa a prioridad.
4. **`omarchy update`** → convergencia completa (paquetes + migraciones + hooks). El guard §5.3
   garantiza que se elijan los personales. **Nota 8ª parte:** `omarchy update` hace `pacman -Syu` y
   **actualiza** lo ya instalado, NO instala paquetes nuevos; los extras personales (p. ej.
   `hola-mundo`) se instalan una vez con `pacman -S <pkg>`.
5. **`omarchy reinstall pkgs`** → reconcilia el set con `install/omarchy-base.packages` del fork
   (si un personal debe estar en todas, añadirlo a esa lista).
6. **`omarchy reinstall-configs`** (opcional; antes de crear usuarios) → materializa `/etc/skel` personalizado.
7. **Validar:** `pacman -Q omarchy omarchy-settings` reportan la versión personal;
   `omarchy-debug --no-sudo --print` sin errores; la webapp de prueba aparece en el launcher.

Nota: los pasos 1–4 son repetibles/automatizables como comando `bin/omarchy-install-*` (forma de los
installers existentes, ej. `omarchy-install-service-tailscale`), NO como script suelto. Mejora de la Etapa 5.

### W9 — Sincronizar el fork con upstream y republicar

Cadencia recomendada: tras cada release upstream (tag `vX.Y.Z` en `quattro`), o cuando `omarchy
update` en la máquina dev lo anuncie. (Versión operativa "cómo" en `docs/05-mantener.md`.)

1. En `~/Work/omarchy/omarchy-installer`:
   ```bash
   git fetch upstream
   git rebase upstream/quattro      # sobre la rama personal
   ```
2. Resolver conflictos si los hubiera (idealmente nunca: las personalizaciones deben tocar archivos
   que upstream no mueve seguido; si uno tuyo choca, revisar si tu cambio conviene upstream).
3. Correr `./test/all` (ver `docs/testing.md`), `git push` de `personal` al fork y **correr la Action
   de release** (W7) con el `pkgver` del tag recién rebasado (la Action re-pinea en lockstep, corre
   el guard §5.3 y república).
4. Verificación posterior (opcional si la Action ya comparó con `vercmp`):
   ```bash
   sudo pacman -Syy --print-format '%r %n %v' 2>/dev/null | grep -E '^(omarchy|omarchy-personal) (omarchy|omarchy-settings)'
   ```
   O más simple: `omarchy update -y` y luego `pacman -Q omarchy | grep <versión-personal>`.
5. En cada máquina: `omarchy update` (y `omarchy reinstall pkgs` si cambió la lista de paquetes).

### W10 — Migraciones (cambios únicos en máquinas existentes)

Cuando una personalización debe tocar un **estado existente** (no solo archivos de fuente), el
mecanismo upstream son las migraciones: `migrations/<unix-timestamp>.sh`, corren por usuario vía
`omarchy-migrate` (marcadores en `~/.local/state/omarchy/migrations/`). Seguir
**`agents/skills/migrations.md`**. Reglas: idempotentes, corren como el usuario, trabajo privilegiado
por helper, una sola reparación por archivo. Se vinculan a versiones de paquete: una máquina que
actualiza de tu par viejo al nuevo corre las migraciones nuevas.

---

## 5. Invariantes de versión y operación

### 5.1 Lockstep del par

`omarchy` depende de `omarchy-settings=${pkgver}` **exacto**. Nunca publicar la pareja a distinto
`pkgver`. `omarchy-pkgs/bin/omarchy-pkgs release` es el **pin engine** que los reescribe acompasados
(mismo `_tag`/`_commit`/`pkgver`/`sha256sums`) — en nuestro flujo lo corre la Action (W7 paso 2),
con el `source=` del PKGBUILD apuntando al fork del usuario. Recordar que el engine **resetea
`pkgrel` a 1** en cada cambio de pkgver; la regla personal §5.3 se re-aplica después del pin, antes del build.

### 5.2 Prioridad del repo personal

pacman: versión más alta gana; a versión igual, el repo listado primero. `[omarchy-personal]` debe
quedar ANTES de `[omarchy]`. La única forma segura de garantizarlo en todas las máquinas es que el
`default/pacman/pacman-stable.conf` del fork lleve ese orden (§1.5, W8 paso 3, Etapa 4).

### 5.3 La regla del sombreado (crítica)

El mirror oficial `pkgs.omarchy.org/stable` publica el par con versión de release (`4.0.1` etc.). Si
el par personal queda **por detrás** en versión, `omarchy update` instala el oficial y **las
personalizaciones desaparecen** (el paquete oficial no contiene tus archivos). Por eso:

- `pkgver` personal = al tag upstream base de la rama personal (arriba de él, nunca abajo); lo fija el pin engine en lockstep (W7).
- `pkgrel` personal = **base alta** (p. ej. `99`) y se **incrementa en cada republicación del mismo
  `pkgver`** (99, 100, 101…), porque:
  - a mismo `pkgver` el pkgrel alto gana (oficial `4.0.1-1` vs personal `4.0.1-99` → gana personal), y
  - el build del pipeline decide "needs build" por diferencia de versión: un cambio de personalización
    con el mismo `pkgver`-`pkgrel` NO se reconstruiría.
- **Recuperación automática:** si alguna vez las máquinas quedan en el par oficial (lag), al
  republicar el personal con `pkgver >=` y `pkgrel` creciente, pacman las devuelve al par personal en
  el próximo `omarchy update`. La única pérdida real es la ventana entre release oficial y
  republicación personal.
- **Cadencia:** rebase + republicación inmediatamente después de sync (W9).
- **Guard operativo:** la Action aborta si `vercmp` del par personal queda por detrás del stable
  oficial (W7 paso 3); automatiza el check manual de W9.

### 5.4 Signing y keyring

- El repo personal usa la clave propia (`D5E75EAC51A44715`); cada paquete firmado (`.sig`), db firmada (`omarchy.db.sig`).
- Máquinas: `pacman-key --add` + `--lsign-key` (W8 paso 1).
- En GitHub Pages, entregar tanto `*.db.tar.zst` como `*.db` y `*.files` (copias, no symlinks) y sus firmas (W7 paso 7).

---

## 6. Tareas menores sin resolver (no bloquean el arranque)

- Nombre del repo host de GitHub Pages — **ya decidido en la práctica**: `robert-flo/omarchy-personal-repo`.
- Cuántas máquinas y si serán todas x86_64 (se asume x86_64; aarch64 posible con el mismo flujo pero build más lento y QEMU).
- Convención de commits personales (§7.1) a fijar como práctica (prefijo `personal: ` ya en uso).
- Decidir si `agents_fork.md` se mantiene fuera del árbol que se rebasea contra upstream (recomendación: mantenerlo fuera de git del fork o en un repo de notas privado). Aquí vive en el repo de notas, sin commitear en el fork.
- (8ª parte) Decidir si `hola-mundo` (PoC) se retira o pasa a `omarchy-base.packages` del fork para onboarding.

---

## 7. Estándares del proyecto personal

### 7.1 Higiene git para contribuir después

- Rama personal con nombre fijo (`personal`) arriba de `upstream/quattro`.
- Cada personalización en commits con prefijo identificable (`personal: …`) y acotados a un solo tema,
  para poder PRear features a `quattro` con `git cherry-pick <commit>` sin arrastrar el resto.
- Nunca editar `agents_fork.md` dentro de commits que se pretendan upstream.
- `git rebase upstream/quattro` como única estrategia de sync (sin merges intermedios que ensucien el historial).

### 7.2 Qué NO hacer nunca

- No editar `/usr/share/omarchy/` a mano en máquinas (es propiedad del paquete).
- No crear repos/scripts de instalación sueltos por máquina cuando existe el mecanismo de paquete/refresh.
- No publicar el par a distinto `pkgver`.
- No omitir el guard de versión (§5.3) en la publicación (en operación lo impone la Action, W7 paso 3).
- No reintroducir el flujo de generación de webapps del Omarchy 3 (los `.desktop` estáticos son el mecanismo actual).
- No usar `omarchy-webapp-install` interactivo como fuente de verdad de lo reproducible; solo como herramienta puntual dev.
- No "arreglar" `bin/`/`build/` de `omarchy-pkgs` por conveniencia: las únicas desviaciones de la
  maquinaria son el Dockerfile (deps oficiales, §1.8) y la entrega final a `gh-pages` (W7 paso 7); el
  resto del pipeline debe quedar idéntico a upstream para poder rebasear y contribuir.

---

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
- `omarchy-pkgs` (repo forkeado; maquinaria §1.8):
  - `bin/repo` — meta-command del pipeline (remote control por SSH; `--local`).
  - `bin/build` + `build/build.sh` — build en Docker; `bin/sign` + `build/sign.sh` — firma con `GPG_PRIVATE_KEY`/`GPG_PASSPHRASE`; `bin/promote-build`, `bin/update-repo` + `build/update-repo.sh`, `bin/clean-repo`.
  - `bin/omarchy-pkgs` — pin engine del par (`release --no-push`, `OMARCHY_UPSTREAM_URL`).
  - `build/Dockerfile` — imagen `omarchy-pkg-builder:latest-<arch>-<mirror>` (única edición permitida: mantener `[omarchy]` oficial para deps, §1.8).
  - `.github/workflows/{test,sync-aur,sync-upstream,sync-rebuilds}.yml` — CI de upstream a replicar.
  - `.github/workflows/release-personal.yml` — nuestra Action de release (W7).