# webapp-workflow.md — Cómo trabajamos las webapps del fork

Referencia de cómo se agrega una webapp al fork de Omarchy y se replica la instalación
en una máquina. Sirve para recordar el mecanismo aunque pasen semanas. La bitácora paso a
paso del primer ciclo (Xataka, sesión 2026-08-30) está en `WORKLOG.md`; acá está la guía
consolidada y el porqué.

---

## 1. Concepto clave: en Omarchy las webapps viven dentro del paquete

Omarchy instalado se compone de **dos paquetes**:

- `omarchy` (motor) — comandos y scripts (`/usr/bin/omarchy-*`).
- `omarchy-settings` (archivos) — configs de usuario, webapps, font/support helpers.

Las **webapps NO son accesos que se agregan a mano en el menú**: son archivos `.desktop`
que viajan *dentro del paquete* `omarchy-settings`. En el repo del fork viven en:

- `applications/<Nombre>.desktop` — el lanzador.
- `applications/icons/<Nombre>.png` — el icono (196×196 o similar, PNG o SVG).

Al construir el paquete, el PKGBUILD se encarga de:

1. Copiar los `.desktop` a `/usr/share/omarchy/applications/` (de ahí
   `omarchy-refresh-applications` los copia a `~/.local/share/applications/`, la carpeta
   que ve el lanzador del usuario).
2. Convertir el icono con `magick` a los tamaños estandar hicolor
   `/usr/share/icons/hicolor/{256,48}x{256,48}/apps/<icon_id>.png`, donde el `icon_id` es
   el nombre sin extensión en **minúsculas y con los no-alfanuméricos convertidos a guion**
   (Xataka.png → `xataka`).
3. También siembra los `.desktop` en `/etc/skel/.local/share/applications/` para usuarios
   nuevos.

El `Exec=` del `.desktop` apunta al launcher de webapps de Omarchy:
`omarchy-launch-webapp <URL>`, que abre el navegador por defecto en **modo app**
(ventana sin barra de navegación) vía `uwsm-app -- <browser> --app=<url>`.
Browsers soportados por el launcher: google-chrome, brave, microsoft-edge, opera,
vivaldi, helium (si el navegador por defecto no está en la lista, cae a chromium).

## 2. El `.desktop` (plantilla usando Xataka)

```desktop
[Desktop Entry]
Version=1.0
Name=Xataka
Exec=omarchy-launch-webapp https://www.xataka.com/
Terminal=false
Type=Application
Icon=xataka
StartupNotify=true
```

Formato: `Name` = nombre visible, `Icon` = icon_id derivado del nombre del PNG, `Exec` =
`omarchy-launch-webapp <URL>`. Eso es todo lo que se toca en el repo para agregar una app.

## 3. Qué cambió entre el fork y el cambio (primer POC)

Nuestra rama `personal` es idéntica a la oficial `quattro` salvo por los commits
"personal:" propios. El commit del POC (`89759761`) agregó exactamente 2 archivos nuevos,
8 líneas:

```
applications/Xataka.desktop        | 8 +++++++++
applications/icons/Xataka.png      | nuevo (3 KB)
```

**Nada del código original de Omarchy fue modificado.** La rama personal sigue la rama
quattro y se actualiza con upstream periódicamente; los cambios personales van en commits
`personal: ...` para poder distinguirlos de las sincronizaciones con upstream.

## 4. El ciclo completo (build + install + refresh)

1. **Fork**: `robert-flo/omarchy`, rama `personal` sobre `upstream/quattro`.
2. **Build**: desde el commit del fork se construye el par "dev"
   (`omarchy-*-dev dev.<sha8>`). El sha en la versión del paquete da trazabilidad: sabés
   de qué commit del fork vino lo instalado.
3. **Instalación**: reemplaza los paquetes oficiales en la máquina (la máquina queda en
   "línea dev" — `omarchy update` normal no aplica hasta reinstalar stock).
4. **Refresh**: `omarchy-refresh-applications` materializa los `.desktop` en
   `~/.local/share/applications/` (idempotente).
5. **Verificación**: `omarchy-launch-webapp <URL>` abre la ventana modo app; se puede
   confirmar con `hyprctl clients -j` (clase `chrome-<dominio>__-Default`).

## 5. Comandos para agregar una webapp nueva (partiendo de una máquina ya en línea dev)

Desde la terminal del usuario (con tty):

