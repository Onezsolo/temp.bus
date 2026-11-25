# Template Business house rules (mandatory)

HOUSE RULE: TEMPLATE BUSINESS

This folder is the house for every project built here. These rules apply to every agent, task, subagent and future project under `C:\laragon\www\template-business`.

## 1. Repository boundary (non-negotiable)

- Every direct child folder that contains `.git` is an independent project repository with its own history, branches and remote. That is the intended structure; never flatten, absorb or re-initialize it.
- The house repository tracks only house files: `AGENTS.md`, `projects.json`, `.gitignore`, `.githooks/`, `.kilo/`, `docs/ai/`, `scripts/` and the showcase under `public/`.
- Never stage, commit, move, rename, delete or rewrite a child project's files or `.git` metadata from the house repository. `.gitignore` excludes child projects and `.githooks/pre-commit` blocks them.
- Never create a nested repository inside a project. Never use one project's remote as the house remote.
- Work on code only inside the target project's own repository. Use the house only for the showcase, registry and shared rules.
- Before changing a child project, check `git status` in that project. Never discard another contributor's uncommitted work. If you take over unfinished work, finish it or report exactly what remains.

## 2. Required reading before work

1. Read this file.
2. Read `docs/ai/PROJECT_RULES.md` for the target project's mandatory rules and source paths.
3. Read the target project's own `AGENTS.md`, `CLAUDE.md`, `.ai/rules/*`, applicable `.claude/skills/*` and relevant `.kilo` config. Project rules are authoritative inside the project.
4. Inspect the target repository and the actual source before editing.

Rule precedence: platform and user instructions > target project rules > house defaults. The repository boundary in section 1 is non-negotiable. If a project rule conflicts with a platform safety rule, stop and report the conflict.

## 3. Communication

Treat the user as a coequal professional. Be direct, technical and evidence-based; state assumptions, trade-offs, disagreement and uncertainty explicitly; do not over-simplify to please. Challenge weak assumptions.

After every completed stage report: what changed, exact file paths, commands/tests and results, blockers, and the next step. Never claim completion without evidence.

## 4. Work and verification

- Keep changes scoped to the target project. Never mix projects in one change or commit.
- Use the project's own test, build and lint commands (listed in `projects.json`). Never claim done without running the relevant checks.
- Never put secrets, credentials, tokens, customer data or infrastructure credentials in any repository, rule file, summary, log or report. Do not copy infrastructure details into the house; `docs/ai/PROJECT_RULES.md` is a sanitized summary.
- Follow the target project's conventions, framework versions and mandatory rules.

## 5. Git and delivery

