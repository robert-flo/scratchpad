# 03 — Uso diario

Lo que usarás en el día a día. Una cosa para recordar siempre:

> `omarchy update` **actualiza** lo que está instalado; **no instala** paquetes nuevos.
> Un paquete personal nuevo se instala una vez a mano y de ahí en adelante se mantiene solo.

## Mantener el sistema

```bash
omarchy update
```

Actualiza los paquetes (pacman + AUR + mise), corre las migraciones y los hooks. Es el único
comando de mantenimiento que existe.

## Instalar un paquete personal nuevo

```bash
pacman -S hola-mundo
```

El paquete se resuelve desde el repositorio `[omarchy-personal]`. Instalado una vez, `omarchy
update` lo mantiene al día (p. ej. `0.1.0-1 → 0.1.0-2`).

## Reconciliar la lista de paquetes entre máquinas

```bash
omarchy reinstall pkgs
```

Instala todo lo que la lista del sistema personal (`omarchy-base.packages`) dice que debe estar.
Úsalo al incorporar una máquina o cuando cambies esa lista (y también para traer de una vez los
paquetes personales que decidiste que vayan en todas las máquinas).

## Volver a sembrar las configs de usuario

```bash
omarchy reinstall-configs     # copia TODO /etc/skel sobre tu usuario (destructivo; con cuidado)
# o, más fino, un componente o archivo suelto:
omarchy refresh shell
omarchy refresh config hypr/bindings.lua
```

## Comandos útiles para verificar

```bash
pacman -Q omarchy omarchy-settings        # versión del par (debe ser la personal, p. ej. 4.0.2-101)
pacman -Qn                                # lista de paquetes instalados
omarchy version
```

## Problemas comunes

**"Después de `omarchy update` algo se actualizó y perdió mi personalización".** El síntoma típico
es la versión del par que ya no es la personal. En máquinas normales no debería pasar (el sistema
personal tiene prioridad por versión y por posición; el propio proceso de publicación aborta si
alguna vez queda detrás del oficial). Si ocurre en una máquina de desarrollo con el par `-dev`
local, es un caso aparte: ver la advertencia del `bootstrap-omarchy-dev.sh`.

**`omarchy update -y` se cuelga unos minutos y aborta con "Something went wrong"** (sesiones
automáticas, sin terminal). Es un quirk de `sudo` de cómo Omarchy mantiene despierta la sesión
(`sudo -v` bajo pty): con contraseña en sudoers `sudo -v` sigue pidiendo la contraseña y el prompt
expira a los ~5 min. En una **terminal normal** no molesta (pide la contraseña y sigue). Si necesitas
el update totalmente automatizado, se resuelve con un drop-in temporal:

```bash
echo 'Defaults:TU_USUARIO !authenticate' | sudo tee /etc/sudoers.d/100-e2e-noauth
sudo visudo -c                       # validar sintaxis
omarchy update -y                    # ahora sí, sin colgarse
sudo rm /etc/sudoers.d/100-e2e-noauth   # retirarlo: dejar la máquina como estaba
```

**Una webapp nueva no aparece en el launcher.** Cambiar el paquete no toca los lanzadores del
usuario actual; hay que refrescarlos:

```bash
omarchy-refresh-applications
```