# 06 — Los launchers y su bootstrap

Cómo funciona la cosecha de launchers del sistema personal y cómo se deja funcionando en una
máquina (lo que el paso "instalar una máquina" de **02** resuelve para los programas pero no para
los *bins* sobre los que corren los launchers).

## Qué es un launcher

Cada entrada de tu menú de apps es un archivo `.desktop` en `/usr/share/omarchy/applications/`
(los trae el paquete `omarchy-settings`) que tu escritorio materializa en
`~/.local/share/applications/` al correr `omarchy refresh-applications`. Cuando lo abres, la
máquina ejecuta su línea `Exec=…`.

El fork personal sumó 60 launchers nuevos (39 webapps + 19 TUI/custom + 2 de Microsoft Edge)
cosechados del sistema anterior, más sus 41 iconos, publicados en el par 4.0.2-103 (11ª parte).

Hay tres familias de `Exec`:

| Familia | Ejemplo | Depende de |
|---|---|---|
| **Webapp** | `Exec=omarchy-launch-webapp "https://claude.ai/new"` | un navegador por defecto (Google Chrome) |
| **TUI en terminal** | `Exec=sh -c "cd \"\$HOME/src\" && exec xdg-terminal-exec --app-id=TUI.tile -e qwen"` | un emulador de terminal + el CLI (`qwen`) |
| **App nativa** | `Exec=xdg-terminal-exec --app-id=TUI.tile -e herdr` | el binario (`herdr`) |

> El patrón `xdg-terminal-exec --app-id=TUI.{tile,float} -e <cmd>` es el canónico upstream: abre
> `cmd` en el terminal por defecto con la clase de ventana que Omarchy usa para sus reglas. El
> bootstrap lo deja resuelto de dos formas: instalando el binario (si el comando existe) o, para
> los CLIs que viven en `mise`, creando contenedores que reenvían al binario correcto.

## El bootstrap idempotente

> **⚠️ DEPRECADO (13ª parte).** Este script (`bin/omarchy-personal-bootstrap-launchers`) fue un
> **POC** para demostrar cómo integrar ejecutables en el fork. No es el camino correcto para el
> futuro: lo correcto es que la lógica viva en `install/user/*.sh` + `omarchy-mise-install` (fila
> "Wrapper de terceros" de la **Matriz de Decisión de `ARCHITECTURE.md`**) y viaje a las máquinas
> vía `omarchy update`. Se conserva aquí como referencia de implementación, no como mecanismo vivo.

Un script del fork (`bin/omarchy-personal-bootstrap-launchers`) instala todo lo que los 78
launchers ejecutan. Es **idempotente**: puedes correrlo varias veces y solo añade lo que falta.
Instala (nada de esto va en el paquete; son dependencias de tus launchers):

- **Sistema (pacman):** `ncdu`, `kitty`, `dua-cli`, `spotify-launcher` (el "spotify" de los TUI).
- **AUR (con `yay`):** `microsoft-edge-stable-bin` (webapps de X y WhatsApp), `lyricify`,
  `spicetify-cli`.
- **mise (CLIs de IA):** `qwen`, `opencode`, `codex`, `oh-my-pi` (`omp`), `antigravity-cli`
  (`agy`), `grok`, y por npm bajo el runtime de mise: `openclaude`, `zero`, `command-code` (`cmd`).
- **Instaladores oficiales:** `mimo` (oficial Xiaomi), `openclaw` (+ su servicio *gateway*, el
  dashboard de `127.0.0.1:18789`), y la app de escritorio **opencode-desktop** (AppImage oficial
  en `~/.local/opt/opencode-desktop/` con un contenedor en `~/.local/bin/opencode-desktop`).
- **Hermes:** crea el contenedor del CLI (vía el instalador canónico de Omarchy) y coloca un shim
  en `~/.hermes/hermes-agent/venv/bin/hermes` — el path exacto que usa el launcher web de Hermes —
  apuntando a ese contenedor (el CLI y el app comparten instalación).
- **Directorio de trabajo `~/src`:** los launchers que empiezan con `cd "$HOME/src"` necesitan que
  exista; el script lo crea.

### Cómo correrlo

```bash
# local (tras pinchar el repo)
bash <(curl -fsSL https://raw.githubusercontent.com/robert-flo/omarchy/personal/bin/omarchy-personal-bootstrap-launchers)
```

Al terminar imprime `done: every launcher binary resolves.` (o la lista de lo que falte).

> Si una máquina no tiene `yay`, el script salta el bloque AUR y avisa qué falta (Edge/Lyricify/
> spicetify). Instala `yay` primero y vuelve a correrlo.

## Cómo se instalan las dependencias en una máquina futura (resumen)

Basta con ejecutar el bootstrap **después de instalar el par personal** (paso 6 de `docs/02`):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/robert-flo/omarchy/personal/bin/omarchy-personal-bootstrap-launchers)
```

El script hace todo de forma **idempotente** (seguro de repetir; solo añade lo que falta) y
verifica al final con `done: every launcher binary resolves.`. Qué instala cada bloque:

| Bloque | Paquetes/binarios | Cómo | Si falta la herramienta |
|---|---|---|---|
| Sistema | `ncdu kitty dua-cli spotify-launcher` | `sudo pacman -S` | – (repo oficial) |
| AUR | `microsoft-edge-stable-bin` `lyricify` `spicetify-cli` | `yay -S` | salta y avisa (instalar `yay` y repetir) |
| AI CLIs (mise) | `qwen opencode codex omp agy grok` + npm `openclaude zero cmd` | `mise use -g` + `npm -g` | requiere `mise` |
| Ctrladores oficiales | `mimo`, `openclaw` (+ gateway `18789`), `opencode-desktop` (AppImage) | instaladores oficiales + wrappers en `~/.local/bin` | `curl` |
| Hermes | wrapper CLI + shim `~/.hermes/hermes-agent/venv/bin/hermes` | `omarchy-install-hermes-cli --now` | requiere el par instalado |
| Trabajo | `~/src` | `mkdir -p` | – |

> **Ruta futura correcta:** estos bloques (mise/npm/oficiales) se integrarán como filas
> "Wrapper de terceros" de la **Matriz de Decisión** (`install/user/*.sh` + `omarchy-mise-install`)
> para que viajen por `omarchy update` y no por este script POC (ver banner de deprecación arriba).

## Cómo entendemos/revisamos la operatividad

La verificación es recorrer los `Exec=` de `~/.local/share/applications/*.desktop`, extraer el
binario/CLI de cada uno y comprobar que existe (`command -v`) y responde a `--version`. Cualquier
`cd "$HOME/src"` requiere `~/src`; cualquier `~/.hermes/…/hermes` requiere ese shim.