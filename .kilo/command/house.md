---
description: Audit the Template Business house and load its mandatory rules
---
Read @AGENTS.md and @docs/ai/PROJECT_RULES.md before acting.

Run the house audit:

!`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/house-audit.ps1`

Then identify the target project, read its own `AGENTS.md`, `CLAUDE.md`, `.ai/rules/*`, applicable `.claude/skills/*` and `.kilo` config, and work only inside that project's repository.

Never stage, move or commit a child project through the house repository. Report changed files, commands, test results, blockers and the next step.
