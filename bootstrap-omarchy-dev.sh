#!/usr/bin/env bash
# bootstrap-omarchy-dev.sh — Etapa 0 del plan (agents_fork.md §2): dejar la máquina
# lista como entorno dev del fork personal de Omarchy.
#
# Por qué estas rutas y no otras:
#   `omarchy dev pkg-test` (bin/omarchy-dev-pkg-test) lee los PKGBUILDs de
#   ${OMARCHY_PKGBUILDS_DIR:-~/Work/omarchy/omarchy-pkgs/pkgbuilds}, es decir, usa
#   ~/Work/omarchy/omarchy-pkgs POR DEFECTO. Respetando esos defaults, el ciclo dev
#   (editar fuente → `omarchy dev pkg-test` → refresh) corre sin argumentos ni env
#   vars. Decisión registrada en el WORKLOG ("Decisiones registradas").
#
#   El nombre `omarchy-installer` (y no `omarchy`) para el checkout de la fuente es
#   la convención ya registrada en agents_fork.md §0.1 — mantenerla para que las
#   notas y recetas (W7, W9) coincidan con el filesystem en todas las máquinas.
#
# El script es idempotente: si el checkout ya existe, lo salta en vez de romper.

set -euo pipefail

WORK="$HOME/Work/omarchy"
GH_SSH="git@github.com:"

# Fork fuente + upstream de referencia. Por qué el remote `upstream`: la estrategia
# de sync del plan (§7.1, receta W9) es `git fetch upstream && git rebase
# upstream/quattro` sobre la rama `personal`; sin ese remote el flujo de sync no
# existe. Igual para omarchy-pkgs (rebase sobre upstream/master).
declare -A REPOS=(
  ["$WORK/omarchy-installer"]="robert-flo/omarchy|personal|omacom/omarchy|quattro"
  ["$WORK/omarchy-pkgs"]="robert-flo/omarchy-pkgs|master|omacom/omarchy-pkgs|master"
)

# Notas del proyecto. Por qué en ~/Work/omarchy: es la "working copy canónica" del
# scratchpad según agents_fork.md §0.1; así toda la documentación del plan vive al
# lado de los checkouts que describe.
NOTES_URL="${GH_SSH}robert-flo/scratchpad.git"
NOTES_DIR="$WORK/scratchpad"

clone_or_skip() {
  local dir="$1" url="$2"
  if [[ -d "$dir/.git" ]]; then
    echo "== $dir ya existe, se salta el clone"
  else
    git clone "$url" "$dir"
  fi
}

echo "== Clonando repos en $WORK"
mkdir -p "$WORK"

for dir in "${!REPOS[@]}"; do
  IFS='|' read -r fork branch upstream_repo upstream_branch <<< "${REPOS[$dir]}"
  clone_or_skip "$dir" "${GH_SSH}${fork}.git"

  # Checkout de la rama de trabajo del fork (personal/master según el repo).
  git -C "$dir" checkout "$branch"

  # Remote upstream si falta (idempotente).
  if ! git -C "$dir" remote get-url upstream &>/dev/null; then
    git -C "$dir" remote add upstream "${GH_SSH}${upstream_repo}.git"
    echo "== $dir: remote upstream agregado (${upstream_repo})"
  fi
  # Fetch inicial de upstream para que `git rebase upstream/<branch>` (W9) funcione
  # desde el primer día sin pasos extra.
  git -C "$dir" fetch upstream
done

clone_or_skip "$NOTES_DIR" "$NOTES_URL"

echo
echo "== Layout final:"
find "$WORK" -maxdepth 1 -mindepth 1 -type d -printf '   %p\n' | sort
echo
echo "== Siguiente validación (Etapa 0, criterio de aceptación):"
echo "   omarchy dev pkg-test   → debe construir e instalar omarchy-dev + omarchy-settings-dev"
echo "   pacman -Q omarchy-dev omarchy-settings-dev   → debe reportar dev.<sha>"
