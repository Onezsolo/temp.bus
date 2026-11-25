# Verified knowledge changelog

Only entries backed by a checkpoint, git state and executed test evidence belong here.

## 2026-11-25 - House orchestration bootstrap

- Adopted the PATU Studio specialist catalog (19 agents), master coding rules and specialist-skill map into central knowledge.
- Added the central knowledge manifest and per-project summaries, the main-brain orchestrator, knowledge-scribe, file claims, task context packages, checkpoints, handover/failover, verified knowledge sync and the Agent Manager 89% handoff integration.
- Evidence: `scripts/ai-workflow-selftest.ps1` passed 33 checks covering context preparation, claim conflicts, checkpoint evidence, handover, failover, resume, verified knowledge sync and session-independent persistence. `scripts/house-audit.ps1` passed all checks.
- Limitations: the Visual Studio Code extension must reload before the new `main-brain` and specialist agents are selectable; the PATU Studio FastAPI/PostgreSQL runtime was not started, so only its agents/rules/task semantics are reused. Live Agent Manager concurrency and quota failover were not exercised beyond the state-machine self-test.

