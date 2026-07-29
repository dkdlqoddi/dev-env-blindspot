#!/usr/bin/env bash
# Consumer onboarding. Run from the consumer project root after mounting this
# repository at .codex/shared. Idempotent: safe to re-run after updates.
set -euo pipefail

SHARED=".codex/shared"

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to install blindspot for Codex" >&2
  echo "managed destinations:" >&2
  echo "  .agents/skills" >&2
  echo "  .codex/agents" >&2
  echo "  .codex/hooks.json" >&2
  echo "  AGENTS.md and existing AGENTS.override.md" >&2
  exit 1
fi

python3 - <<'PY'
import json
import os
from pathlib import Path
import stat
import tempfile

SHARED = Path(".codex/shared")
HOOKS_PATH = Path(".codex/hooks.json")
AGENTS_PATH = Path("AGENTS.md")
OVERRIDE_PATH = Path("AGENTS.override.md")
HOOK_CMD = 'bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"'
START = "<!-- dev-env-blindspot:mandate:start -->"
END = "<!-- dev-env-blindspot:mandate:end -->"

SKILLS = (
    "blindspot-flow",
    "blindspot-pass",
    "explainer",
    "requirements-interview",
    "work-report",
)
AGENTS = (
    "change_analyzer",
    "check_runner",
    "codebase_scanner",
    "doc_verifier",
    "domain_researcher",
)


class InstallError(Exception):
    pass


def read_text(path, description):
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise InstallError(f"cannot read {description} at {path}: {exc}") from exc


def read_bytes(path, description):
    try:
        return path.read_bytes()
    except OSError as exc:
        raise InstallError(f"cannot read {description} at {path}: {exc}") from exc


def validate_guidance(path, text):
    start_marker = START.encode("utf-8")
    end_marker = END.encode("utf-8")
    starts = text.count(start_marker)
    ends = text.count(end_marker)
    if starts == 0 and ends == 0:
        return
    if (
        starts == 1
        and ends == 1
        and text.index(start_marker) < text.index(end_marker)
    ):
        return
    raise InstallError(
        f"{path} must contain either no mandate markers or one ordered marker pair"
    )


def render_guidance(text, mandate):
    start_marker = START.encode("utf-8")
    end_marker = END.encode("utf-8")
    mandate_suffix = b"" if mandate.endswith(b"\n") else b"\n"
    block = start_marker + b"\n" + mandate + mandate_suffix + end_marker
    if start_marker in text:
        start_at = text.index(start_marker)
        end_at = text.index(end_marker, start_at) + len(end_marker)
        return text[:start_at] + block + text[end_at:]
    if not text:
        return block + b"\n"
    if text.endswith(b"\n\n"):
        boundary = b""
    elif text.endswith(b"\n"):
        boundary = b"\n"
    else:
        boundary = b"\n\n"
    return text + boundary + block + b"\n"


def atomic_write(path, content, mode=None):
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
        if mode is not None:
            os.chmod(temporary_path, mode)
        os.replace(temporary_path, path)
    except BaseException:
        temporary_path.unlink(missing_ok=True)
        raise


def atomic_link(path, target):
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    os.close(fd)
    temporary_path = Path(temporary)
    temporary_path.unlink()
    try:
        os.symlink(target, temporary_path)
        os.replace(temporary_path, path)
    except BaseException:
        temporary_path.unlink(missing_ok=True)
        raise


def existing_mode(path, default=0o644):
    try:
        return stat.S_IMODE(path.stat().st_mode)
    except OSError:
        return default


