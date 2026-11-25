---
description: Hand over or fail over a task without losing progress
---
1. Confirm the task and actual workspace state.
2. Record a final checkpoint if the current work is testable.
3. Create the handover:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action handover -TaskId "<task-id>" -NextStep "<remaining step>"
```

For quota exhaustion, session loss, an unavailable agent or a stale task:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action failover -TaskId "<task-id>" -Reason "<reason>"
```

4. Read `docs/ai/tasks/<task-id>/handover.md` and `failover.md` (when present).
5. Create or select a replacement Agent Manager session, give it the task ID, context path and handover, and reassign the task.
6. The replacement must verify the actual workspace, claim the remaining files and continue from the last verified checkpoint. Never assume an interrupted task is complete.
