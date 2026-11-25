---
description: Create a central task, context package and ownership plan
---
Use the main-brain orchestration workflow.

1. Identify the target project, title, objective, expected files, dependencies, priority and risk from the user request.
2. Create the task and context package:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action intake -Project "<project-name>" -Title "<task-title>" -Objective "<expected outcome>" -Files "path/one","path/two" -Priority "medium"
```

3. Read the generated `docs/ai/tasks/<task-id>/context.md`. Do not perform a full-worktree discovery.
4. Claim the expected files:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action claim -TaskId "<task-id>"
```

5. Select an eligible specialist from `docs/ai/knowledge/studio-specialists.json` and an eligible Agent Manager session. Assign the task with `-Action assign` and record the session ID, worktree and branch.
6. Give the worker only the task ID, context path, claimed files and required evidence. The worker must inspect the actual relevant files before editing.

If the task is high risk (security, financial, production, credentials), require explicit approval before implementation.
