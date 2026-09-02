# ARCHITECTURE.md — Arquitectura de personalización del fork (CANÓNICO)

> **Este documento es la fuente única de verdad para decidir DÓNDE va cada cambio del fork.**
> Ningún agente ni humano debe crear un mecanismo paralelo ni adivinar dónde colocar un archivo.
> Ante cualquier duda, el flujo autoritario es: **dar con la fila exacta de la Matriz de Decisión
> (sección §2) y seguir su columna "Validación dev" y "Se lleva a otras máquinas".** Si un cambio
> no encaja en ninguna fila, es señal de que NO se está siguiendo el modelo upstream: parar y
> re-preguntar (principio 1 de `agents_fork.md`, §3).
>
> Fecha de fijación: 2026-09-02. Estado: **DECISIÓN ARQUITECTÓNICA FIRME** (consensuada con el
> dueño tras la investigación del flujo de plugins, configs y ejecutables). Todo lo anterior a
> esta fecha que contradiga la Matriz queda **derogado**.

---

## 1. Dos y solo dos comandos gobiernan el flujo

Todo el modelo de personalización se reduce a **dos escenarios**. No hay un tercero. Cuando el
dueño diga "agrega esto" / "agrega aquello", el agente opera en uno de estos dos mundos y debe
saber cuál desde el inicio:

### 1.1 Escenario DEV — "lo estoy construyendo y validando en la máquina dev"

El ciclo iterativo del que construye o modifica el fork (un agente trabajando en el repo):

```text
editar la fuente en el fork  →  omarchy dev pkg-test  →  refresh del componente  →  validar
```

| Paso | Qué hace | Cuándo |
|---|---|---|
| `omarchy dev pkg-test` | Construye e instala **localmente** uno o ambos paquetes del par (`omarchy-dev`, `omarchy-settings-dev`) desde el checkout del fork; lo re-etiqueta `dev.<sha>` para saber de qué commit vino. **No publica nada.** | Después de cada cambio de fuente en `config/`, `bin/`, `applications/`, `install/`, `migrations/`, `themes/`. |
| `omarchy refresh config <relpath>` | Copia un archivo de `$OMARCHY_PATH/config/<relpath>` a `~/.config/<relpath>` (con backup). | Tras tocar un config de usuario. |
| `omarchy refresh-applications` | Materializa los `.desktop` en `~/.local/share/applications/` y (vía `install/user/mise.sh`) los wrappers de mise en `~/.local/bin`. | Tras tocar webapps/launchers o `install/user/*.sh`. |
| `omarchy refresh <componente>` | Refresh específico (shell, hyprland, terminal…). | Tras tocar ese componente. |
| `omarchy reinstall-configs` | Re-copia **todo** `/etc/skel` sobre `$HOME`. Nuclear/destructivo. | Sobre todo tras cambiar `config/` en bloque. |
| `omarchy reinstall pkgs` | Reinstala el set de paquetes de `install/*.packages` (`--needed`). | Tras tocar el set de paquetes (W6). |

> **Regla:** en dev, **la máquina dev queda en línea `-dev`** (`pacman -Q` muestra versiones
> `dev.<sha>`). Aquí se valida que el cambio *funciona*; todavía no está en ninguna otra máquina.

### 1.2 Escenario MÁQUINAS — "lo llevo a todas mis computadoras"

El único gatillo de distribución. **Todo lo que viaja por el par personal llega solo a cada
máquina con `omarchy update`.** No hay que hacer nada máquina por máquina.

```text
git commit + git push origin personal  →  Action release-personal  →  par republicado  →
omarchy update (en cada máquina)       →  pacman instala el par personal  →  todos los cambios
```

Qué hace `omarchy update`: `pacman -Syu` (instala el nuevo par personal), luego `omarchy-migrate`
(migraciones pendientes), luego `omarchy-hook post-update`. Las configs/launchers/wrappers que
lleva el paquete quedan disponibles; materializarlos en `$HOME` de usuarios existentes se hace con
los refresh (pero **ese es trabajo de dev / una migración**, ver §3).

> **Regla de oro (repetida del encargo):** el dueño quiere **que TODO viaje vía `omarchy update`
> en máquinas futuras**. Nada se instala por un script suelto que se corre a mano por máquina, ni
> por dotfiles, ni por mecanismos paralelos.

---

## 2. MATRIZ DE DECISIÓN — la puerta obligatoria

**Antes de tocar el fork, el agente cruza la columna "Tipo de cambio" con el "lugar del fork" y
así sabe todo lo demás.** Si el dueño dice "agrega X", el primer paso es: ¿X es un config de
usuario, una webapp, un comando, un wrapper de terceros o un provisioning/migración? Esa
respuesta decide la fila y, con ella, TODO lo que sigue.

