# 02 — Instalar una máquina nueva

Cómo dejar cualquier máquina (x86_64, instalada con la ISO oficial estable de omarchy.org) en tu
**sistema personal**. Son 8 pasos; se hacen una sola vez por máquina. (El detalle del *porqué* de
los launchers está en [`docs/06-launchers.md`](06-launchers.md)).

## Antes de empezar

Necesitas el archivo de la clave pública del repositorio personal:
`keys/omarchy-personal-repo.pub.asc` (vive en este repositorio de notas).

> Nota de seguridad: solo se comparte la **clave pública** (firma).
> La privada nunca sale del proyecto.

## Los pasos

```bash
# 1) Confiar la clave del repo personal en esta máquina (una vez, como root)
sudo pacman-key --add /ruta/a/omarchy-personal-repo.pub.asc
sudo pacman-key --lsign-key D5E75EAC51A44715

# 2) Instalar el par personal la primera vez (aún no hay repo configurado)
#    Descarga desde el navegador (o curl):
#    La versión actual del par se lee de la tabla de estado del README (hoy 4.0.2-103).
    #    Descarga desde el navegador (o curl):
    #    https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/omarchy-<VERSIÓN>-any.pkg.tar.zst
    #    …y su .sig (mismo nombre + .sig), e instala AMBOS a la vez (misma versión, obligatorio):
sudo pacman -U omarchy-<VERSIÓN>-any.pkg.tar.zst omarchy-settings-<VERSIÓN>-any.pkg.tar.zst
#    El .sig descargado al lado del .pkg.tar.zst lo verifica pacman automáticamente
#    (Good signature de D5E75EAC51A44715); no hace falta pasarlo como argumento.

# 3) Escribir el pacman.conf del sistema personal (ya trae el repo personal ANTES del oficial)
omarchy refresh pacman

# 4) Update completo: convergencia de paquetes, migraciones y hooks
omarchy update

# 5) Reconciliar la lista de paquetes con la del sistema personal
omarchy reinstall pkgs

# 6) [Solo si ya exite el primer usuario o vas a usarlo enseguida — y solo DESPUÉS
#    de haber instalado el par personal en el paso 2; el bootstrap usa sus helpers y `yay`]
#    Instala las dependencias que corren los launchers del fork (CLIs de IA, navegador
#    Edge, TUI helpers, Hermes, app desktop de OpenCode, ~/src). Idempotente.
bash <(curl -fsSL https://raw.githubusercontent.com/robert-flo/omarchy/personal/bin/omarchy-personal-bootstrap-launchers)

# 7) Materializa las configs del sistema personal sobre tu usuario:
omarchy reinstall-configs
```

## Comprobar que quedó bien

```bash
pacman -Q omarchy omarchy-settings      # → omarchy 4.0.2-103 (misma versión ambos)
pacman -Q hola-mundo                    # → hola-mundo 0.1.0-2  (instálalo antes si quieres)
omarchy-debug --no-sudo --print         # sin errores
bash <(curl -fsSL https://raw.githubusercontent.com/robert-flo/omarchy/personal/bin/omarchy-personal-bootstrap-launchers)
                                        # → "done: every launcher binary resolves."
```

Además, en `/etc/pacman.conf` debes ver la sección `[omarchy-personal]` **antes** de `[omarchy]`
(vigila que el orden sea ese).

## Qué pasa si en el paso 4 ves "Something went wrong"

Es una pecularidad conocida del update no interactivo (ver **03 — Problemas comunes**). En una
terminal normal solo te pedirá la contraseña y seguirá. No hay nada roto en el sistema.