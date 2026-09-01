#!/usr/bin/env bash
# bootstrap-omarchy-dev.sh — Etapa 0 del plan (agents_fork.md §2): dejar una máquina
# lista como entorno dev del fork personal de Omarchy.
#
# El script tiene DOS fases:
#   Fase 1 — Clones: reproducir el layout `~/Work/omarchy/{omarchy-installer,omarchy-pkgs,scratchpad}`
#            con los remotes `origin` (fork) y `upstream` (omacom) bien configurados.
#   Fase 2 — Ciclo dev: construir e instalar el par `omarchy-dev` + `omarchy-settings-dev`
#            desde el checkout del fork (el "criterio de aceptación" de la Etapa 0).
#
# ---------------------------------------------------------------------------
# POR QUÉ ESTAS RUTAS Y NO OTRAS (fase 1)
#
#   `omarchy dev pkg-test` (bin/omarchy-dev-pkg-test) lee los PKGBUILDs de
#   ${OMARCHY_PKGBUILDS_DIR:-~/Work/omarchy/omarchy-pkgs/pkgbuilds}, es decir, usa
#   ~/Work/omarchy/omarchy-pkgs POR DEFECTO. Respetando esos defaults, el ciclo dev
#   corre sin argumentos ni env vars. Decisión registrada en el WORKLOG
#   ("Decisiones registradas", sesión 2026-08-30).
#
#   El nombre `omarchy-installer` (y no `omarchy`) para el checkout de la fuente es
#   la convención ya registrada en agents_fork.md §0.1 — mantenerla para que las
#   notas y recetas (W7, W9) coincidan con el filesystem en todas las máquinas.
#
#   El remote `upstream` en ambos forks es requisito de la estrategia de sync del
#   plan (§7.1, receta W9): `git fetch upstream && git rebase upstream/quattro`
#   (o upstream/master en pkgs) sobre la rama `personal`. Sin ese remote, el flujo
#   de sync no existe.
#
# POR QUÉ NO EJECUTAR `omarchy dev pkg-test` DIRECTO (fase 2)
#
#   La herramienta oficial es `omarchy dev pkg-test`, pero en una sesión de agente
#   sin terminal falla en su último paso: llama a `sudo pacman -U`, y sudo no puede
#   pedir password sin TTY. La regla del skill de Omarchy (Privilege Escalation,
#   default/agents/skills/omarchy/SKILL.md) es: con terminal → sudo, sin terminal →
#   pkexec. Por eso aquí la instalación usa `pkexec`.
#
#   Además hay una trampa mayor: en una máquina con el par STOCK instalado (p. ej.
#   omarchy 4.0.2-1), `omarchy-settings-dev` y `omarchy-settings` SE CONFLICTÚAN,
#   y `omarchy` stock depende de `omarchy-settings=4.0.2` con versión EXACTA.
#   Instalar un solo paquete dev rompe esa dependencia. Solución (verificada en
#   las sesiones 2026-08-30 y 2026-09-01 del WORKLOG): instalar EL PAR COMPLETO EN
#   UN SOLO `pacman -U`, con `--ask 4` (responder yes a los reemplazos de paquetes
#   conflictivos; es el mismo truco que usa el wrapper pacman-for-makepkg del
#   Dockerfile de build de upstream) y `--overwrite='*'` (los builds dev chocan con
#   archivos de versiones previas; el paquete recién construido es el estado
#   autoritativo — misma razón que arguye el propio pkg-test).
#
#   La fase 2 replica EXACTAMENTE lo que hace bin/omarchy-dev-pkg-test:
#     1. Copia cada PKGBUILD de ~/Work/omarchy/omarchy-pkgs/pkgbuilds/<pkg>/ a un dir temporal.
#     2. Elimina la función pkgver() con awk (mismo algoritmo literal del tool:
#        el PKGBUILD usa pkgver() dinámica basada en git upstream, inútil para un
#        build local OMARCHY_SRC; sin quitarla, makepkg pisaría nuestro pkgver dev).
#     3. Reescribe pkgver=dev.<short-sha>[.dirty] — así `pacman -Q` delata de qué
#        commit salió lo instalado.
#     4. makepkg -s --skipchecksums con OMARCHY_SRC apuntando al checkout del fork
#        (con OMARCHY_SRC seteado, source=() queda vacío y se copia el checkout entero).
#     5. Instala el par junto (ver trampa de arriba).
#
#   Detalle fino del build: `makepkg -s` de `omarchy-dev` NO resuelve su dependencia
#   `omarchy-settings-dev` (todavía no está en ningún repo al momento de construir),
#   por eso ese paquete se construye con `--nodeps`; las dependencias runtime se
#   validan en la instalación conjunta del paso 5.
#
# ADVERTENCIA de estado: la fase 2 deja la máquina en la LÍNEA DEV (reemplaza el par
# stock por el par dev). En ese estado `omarchy update` normal NO aplica hasta
# reinstalar el par stock. Es el estado esperado de una máquina de desarrollo.
#
# El script es idempotente en la fase 1 (si el checkout ya existe, lo salta en vez
# de romper). La fase 2 se puede omitir con --no-install.
# ---------------------------------------------------------------------------

