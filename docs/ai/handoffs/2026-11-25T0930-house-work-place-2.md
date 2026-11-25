# Handoff — House Work 2

- Created: 2026-11-25 09:30 UTC
- Source: `main` at `5935b85` plus this handoff commit
- Next working place: `house/work-place-2`

## Completed and verified

- House rules, central knowledge, main-brain and specialist catalog, task lifecycle and Agent Manager integration are implemented and pushed.
- Shared Unslop skill installed at `.kilo/skills/unslop`, registered globally through `skills.paths`, with UI task context injection and design-review command.
- House projects grouped by website: Datatem, Patupa, PATU Technologies, AFA Ghana, Novagel, PATU Research, PATUchat and Patutrade. `projects.json.websites` and `knowledge/WEBSITES.md` are authoritative; the 10 checkout folders were not moved.
- VPS audit completed read-only (host `vmi3756685`, Ubuntu 24.04, 6 vCPU, 11 GiB RAM, 96 GB disk 81%). The VPS runs Studio, monitoring and Patutrade; no other house project runs there.
- VPS findings: Studio API/frontend, PostgreSQL, Redis, Caddy/WAF and monitoring are active; Sociabot is active/public; Voice and Sandbox are idle; Ollama is active with four local models; Patutrade is active and CPU-heavy; Docker build cache is 20.47 GB. No production migration was performed.

## Local Studio workspace on this PC

- Docker Desktop 4.100.1 installed; engine 29.9.3 on WSL2; AutoStart disabled; daemon is named-pipe only; no TCP 2375/2376.
- Local PostgreSQL 17 and Redis 7 containers run on `127.0.0.1:5433` and `127.0.0.1:6379`; loopback only.
- Studio API runs at `http://127.0.0.1:8000`; UI at `http://localhost:5173`; `/readyz` reports database and Redis ready; admin login lands on `/app`.
- Local DB was migrated and seeded fresh. No production data was copied. Local admin credentials are in ignored `patu-technologies/backend/.env`.
- Start/stop: `C:\Users\ESCCAY\.patu-local\start-studio.ps1` and `stop-studio.ps1`.
- Security boundary: local ports are loopback only; Redis has a local password; no worker, ZAP, voice, Sociabot or security worker runs on Windows; do not set `PATU_WORKER_ALLOW_UNSANDBOXED=true` for shared or production work.
- Current local limitation: 0 providers connected, 0 coding workers. The Studio UI/planning works; delivery execution is intentionally disabled. Connect an approved provider/local Ollama and use the VPS worker or a Linux VM for code execution.

## VPS access and safety

- SSH as `patuadmin` with `%USERPROFILE%\.ssh\patu_prod`; passwordless sudo. The VPS host is recorded in local deployment notes and `known_hosts`.
- The old PC IP and hotspot IP were whitelisted in fail2ban/CrowdSec; the unrelated `27.71.17.237` ban remains. A future ISP IP change needs a new whitelist entry.
- Do not stop or migrate public API/WAF, PostgreSQL/Redis, Sociabot, Patutrade, monitoring or security services without explicit approval.
- VPS audit evidence is in `%TEMP%\kilo\vps-audit-final.txt` and `vps-d-final.txt`; do not copy secrets from those files into the repository.

## Recommended next work

1. Connect a local Ollama model or an approved AI provider in the local AI Control Center; start with a small Qwen model on this laptop (no discrete GPU).
2. Decide worker strategy: keep coding/security execution on the VPS or use a Linux VM; do not run an unsandboxed Windows worker.
3. If production data is needed locally, take a VPS database dump (36 MB), workspace archive (4.04 GB) and sanitized config after explicit approval; never copy provider credentials or customer secrets into the repo.
4. Continue Studio engineering work from the local UI; use the VPS public stack for external availability.
5. Keep the 20.47 GB VPS build cache / idle images cleanup as a separate approved maintenance task.

No migration has started. Verify actual workspace and VPS state before continuing.
