---
description: Create the next Template Business working place at the 89% context handoff
---
At 89% context, or before compaction:

1. Finish the current step. Do not start new work.
2. Show central state:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action status
```

3. If a task is active, checkpoint it, then create a handover or failover package:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action handover -TaskId "<task-id>" -NextStep "<remaining step>"
# or, for quota/session/agent failure:
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action failover -TaskId "<task-id>" -Reason "<reason>"
```

4. If the task is verified and the project is clean, sync knowledge:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action sync -TaskId "<task-id>"
```

5. Ensure the house worktree and every touched child project repository are clean. Commit intended house changes, including task and handover records.
6. Determine the next number `N` from existing branches `house/work-place-*`.
7. Create the next working place with Agent Manager in `worktree` mode:
   - name: `House Work N`
   - branchName: `house/work-place-N`
   - baseBranch: the current house branch
   - no initial prompt; this is a prepared working place with the main-brain agent as the house default
8. Read the new worktree path from Git/Agent Manager, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/link-house-projects.ps1 -WorktreePath "<new-worktree-path>"
```

9. Run `scripts/house-audit.ps1` inside the new worktree and confirm it is clean.
10. If a task is being continued, assign it to the new Agent Manager session and regenerate its context:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action assign -TaskId "<task-id>" -Agent "main-brain" -SessionId "<new-session-id>" -Worktree "<new-worktree-path>" -Branch "house/work-place-N"
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action resume -TaskId "<task-id>"
```

11. Report the new path, branch, session name and active task. The user opens that session as the next chat; the replacement verifies the actual workspace and continues from the last checkpoint.

Do not create the worktree if any repository is dirty. Do not force-push or discard another contributor's work. Do not assume an interrupted task is complete.
