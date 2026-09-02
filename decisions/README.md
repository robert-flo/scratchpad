# decisions/ — Registro de decisiones (ADRs)

Decisiones de arquitectura/operación del proyecto, extraídas de las "Decisiones registradas" del
`WORKLOG.md` y de la revisión L8 (2026-09-01). Cadena ADR significa **Arquitecture Decision
Record**; aquí el formato es aligerado pero conserva la estructura: Contexto → Decisión →
Consecuencias.

## ¿Cómo se registra una decisión?

1. En el `WORKLOG.md` de la sesión queda la motivación con detalle (qué pasó, por qué).
2. Si la decisión afecta a cómo se mantiene/opera el proyecto a futuro, se **promueve** a un ADR
   acá (enlace del WORKLOG en la sección "Fuentes").
3. Todo ADR tiene estado: **Aceptada** (vigente), **Reemplazada** (señala al ADR que la sustituye),
   **Deprecated**.
4. Para cambiar una decisión vigente: escribir un nuevo ADR que la reemplace (nunca editar el
   histórico como si no hubiera pasado).

## Índice

| ADR | Sección del WORKLOG / hito | Estado |
|---|---|---|
| [ADR-001 — Hosting: GitHub Pages + GitHub Actions como build host](ADR-001-hosting-github-pages.md) | 4ª parte (Etapa 3) | Aceptada |
| [ADR-002 — Solo canal stable en el repo personal](ADR-002-canal-estable-solo.md) | 4ª parte | Aceptada |
| [ADR-003 — Sombreado parcial: `[omarchy-personal]` antes de `[omarchy]`](ADR-003-sombreado-parcial.md) | 5ª parte (Etapa 4) | Aceptada |
| [ADR-004 — Regla §5.3: `pkgrel` base alta + incremento por republicación](ADR-004-regla-pkgrel.md) | 7ª parte; hoy autoderivado (L8) | Aceptada (mecánica = L8) |
| [ADR-005 — Publicación de TODOS los `personal: true` (no solo el par)](ADR-005-marcador-personal.md) | 8ª parte (generalización) | Aceptada |
| [ADR-006 — Claves GPG y deploy key: modelo de confianza, rotación y DR](ADR-006-claves-gpg.md) | 4ª parte + revisión L8 (S1) | Aceptada |
| [ADR-007 — Entorno de build rolling vs pin a digest](ADR-007-entorno-build.md) | revisión L8 (S3) | Aceptada (riesgo declarado) |

## Enlaces

- `agents_fork.md` §0.2 — "Decisiones ya fijadas (Q&A previo)" (versión resumida en el plan).
- `agents_fork.md` §5 — invariantes operativos (traducción de varias decisiones a reglas de operación).
- `RUNBOOK.md` — los puntos de recuperación de las decisiones (p. ej. roll-forward, rotación de claves).