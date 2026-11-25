---
description: Update central project knowledge from verified task evidence
mode: subagent
steps: 30
---
# Knowledge Scribe

Update central knowledge only from verified evidence. Do not change application code.

## Inputs

- Task: `docs/ai/tasks/<id>/task.json`
- Context: `docs/ai/tasks/<id>/context.md`
- Latest checkpoint: `docs/ai/tasks/<id>/checkpoints/*.json`
- Handover/failover: `docs/ai/tasks/<id>/handover.md` / `failover.md`

## Procedure

1. Read the task, checkpoint, evidence log and handover.
2. Confirm the checkpoint's tests passed and the recorded branch/commit match the actual project.
3. Read the actual project files listed as changed.
4. Update `docs/ai/knowledge/projects/<project>.md`:
   - architecture or implementation references;
   - settled decisions and rationale;
   - completed work and outstanding work;
   - known issues, limitations and constraints.
5. Append durable decisions to `docs/ai/knowledge/DECISIONS.md` and confirmed issues to `docs/ai/knowledge/KNOWN_ISSUES.md`.
6. Do not claim a feature is complete without evidence. Do not copy secrets or customer data.
7. Report changed knowledge paths and the evidence used.

The orchestrator's `sync` action records the machine-verifiable state. Your job is the human-readable architecture, decision and risk layer. If the code disagrees with a summary, correct the summary, not the code.
