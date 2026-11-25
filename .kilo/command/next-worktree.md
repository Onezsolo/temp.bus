---
description: Create the next Template Business working place at the 89% context handoff
---
At 89% context, or before compaction:

1. Finish the current step. Do not start new work.
2. Ensure the house worktree and every touched child project repository are clean. Commit or explicitly hand off intended changes.
3. Write a handoff note at `docs/ai/handoffs/<timestamp>-<branch>.md` with the branch, HEAD, changed files, tests, blockers and next step. Commit it with the current house work.
4. Determine the next number `N` from existing branches `house/work-place-*`.
5. Create the next working place with Agent Manager in `worktree` mode:
   - name: `House Work N`
   - branchName: `house/work-place-N`
   - baseBranch: the current house branch
   - no initial prompt; this is a prepared working place
6. Read the new worktree path from Git or Agent Manager, then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/link-house-projects.ps1 -WorktreePath "<new-worktree-path>"
```

7. Run `scripts/house-audit.ps1` inside the new worktree and confirm it is clean.
8. Report the new path, branch and Agent Manager session name. The user opens that session as the next chat.

Do not create the worktree if any repository is dirty. Do not force-push or discard another contributor's work.
