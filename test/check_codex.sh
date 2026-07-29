#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }

if ! command -v codex >/dev/null 2>&1; then
  echo "SKIP: codex CLI unavailable"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
mkdir -p "$proj/.codex"
git -C "$proj" init -q
ln -s "$ROOT" "$proj/.codex/shared"
(cd "$proj" && bash .codex/shared/install.sh >/dev/null)

codex_home="$tmp/codex-home"
mkdir -p "$codex_home"
printf '[projects."%s"]\ntrust_level = "trusted"\n' "$proj" > "$codex_home/config.toml"

stdout="$tmp/codex.out"
stderr="$tmp/codex.err"
if ! CODEX_HOME="$codex_home" codex --dangerously-bypass-hook-trust --strict-config -C "$proj" debug prompt-input "Summarize active blindspot instructions." >"$stdout" 2>"$stderr"; then
  strict_unsupported='Error: `--strict-config` is not supported for `codex debug`'
  if ! rg -qx -F "$strict_unsupported" "$stderr"; then
    cat "$stdout"
    cat "$stderr" >&2
    fail "Codex strict prompt discovery failed"
  fi
  echo "INFO: codex debug lacks --strict-config; using compatibility fallback"
  if ! CODEX_HOME="$codex_home" codex --dangerously-bypass-hook-trust -C "$proj" debug prompt-input "Summarize active blindspot instructions." >"$stdout" 2>"$stderr"; then
    cat "$stdout"
    cat "$stderr" >&2
    fail "Codex compatibility prompt discovery failed"
  fi
fi

rg -q -F 'Blindspot Mandate' "$stdout" || fail "Codex prompt omitted Blindspot Mandate"
for skill in blindspot-flow blindspot-pass explainer requirements-interview work-report; do
  rg -q -F -- "- $skill:" "$stdout" || fail "Codex prompt omitted skill catalog entry $skill"
  rg -q -F -- "/skills/$skill/SKILL.md" "$stdout" || fail "Codex prompt omitted skill catalog location $skill"
done

warning='(warn(ing)?[^[:cntrl:]]*(pars(e|er)|custom[- ]agent)|(pars(e|er)|custom[- ]agent)[^[:cntrl:]]*warn(ing)?)'
if rg -qi "$warning" "$stderr"; then
  cat "$stderr" >&2
  fail "Codex reported a parser or custom-agent configuration warning"
fi

echo "OK: native Codex discovery"