set -euo pipefail

WORK="$HOME/Work/omarchy"
GH_SSH="git@github.com:"
FORK_OWNER="robert-flo"

NO_INSTALL=false
[[ "${1:-}" == "--no-install" ]] && NO_INSTALL=true

# ---------------------------------------------------------------------------
# FASE 1 — Clones y remotes
# ---------------------------------------------------------------------------
# fork|rama de trabajo|repo upstream|rama upstream contra la que se rebasea (W9)
declare -A REPOS=(
  ["$WORK/omarchy-installer"]="${FORK_OWNER}/omarchy|personal|omacom/omarchy|quattro"
  ["$WORK/omarchy-pkgs"]="${FORK_OWNER}/omarchy-pkgs|master|omacom/omarchy-pkgs|master"
)

# Notas del proyecto. Por qué en ~/Work/omarchy: es la "working copy canónica" del
# scratchpad según agents_fork.md §0.1; así toda la documentación del plan vive al
# lado de los checkouts que describe.
NOTES_URL="${GH_SSH}${FORK_OWNER}/scratchpad.git"
NOTES_DIR="$WORK/scratchpad"

clone_or_skip() {
  local dir="$1" url="$2"
  if [[ -d "$dir/.git" ]]; then
    echo "== $dir ya existe, se salta el clone"
  else
    git clone "$url" "$dir"
  fi
}

echo "== Fase 1: clonando repos en $WORK"
mkdir -p "$WORK"

for dir in "${!REPOS[@]}"; do
  IFS='|' read -r fork branch upstream_repo _ <<< "${REPOS[$dir]}"
  clone_or_skip "$dir" "${GH_SSH}${fork}.git"

  # Checkout de la rama de trabajo del fork (personal/master según el repo).
  git -C "$dir" checkout "$branch"

  # Remote upstream si falta (idempotente). Fetch inicial para que
  # `git rebase upstream/<rama>` (W9) funcione desde el primer día.
  if ! git -C "$dir" remote get-url upstream &>/dev/null; then
    git -C "$dir" remote add upstream "${GH_SSH}${upstream_repo}.git"
    echo "== $dir: remote upstream agregado (${upstream_repo})"
  fi
  git -C "$dir" fetch upstream
done

clone_or_skip "$NOTES_DIR" "$NOTES_URL"

# ---------------------------------------------------------------------------
# FASE 2 — Ciclo dev: build + instalación del par dev (criterio de aceptación Etapa 0)
# ---------------------------------------------------------------------------
if $NO_INSTALL; then
  echo "== --no-install: se omite la fase 2 (build/instalación del par dev)"