```bash
cd ~/Work/omarchy/omarchy-installer

# 1) crear la webapp (plantilla = Xataka en el §2):
#    applications/<Nombre>.desktop   →  Exec=omarchy-launch-webapp <URL>
#    applications/icons/<Nombre>.png

# 2) commit + push
git add applications/<Nombre>.desktop applications/icons/<Nombre>.png
git commit -m "personal: add <Nombre> webapp"
git push origin personal

# 3) build + instala (te pide tu contraseña)
omarchy dev pkg-test omarchy-settings

# 4) materializar lanzador en la sesión y probar
omarchy-refresh-applications
omarchy-launch-webapp https://<url>
```

> Nota: como la máquina ya está en línea dev, instalar el paquete `omarchy-settings-dev`
> nuevo es una **actualización** normal (mismo pkgname), sin conflictos. El único caso
> conflictivo fue la transición inicial stock → dev, resuelta con `--ask 4` (ver §6).

Sin terminal (agentes o automatización) — misma operación a mano:

```bash
SHA=$(git -C ~/Work/omarchy/omarchy-installer rev-parse --short HEAD)
DIR=$(mktemp -d -t omarchy-settings-dev.XXXXXX)
cp -a "$HOME/Work/omarchy/omarchy-pkgs/pkgbuilds/omarchy-settings-dev/." "$DIR/"
awk '/^pkgver\(\)[[:space:]]*\{/{in_pkgver=1;depth=0} in_pkgver{line=$0;o=gsub(/\{/,"{",line);line=$0;c=gsub(/\}/,"}",line);depth+=o-c;if(depth<=0){in_pkgver=0};next} {print}' "$DIR/PKGBUILD" > "$DIR/PKGBUILD.t" && mv "$DIR/PKGBUILD.t" "$DIR/PKGBUILD"
sed -i "s/^pkgver=.*/pkgver=dev.$SHA/" "$DIR/PKGBUILD"
( cd "$DIR" && OMARCHY_SRC="$HOME/Work/omarchy/omarchy-installer" makepkg --skipchecksums --noconfirm )
pkexec pacman -U --noconfirm --overwrite='*' "$DIR"/omarchy-settings-dev-*.pkg.tar.zst
omarchy-refresh-applications
```

## 6. Detalles que conviene no olvidar

- **Escalación sin terminal**: la regla del SKILL de Omarchy es `sudo` si hay terminal,
  **`pkexec`** si no (abre diálogo gráfico de contraseña). Si `pkexec` falla por no haber
  agente polkit, el comando debe correr desde la terminal gráfica del usuario.
- **Transición stock → dev (una sola vez)**: `omarchy-settings-dev` conflictúa con
  `omarchy-settings` oficial, y `omarchy` 4.0.1 exige `omarchy-settings=4.0.1` (dep con
  versión). No puede instalarse uno solo. Se instala **el par completo de una vez** con
  `--ask 4` (responde "sí" al reemplazo de los paquetes oficiales — mismo mecanismo que
  usa el wrapper del contenedor de build de upstream):

  ```bash
  pkexec pacman -U --ask 4 --noconfirm --overwrite='*' \
    omarchy-settings-dev-*.zst omarchy-dev-*.zst
  ```

- **`pkgver()` en PKGBUILDs dev**: la función recalcula la versión con git en build; para
  fijar `dev.<sha>` hay que quitarla con el awk anterior (que es exactamente lo que hace
  `omarchy dev pkg-test` por dentro), y luego `sed` fijar `pkgver`.
- **`makepkg -s` no resuelve `omarchy-settings-dev`** al construir `omarchy-dev` (todavía
  no está instalado) → construir `omarchy-dev` con `--nodeps --skipchecksums`; las deps
  runtime se validan en la instalación conjunta.
- **Paths del dev loop**: `~/Work/omarchy/omarchy-installer` (fork, rama personal) y
  `~/Work/omarchy/omarchy-pkgs` (pkgs, de momento clone de upstream). El tool
  `omarchy dev pkg-test` usa esas rutas por valor; no cambiarlas sin parchear el tool.
  Ojo en sesiones de agente: `command -v omarchy` puede apuntar a otro checkout; usar
  `/usr/bin/omarchy` o la ruta del dev instalado.

## 7. Estado al cierre de esta guía (2026-08-30)

- Fork: `robert-flo/omarchy`, rama `personal` en `89759761` ("personal: add Xataka webapp (POC)").
- Máquina: `omarchy-dev` + `omarchy-settings-dev` `dev.89759761-1` (línea dev).
- POC verificado: ventana Chrome modo app con Xataka (`chrome-www.xataka.com__-Default`).
- Pendiente: iterar las ~55 webapps del dueño con este mismo patrón; luego el repo pacman
  personal (Etapa 3 — ver `agents_fork.md`).