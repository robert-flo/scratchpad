# build-install-cycle.md — El ciclo build → instalación explicado a fondo

Explicación detallada de dos pasos del flujo dev: **2) Build** y **3) Instalación**.
Complementa a `webapp-workflow.md` (guía condensada) y a `WORKLOG.md` (bitácora). Acá está
el "cómo funciona por dentro", para revisar cuando se necesite entender la mecánica o
explicarla a alguien más.

---

## Paso 2 — Build (de dónde sale el paquete y por qué lleva el sha)

### Qué es un PKGBUILD

Un **PKGBUILD** es la "receta" que lee `makepkg` (el constructor de paquetes de Arch)
para producir un archivo `.pkg.tar.zst` — el equivalente al "deb" de Debian: un archivo
comprimido con todos los archivos listos para copiarse al sistema. En nuestro caso:

- `omarchy-pkgs/pkgbuilds/omarchy-settings-dev/PKGBUILD` → produce `omarchy-settings-dev`
- `omarchy-pkgs/pkgbuilds/omarchy-dev/PKGBUILD` → produce `omarchy-dev`

Cada receta define: de dónde sale el código, cómo es procesado, y qué archivos se instalan.

### De dónde sale el código: el truco de `OMARCHY_SRC`

La receta dev tiene `source=()` **vacío**; cuando está seteada la variable `OMARCHY_SRC`,
`makepkg` **copia todo el checkout de git indicado** dentro del directorio de build. O sea:
el contenido de nuestro fork en ese commit (rama `personal`, incluida la webapp) **es** el
material del paquete. Se le pasa:

```bash
OMARCHY_SRC="$HOME/Work/omarchy/omarchy-installer"   # nuestro checkout del fork
```

Consecuencia importante: lo que se agregue al fork aparece en el sistema sin pasos
intermedios de copia de archivos.

### La versión: por qué el nombre dice `dev.<sha8>`

El PKGBUILD dev tiene una función **`pkgver()`** que, al compilar, recalcula la versión en
vivo con `git describe` del checkout. El tool oficial (`omarchy dev pkg-test`) la neutraliza
en dos pasos y nosotros replicamos exactamente eso:

1. **Quitar la función `pkgver()`** con un awk (si no, sobrescribe lo que pongamos).
2. **Fijar** `pkgver=dev.<sha8>` con el commit corto del fork:

```bash
SHA=$(git -C ~/Work/omarchy/omarchy-installer rev-parse --short HEAD)   # → 89759761
sed -i "s/^pkgver=.*/pkgver=dev.$SHA/" "$DIR/PKGBUILD"
```

Resultado: `omarchy-settings-dev-dev.89759761-1-any.pkg.tar.zst`. Tres razones de esa versión:

- **Trazabilidad**: el paquete instalado dice exactamente qué commit del fork lo construyó
  (`pacman -Q omarchy-settings` → `dev.89759761-1`).
- **Orden de versiones**: pacman compara segmentos numéricos numéricamente y segmentos con
  letras lexicalmente; un segmento con letras (`dev`) ordena *después* de uno numérico
  (`4.0.0…`), así que la versión dev se ve "más nueva" y reemplaza/actualiza limpiamente
  sobre la oficial sin tocar el pkgrel.
- **No colisiona con releases reales**: `dev.<sha>` nunca choca con `4.0.x`.

### Qué pasa dentro del build

`makepkg` copia la receta a un dir temporal (`mktemp -d`), copia el checkout del fork (vía
`OMARCHY_SRC`), corre `build()` (ensamblar) y luego `package()`, que con `install -Dm644`
va dejando archivos en un "root falso". En `omarchy-settings`, `package()` hace real la
webapp:

- los `applications/*.desktop` → copiados a `/usr/share/omarchy/applications/`;
- el icono `Xataka.png` (196×196) → convertido con **`magick`** a los tamaños estándar
  `/usr/share/icons/hicolor/256x256/apps/xataka.png` y `48x48` (el `icon_id` = nombre en
  minúsculas, no-alfanumérico → guion).

Final: todo se comprime a un único `.pkg.tar.zst`. Flags usados:

- `--skipchecksums` → no hay sumas que verificar (el source no se descarga, viene de `OMARCHY_SRC`).
- `--nodeps` (solo `omarchy-dev`) → `makepkg -s` buscaba `omarchy-settings-dev` como
  dependencia y no la veía (aún no instalada); se construye sin resolución y las deps runtime
  se validan en la instalación conjunta del paso 3.

## Paso 3 — Instalación (stock → dev sin romper nada)

### Qué es `pacman -U`

Instala un paquete **a partir del archivo local** (U de "upgrade/install local"), en vez de
buscarlo en un repo. Compara contra lo instalado, resuelve dependencias y ejecuta los hook
de post-instalación.

### Por qué no era un simple `pacman -U`

La máquina estaba en stock (`omarchy 4.0.1-1` + `omarchy-settings 4.0.1-1`). Dos trampas:

