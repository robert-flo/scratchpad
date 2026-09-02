# 01 — Tu sistema personal de Omarchy

Idea en una frase: todas tus máquinas Omarchy son **idénticas y se mantienen solas** con un solo
comando (`omarchy update`), con tus personalizaciones aplicadas.

## La pieza que hace posible todo: el repo personal

Omarchy instala los paquetes del sistema desde un repositorio oficial (`pkgs.omarchy.org`).
Además de ese, existe un **repositorio personal** alojado en GitHub Pages:

`https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64`

Ese repositorio se construye **solo** desde tu proyecto (un fork del código de Omarchy) en el que
tus personalizaciones están commiteadas como cambios de fuente: webapps, configs, temas, comandos,
y hasta paquetes propios. Una automatización (GitHub Action) lo empaqueta, lo firma y lo publica.

## Qué es el "sombreado" (y por qué te conviene)

En cada máquina, el repositorio personal se lista **antes** del oficial en la configuración de
pacman (lo escribe el propio sistema personal). pacman prefiere el repo listado primero a versión
igual, y además nuestros paquetes llevan un número de versión **por encima** del oficial.
Resultado con una sola regla:

> En cada `omarchy update`:
> **tus paquetes personales** (el motor `omarchy`, `omarchy-settings` y los extras) salen de **tu**
> repositorio;
> **el resto del ecosistema** (el resto de paquetes de Omarchy) sigue saliendo del repositorio
> oficial.

No tienes que combinar nada a mano: el mismo `omarchy update` mezcla ambos orígenes.

## Qué contiene tu repositorio hoy

| Paquete | Para qué | Versión |
|---|---|---|
| `omarchy` + `omarchy-settings` | El motor y los archivos del sistema, con tus personalizaciones | 4.0.2-102 |
| `hola-mundo` | Paquete de ejemplo (prueba de que el mecanismo funciona) | 0.1.0-2 |

Todos los paquetes van **firmados** con una clave propia del proyecto. En la primera máquina se
importa esa clave una sola vez (paso del [documento 02](02-instalar-una-maquina.md)); a partir de
ahí la verificación es automática.

## La cadena completa, en un vistazo

```
1. Cambio en el código (fork) ──► 2. Publicación automática (Github Action)
                                         │
4. `omarchy update` en tus máquinas ◄─── 3. Repositorio personal (GitHub Pages)
```

- **1 → 2** lo haces tú (o tu asistente): cada cambio se commitea y se publica con una orden.
- **3 → 4** es automático: como ya está instalado, `omarchy update` lo trae.

**La única regla de oro:** un paquete personal que no está instalado en una máquina, `omarchy
update` **no lo instala** (solo actualiza lo que ya existe). Cada paquete personal nuevo se instala
**una sola vez** con `sudo pacman -S <paquete>`; de ahí en adelante se mantiene solo. Ver el documento
**[03 — Uso diario](03-uso-diario.md)**.