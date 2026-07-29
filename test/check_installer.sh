#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
skill_names=(blindspot-flow blindspot-pass explainer requirements-interview work-report)
agent_names=(change_analyzer check_runner codebase_scanner doc_verifier domain_researcher)
assert_reserved_absent() {
  local consumer="$1" allowed_skill="${2:-}" allowed_agent="${3:-}"
  local name
  for name in "${skill_names[@]}"; do
    if [[ "$name" != "$allowed_skill" ]]; then
      [[ ! -e "$consumer/.agents/skills/$name" && ! -L "$consumer/.agents/skills/$name" ]] || fail "unexpected managed skill after failed install: $name"
    fi
  done
  for name in "${agent_names[@]}"; do
    if [[ "$name" != "$allowed_agent" ]]; then
      [[ ! -e "$consumer/.codex/agents/$name.toml" && ! -L "$consumer/.codex/agents/$name.toml" ]] || fail "unexpected managed agent after failed install: $name"
    fi
  done
}
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
mkdir -p "$proj/.codex/shared" "$proj/.agents/skills/local-skill" "$proj/.codex/agents"
cp -a "$ROOT/." "$proj/.codex/shared/"
git -C "$proj" init -q
printf '%s\n' '# local skill' > "$proj/.agents/skills/local-skill/SKILL.md"
printf '%s\n' 'name = "local_agent"' 'description = "consumer-owned"' 'developer_instructions = "consumer-owned"' > "$proj/.codex/agents/local_agent.toml"
printf '%s\n' 'stale reserved skill' > "$proj/.agents/skills/blindspot-flow"
ln -s 'stale-target' "$proj/.agents/skills/blindspot-pass"
printf '%s\n' 'stale reserved agent' > "$proj/.codex/agents/change_analyzer.toml"
printf 'consumer guidance\r\n<!-- dev-env-blindspot:mandate:start -->\r\nstale mandate\r\n<!-- dev-env-blindspot:mandate:end -->\r\nconsumer tail\r\n' > "$proj/AGENTS.md"
printf '%s\n' 'consumer override' > "$proj/AGENTS.override.md"
python3 - "$proj/.codex/hooks.json" <<'PY'
import json, sys
cmd = 'bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"'
data = {
    "description": "consumer hooks",
    "consumerTop": {"keep": True},
    "hooks": {
        "Stop": [{"hooks": [{"type": "command", "command": "true"}]}],
        "SessionStart": [
            {
                "matcher": "startup",
                "extra": "keep",
                "hooks": [
                    {"type": "command", "command": cmd, "statusMessage": "stale"},
                    {"type": "command", "command": "keep-startup"},
                ],
            },
            {"hooks": [{"type": "command", "command": cmd}]},
            {"matcher": "other", "hooks": [{"type": "command", "command": "keep-other"}]},
        ],
    },
}
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

install_output="$(cd "$proj" && bash .codex/shared/install.sh)"
[[ "$install_output" == "blindspot: installed — 5 skills linked, 5 Codex agents copied, SessionStart hook merged, mandate guidance ensured" ]] || fail "wrong installer success message"
first="$(sha256sum "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" "$proj/.codex/agents/"*.toml; for link in "$proj/.agents/skills/"*; do [[ -L "$link" ]] && readlink "$link"; done)"
(cd "$proj" && bash .codex/shared/install.sh >/dev/null)
second="$(sha256sum "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" "$proj/.codex/agents/"*.toml; for link in "$proj/.agents/skills/"*; do [[ -L "$link" ]] && readlink "$link"; done)"
[[ "$first" == "$second" ]] || fail "second install changed managed output"

for name in "${skill_names[@]}"; do
  [[ -L "$proj/.agents/skills/$name" ]] || fail "missing skill link $name"
  [[ -f "$proj/.agents/skills/$name/SKILL.md" ]] || fail "broken skill link $name"
  [[ "$(readlink "$proj/.agents/skills/$name")" == "../../.codex/shared/skills/$name" ]] || fail "wrong skill link target $name"
done
for name in "${agent_names[@]}"; do
  [[ -f "$proj/.codex/agents/$name.toml" && ! -L "$proj/.codex/agents/$name.toml" ]] || fail "agent $name is not a real file"
  cmp -s "$proj/.codex/agents/$name.toml" "$proj/.codex/shared/agents/$name.toml" || fail "agent $name differs from source"