1. **`conflicts=`**: cada dev declara conflicto con el oficial
   (`omarchy-dev conflicts omarchy`, `omarchy-settings-dev conflicts omarchy-settings`).
   No pueden coexistir. Con `--noconfirm` pacman responde "N" a "¿remover el oficial?" →
   `error: unresolvable package conflicts detected` (el error real que vimos).
2. **Dependencia con versión**: el oficial `omarchy 4.0.1-1` exige `omarchy-settings=4.0.1`
   (con versión). El dev settings solo `provides omarchy-settings` sin versión → NO la
   satisface. Instalar solo settings-dev habría dejado a `omarchy` con dep rota (pacman
   habría querido remover también el motor).

### La solución: el par completo en una sola transacción atómica

```bash
pkexec pacman -U --ask 4 --noconfirm --overwrite='*' \
  omarchy-settings-dev-*.pkg.tar.zst  omarchy-dev-*.pkg.tar.zst
```

pacman recibe los dos dev **juntos** y resuelve el grafo como una unidad: el par stock se
reemplaza por el par dev sin pasar por un estado intermedio sin motor. Flags:

- **`--ask 4`** — contesta "sí" automáticamente a la pregunta de reemplazar los paquetes
  conflictivos. Es el mismo mecanismo que usa el wrapper `pacman-for-makepkg` del contenedor
  de build de upstream.
- **`--overwrite='*'`** — permite sobrescribir archivos ya existentes (los dev re-instalan
  las mismas rutas que el stock, p.ej. `/etc/skel/.config/...`).
- **`--noconfirm`** — evita cualquier otra pregunta interactiva.
- **`pkexec`** — ejecuta como root **sin terminal**: abre el diálogo gráfico de token
  (polkit), el que aparece en pantalla al autenticarse. Regla del SKILL de Omarchy:
  terminal → `sudo`; sin terminal → `pkexec`.

Volviendo a mañana: como ya hay `omarchy-settings-dev` instalado, instalar la versión nueva
es una **actualización normal del mismo pkgname** (sin conflictos, sin `--ask 4`).

### Verificación del resultado

La salida mostraba "installing omarchy-dev…" y corría los hooks (`Reloading Hyprland after
Omarchy settings update`, `Updating icon theme caches`, etc.):

```bash
$ pacman -Q omarchy omarchy-settings
omarchy-dev dev.89759761-1
omarchy-settings-dev dev.89759761-1
```

## ¿Y los updates futuros? ¿Serán desde el fork o con `omarchy update` de upstream?

**El comando no cambia: sigue siendo `omarchy update`.** Ese es el principio rector
(sin inventar mecanismos, ver `agents_fork.md`). Lo que cambia es de dónde sale el paquete
para el par `omarchy` + `omarchy-settings`:

### Modelo decidido: "sombreado parcial"

Se agrega el repo `[omarchy-personal]` **antes** del `[omarchy]` oficial en la config de
pacman (`default/pacman/pacman-stable.conf`). pacman resuelve en orden de repos, así que:

- `omarchy` + `omarchy-settings` (el par) → **de nuestro fork** (el pipeline de GitHub
  Actions construye desde el fork y publica la versión que decidamos pinner).
- **Todo el resto del ecosistema** → sigue de upstream `pkgs.omarchy.org`.

Un solo `omarchy update` mezcla ambos orígenes; el usuario no nota cambio de comando.

### Situación actual de esta máquina (línea dev, sin repo personal todavía)

Si corre `omarchy update` hoy:

- actualiza el resto del ecosistema desde upstream, y
- **se saltea el par dev**: `dev.89759761` ordena después de `4.0.1` en la comparación de
  versión de pacman, así que no intenta "bajar" a stock. El par dev queda instalado hasta
  que decidas reinstalar (volver a stock = instalar los paquetes oficiales).

### Diferencia clave: la máquina dev vs. las máquinas reales

- La máquina dev instala `dev.<sha>` (build directo del commit). Es del ciclo de desarrollo.
- Las máquinas reales (con `[omarchy-personal]`) instalarán la versión **pinneada** que
  republicamos desde el fork — pkgver = versión base de upstream, pkgrel alto (99, 100…)
  según §5.3 de `agents_fork.md` — para que el orden de versiones siga coincidiendo con
  upstream y el update natural funcione.



## Estado al cierre de esta guía (snapshot 2026-08-30)

> Snapshot de cuando se escribió la guía. El estado actual está en
> [`README.md`](README.md) (Etapa 3/4 completas, par publicado 4.0.2-101); el flujo operativo
> vigente es el de la Action de release (W7 de `agents_fork.md`): "sombreado parcial" ya está en
> producción, no es un plan.

- Máquina dev: `omarchy-dev` + `omarchy-settings-dev` `dev.89759761-1`.
- Fork: `robert-flo/omarchy`, rama `personal`, commit `89759761` (POC Xataka).
- Repo notas: this repo (scratchpad); working copy `~/Work/omarchy/scratchpad`.