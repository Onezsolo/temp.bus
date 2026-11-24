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
