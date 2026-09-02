# 04 — Webapps

Las webapps de Omarchy (YouTube, Xataka, Google Photos, WhatsApp…) no son accesos sueltos del menú:
viven **dentro de los archivos del sistema** y viajan por el repositorio personal. Para agregar una:

## Antes de nada: qué partes componen una webapp

- `applications/<Nombre>.desktop` — el lanzador.
- `applications/icons/<Nombre>.png` (o `.svg`) — el icono.

Gráficamente, un `.desktop` se ve así (ejemplo con Xataka):

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

Reglas rápidas:

- `Exec` siempre es `omarchy-launch-webapp <URL>` (abre el navegador por defecto en ventana de app).
  Si la URL lleva caracteres reservados (`?&#`…) va entre comillas dobles:
  `omarchy-launch-webapp "https://…/?a=b&c=d"`. Para launchers que necesitan shell
  (`cd "$HOME/src" && exec …`) el canon es `sh -c "…\"\$HOME…\"…"` (dobles + `\"` y `\$`).
- `Icon` es el nombre del icono en **minúsculas y con espacios/acentos convertidos a guion**:
  `Google Photos.png` → `google-photos`, `Xataka.png` → `xataka`.
- Si es una webapp que maneja un esquema (mailto, ...) se agrega `MimeType=x-scheme-handler/<esquema>`.

## Agregar una webapp (en 4 pasos)

Trabaja en el repositorio del proyecto (fork), rama `personal`:

```bash
cd ~/Work/omarchy/omarchy-installer

# 1) Crear los dos archivos (modelo: applications/Xataka.desktop e icons/Xataka.png)
# 2) Commitear
git add applications/<Nombre>.desktop applications/icons/<Nombre>.png
git commit -m "personal: add <Nombre> webapp"
git push origin personal
```

```bash
# 3) Publicar (reprisa el repositorio personal con la Action).
#    No hace falta decirle el pkgrel: la Action lo deriva sola (§5.3 del plan) —
#    pkgver nuevo → 99; mismo pkgver → última republicación +1 (lo lee del
#    PKGBUILD commitado; hoy 102 → 103).
gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs \
  --ref personal -f version=v4.0.2
```

```bash
# 4) En cada máquina: actualizar y refrescar lanzadores
omarchy update
omarchy-refresh-applications
```

## Verificar

```bash
pacman -Q omarchy-settings      # la versión personal
omarchy-refresh-applications    # materializa el .desktop en tu usuario
```

Y ojo: si la app está **en una máquina con el usuario ya creado**, sin el paso
`omarchy-refresh-applications` no aparecerá en el launcher.

## Cambiar o quitar una webapp

- **Cambiar** (URL, nombre, icono): edita el `.desktop` / icono, commit `personal: update <app>`, publica (paso 3) y actualiza (paso 4).
- **Quitar**: borra los dos archivos, commit `personal: remove <app>`, publica y actualiza. En las
  máquinas existentes, `omarchy-refresh-applications` quita el lanzador sobrante al refrescar.

## Truco rápido para el día a día

Para probar una webapp sin esperar la publicación (máquina de desarrollo):

```bash
omarchy-launch-webapp https://www.xataka.com/
```