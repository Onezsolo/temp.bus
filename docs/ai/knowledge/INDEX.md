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

- `projects.json` - machine-readable project and website manifest (stack, rules, verify commands, key paths, current commits).
- `projects/<name>.md` - per-checkout verified summary and architecture notes.
- `WEBSITES.md` - one row per website/repository, with primary and variant working copies.
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

## Websites

One website per repository. Separate checkouts are working copies, not separate products. Full details: `WEBSITES.md`.

| Website | Repository | Primary working copy | Other working copies | Knowledge |
|---|---|---|---|---|
| Datatem | `Onezsolo/datatem.git` | `one-system` (`feat/one-system-foundation`) | `datatem` (base, `main`) | `projects/one-system.md`, `projects/datatem.md` |
| Patupa | `Onezsolo/patupa.git` | `patupa` (`main`) | `patupaa-worker` (`feature/patu-dialer`) | `projects/patupa.md`, `projects/patupaa-worker.md` |
| PATU Technologies | `Onezsolo/patu-codes.git` | `patu-technologies` (`main`) | `patu-design-intelligence` (`design-intelligence`) | `projects/patu-technologies.md`, `projects/patu-design-intelligence.md` |
| AFA Ghana | `Onezsolo/afa.git` | `AFA-GHANA` (`main`) | none | `projects/AFA-GHANA.md` |
| Novagel Imports | `Onezsolo/novagel.git` | `novagel` (`patu/program-f99758f5`) | none | `projects/novagel.md` |
| PATU Research | `Onezsolo/patu-research.git` | `patu-research` (`main`) | none | `projects/patu-research.md` |
| PATUchat | `Onezsolo/PATUchat.git` | `PATUchat` (`main`) | none | `projects/PATUchat.md` |
| Patutrade | `Onezsolo/patutrade.git` | `patutrade.worktrees/patutrade` (`deploy/six-bot-okx-demo`) | `patutrade.worktrees/changes-not-showing-fix` (`agents/changes-not-showing-fix`) | `WEBSITES.md` |

## Task lifecycle

`intake -> context -> claim -> assign -> checkpoint -> handover/failover -> resume -> sync`

Task state and handover records live under `docs/ai/tasks`. Runtime claims live under the house main worktree's `.kilo/ai/`. Use `scripts/ai-orchestrator.ps1`.