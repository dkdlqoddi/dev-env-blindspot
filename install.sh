#!/usr/bin/env bash
# Consumer onboarding. Run from the consumer project root after:
#   git submodule add <repo-url> .claude/shared
# Idempotent: safe to re-run after submodule updates.
set -euo pipefail
shopt -s nullglob

SHARED=".claude/shared"
[[ -d "$SHARED/skills" ]] || { echo "error: run from the consumer project root (needs $SHARED/skills)"; exit 1; }

# 1. symlink skills and agents individually (coexists with project-local ones)
mkdir -p .claude/skills .claude/agents
for d in "$SHARED"/skills/*/; do
  name="$(basename "$d")"
  ln -sfn "../shared/skills/$name" ".claude/skills/$name"
done
for f in "$SHARED"/agents/*.md; do
  name="$(basename "$f")"
  ln -sfn "../shared/agents/$name" ".claude/agents/$name"
done

# 2. merge SessionStart hook into .claude/settings.json
SETTINGS=".claude/settings.json"
HOOK_CMD='bash "$CLAUDE_PROJECT_DIR/.claude/shared/hooks/mandate.sh"'
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: need python3 to merge $SETTINGS."
  echo "Add this to $SETTINGS manually:"
  echo '  {"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$CLAUDE_PROJECT_DIR/.claude/shared/hooks/mandate.sh\""}]}]}}'
  exit 1
fi
python3 - "$SETTINGS" "$HOOK_CMD" <<'PY'
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except ValueError:
        sys.exit(f"error: {path} is not valid JSON — fix or remove it, then re-run")
    if not isinstance(data, dict):
        sys.exit(f"error: {path} is not a JSON object — fix or remove it, then re-run")
ss = data.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == cmd for e in ss for h in e.get("hooks", [])):
    ss.append({"hooks": [{"type": "command", "command": cmd}]})
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
PY

# 3. ensure CLAUDE.md imports the mandate
IMPORT_LINE='@.claude/shared/MANDATE.md'
if [[ -f CLAUDE.md ]]; then
  grep -qxF "$IMPORT_LINE" CLAUDE.md || printf '\n%s\n' "$IMPORT_LINE" >> CLAUDE.md
else
  printf '%s\n' "$IMPORT_LINE" > CLAUDE.md
fi

echo "blindspot: installed — skills/agents symlinked, SessionStart hook merged, CLAUDE.md import ensured"
