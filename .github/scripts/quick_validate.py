#!/usr/bin/env python3
import re
import sys
from pathlib import Path


def validate_skill(skill_path):
    skill_dir = Path(skill_path)
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return False, "SKILL.md not found"

    content = skill_md.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return False, "Invalid or missing YAML frontmatter"

    frontmatter = {}
    for line in match.group(1).splitlines():
        if not line.strip():
            continue
        if ":" not in line:
            return False, f"Invalid frontmatter line: {line}"
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value.startswith(("'", '"')) and value.endswith(("'", '"')):
            value = value[1:-1]
        frontmatter[key] = value

    unexpected = set(frontmatter) - {"name", "description"}
    if unexpected:
        return False, f"Unexpected frontmatter keys: {', '.join(sorted(unexpected))}"

    name = frontmatter.get("name")
    description = frontmatter.get("description")

    if not isinstance(name, str) or not re.match(r"^[a-z0-9-]{1,64}$", name):
        return False, "name must be 1-64 chars of lowercase letters, digits, and hyphens"

    if name.startswith("-") or name.endswith("-") or "--" in name:
        return False, "name cannot start/end with hyphen or contain consecutive hyphens"

    if not isinstance(description, str) or not description.strip():
        return False, "description is required"

    if len(description) > 1024:
        return False, "description exceeds 1024 characters"

    return True, "Skill is valid!"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: quick_validate.py <skill_directory>")
        sys.exit(1)

    ok, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if ok else 1)
