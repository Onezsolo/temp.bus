---
description: Record a verified task checkpoint with real test evidence
---
Before checkpointing:

1. Read the active task and its context package.
2. Confirm every edited file is claimed by this task.
3. Run the project's actual verify command from `projects.json`.
4. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action checkpoint -TaskId "<task-id>" -TestCommand "<verify command>"
```

The checkpoint records the real git state, changed files, exit code and evidence. A failed test is a failed checkpoint, not a completion. Do not claim completion without fresh evidence. If the task is not complete, create a handover.
