#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
mkdir -p "$proj/.codex/shared" "$proj/.agents/skills/local-skill" "$proj/.codex/agents"
cp -a "$ROOT/." "$proj/.codex/shared/"
git -C "$proj" init -q
printf '%s\n' '# local skill' > "$proj/.agents/skills/local-skill/SKILL.md"
printf '%s\n' 'name = "local_agent"' 'description = "consumer-owned"' 'developer_instructions = "consumer-owned"' > "$proj/.codex/agents/local_agent.toml"
printf '%s\n' 'consumer guidance' > "$proj/AGENTS.md"
printf '%s\n' 'consumer override' > "$proj/AGENTS.override.md"
python3 - "$proj/.codex/hooks.json" <<'PY'
import json, sys
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump({"description": "consumer hooks", "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "true"}]}]}}, f, indent=2)
    f.write("\n")
PY

(cd "$proj" && bash .codex/shared/install.sh >/dev/null)
first="$(sha256sum "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" "$proj/.codex/agents/"*.toml; for link in "$proj/.agents/skills/"*; do [[ -L "$link" ]] && readlink "$link"; done)"
(cd "$proj" && bash .codex/shared/install.sh >/dev/null)
second="$(sha256sum "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" "$proj/.codex/agents/"*.toml; for link in "$proj/.agents/skills/"*; do [[ -L "$link" ]] && readlink "$link"; done)"
[[ "$first" == "$second" ]] || fail "second install changed managed output"

for name in blindspot-flow blindspot-pass explainer requirements-interview work-report; do
  [[ -L "$proj/.agents/skills/$name" ]] || fail "missing skill link $name"
  [[ -f "$proj/.agents/skills/$name/SKILL.md" ]] || fail "broken skill link $name"
done
for name in change_analyzer check_runner codebase_scanner doc_verifier domain_researcher; do
  [[ -f "$proj/.codex/agents/$name.toml" && ! -L "$proj/.codex/agents/$name.toml" ]] || fail "agent $name is not a real file"
done
[[ -f "$proj/.agents/skills/local-skill/SKILL.md" ]] || fail "unrelated skill was changed"
rg -q 'consumer-owned' "$proj/.codex/agents/local_agent.toml" || fail "unrelated agent was changed"
rg -q 'consumer guidance' "$proj/AGENTS.md" || fail "AGENTS content was lost"
rg -q 'consumer override' "$proj/AGENTS.override.md" || fail "override content was lost"

python3 - "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" <<'PY'
import json, sys
hooks = json.load(open(sys.argv[1], encoding="utf-8"))
assert hooks["description"] == "consumer hooks"
assert hooks["hooks"]["Stop"][0]["hooks"][0]["command"] == "true"
cmd = 'bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"'
found = [h for g in hooks["hooks"]["SessionStart"] for h in g.get("hooks", []) if h.get("command") == cmd]
assert len(found) == 1
for path in sys.argv[2:]:
    text = open(path, encoding="utf-8").read()
    assert text.count("<!-- dev-env-blindspot:mandate:start -->") == 1
    assert text.count("<!-- dev-env-blindspot:mandate:end -->") == 1
    assert "# Blindspot Mandate" in text
PY

mkdir -p "$proj/nested/path"
(cd "$proj/nested/path" && bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh") > "$tmp/hook.out"
cmp -s "$tmp/hook.out" "$proj/.codex/shared/MANDATE.md" || fail "nested hook output differs from MANDATE.md"

bad="$tmp/bad"
mkdir -p "$bad/.codex/shared" "$bad/.codex"
cp -a "$ROOT/." "$bad/.codex/shared/"
printf '%s\n' '{broken' > "$bad/.codex/hooks.json"
printf '%s\n' 'keep me' > "$bad/AGENTS.md"
before="$(sha256sum "$bad/.codex/hooks.json" "$bad/AGENTS.md")"
if (cd "$bad" && bash .codex/shared/install.sh >/dev/null 2>&1); then fail "invalid hooks JSON was accepted"; fi
after="$(sha256sum "$bad/.codex/hooks.json" "$bad/AGENTS.md")"
[[ "$before" == "$after" ]] || fail "failed install changed consumer files"

echo "OK: installer contract"
