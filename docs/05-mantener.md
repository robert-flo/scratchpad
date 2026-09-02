# 05 — Mantener (para el mantenedor)

Dos rutinas que hacen que el sistema personal "respire": **añadir un paquete personal** y **seguir
las versiones de Omarchy upstream**. Ambas terminan igual: publicar con la Action y actualizar las
máquinas.

> Regla de oro del versionado del par `omarchy`/`omarchy-settings`:
> **mismo `pkgver` que el upstream base, `pkgrel` siempre alto y creciente** (99, 100, 101…).
> Eso garantiza que tus versiones le ganen a las oficiales y `omarchy update` nunca baje al par
> oficial (que no tendría tus personalizaciones).
> Desde 2026-09-01 la Action **deriva el `pkgrel` sola** (§5.3 del plan): pkgver nuevo → 99;
> mismo pkgver → última republicación +1. Tú solo pasas la `version`.

## Añadir un paquete personal nuevo

Un paquete tuyo, con tus archivos, publicado por el mismo repositorio. Ejemplo real ya funcionando:
`hola-mundo` (un script que imprime un mensaje).

Estructura de un paquete (en `omarchy-pkgs`):

```
pkgbuilds/hola-mundo/
├── PKGBUILD
└── .omarchy/
    └── package.json
```

Pasos:

```bash
cd ~/Work/omarchy/omarchy-pkgs
mkdir pkgbuilds/mi-paquete
# 1) Escribe pkgbuilds/mi-paquete/PKGBUILD (receta de package de Arch normal)
# 2) Mark como "personal":
#    pkgbuilds/mi-paquete/.omarchy/package.json →
#      { "source": "local", "release_ring": "fast", "personal": true }
git add pkgbuilds/mi-paquete
git commit -m "personal: add mi-paquete"
git push origin personal
```

```bash
# 3) Publicar (el pkgrel del par lo deriva sola la Action; SIEMPRE --ref personal)
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v4.0.2
```

```bash
# 4) En cada máquina donde quieras el paquete: instalarlo UNA vez
sudo pacman -S mi-paquete
```

De ahí en adelante `omarchy update` lo mantiene. Si el paquete debe estar en TODAS las máquinas
desde cero, añádelo también a `install/omarchy-base.packages` del fork fuente.

Detalles prácticos de un PKGBUILD personal (lo visto con `hola-mundo`):

- `arch=('any')` si no compila nada; `sha256sums=('SKIP')` si el source es local.
- No necesita lockstep ni tag: eso es solo del par `omarchy`/`omarchy-settings` (lo gestiona el
  propio proceso de publicación).
- El `pkgrel` de un paquete genérico es el normal que escribas en su PKGBUILD (la regla 99+ crece
  solo se aplica al par).

## Publicar un cambio (la orden que se repite)

Cada vez que hagas un cambio de fuente (webapp, config, tema, comando, paquete), publica y actualiza:

```bash
# Publicar (en ~/Work/omarchy/omarchy-pkgs, rama personal; SIEMPRE --ref personal;
# el pkgrel del par se deriva solo)
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v4.0.2

# Esperar a que termine (unos minutos) y verificar la publicación:
gh run watch --exit-status
# …y en las máquinas:
omarchy update
```

## Seguir el release de Omarchy upstream

Cuando Omarchy publica una versión nueva (`vX.Y.Z`), hay que alinear el fork y republicar. Los
pasos (en `~/Work/omarchy/omarchy-installer`):

```bash
git fetch upstream
git rebase upstream/quattro        # sobre la rama personal
git push --force-with-lease origin personal
git push origin vX.Y.Z             # sincroniza el tag de la versión al fork
```

```bash
# En ~/Work/omarchy/omarchy-pkgs: publicar con el pkgver del tag nuevo (el pkgrel se
# deriva solo: pkgver nuevo → base 99, por encima del oficial)
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=vX.Y.Z
```

…y en cada máquina `omarchy update`.

### Qué hacer si hay conflictos en el rebase

Ideales: no deberían existir si tus cambios personales tocan archivos que upstream apenas mueve.
Si un archivo tuyo choca con upstream, pregunta si tu cambio conviene upstream (está en el espíritu
del proyecto contribuir de vuelta) y resuelve el conflicto a mano como cualquier rebase.

### Verificación mínima tras publicar

```bash
# La db del repo personal debe listar las versiones nuevas:
curl -s https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/omarchy.db.tar.zst | bsdtar -xOf - omarchy/desc
# En una máquina:
pacman -Q omarchy omarchy-settings
```

## Checklist rápida de la cadencia (tras un release upstream)

1. [ ] `git fetch upstream` + rebase (sin conflictos, o resueltos).
2. [ ] `./test/all` pasa (salvo tests ambientales).
3. [ ] `git push --force-with-lease origin personal` + tag sync.
4. [ ] Dispatch de la Action **con `--ref personal`** y el pkgver del tag nuevo (pkgrel autoderivado); el run acaba verde.
5. [ ] `omarchy update` en cada máquina llega a la versión personal nueva.