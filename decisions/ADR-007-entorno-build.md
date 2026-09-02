# ADR-007 — Entorno de build: `archlinux:base-devel` rolling (decisión declarada)

- **Estado:** Aceptada con riesgo declarado (S3 de la revisión L8)
- **Fecha / hito:** revisión L8, 2026-09-01

## Contexto

La Action builda dentro de `docker run archlinux:base-devel` (imagen **rolling**: el tag mutable
sigue la última versión de Arch). Un build reproducible al 100% exigiría pin a digest
(`archlinux:base-devel@sha256:…`). Upstream builda igual (rolling, en su propia infra) y el repo
personal solo sirve `stable`, con una cadencia de rebuild muy baja (solo cuando cambias la fuente).

## Decisión

- **Mantener `archlinux:base-devel` rolling**, de forma consciente y documentada.
  - Justificación: cada release reconstruye todo el conjunto publicado; el pin a digest solo daría
    determinismo byte-a-byte entre two runs del MISMO commit, que no es un caso real
    (cada republicación cambia `pkgrel` → ya es un build distinto).
  - Riesgo aceptado: un update de base-devel podría cambiar deps/comportamiento entre dos
    republicaciones del mismo `pkgver`. Impacto real en este proyecto: bajo (una o dos máquinas,
    mismo usuario que controla ambos lados).
- **Acción de seguimiento (no bloqueante):** si algún día el repo personal se usa para instalar en
  terceros o se exige reproducibilidad byte-a-byte, migrar a:
  - `docker pull archlinux:base-devel` en el pipeline y usar el digest de esa imagen en el `run`,
    guardado (o documentado) en el propio workflow, reevaluado en cada cadencia W9.

## Consecuencias

- Simplicidad a costa de no tener determinismo estricto (declarado, no oculto).
- El guard §5.3 y la validación post-publicación siguen cubriendo la seguridad funcional.
- Cualquier cambio a pin-digest debe pasar por un ADR que lo reemplace (ver index).

## Fuentes

- `agents_fork.md` W7 paso 2 (docker run `archlinux:base-devel`).
- Revisión L8, hallazgo S3.