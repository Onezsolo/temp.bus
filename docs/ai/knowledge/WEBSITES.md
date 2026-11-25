# Website arrangement

The house tracks **one website per repository**. A website may have several independent Git checkouts (working copies/branches); those checkouts are implementation states, not separate products.

No checkout is moved or consolidated by this arrangement. Each working copy keeps its own `.git`, remote and branch.

| Website | Repository | Primary working copy | Other working copies | Local domains |
|---|---|---|---|---|
| Datatem | `Onezsolo/datatem.git` | `one-system` (`feat/one-system-foundation`) | `datatem` (base, `main`) | `datatem.test`, `one-system.test` |
| Patupa | `Onezsolo/patupa.git` | `patupa` (`main`) | `patupaa-worker` (`feature/patu-dialer`) | `patupa.test` |
| PATU Technologies | `Onezsolo/patu-codes.git` | `patu-technologies` (`main`) | `patu-design-intelligence` (`design-intelligence`) | none |
| AFA Ghana | `Onezsolo/afa.git` | `AFA-GHANA` (`main`) | none | `AFA-GHANA.test` |
| Novagel Imports | `Onezsolo/novagel.git` | `novagel` (`patu/program-f99758f5`) | none | none |
| PATU Research | `Onezsolo/patu-research.git` | `patu-research` (`main`) | none | none |
| PATUchat | `Onezsolo/PATUchat.git` | `PATUchat` (`main`) | none | `PATUchat.test` |
| Patutrade | `Onezsolo/patutrade.git` | `patutrade.worktrees/patutrade` (`deploy/six-bot-okx-demo`) | `patutrade.worktrees/changes-not-showing-fix` (`agents/changes-not-showing-fix`) | `patutrade.worktrees.test` |

## Rules

- The primary working copy is the current/live implementation for audits, demos and design work.
- A variant checkout is the same website/repository on a different branch. Do not count it as a separate product in the registry, showcase, knowledge or design audit.
- `projects.json.websites` is the website grouping. `projects.json.projects` remains the checkout registry because every checkout still has its own Git boundary and rules.
- The public showcase (`public/index.php`) lists each website once.
- Do not move, rename, merge or delete a checkout to consolidate a website unless the user explicitly authorizes a structural migration.
- Design and coverage audits count websites once. Branch-specific screens are recorded under the website, not as separate websites.
