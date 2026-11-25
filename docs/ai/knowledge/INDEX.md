# Central knowledge index

This is the permanent, repository-backed knowledge layer for the Template Business house. Agents are temporary workers; code, verified checkpoints and this knowledge survive sessions.

## Load order

1. `AGENTS.md` - mandatory house rules.
2. `docs/ai/knowledge/INDEX.md` (this file).
3. `docs/ai/knowledge/MASTER_RULES.md` - adopted PATU Studio master rules.
4. The target project's summary below, its rule sources, and task context package.
5. Only then the task's expected files and immediate dependencies.

Do not perform a full-worktree onboarding before every task. The orchestrator prepares a task context package with the relevant knowledge and file references.

## Knowledge files

- `projects.json` - machine-readable project manifest (stack, rules, verify commands, key paths, current commits).
- `projects/<name>.md` - per-project verified summary and architecture notes.
- `VERIFIED_STATE.json` - latest verified checkpoint per project.
- `CHANGELOG.md` - verified changes, newest first.
- `DECISIONS.md` - settled decisions and rationale.
- `KNOWN_ISSUES.md` - confirmed issues and limitations.
- `studio-specialists.json` - adopted Studio specialist catalog.
- `studio-skill-map.json` - specialist-to-skill mapping.
- `MASTER_RULES.md` - adopted Studio master coding rules.
- `UNSLOP.md` - shared design skill installation, discovery and usage rules.

## Shared tools

- Unslop design skill: `C:\laragon\www\template-business\.kilo\skills\unslop\SKILL.md`. Use it for UI/UX, frontend, layout, visual, copy, typography, motion, responsive and design-review tasks; do not invoke it for backend-only work. It is registered globally through `skills.paths`; do not copy it into child projects. Project design systems and tokens take precedence.

## Projects

| Project | Type | Knowledge | Remote |
|---|---|---|---|
| AFA-GHANA | Laravel | `docs/ai/knowledge/projects/AFA-GHANA.md` | https://github.com/Onezsolo/afa.git |
| datatem | Laravel base clone | `docs/ai/knowledge/projects/datatem.md` | https://github.com/Onezsolo/datatem.git |
| novagel | Laravel | `docs/ai/knowledge/projects/novagel.md` | https://github.com/Onezsolo/novagel.git |
| one-system | Laravel | `docs/ai/knowledge/projects/one-system.md` | https://github.com/Onezsolo/datatem.git |
| patu-design-intelligence | Python FastAPI + SvelteKit | `docs/ai/knowledge/projects/patu-design-intelligence.md` | https://github.com/Onezsolo/patu-codes.git |
| patu-research | Python FastAPI + Next.js | `docs/ai/knowledge/projects/patu-research.md` | https://github.com/Onezsolo/patu-research.git |
| patu-technologies | Python FastAPI + SvelteKit | `docs/ai/knowledge/projects/patu-technologies.md` | https://github.com/Onezsolo/patu-codes.git |
| PATUchat | Laravel | `docs/ai/knowledge/projects/PATUchat.md` | https://github.com/Onezsolo/PATUchat.git |
| patupa | Laravel | `docs/ai/knowledge/projects/patupa.md` | https://github.com/Onezsolo/patupa.git |
| patupaa-worker | Laravel worker | `docs/ai/knowledge/projects/patupaa-worker.md` | https://github.com/Onezsolo/patupa.git |

## Task lifecycle

`intake -> context -> claim -> assign -> checkpoint -> handover/failover -> resume -> sync`

Task state and handover records live under `docs/ai/tasks`. Runtime claims live under the house main worktree's `.kilo/ai/`. Use `scripts/ai-orchestrator.ps1`.