# ADR-002 — El repo personal publica SOLO el canal stable

- **Estado:** Aceptada
- **Fecha / hito:** Etapa 3 (WORKLOG 4ª parte)

## Contexto

Upstream publica tres canales (`edge`, `rc`, `stable`) y un walk de promoción entre ellos. El repo
personal solo necesita servir a máquinas que corren el canal estable.

## Decisión

- Publicar solo `stable` en `robert-flo/omarchy-personal-repo`; no replicar `edge`/`rc` ni el walk
  de promoción.
- Las máquinas no requieren más: su `[omarchy-personal]` se lista ANTES de `[omarchy]` (ADR-003) y
  resuelve exactamente lo que shippea el fork en stable.

## Consecuencias

- El guard §5.3 (officest vs. personal en `stable`) se compara contra `pkgs.omarchy.org/stable`.
- Cualquier necesidad futura de edge/rc personal = nuevo ADR (probablemente innecesaria).

## Fuentes

- `agents_fork.md` §0.2 ("Canal a publicar: solo stable").