# Unslop shared design skill

## Installation

- Source: https://github.com/heydamir/unslop
- Installed source commit: `620163eedb3529d9cd23a3994ed8d287d06f760d`
- Canonical path: `C:\laragon\www\template-business\.kilo\skills\unslop\SKILL.md`
- Compatibility path: `C:\laragon\www\template-business\.kilocode\skills\unslop\SKILL.md` (directory junction to the canonical copy)
- License: CC-BY-4.0, created by Damir Sokolovsky. The attribution in the skill and the copied `LICENSE` must remain.
- Complete skill copied: `SKILL.md`, references, reference images, scripts and agent metadata. No project copy is installed.

## Discovery mechanism

Kilo project config discovery walks from the current directory up to that Git worktree root. Each child project under the house is its own Git root, so the parent `.kilo` directory is not automatically discovered from inside a child project.

The supported shared mechanism is the global `skills.paths` entry in `C:\Users\ESCCAY\.config\kilo\kilo.jsonc`:

```json
"skills": {
  "paths": [
    "C:/laragon/www/template-business/.kilo/skills"
  ]
}
```

This global config is loaded by every Kilo session, including sessions in child projects, delegated subagents and replacement sessions after model failover. The parent `.kilocode` path is a compatibility link, not the discovery mechanism.

## When agents use it

Use for UI, UX, frontend, layout, visual, copy, typography, motion, responsive and design-review tasks. Do not use for backend, database, infrastructure, API or payment-only work.

The project's own design system, tokens, brand and components take precedence. Unslop is a craft audit and direction process, not a replacement identity.

The central orchestrator task context automatically adds the Unslop path for UI/UX task terms; the design, frontend and mobile specialist prompts also require it. The shared `/design-review` command loads it explicitly.

## Verification

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-unslop.ps1
```

Static verification result: 9 PASS, including SKILL.md hash equality, frontmatter/license, `.kilocode` link, global `skills.paths`, both project reads, and no project copies.

### Live CLI tests

- `AFA-GHANA`: `kilo run --dir C:\laragon\www\template-business\AFA-GHANA` returned `DISCOVERED: yes`, `FIRST_HEADING: # Unslop`, and read `C:\laragon\www\template-business\.kilo\skills\unslop\SKILL.md`. Log: `C:\Users\ESCCAY\AppData\Local\Temp\kilo\unslop-afa-read.log`.
- `patu-research`: the same read-only prompt returned `DISCOVERED: yes`, `FIRST_HEADING: # Unslop`, and the same skill path. Log: `C:\Users\ESCCAY\AppData\Local\Temp\kilo\unslop-patu-research-read-default.log`.
- Delegated `specialists/design` subagent: `DELEGATED: yes`, `FIRST_HEADING: # Unslop`, read the same path, and confirmed project design systems take precedence.

### Additional test notes

- The non-interactive CLI code agent found the skill in its available skills list and tried the `skill` tool, but the CLI rejected that specific tool call with `The user rejected permission to use this specific tool call` even with `--auto` and an explicit allow. The read-tool path was verified in both projects and is what the specialist prompts and `/design-review` use.
- An alternate paid model (`kilo/deepseek/deepseek-v4.1-flash`) could not run the check because the account had no credits. The skill is file/global-config based and not model-bound; replacement sessions that use the working default model retain access. This model-failover case is configuration-verified, not live-model-tested.
- Test projects were not modified; only the house and the global Kilo config were changed. Global config backup: `C:\Users\ESCCAY\.config\kilo\kilo.jsonc.bak-unslop-20261125-074003`.
- Workflow self-test after the Unslop integration: 35 checks passed, including non-UI exclusion and automatic UI context inclusion.

