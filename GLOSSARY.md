# GLOSSARY.md — Glosario del proyecto

Términos usados en la documentación (`agents_fork.md`, `RUNBOOK.md`, `docs/`, `WORKLOG.md`).
Una definición por término; si algo no está acá, se busca primero el término upstream
(`docs/` del repo fuente).

| Término | Qué es (en este proyecto) |
|---|---|
| **Action / `release-personal.yml`** | Workflow de GitHub Actions en `robert-flo/omarchy-pkgs` que construye y publica el repo personal de paquetes en GitHub Pages (W7). |
| **bootstrap** | Dejar una máquina lista como entorno dev: clones, `omarchy dev pkg-test` y par dev instalado (`bootstrap-omarchy-dev.sh`, Etapa 0). |
| **cadencia / sync (W9)** | Rutina de mantener el fork al día con `upstream/quattro` (rebase → re-pin → re-release) para que la personalización nunca se quede atrás del estable oficial (§5.3). |
| **`clean` / `clean-repo`** | Paso del pipeline que poda versiones viejas del repo publicado: solo queda la última → no hay "rollback" a una versión anterior (ver RUNBOOK §2). |
| **db / database file** | La base de datos del repo pacman: `omarchy.db` (pacman deriva `omarchy-personal.db` del nombre de sección). Es un tar comprimido con metadatos (desc, depends, files). Alias + firmas en gh-pages. |
| **deploy key** | Clave SSH (secret `SSH_DEPLOY_KEY`) que la Action usa para escribir en `gh-pages` de `omarchy-personal-repo`. |
| **dispatch** | Disparar el workflow a mano: `gh workflow run release-personal.yml -R robert-flo/omarchy-pkgs --ref personal -f version=…`. |
| **`dry_run`** | Modo de la Action que ensaya la publicación completa sin publicar nada (ni pin en `personal`, ni push a `gh-pages`). |
| **fork** | Copia de un repo upstream en la cuenta propia. Aquí: `robert-flo/omarchy` (fuente) y `robert-flo/omarchy-pkgs` (paquetes), con rama `personal` sobre `upstream/quattro`. |
| **gh-pages** | Rama del repo `omarchy-personal-repo` que GitHub publica como web estática: los archivos del repo pacman (`.zst`, `.sig`, db, `.files`). |
| **guard §5.3** | Paso de la Action que aborta si el par personal quedara por detrás del estable oficial (`vercmp`). |
| **guard fail-fast** | Paso de la Action que aborta si el workflow se disparó desde una rama ≠ `personal`. |
| **keyring / confianza de clave** | En cada máquina, `pacman-key --add` + `--lsign-key` de la clave pública personal para que pacman acepte las firmas del repo personal. |
| **lockstep (par)** | Regla: `omarchy` y `omarchy-settings` se construyen siempre del mismo commit/source y comparten `pkgver`/`pkgrel`/`_tag`/`_commit`; `omarchy` depende de `omarchy-settings=${pkgver}` exacto (§1.1, §5.1). |
| **`omarchy update`** | Flujo de actualización normal que mantiene las máquinas: `pacman -Sy`, `yay -Sua`, mise, migraciones y hooks. Actualiza paquetes YA instalados; no instala paquetes nuevos. |
| **`omarchy-personal.db`** | Alias del `omarchy.db` en gh-pages; pacman resuelve la db por el nombre de sección `[omarchy-personal]` (Etapa 4). |
| **par (lockstep)** | el par de paquetes `omarchy` + `omarchy-settings`. |
| **pin / pin engine** | `bin/omarchy-pkgs release` reescribe el par con `_tag`/`_commit`/`pkgver`/`sha256sums` del commit base a publicar. Resetea `pkgrel` a 1 en cada cambio de `pkgver` (§5.1). |
| **`pinned`** | Marca en `.omarchy/package.json` (`"pinned": true`): el paquete se genera por el pin engine y NO builda nativo a `stable` (por eso el un-pin temporal local en la Action). |
| **`personal: true`** | Marca en `.omarchy/package.json` del PKGBUILD: EL flag que hace que la Action lo publique en el repo personal. |
| **`pkgrel`** | Componente de la versión pacman después del guion (`4.0.2-102`). En el par personal es un contador de republicación (§5.3), base 99, incremento por cada república del mismo `pkgver` (hoy autoderivado por la Action). |
| **`pkgver`** | Versión del paquete (`4.0.2`). En el par personal = tag upstream base de la rama `personal`. |
| **repo personal** | `robert-flo/omarchy-personal-repo` (Pages). Es un repo pacman de solo `stable`. |
| **shading / sombreado parcial** | Modelo de repos en máquina: `[omarchy-personal]` listado ANTES de `[omarchy]` → el par y los extras personales se sirven del repo personal, el resto del ecosistema del mirror oficial (Etapa 4, §1.5). |
| **stable** | Único canal publicado por el repo personal (no edge/rc). |
| **un-pin temporal** | El truco del build personal: marcar temporalmente `"pinned": false` (sin commitear) para que el par buildee directo a `stable`. |
| **`vercmp`** | Comparador de versiones pacman (gana el pkgver más alto; a igual pkgver, el pkgrel más alto). Regia del sombreado (§5.2, §5.3). |
| **webapp** | Aplicación que Omarchy sirve como `.desktop` estático (`applications/<Nombre>.desktop` + icono); cualquier `.desktop` nuevo entra al paquete sin tocar PKGBUILD (§1.3, `webapp-workflow.md`). |