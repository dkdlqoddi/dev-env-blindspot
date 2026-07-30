#!/usr/bin/env bash
# Consumer onboarding. Run from the consumer project root after:
#   git submodule add <repo-url> .antigravity/shared
# Idempotent: safe to re-run after submodule updates.
set -euo pipefail
shopt -s nullglob

SHARED=".antigravity/shared"
[[ -d "$SHARED/skills" ]] || { echo "error: run from the consumer project root (needs $SHARED/skills)"; exit 1; }

# 1. symlink skills and agents individually (coexists with project-local ones)
mkdir -p .antigravity/skills .antigravity/agents
for d in "$SHARED"/skills/*/; do
  name="$(basename "$d")"
  rm -rf ".antigravity/skills/$name"
  ln -sfn "../shared/skills/$name" ".antigravity/skills/$name"
done
for f in "$SHARED"/agents/*.md; do
  name="$(basename "$f")"
  rm -f ".antigravity/agents/$name"
  ln -sfn "../shared/agents/$name" ".antigravity/agents/$name"
done

# 2. merge SessionStart hook into .antigravity/settings.json
SETTINGS=".antigravity/settings.json"
HOOK_CMD='bash "$ANTIGRAVITY_PROJECT_DIR/.antigravity/shared/hooks/mandate.sh"'
if command -v python3 >/dev/null 2>&1 && python3 -c "" >/dev/null 2>&1; then
  PY_CMD=python3
elif command -v python >/dev/null 2>&1 && python -c "" >/dev/null 2>&1; then
  PY_CMD=python
else
  echo "error: need python3 or python to merge $SETTINGS."
  echo "Add this to $SETTINGS manually:"
  echo '  {"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$ANTIGRAVITY_PROJECT_DIR/.antigravity/shared/hooks/mandate.sh\""}]}]}}'
  exit 1
fi
$PY_CMD - "$SETTINGS" "$HOOK_CMD" <<'PY'
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

# 3. ensure ANTIGRAVITY.md imports the mandate
IMPORT_LINE='@.antigravity/shared/MANDATE.md'
if [[ -f ANTIGRAVITY.md ]]; then
  grep -qxF "$IMPORT_LINE" ANTIGRAVITY.md || printf '\n%s\n' "$IMPORT_LINE" >> ANTIGRAVITY.md
else
  printf '%s\n' "$IMPORT_LINE" > ANTIGRAVITY.md
fi

echo "blindspot: installed — skills/agents symlinked, SessionStart hook merged, ANTIGRAVITY.md import ensured"