else
  CHECKOUT="$WORK/omarchy-installer"
  PKGBUILDS_ROOT="$WORK/omarchy-pkgs/pkgbuilds"

  # pkgver=dev.<short-sha>[.dirty]: el dirty-flag delata builds con cambios sin
  # commitear en el checkout (mismo criterio del tool oficial).
  short_sha=$(git -C "$CHECKOUT" rev-parse --short HEAD)
  dirty=""
  [[ -n "$(git -C "$CHECKOUT" status --porcelain)" ]] && dirty=".dirty"
  NEW_PKGVER="dev.${short_sha}${dirty}"

  # Réplica literal de remove_pkgver_function() de bin/omarchy-dev-pkg-test:
  # elimina la función completa contando llaves para saber dónde termina.
  remove_pkgver_function() {
    local pkgbuild="$1"
    local tmp="$pkgbuild.tmp"
    awk '
      /^pkgver\(\)[[:space:]]*\{/ { in_pkgver = 1; depth = 0 }
      in_pkgver {
        line = $0; opens = gsub(/\{/, "{", line)
        line = $0; closes = gsub(/\}/, "}", line)
        depth += opens - closes
        if (depth <= 0) { in_pkgver = 0 }
        next
      }
      { print }
    ' "$pkgbuild" >"$tmp" && mv "$tmp" "$pkgbuild"
  }

  build_dir=$(mktemp -d -t omarchy-dev-pkgtest.XXXXXX)
  echo "== Fase 2: construyendo par dev ${NEW_PKGVER} (build dir: $build_dir)"

  for PKG in omarchy-settings-dev omarchy-dev; do
    pkg_dir="$build_dir/$PKG"
    mkdir -p "$pkg_dir"
    cp -a "$PKGBUILDS_ROOT/$PKG/." "$pkg_dir/"
    remove_pkgver_function "$pkg_dir/PKGBUILD"
    sed -i "s/^pkgver=.*/pkgver=${NEW_PKGVER}/" "$pkg_dir/PKGBUILD"

    # --nodeps SOLO para omarchy-dev: makepkg -s no puede resolver
    # omarchy-settings-dev (aún no instalada ni en ningún repo). Ver cabecera.
    extra_args=()
    [[ "$PKG" == "omarchy-dev" ]] && extra_args=(--nodeps)

    echo "   → makepkg $PKG ${NEW_PKGVER}"
    (
      cd "$pkg_dir"
      # OMARCHY_SRC: con esta var seteada, prepare() del PKGBUILD vacía source()
      # y copia el checkout local completo — así el paquete sale del fork, no de
      # un clone efímero del commit pineado en GitHub.
      OMARCHY_SRC="$CHECKOUT" makepkg -s --skipchecksums --noconfirm "${extra_args[@]}"
    )
  done

  settings_zst=$(ls "$build_dir"/omarchy-settings-dev/*.pkg.tar.zst | head -1)
  engine_zst=$(ls "$build_dir"/omarchy-dev/*.pkg.tar.zst | head -1)

  # Instalación del PAR JUNTO (ver cabecera: conflictos + dep de versión exacta).
  # pkexec porque este script puede correr sin TTY (regla del SKILL.md de Omarchy).
  # --ask 4: pacman contesta yes a los reemplazos de conflictivos (patrón upstream).
  echo "== Fase 2: instalando el par dev (pkexec pacman -U --ask 4)"
  pkexec pacman -U --ask 4 --noconfirm --overwrite='*' "$settings_zst" "$engine_zst"

  rm -rf "$build_dir"

  # Criterio de aceptación Etapa 0: pacman -Q reporta dev.<sha> en ambos.
  echo
  echo "== Verificación (criterio de aceptación Etapa 0):"
  pacman -Q omarchy-dev omarchy-settings-dev
fi

echo
echo "== Layout final:"
find "$WORK" -maxdepth 1 -mindepth 1 -type d -printf '   %p\n' | sort
echo
echo "== Estado: máquina en LÍNEA DEV (omarchy update normal no aplica hasta reinstalar el par stock)."
echo "== Siguientes pasos según plan §0.2: apuntar OMARCHY_UPSTREAM_URL al fork y Etapa 3/W7."