done
[[ -f "$proj/.agents/skills/local-skill/SKILL.md" ]] || fail "unrelated skill was changed"
rg -q 'consumer-owned' "$proj/.codex/agents/local_agent.toml" || fail "unrelated agent was changed"
rg -q 'consumer guidance' "$proj/AGENTS.md" || fail "AGENTS content was lost"
rg -q 'consumer override' "$proj/AGENTS.override.md" || fail "override content was lost"

python3 - "$proj/.codex/hooks.json" "$proj/AGENTS.md" "$proj/AGENTS.override.md" "$proj/.codex/shared/MANDATE.md" <<'PY'
import json, pathlib, sys
hooks = json.load(open(sys.argv[1], encoding="utf-8"))
assert hooks["description"] == "consumer hooks"
assert hooks["consumerTop"] == {"keep": True}
assert hooks["hooks"]["Stop"][0]["hooks"][0]["command"] == "true"
cmd = 'bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"'
groups = hooks["hooks"]["SessionStart"]
found = [h for g in groups for h in g.get("hooks", []) if h.get("command") == cmd]
assert len(found) == 1
assert groups[0] == {
    "matcher": "startup",
    "extra": "keep",
    "hooks": [{"type": "command", "command": "keep-startup"}],
}
assert groups[1] == {
    "matcher": "other",
    "hooks": [{"type": "command", "command": "keep-other"}],
}
assert groups[2] == {
    "hooks": [{
        "type": "command",
        "command": cmd,
        "statusMessage": "Loading blindspot workflow",
    }]
}
assert len(groups) == 3

start = b"<!-- dev-env-blindspot:mandate:start -->"
end = b"<!-- dev-env-blindspot:mandate:end -->"
mandate = pathlib.Path(sys.argv[4]).read_bytes()
block = start + b"\n" + mandate + (b"" if mandate.endswith(b"\n") else b"\n") + end
agents = pathlib.Path(sys.argv[2]).read_bytes()
assert agents.count(start) == agents.count(end) == 1
start_at = agents.index(start)
end_at = agents.index(end) + len(end)
assert agents[:start_at] == b"consumer guidance\r\n"
assert agents[start_at:end_at] == block
assert agents[end_at:] == b"\r\nconsumer tail\r\n"
override = pathlib.Path(sys.argv[3]).read_bytes()
assert override == b"consumer override\n\n" + block + b"\n"
PY

