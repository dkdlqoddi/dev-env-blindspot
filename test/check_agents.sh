#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

expected=(change_analyzer check_runner codebase_scanner doc_verifier domain_researcher)
files=("$ROOT"/agents/*.toml)
[[ ${#files[@]} -eq 5 ]] || fail "expected 5 Codex TOML agents, got ${#files[@]}"

for name in "${expected[@]}"; do
  file="$ROOT/agents/$name.toml"
  [[ -f "$file" ]] || fail "missing $file"
  rg -q "^name = \"$name\"$" "$file" || fail "$file: wrong or missing name"
  rg -q '^description = ".+"$' "$file" || fail "$file: missing description"
  [[ "$(rg -c '^developer_instructions = """$' "$file")" == 1 ]] || fail "$file: missing developer_instructions"
done

for name in doc_verifier check_runner; do
  rg -q '^model = "gpt-5.6-terra"$' "$ROOT/agents/$name.toml" || fail "$name: wrong model"
  rg -q '^model_reasoning_effort = "low"$' "$ROOT/agents/$name.toml" || fail "$name: wrong effort"
done
for name in codebase_scanner domain_researcher; do
  rg -q '^model = "gpt-5.6-terra"$' "$ROOT/agents/$name.toml" || fail "$name: wrong model"
  rg -q '^model_reasoning_effort = "medium"$' "$ROOT/agents/$name.toml" || fail "$name: wrong effort"
done
! rg -q '^(model|model_reasoning_effort) =' "$ROOT/agents/change_analyzer.toml" || fail "change_analyzer must inherit the parent model"

for name in change_analyzer codebase_scanner doc_verifier domain_researcher; do
  rg -q '^sandbox_mode = "read-only"$' "$ROOT/agents/$name.toml" || fail "$name: must be read-only"
done
rg -q '^sandbox_mode = "workspace-write"$' "$ROOT/agents/check_runner.toml" || fail "check_runner: must run artifact-writing checks"

echo "OK: custom-agent contract"