def validate_and_render():
    mandate_path = SHARED / "MANDATE.md"
    if not mandate_path.is_file():
        raise InstallError(f"missing mandate file: {mandate_path}")
    mandate = read_bytes(mandate_path, "mandate")
    if not mandate:
        raise InstallError(f"mandate file is empty: {mandate_path}")

    for name in SKILLS:
        skill_path = SHARED / "skills" / name
        if not skill_path.is_dir():
            raise InstallError(f"missing skill directory: {skill_path}")
        skill_file = skill_path / "SKILL.md"
        if not skill_file.is_file():
            raise InstallError(f"missing skill entry point: {skill_file}")
        read_bytes(skill_file, "skill entry point")

    agent_sources = {}
    for name in AGENTS:
        source = SHARED / "agents" / f"{name}.toml"
        if not source.is_file():
            raise InstallError(f"missing Codex agent profile: {source}")
        content = read_bytes(source, "Codex agent profile")
        if not content:
            raise InstallError(f"Codex agent profile is empty: {source}")
        agent_sources[name] = (content, stat.S_IMODE(source.stat().st_mode))

    if HOOKS_PATH.exists():
        hooks_text = read_text(HOOKS_PATH, "hooks JSON")
        try:
            hooks_data = json.loads(hooks_text)
        except json.JSONDecodeError as exc:
            raise InstallError(f"{HOOKS_PATH} is not valid JSON: {exc}") from exc
        if not isinstance(hooks_data, dict):
            raise InstallError(f"{HOOKS_PATH} must contain a JSON object")
    else:
        hooks_data = {}

    if "hooks" in hooks_data and not isinstance(hooks_data["hooks"], dict):
        raise InstallError(f"{HOOKS_PATH}: hooks must be a JSON object")
    hooks = hooks_data.get("hooks", {})
    if "SessionStart" in hooks and not isinstance(hooks["SessionStart"], list):
        raise InstallError(f"{HOOKS_PATH}: hooks.SessionStart must be a JSON list")
    session_start = hooks.get("SessionStart", [])
    for group_number, group in enumerate(session_start, start=1):
        if not isinstance(group, dict):
            raise InstallError(
                f"{HOOKS_PATH}: SessionStart group {group_number} must be a JSON object"
            )
        if "hooks" not in group or not isinstance(group["hooks"], list):
            raise InstallError(
                f"{HOOKS_PATH}: SessionStart group {group_number} hooks must be a JSON list"
            )
        for handler_number, handler in enumerate(group["hooks"], start=1):
            if not isinstance(handler, dict):
                raise InstallError(
                    f"{HOOKS_PATH}: SessionStart group {group_number} handler "
                    f"{handler_number} must be a JSON object"
                )

    agents_text = read_bytes(AGENTS_PATH, "AGENTS guidance") if AGENTS_PATH.exists() else b""
    validate_guidance(AGENTS_PATH, agents_text)
    override_existed = OVERRIDE_PATH.exists()
    override_text = (
        read_bytes(OVERRIDE_PATH, "AGENTS override guidance") if override_existed else None
    )
    if override_text is not None:
        validate_guidance(OVERRIDE_PATH, override_text)

    for name in SKILLS:
        destination = Path(".agents/skills") / name
        if destination.is_dir() and not destination.is_symlink():
            raise InstallError(
                f"refusing to replace consumer skill directory: {destination}"
            )

    for destination_root in (Path(".agents/skills"), Path(".codex/agents")):
        for candidate in (destination_root.parent, destination_root):
            if os.path.lexists(candidate) and not candidate.is_dir():
                raise InstallError(f"managed directory path is not a directory: {candidate}")
    for name in AGENTS:
        destination = Path(".codex/agents") / f"{name}.toml"
        if destination.is_dir() and not destination.is_symlink():
            raise InstallError(
                f"refusing to replace directory with Codex agent profile: {destination}"
            )

    rendered_groups = []
    for group in session_start:
        rendered_group = dict(group)
        rendered_group["hooks"] = [
            handler
            for handler in group["hooks"]
            if handler.get("command") != HOOK_CMD
        ]
        if rendered_group["hooks"] or any(key != "hooks" for key in rendered_group):
            rendered_groups.append(rendered_group)
    rendered_groups.append(
        {
            "hooks": [
                {
                    "type": "command",
                    "command": HOOK_CMD,
                    "statusMessage": "Loading blindspot workflow",
                }
            ]
        }
    )
    rendered_hooks = dict(hooks_data)
    rendered_hook_map = dict(hooks)
    rendered_hook_map["SessionStart"] = rendered_groups
    rendered_hooks["hooks"] = rendered_hook_map
    hooks_content = (
        json.dumps(rendered_hooks, indent=2, ensure_ascii=False) + "\n"
    ).encode("utf-8")
    agents_content = render_guidance(agents_text, mandate)
    override_content = (
        render_guidance(override_text, mandate)
        if override_text is not None
        else None
    )
    return agent_sources, hooks_content, agents_content, override_content, override_existed


def install():
    (
        agent_sources,
        hooks_content,
        agents_content,
        override_content,
        override_existed,
    ) = validate_and_render()

    skills_destination = Path(".agents/skills")
    agents_destination = Path(".codex/agents")
    skills_destination.mkdir(parents=True, exist_ok=True)
    agents_destination.mkdir(parents=True, exist_ok=True)

    for name in SKILLS:
        atomic_link(
            skills_destination / name,
            f"../../.codex/shared/skills/{name}",
        )
    for name in AGENTS:
        content, mode = agent_sources[name]
        atomic_write(agents_destination / f"{name}.toml", content, mode)

    atomic_write(HOOKS_PATH, hooks_content, existing_mode(HOOKS_PATH))
    atomic_write(AGENTS_PATH, agents_content, existing_mode(AGENTS_PATH))
    if override_existed:
        atomic_write(
            OVERRIDE_PATH,
            override_content,
            existing_mode(OVERRIDE_PATH),
        )


try:
    install()
except InstallError as exc:
    raise SystemExit(f"error: {exc}")
except OSError as exc:
    raise SystemExit(f"error: unable to install blindspot: {exc}")
PY

echo "blindspot: installed — 5 skills linked, 5 Codex agents copied, SessionStart hook merged, mandate guidance ensured"
