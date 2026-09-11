#!/usr/bin/env python3
"""Offline, deterministic first-pass router. Configure behavior in config/router.json."""
import argparse, json, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RISK_ORDER = {"low": 0, "medium": 1, "high": 2, "critical": 3}

def route(description, config_path=ROOT / "config" / "router.json"):
    config = json.loads(Path(config_path).read_text(encoding="utf-8"))
    tokens = set(re.findall(r"[a-z0-9]+", description.lower()))
    matches = []
    for name, rule in config["categories"].items():
        hits = [word for word in rule["keywords"] if set(word.split()) <= tokens]
        if hits:
            matches.append((len(hits), RISK_ORDER.get(rule["risk"], 0), name, rule, hits))
    if matches:
        _, _, category, rule, hits = max(matches, key=lambda item: (item[0], item[1]))
    else:
        category, rule, hits = config["defaults"]["category"], config["defaults"], []
    stack = rule["stack"]
    roles = config["roles"]
    primary = stack[0]
    return {
        "category": category,
        "risk_level": rule["risk"],
        "primary": {"role": primary, **roles[primary]},
        "implementation_role": next(({"role": r, **roles[r]} for r in stack if r == "implementer"), None),
        "reviewer": next(({"role": r, **roles[r]} for r in reversed(stack) if r == "reviewer"), None),
        "role_stack": [{"role": r, "model": roles[r]["model"]} for r in stack],
        "review_required": rule["review_required"],
        "never_auto_merge": config["defaults"]["never_auto_merge"],
        "reasoning": "Matched: " + (", ".join(hits) if hits else "no category keywords; using default policy")
    }

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Return a structured AI development routing decision.")
    parser.add_argument("description")
    parser.add_argument("--config", type=Path, default=ROOT / "config" / "router.json")
    args = parser.parse_args()
    print(json.dumps(route(args.description, args.config), indent=2))
