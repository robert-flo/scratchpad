# Changelog

All notable changes to the Omarchy Personal Fork Documentation & Scratchpad repository will be documented in this file.

## [2026-09-29]

### Added
- **Repository Publication**: Created and published canonical `robert-flo/scratchpad` public repository on GitHub to provide persistent cloud backup and transparent documentation access for the Omarchy personal fork.
- **Root Restructuring**: Relocated documentation repository from legacy path `OLD/Omarchy-Fork/robert-flo-scratchpad` directly into the active workspace root (`pj-omarchy-fork/robert-flo-scratchpad`).
- **Initial Changelog**: Added `CHANGELOG.md` to record architectural updates, runbook revisions, decision logs (ADRs), and cross-repository synchronization milestones.

### Architectural Context & Components
- **Canonical Architecture Matrix**: Preserved [`ARCHITECTURE.md`](ARCHITECTURE.md) as the single source of truth for fork modifications (Decision Matrix, dev vs machine distribution flows).
- **Master Plan & Guidelines**: Preserved [`agents_fork.md`](agents_fork.md) normative rules governing upstream synchronization, lockstep release pins, and pacman repository publication via GitHub Pages.
- **Operational Runbook**: Maintained [`RUNBOOK.md`](RUNBOOK.md) failure modes, cadence checks, and recovery procedures.
- **Safety Backups**: Verified full binary git bundle in `backups/scratchpad-backup.bundle` to guarantee physical recovery resilience.