mkdir -p "$proj/nested/path"
(cd "$proj/nested/path" && bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh") > "$tmp/hook.out"
cmp -s "$tmp/hook.out" "$proj/.codex/shared/MANDATE.md" || fail "nested hook output differs from MANDATE.md"

no_override="$tmp/no-override"
mkdir -p "$no_override/.codex/shared"
cp -a "$ROOT/." "$no_override/.codex/shared/"
(cd "$no_override" && bash .codex/shared/install.sh >/dev/null)
[[ ! -e "$no_override/AGENTS.override.md" ]] || fail "absent override was created"

bad="$tmp/bad"
mkdir -p "$bad/.codex/shared" "$bad/.codex"
cp -a "$ROOT/." "$bad/.codex/shared/"
printf '%s\n' '{broken' > "$bad/.codex/hooks.json"
printf '%s\n' 'keep me' > "$bad/AGENTS.md"
before="$(sha256sum "$bad/.codex/hooks.json" "$bad/AGENTS.md")"
if (cd "$bad" && bash .codex/shared/install.sh >/dev/null 2>&1); then fail "invalid hooks JSON was accepted"; fi
after="$(sha256sum "$bad/.codex/hooks.json" "$bad/AGENTS.md")"
[[ "$before" == "$after" ]] || fail "failed install changed consumer files"
[[ ! -e "$bad/.agents" ]] || fail "invalid hooks JSON created .agents"
[[ ! -e "$bad/.codex/agents" ]] || fail "invalid hooks JSON created agents"
[[ ! -e "$bad/AGENTS.override.md" ]] || fail "invalid hooks JSON created override"
assert_reserved_absent "$bad"

python3 - "$tmp" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
cases = {
    "bad-root-shape": [],
    "bad-hooks-shape": {"hooks": []},
    "bad-session-shape": {"hooks": {"SessionStart": {}}},
    "bad-group-shape": {"hooks": {"SessionStart": [[]]}},
    "bad-group-hooks-shape": {"hooks": {"SessionStart": [{"hooks": {}}]}},
    "bad-handler-shape": {"hooks": {"SessionStart": [{"hooks": ["command"]}]}},
}
for name, data in cases.items():
    path = root / name / ".codex" / "hooks.json"
    path.parent.mkdir(parents=True)
    path.write_text(json.dumps(data) + "\n", encoding="utf-8")
PY
for label in bad-root-shape bad-hooks-shape bad-session-shape bad-group-shape bad-group-hooks-shape bad-handler-shape; do
  bad_shape="$tmp/$label"
  mkdir -p "$bad_shape/.codex/shared"
  cp -a "$ROOT/." "$bad_shape/.codex/shared/"
  printf '%s\n' 'keep malformed shape guidance' > "$bad_shape/AGENTS.md"
  shape_before="$(sha256sum "$bad_shape/.codex/hooks.json" "$bad_shape/AGENTS.md")"
  if (cd "$bad_shape" && bash .codex/shared/install.sh >/dev/null 2>&1); then fail "$label was accepted"; fi
  [[ "$shape_before" == "$(sha256sum "$bad_shape/.codex/hooks.json" "$bad_shape/AGENTS.md")" ]] || fail "$label changed consumer files"
  [[ ! -e "$bad_shape/.agents" ]] || fail "$label created .agents"
  [[ ! -e "$bad_shape/.codex/agents" ]] || fail "$label created agents"
  [[ ! -e "$bad_shape/AGENTS.override.md" ]] || fail "$label created override"
  assert_reserved_absent "$bad_shape"
done

bad_agents_marker="$tmp/bad-agents-marker"
mkdir -p "$bad_agents_marker/.codex/shared"
cp -a "$ROOT/." "$bad_agents_marker/.codex/shared/"
printf '%s\n' 'keep agents prefix' '<!-- dev-env-blindspot:mandate:start -->' > "$bad_agents_marker/AGENTS.md"
agents_marker_before="$(sha256sum "$bad_agents_marker/AGENTS.md")"
if (cd "$bad_agents_marker" && bash .codex/shared/install.sh >/dev/null 2>&1); then fail "malformed AGENTS markers were accepted"; fi
[[ "$agents_marker_before" == "$(sha256sum "$bad_agents_marker/AGENTS.md")" ]] || fail "malformed AGENTS markers changed guidance"
[[ ! -e "$bad_agents_marker/.agents" ]] || fail "malformed AGENTS markers created .agents"
[[ ! -e "$bad_agents_marker/.codex/agents" ]] || fail "malformed AGENTS markers created agents"
[[ ! -e "$bad_agents_marker/.codex/hooks.json" ]] || fail "malformed AGENTS markers created hooks"
[[ ! -e "$bad_agents_marker/AGENTS.override.md" ]] || fail "malformed AGENTS markers created override"
assert_reserved_absent "$bad_agents_marker"

bad_override_marker="$tmp/bad-override-marker"
mkdir -p "$bad_override_marker/.codex/shared"
cp -a "$ROOT/." "$bad_override_marker/.codex/shared/"
printf '%s\n' 'keep agents guidance' > "$bad_override_marker/AGENTS.md"
printf '%s\n' '<!-- dev-env-blindspot:mandate:end -->' 'keep override suffix' > "$bad_override_marker/AGENTS.override.md"
override_marker_before="$(sha256sum "$bad_override_marker/AGENTS.md" "$bad_override_marker/AGENTS.override.md")"
if (cd "$bad_override_marker" && bash .codex/shared/install.sh >/dev/null 2>&1); then fail "malformed override markers were accepted"; fi
[[ "$override_marker_before" == "$(sha256sum "$bad_override_marker/AGENTS.md" "$bad_override_marker/AGENTS.override.md")" ]] || fail "malformed override markers changed guidance"
[[ ! -e "$bad_override_marker/.agents" ]] || fail "malformed override markers created .agents"
[[ ! -e "$bad_override_marker/.codex/agents" ]] || fail "malformed override markers created agents"
[[ ! -e "$bad_override_marker/.codex/hooks.json" ]] || fail "malformed override markers created hooks"
assert_reserved_absent "$bad_override_marker"

reserved_directory="$tmp/reserved-directory"
mkdir -p "$reserved_directory/.codex/shared" "$reserved_directory/.agents/skills/blindspot-flow"
cp -a "$ROOT/." "$reserved_directory/.codex/shared/"
printf '%s\n' 'keep reserved directory sentinel' > "$reserved_directory/.agents/skills/blindspot-flow/SKILL.md"
printf '%s\n' 'keep reserved directory guidance' > "$reserved_directory/AGENTS.md"
reserved_before="$(sha256sum "$reserved_directory/.agents/skills/blindspot-flow/SKILL.md" "$reserved_directory/AGENTS.md")"
if (cd "$reserved_directory" && bash .codex/shared/install.sh >/dev/null 2>&1); then fail "reserved skill directory was accepted"; fi
[[ "$reserved_before" == "$(sha256sum "$reserved_directory/.agents/skills/blindspot-flow/SKILL.md" "$reserved_directory/AGENTS.md")" ]] || fail "reserved skill directory failure changed consumer files"
[[ ! -e "$reserved_directory/.codex/agents" ]] || fail "reserved skill directory failure created agents"
[[ ! -e "$reserved_directory/.codex/hooks.json" ]] || fail "reserved skill directory failure created hooks"
[[ ! -e "$reserved_directory/AGENTS.override.md" ]] || fail "reserved skill directory failure created override"
assert_reserved_absent "$reserved_directory" blindspot-flow

expect_source_failure() {
  local consumer="$1" label="$2"
  printf '%s\n' 'keep source failure guidance' > "$consumer/AGENTS.md"
  local before_agents
  before_agents="$(sha256sum "$consumer/AGENTS.md")"
  if (cd "$consumer" && bash .codex/shared/install.sh >/dev/null 2>&1); then
    fail "$label was accepted"
  fi
  [[ "$before_agents" == "$(sha256sum "$consumer/AGENTS.md")" ]] || fail "$label changed AGENTS.md"
  [[ ! -e "$consumer/.agents" ]] || fail "$label created .agents"
  [[ ! -e "$consumer/.codex/agents" ]] || fail "$label created .codex/agents"
  [[ ! -e "$consumer/.codex/hooks.json" ]] || fail "$label created hooks.json"
  [[ ! -e "$consumer/AGENTS.override.md" ]] || fail "$label created AGENTS.override.md"
}

bad_toml="$tmp/bad-toml"
mkdir -p "$bad_toml/.codex/shared"
cp -a "$ROOT/." "$bad_toml/.codex/shared/"
printf '%s\n' 'name = [' > "$bad_toml/.codex/shared/agents/change_analyzer.toml"
expect_source_failure "$bad_toml" "malformed agent TOML"

bad_multiline_toml="$tmp/bad-multiline-toml"
mkdir -p "$bad_multiline_toml/.codex/shared"
cp -a "$ROOT/." "$bad_multiline_toml/.codex/shared/"
printf '%s\n' 'name = "change_analyzer"' 'description = "invalid multiline TOML"' 'developer_instructions = """' 'valid"""garbage' '"""' > "$bad_multiline_toml/.codex/shared/agents/change_analyzer.toml"
expect_source_failure "$bad_multiline_toml" "malformed multiline agent TOML"

bad_scalar_toml="$tmp/bad-scalar-toml"
mkdir -p "$bad_scalar_toml/.codex/shared"
cp -a "$ROOT/." "$bad_scalar_toml/.codex/shared/"
printf '%s\n' 'name = "change_analyzer"' 'description = "\uD800"' 'developer_instructions = "invalid Unicode scalar"' > "$bad_scalar_toml/.codex/shared/agents/change_analyzer.toml"
expect_source_failure "$bad_scalar_toml" "invalid TOML Unicode scalar"

bad_control_toml="$tmp/bad-control-toml"
mkdir -p "$bad_control_toml/.codex/shared"
cp -a "$ROOT/." "$bad_control_toml/.codex/shared/"
printf 'name = "change_analyzer"\ndescription = "invalid literal control"\ndeveloper_instructions = """\nvalid\vcontrol\n"""\n' > "$bad_control_toml/.codex/shared/agents/change_analyzer.toml"
expect_source_failure "$bad_control_toml" "invalid TOML literal control"

bad_structure="$tmp/bad-agent-structure"
mkdir -p "$bad_structure/.codex/shared"
cp -a "$ROOT/." "$bad_structure/.codex/shared/"
printf '%s\n' 'name = "wrong_name"' > "$bad_structure/.codex/shared/agents/change_analyzer.toml"
expect_source_failure "$bad_structure" "invalid agent structure"

bad_agent_encoding="$tmp/bad-agent-encoding"
mkdir -p "$bad_agent_encoding/.codex/shared"
cp -a "$ROOT/." "$bad_agent_encoding/.codex/shared/"
printf '\377\n' > "$bad_agent_encoding/.codex/shared/agents/change_analyzer.toml"
expect_source_failure "$bad_agent_encoding" "invalid agent encoding"

bad_mandate_marker="$tmp/bad-mandate-marker"
mkdir -p "$bad_mandate_marker/.codex/shared"
cp -a "$ROOT/." "$bad_mandate_marker/.codex/shared/"
printf '%s\n' '# Blindspot Mandate' '<!-- dev-env-blindspot:mandate:start -->' > "$bad_mandate_marker/.codex/shared/MANDATE.md"
expect_source_failure "$bad_mandate_marker" "mandate with managed marker"

bad_mandate_encoding="$tmp/bad-mandate-encoding"
mkdir -p "$bad_mandate_encoding/.codex/shared"
cp -a "$ROOT/." "$bad_mandate_encoding/.codex/shared/"
printf '\377\n' > "$bad_mandate_encoding/.codex/shared/MANDATE.md"
expect_source_failure "$bad_mandate_encoding" "invalid mandate encoding"

special_skill="$tmp/special-skill"
mkdir -p "$special_skill/.codex/shared" "$special_skill/.agents/skills"
cp -a "$ROOT/." "$special_skill/.codex/shared/"
mkfifo "$special_skill/.agents/skills/blindspot-flow"
printf '%s\n' 'keep special skill guidance' > "$special_skill/AGENTS.md"
special_skill_agents="$(sha256sum "$special_skill/AGENTS.md")"
if (cd "$special_skill" && bash .codex/shared/install.sh >/dev/null 2>&1); then
  fail "reserved skill FIFO was accepted"
fi
[[ -p "$special_skill/.agents/skills/blindspot-flow" ]] || fail "reserved skill FIFO was changed"
[[ "$special_skill_agents" == "$(sha256sum "$special_skill/AGENTS.md")" ]] || fail "reserved skill FIFO failure changed AGENTS.md"
[[ ! -e "$special_skill/.codex/agents" ]] || fail "reserved skill FIFO failure created agents"
[[ ! -e "$special_skill/.codex/hooks.json" ]] || fail "reserved skill FIFO failure created hooks"
[[ ! -e "$special_skill/AGENTS.override.md" ]] || fail "reserved skill FIFO failure created override"
assert_reserved_absent "$special_skill" blindspot-flow

special_agent="$tmp/special-agent"
mkdir -p "$special_agent/.codex/shared" "$special_agent/.codex/agents"
cp -a "$ROOT/." "$special_agent/.codex/shared/"
mkfifo "$special_agent/.codex/agents/change_analyzer.toml"
printf '%s\n' 'keep special agent guidance' > "$special_agent/AGENTS.md"
special_agent_agents="$(sha256sum "$special_agent/AGENTS.md")"
if (cd "$special_agent" && bash .codex/shared/install.sh >/dev/null 2>&1); then
  fail "reserved agent FIFO was accepted"
fi
[[ -p "$special_agent/.codex/agents/change_analyzer.toml" ]] || fail "reserved agent FIFO was changed"
[[ "$special_agent_agents" == "$(sha256sum "$special_agent/AGENTS.md")" ]] || fail "reserved agent FIFO failure changed AGENTS.md"
[[ ! -e "$special_agent/.agents" ]] || fail "reserved agent FIFO failure created skills"
[[ ! -e "$special_agent/.codex/hooks.json" ]] || fail "reserved agent FIFO failure created hooks"
[[ ! -e "$special_agent/AGENTS.override.md" ]] || fail "reserved agent FIFO failure created override"
assert_reserved_absent "$special_agent" "" change_analyzer

echo "OK: installer contract"
