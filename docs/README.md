# Documentación del usuario

Estos documentos explican el **cómo** del sistema personal de Omarchy, con ejemplos y comandos,
sin el "porqué" técnico (que vive en el [plan maestro](../agents_fork.md)). Léelos en orden y en
menos de 10 minutos tendrás todo el panorama.

## Lectura rápida

1. [**01 — Tu sistema personal de Omarchy**](01-conceptos.md) — qué es el repo personal, qué es el
   "sombreado", cómo se hace un cambio (5 minutos).
2. [**02 — Instalar una máquina nueva**](02-instalar-una-maquina.md) — dejar una máquina en el
   sistema personal, paso a paso.
3. [**03 — Uso diario**](03-uso-diario.md) — `omarchy update`, instalar un paquete personal,
   reconciliar el set, problemas comunes.
4. [**04 — Webapps**](04-webapps.md) — agregar, cambiar y quitar tus webapps.
5. [**05 — Mantener**](05-mantener.md) — para el mantenedor: añadir un paquete personal nuevo y
   seguir el release de Omarchy upstream.

## Ejemplo real: "quiero echar un vistazo"

```bash
sudo pacman -S hola-mundo     # instala el paquete de prueba desde el repo personal (con sudo: instalas)
hola-mundo                    # imprime el mensaje del paquete
omarchy update                # mantiene TODO tu sistema personal al día
```

Todo lo que las máquinas necesitan para esto ya está publicado y firmado en
<https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64>.