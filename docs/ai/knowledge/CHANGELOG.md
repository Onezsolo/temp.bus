# Verified knowledge changelog

Only entries backed by a checkpoint, git state and executed test evidence belong here.

## 2026-11-25 - House orchestration bootstrap

- Adopted the PATU Studio specialist catalog (19 agents), master coding rules and specialist-skill map into central knowledge.
- Added the central knowledge manifest and per-project summaries, the main-brain orchestrator, knowledge-scribe, file claims, task context packages, checkpoints, handover/failover, verified knowledge sync and the Agent Manager 89% handoff integration.
- Evidence: `scripts/ai-workflow-selftest.ps1` passed 33 checks covering context preparation, claim conflicts, checkpoint evidence, handover, failover, resume, verified knowledge sync and session-independent persistence. `scripts/house-audit.ps1` passed all checks.
- Limitations: the Visual Studio Code extension must reload before the new `main-brain` and specialist agents are selectable; the PATU Studio FastAPI/PostgreSQL runtime was not started, so only its agents/rules/task semantics are reused. Live Agent Manager concurrency and quota failover were not exercised beyond the state-machine self-test.

## 2026-11-25 - Shared Unslop design skill

- Installed the complete official Unslop skill at the house parent (`C:\laragon\www\template-business\.kilo\skills\unslop`) with the CC-BY-4.0 license and a `.kilocode/skills/unslop` compatibility junction.
- Registered the parent skills directory in the global Kilo `skills.paths`; added scoped read/external-directory permissions for the shared skill.
- Added UI task context injection, `/design-review`, design/frontend/mobile specialist addenda and central knowledge `UNSLOP.md`.
- Verified: `verify-unslop.ps1` 9 PASS; workflow self-test 35 PASS; live `kilo run` read-only discovery/read passed in AFA-GHANA and patu-research; delegated `specialists/design` read passed.
- Limitations: the non-interactive CLI rejected the `skill` tool itself despite the permission setting, so access was verified through the read tool; alternate paid model failed on credits, so live model failover was not exercised.

## 2026-11-25 - Website grouping

- Grouped the 10 checkouts into 8 websites in `projects.json.websites`; same-repository variants are working copies, not separate products.
- Updated `WEBSITES.md`, the knowledge index, all project summaries, the orchestrator context and the public showcase to count each website once. No checkout was moved.
- `patupa` + `patupaa-worker`, `datatem` + `one-system`, `patu-technologies` + `patu-design-intelligence`, and the two Patutrade clones are recorded as one website each.
- Verified: house audit passes all 8 website groups; showcase serves 8 cards; workflow self-test passes.

