# scratchpad — Fork personal de Omarchy

Notas y documentación de un proyecto personal de **N máquinas Omarchy idénticas, mantenidas
automáticamente por `omarchy update`**, donde todas las personalizaciones viven como cambios de
**fuente en un fork de `omacom/omarchy`** siguiente el modelo upstream (con miras a contribuir de
vuelta). El repositorio personal de paquetes se sirve desde **GitHub Pages** y lo construye una
**GitHub Action**.

Toda la documentación está en español. Hay **dos públicos**:

- **Desarrollador / mantenedor** → documentos de la raíz (plan, bitácora y recetas).
- **Usuario final** (el "cómo" con ejemplos, sin el "porqué") → carpeta [`docs/`](docs/).

---

## Estado (2026-09-01)

Todo lo siguiente está **completo y probado end-to-end** en la máquina dev:

- **Etapa 0** — entorno dev reproducible (`bootstrap-omarchy-dev.sh`) y dev loop apuntado al fork.
- **Etapa 3 / W7** — repo pacman personal en GitHub Pages generado por la Action `release-personal.yml`.
- **Etapa 4** — sombreado: el fork shippea `[omarchy-personal]` **antes** de `[omarchy]` en el
  `pacman-stable.conf`, así el par se sirve desde el repo personal.
- **Cadencia W9** — sync del fork con upstream `quattro` practicado (rebase → re-pin → re-release).
- **Repo generalizada** — la Action publica **todos** los PKGBUILD marcados `"personal": true`;
  el PoC `hola-mundo` quedó instalado y **mantenido vía `omarchy update`**.

Publicado en <https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64> (firmado con la
clave GPG dedicada `D5E75EAC51A44715`):

| Paquete | Publicado | En la máquina dev |
|---|---|---|
| `omarchy` + `omarchy-settings` (par lockstep) | **4.0.2-101** | **4.0.2-101** |
| `hola-mundo` (PoC de paquete personal) | **0.1.0-2** | **0.1.0-2** |

> Nota operativa crítica: la Action corre en `robert-flo/omarchy-pkgs`; el dispatch se hace
> **SIEMPRE con `--ref personal`** (sin `--ref`, GitHub usa la versión `master` — desactualizada).
> Clave pública: `keys/omarchy-personal-repo.pub.asc` (la privada NO se versiona).

---

## Documentos

### Para desarrollador / mantenedor (raíz)

| Archivo | Qué es | Contenido |
|---|---|---|
| [`agents_fork.md`](agents_fork.md) | **Plan maestro** | encargo, modelo mental de upstream, hoja de ruta por etapas, recetas W1–W10, invariantes, estándares |
| [`WORKLOG.md`](WORKLOG.md) | **Bitácora** | qué se hizo, por qué y cómo, sesión por sesión (memoria de procedimiento) |
| [`webapp-workflow.md`](webapp-workflow.md) | **Guía de webapps** | cómo agregar una webapp al fork y materializarla en una máquina |
| [`build-install-cycle.md`](build-install-cycle.md) | **Mecánica build/install** | el "cómo funciona por dentro" del ciclo dev (antes de arrancar: leer) |
| [`bootstrap-omarchy-dev.sh`](bootstrap-omarchy-dev.sh) | **Script** | deja una máquina lista como entorno dev (clones + build e instalación del par dev) |
| `keys/omarchy-personal-repo.pub.asc` | Clave pública | para confiar el repo personal en las máquinas |

### Para usuario final (`docs/`)

| Archivo | Qué es |
|---|---|
| [`docs/README.md`](docs/README.md) | índice de usuario |
| [`docs/01-conceptos.md`](docs/01-conceptos.md) | en 5 minutos: qué es el repo personal y el "sombreado" |
| [`docs/02-instalar-una-maquina.md`](docs/02-instalar-una-maquina.md) | dejar una máquina en el sistema personal, paso a paso |
| [`docs/03-uso-diario.md`](docs/03-uso-diario.md) | `omarchy update`, instalar un paquete personal, reconciliar el set, problemas comunes |
| [`docs/04-webapps.md`](docs/04-webapps.md) | agregar y actualizar tus webapps |
| [`docs/05-mantener.md`](docs/05-mantener.md) | para el mantenedor: añadir un paquete personal y seguir el release upstream |