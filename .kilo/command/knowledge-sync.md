---
description: Synchronize verified task evidence into central knowledge
---
Perform knowledge sync only after the task has a passing checkpoint and a clean project working tree.

1. Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ai-orchestrator.ps1 -Action sync -TaskId "<task-id>" -Complete
```

2. Run the knowledge-scribe to update the project summary, architecture references, decisions and known issues from the actual diff and evidence.
3. Verify `docs/ai/knowledge/VERIFIED_STATE.json`, `CHANGELOG.md`, `DECISIONS.md`, `KNOWN_ISSUES.md` and the project summary.
4. Release the task's file claims.
5. Report the verified commit, tests, changed files and remaining limitations.

Do not mark a task complete because an agent says it is complete. The checkpoint's tests and the actual workspace are the evidence.
