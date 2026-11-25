from __future__ import annotations

import importlib.util
import json
import sys
from dataclasses import asdict
from datetime import datetime, timezone
from pathlib import Path

HOUSE = Path(__file__).resolve().parents[1]
STUDIO = HOUSE / "patu-technologies"
SPECIALISTS_FILE = STUDIO / "backend" / "app" / "services" / "orchestration" / "specialists.py"
MASTER_RULES_FILE = STUDIO / "backend" / "app" / "services" / "ai" / "master_rules.py"
SKILLS_FILE = STUDIO / "backend" / "app" / "services" / "ai" / "skills_catalog.py"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def main() -> None:
    specialists_module = load_module("patu_specialists", SPECIALISTS_FILE)
    master_module = load_module("patu_master_rules", MASTER_RULES_FILE)
    skills_module = load_module("patu_skills", SKILLS_FILE)

    knowledge_dir = HOUSE / "docs" / "ai" / "knowledge"
    agents_dir = HOUSE / ".kilo" / "agent" / "specialists"
    knowledge_dir.mkdir(parents=True, exist_ok=True)
    agents_dir.mkdir(parents=True, exist_ok=True)

    specialists = []
    for specialist in specialists_module.SPECIALISTS:
        data = asdict(specialist)
        key = data["key"]
        data["skills"] = [
            {"name": name, "purpose": purpose}
            for name, purpose in skills_module.SKILL_GUIDE.get(key, ())
        ]
        specialists.append(data)

        description = json.dumps(data["mission"])
        body = []
        body.append("---")
        body.append(f"description: {description}")
        body.append("mode: subagent")
        body.append("hidden: false")
        body.append("---")
        body.append("")
        body.append(f"# PATU {key.replace('_', ' ').title()} specialist")
        body.append("")
        body.append(data["system_prompt"].strip())
        body.append("")
        body.append("## Mission")
        body.append(data["mission"])
        body.append("")
        body.append("## Responsibilities")
        for responsibility in data.get("responsibilities", []):
            body.append(f"- {responsibility}")
        body.append("")
        body.append("## Triggers")
        for trigger in data.get("triggers", []):
            body.append(f"- {trigger}")
        body.append("")
        if data["skills"]:
            body.append("## Applicable working skills")
            for skill in data["skills"]:
                body.append(f"- {skill['name']}: {skill['purpose']}")
            body.append("")
        body.append("## House requirement")
        body.append(
            "Read the Template Business house AGENTS.md, the central knowledge index and the "
            "task context package before acting. Work only inside the assigned task and project. "
            "Never claim completion without fresh test or verification evidence."
        )
        body.append("")
        (agents_dir / f"{key}.md").write_text("\n".join(body), encoding="utf-8")

    catalog = {
        "source": "patu-technologies/backend/app/services/orchestration/specialists.py",
        "importedAt": datetime.now(timezone.utc).isoformat(),
        "specialists": specialists,
    }
    (knowledge_dir / "studio-specialists.json").write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    master_rules = getattr(master_module, "MASTER_CODING_RULES", "")
    (knowledge_dir / "MASTER_RULES.md").write_text(master_rules.strip() + "\n", encoding="utf-8")

    skill_map = {
        "source": "patu-technologies/backend/app/services/ai/skills_catalog.py",
        "importedAt": datetime.now(timezone.utc).isoformat(),
        "allWorkerSkills": list(getattr(skills_module, "ALL_WORKER_SKILLS", ())),
        "guide": {key: [{"name": n, "purpose": p} for n, p in entries] for key, entries in skills_module.SKILL_GUIDE.items()},
    }
    (knowledge_dir / "studio-skill-map.json").write_text(
        json.dumps(skill_map, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    print(f"Imported {len(specialists)} Studio specialists")
    print(f"Wrote {knowledge_dir / 'studio-specialists.json'}")
    print(f"Wrote {knowledge_dir / 'MASTER_RULES.md'}")
    print(f"Generated {len(specialists)} agent files in {agents_dir}")


if __name__ == "__main__":
    main()