| Tipo de cambio | Dónde en el fork | Dónde se instala | Paquete | Validación dev | Se lleva a otras máquinas |
|---|---|---|---|---|---|
| **Config de usuario** (kitty, foot, hypr, shell…) | `config/<app>/` | `~/.config/<app>/` (seed en `/etc/skel` + fuente de resync en `/usr/share/omarchy/config`) | `omarchy-settings` | `omarchy dev pkg-test` + `omarchy refresh config <archivo>` | `omarchy update` |
| **Webapp / launcher** | `applications/*.desktop` + `applications/icons/` | `~/.local/share/applications/` (+ iconos hicolor) | `omarchy-settings` | `omarchy dev pkg-test` + `omarchy refresh-applications` | `omarchy update` |
| **Ejecutable propio** (`omarchy-*`) | `bin/omarchy-*` (con metadatos `# omarchy:summary=…`) | `/usr/bin/` (para el paquete `omarchy`) | `omarchy` | `omarchy dev pkg-test` | `omarchy update` |
| **Wrapper de terceros** (mise, npm, oficiales) | `install/user/*.sh` + líneas `omarchy-mise-install` / `omarchy-install-*` | `~/.local/bin/` (idempotente, corre en provision/refresh) | `omarchy-settings` | `omarchy refresh-applications` (ejecuta `install/user/*.sh`) | `omarchy update` |
| **Set de paquetes del sistema** | `install/omarchy-base.packages` / `omarchy-other.packages` | instalado por pacman (ISO / `reinstall pkgs`) | `omarchy-settings` | `omarchy reinstall pkgs` | `omarchy update` |
| **Script de provisioning / migración** | `install/` (leafs por-usuario, `install/user/*.sh`) / `migrations/*.sh` | `/usr/share/omarchy/install/` / `migrations/` | `omarchy` | `omarchy dev pkg-test` (+ ejecutar la migración/leaf) | `omarchy update` (migraciones corren automágicamente) |

> **Una sola fila describe "wrapper de terceros" (el caso del POC `omarchy-personal-bootstrap-launchers`).**
> Ese POC queda **deprecado por esta fila**: su lógica debe moverse a `install/user/*.sh` +
> `omarchy-mise-install`, siguiendo exactamente `install/user/mise.sh` de upstream. El POC se
> conserva un tiempo como **referencia/ejemplo de integración**, no como mecanismo vivo (ver §4).

---

## 3. Cómo se materializa en `$HOME` y cuándo lo hace el update

Ojo a una sutileza que confunde: **el paquete entrega los archivos a su "lugar del sistema"
(`/usr/share/...`, `/etc/skel`) pero el `$HOME` de un usuario EXISTENTE no se re-copia solo.**
`omarchy update` instala el paquete; luego, si el cambio afecta a `$HOME` de usuarios existentes,
eso se hace con:

- un **refresh** (`omarchy refresh config …`, `omarchy refresh-applications …`, etc.) — correcto
  cuando lo querés aplicar **ya mismo** en la máquina dev, o
- una **migración** (`migrations/<ts>.sh`, idempotente) — correcto cuando querés que **cada
  máquina existente** lo aplique automágicamente en su próximo `omarchy update`.

Distinción importante para el escenario MÁQUINAS:

- Usuarios **nuevos**: `/etc/skel` ya los siembra al crearse. Sin trabajo adicional.
- Usuarios **existentes**: el update entrega el paquete; la copia a `$HOME` requiere o un refresh
  manual (dev) o una migración (una vez por máquina).

---

## 4. Estado de los mecanismos (qué está vivo y qué queda derogado)

| Mecanismo | Estado | Destino |
|---|---|---|
| `config/`, `applications/`, `bin/`, `themes/`, `install/`, `migrations/` del fork | **VIVO** — la Matriz (§2) | permanecer |
| `omarchy-personal-bootstrap-launchers` (POC, `bin/`) | **DEPRECADO como mecanismo vivo** | su lógica se absorbe en `install/user/*.sh` + `omarchy-mise-install` (fila "Wrapper de terceros"); se conserva temporalmente como POC de referencia (§2 nota) |
| Repo plugins de omarchy (`~/.config/omarchy/plugins/`) | **NO USADO** para esto | el sistema de plugins es SOLO para widgets del shell Quickshell; no es el mecanismo para ejecutables/configs — descartado explícitamente |

---

## 5. Reglas duras (incumplirlas es un error de arquitectura)

1. **Nada de mecanismos paralelos**: no crear repos aparte, no dotfiles managers, no scripts
   per-máquina sueltos. Si algo no encaja en la Matriz → es señal de re-preguntar.
2. **`omarchy update` es el único gatillo de distribución.** Para público cliente nunca se corre
   `omarchy dev pkg-test` (ese es solo dev).
3. **`omarchy dev pkg-test` es solo para la máquina dev**, para validar un cambio antes de
   publicarlo; deja la máquina en línea `-dev`.
4. **El patrón upstream es la verdad.** Esto no es "opinión": está anclado a los documentos
   autoritativos del propio fork (`docs/file-layout.md`, `agents/skills/*`, `AGENTS.md`). Referirse
   a ellos antes de escribir cualquier código.
5. **Los scripts de `bin/` llevan metadatos** `# omarchy:summary=` / `# omarchy:args=` /
   `# omarchy:examples=` y van registrados si son un grupo nuevo (`agents/skills/command-metadata.md`).
6. **Mantener el repo personal por delante del oficial** para el par, si no `omarchy update`
   instalaría el par oficial y borraría personalizaciones (`agents_fork.md` §5.3).

---

## 6. Vínculo con el resto de la documentación

- **`agents_fork.md` §4 (W1–W10)** contiene las recetas paso a paso de cada fila de la Matriz. Este
  documento ES la tabla de alto nivel; W1–W10 son la ejecución detallada.
- **`docs/06-launchers.md`** describe los launchers y el POC; debe leerse *a la luz* de la fila
  "Webapp / launcher" y de la nota de deprecación del §4.
- **`docs/file-layout.md`** (dentro del fork) es la tabla canónica de "repo → path instalado".
- **`RUNBOOK.md`** para fallos.
- **`WORKLOG.md`** para la historia de decisiones; la 13ª parte registra esta fijación.

---

*Documento de decisión. Una vez firmado, es la respuesta a "¿dónde va esto?" antes de cualquier
investigación. Cualquier agente que trabaje el repo debe leer la §2 antes de tocar nada.*