- Commit, amend, push or open a PR only when the user explicitly authorizes it, or when the target project's standing workflow authorizes that step after a user-assigned implementation task. Never commit secrets, unrelated files or generated artifacts.
- Child delivery rules (for example patupa's post-task commit rule) apply inside that child repository and only after its tests pass.
- Never force-push, rewrite shared history, deploy or restart production without explicit approval.
- Do not push directly to a protected/main branch where the project requires a branch and PR.

## 6. New projects

A new project added under the house must:

1. live in its own folder and its own `.git` repository/remote;
2. include an `AGENTS.md` with a pointer to this house rule;
3. be added to `projects.json`;
4. be added to `.gitignore` as `/ProjectName/`;
5. be indexed in `docs/ai/PROJECT_RULES.md`;
6. pass `scripts/house-audit.ps1`.

## 7. Mandatory audit

Run the audit when starting and before reporting house work:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\laragon\www\template-business\scripts\house-audit.ps1"
```

After a project changes its rule files, refresh the rule lock so the change is reviewed deliberately:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\laragon\www\template-business\scripts\sync-rule-hashes.ps1"
```

The audit fails when the house remote is wrong, a child repository is unregistered or not ignored, a project remote is missing, a rule source is missing or changed without a lock refresh, or the house pre-commit hook is not configured.

## 8. Public page standard

For any house project with public pages, every customer-facing page ships with:

- a descriptive title and meta description;
- a canonical URL;
- Open Graph and Twitter metadata;
- the relevant JSON-LD;
- a sitemap entry;
- a public navigation or footer link;
- focused tests for the page and its metadata.

An authenticated version is additional to a public page, never a replacement. Do not launch a service only behind login unless the user explicitly requires it.

## 9. Context handoff worktrees

The house uses numbered working places: Agent Manager worktrees on branches `house/work-place-N`. Child projects are linked into each worktree as junctions so they remain independent repositories.

The chat context indicator is owned by the client. When it reaches 89% (or before compaction), the handoff is triggered:

1. Stop starting new work and finish the current step.
2. Ensure the house worktree and every touched project repository are clean; commit or explicitly hand off intended changes.
3. Write `docs/ai/handoffs/<timestamp>-<branch>.md` with the branch, HEAD, changed files, tests, blockers and next step.
4. Run `/next-worktree` to create the next Agent Manager worktree, link the projects and open the next chat there.
5. Report the new worktree path and branch.

Never create the next worktree silently or leave uncommitted work behind. The agent cannot see the client's 89% indicator, so the user or client must trigger the handoff.

## 10. Central knowledge and main-brain orchestration

The house is knowledge-driven, not session-driven. Agents are temporary workers.

- Permanent knowledge lives in `docs/ai/knowledge/`: project summaries, adopted Studio specialist catalog, Studio master rules, decisions, known issues, verified state and changelog.
- Permanent task history lives in `docs/ai/tasks/`: task records, context packages, checkpoints, evidence, handovers and failover packages.
- The `main-brain` agent is the default house orchestrator. It retrieves knowledge, prepares task context, selects eligible agents/specialists, assigns work through Agent Manager/VS Code, monitors, handles failover, verifies and synchronizes knowledge.
- Agents must not perform a full-worktree onboarding for each task. Use the task context package and then inspect only the actual files required. Never sacrifice correctness or security to reduce context.
- Before editing, claim the task's files with `scripts/ai-orchestrator.ps1 -Action claim`. Never edit files claimed by another task. Release claims at completion or handover.
- Record a real checkpoint after each verified step, with the executed test command and actual result. A checkpoint is not completion.
- On completion, quota exhaustion, error, session loss or replacement, write a handover or failover package. The replacement must verify the actual workspace and continue from the last verified checkpoint; never assume an interrupted task is finished.
- Run `scripts/ai-orchestrator.ps1 -Action sync` only after verified tests and a clean project state. The knowledge-scribe updates the human-readable architecture, decisions and known issues from actual diffs and evidence.
- The adopted Studio specialist definitions are in `docs/ai/knowledge/studio-specialists.json` and `.kilo/agent/specialists/`. The master rules are in `docs/ai/knowledge/MASTER_RULES.md`.
- Agents must not independently redefine project architecture or override settled decisions without authorization. Escalate cross-project or high-risk decisions to the main brain and the user.
- Required flow: KNOWLEDGE -> PLAN -> CONTEXT -> ASSIGN -> IMPLEMENT -> CHECKPOINT -> HANDOVER/FAILOVER -> NEXT AGENT -> INTEGRATE -> KNOWLEDGE SYNC.

## 11. Shared design skill (Unslop)

Unslop is installed once at the house root: `.kilo/skills/unslop/SKILL.md`, with references and scripts in the same folder. A `.kilocode/skills/unslop` compatibility link points to the same copy. It is shared through the global Kilo `skills.paths` setting and must not be copied into individual projects.

- Use Unslop for UI, UX, frontend, layout, visual, copy, typography, motion, responsive or design-review tasks.
- Do not invoke Unslop for backend, database, infrastructure, API or payment-only tasks.
- Project-specific design systems, tokens, brand assets and component conventions take precedence. Unslop improves craft; it does not replace the product identity.
- The skill is licensed CC-BY-4.0; keep the attribution in the skill.
- The central orchestrator adds the skill to UI task context packages automatically. Design, frontend and mobile specialists must consult it; other specialists should not.

## 12. Website arrangement

- The house groups checkouts by website/repository. A website may have several independent working copies on different branches: `patupa` + `patupaa-worker`, `datatem` + `one-system`, `patu-technologies` + `patu-design-intelligence`, and the Patutrade clones.
- `projects.json.projects` is the checkout registry, because every checkout has its own Git boundary. `projects.json.websites` and `docs/ai/knowledge/WEBSITES.md` are the website grouping.
- Count each website once in the showcase, knowledge, audits and reports. A branch working copy is not a separate product.
- The primary working copy is the current implementation for audits and demos; branch variants are recorded underneath the website.
- Do not move, rename, merge or delete a checkout to consolidate a website unless the user explicitly authorizes a structural migration.




