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
import re
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


def validate_multiline_basic_string(value, key):
    if '\"\"\"' in value:
        raise ValueError(f"invalid multiline delimiter in {key!r}")
    position = 0
    while position < len(value):
        character = value[position]
        codepoint = ord(character)
        if codepoint == 0x7F or codepoint < 0x20 and character not in {"\t", "\n"}:
            raise ValueError(f"invalid control character in {key!r}")
        if character != "\\":
            position += 1
            continue
        position += 1
        if position == len(value):
            raise ValueError(f"trailing escape in {key!r}")
        escape = value[position]
        if escape in {'b', 't', 'n', 'f', 'r', '"', '\\'}:
            position += 1
            continue
        if escape in {'u', 'U'}:
            width = 4 if escape == 'u' else 8
            digits = value[position + 1 : position + 1 + width]
            if len(digits) != width or any(
                digit not in "0123456789abcdefABCDEF" for digit in digits
            ):
                raise ValueError(f"invalid Unicode escape in {key!r}")
            escaped_codepoint = int(digits, 16)
            if escaped_codepoint > 0x10FFFF or 0xD800 <= escaped_codepoint <= 0xDFFF:
                raise ValueError(f"invalid Unicode scalar in {key!r}")
            position += width + 1
            continue
        while position < len(value) and value[position] in {" ", "\t"}:
            position += 1
        if position == len(value) or value[position] != "\n":
            raise ValueError(f"invalid escape in multiline string {key!r}")
        position += 1
        while position < len(value) and value[position] in {" ", "\t", "\n"}:
            position += 1


def parse_string_only_toml(text):
    """Parse the top-level basic-string subset used by Codex agent profiles."""
    for position, character in enumerate(text):
        codepoint = ord(character)
        if codepoint == 0x7F or codepoint < 0x20 and character not in {"\t", "\n", "\r"}:
            raise ValueError("invalid literal control character")
        if character == "\r" and text[position + 1 : position + 2] != "\n":
            raise ValueError("bare carriage return")
    values = {}
    lines = [line[:-1] if line.endswith("\r") else line for line in text.split("\n")]
    line_number = 0
    while line_number < len(lines):
        line = lines[line_number]
        line_number += 1
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        match = re.fullmatch(
            r"([A-Za-z_][A-Za-z0-9_-]*)[ \t]*=[ \t]*(.*)", line
        )
        if match is None:
            raise ValueError(f"invalid assignment on line {line_number}")
        key, encoded_value = match.groups()
        if key in values:
            raise ValueError(f"duplicate key {key!r}")
        if encoded_value == '\"\"\"':
            body = []
            while line_number < len(lines) and lines[line_number] != '\"\"\"':
                body.append(lines[line_number])
                line_number += 1
            if line_number == len(lines):
                raise ValueError(f"unterminated multiline string for {key!r}")
            line_number += 1
            value = "\n".join(body)
            validate_multiline_basic_string(value, key)
        else:
            if "\\/" in encoded_value:
                raise ValueError(f"invalid TOML escape in {key!r}")
            try:
                value = json.loads(encoded_value)
            except json.JSONDecodeError as exc:
                raise ValueError(f"invalid basic string for {key!r}: {exc}") from exc
            if not isinstance(value, str):
                raise ValueError(f"{key!r} must be a string")
            if any(0xD800 <= ord(character) <= 0xDFFF for character in value):
                raise ValueError(f"invalid Unicode scalar in {key!r}")
        values[key] = value
    return values


def parse_agent_profile(content, source, expected_name):
    try:
        text = content.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise InstallError(f"Codex agent profile is not valid UTF-8: {source}") from exc
    try:
        try:
            import tomllib
        except ImportError:
            profile = parse_string_only_toml(text)
        else:
            profile = tomllib.loads(text)
    except ValueError as exc:
        raise InstallError(f"Codex agent profile is not valid TOML: {source}: {exc}") from exc
    if profile.get("name") != expected_name:
        raise InstallError(f"Codex agent profile has wrong name: {source}")
    for field in ("description", "developer_instructions"):
        if not isinstance(profile.get(field), str) or not profile[field].strip():
            raise InstallError(f"Codex agent profile is missing nonempty {field}: {source}")


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


def validate_replaceable_destination(path, description):
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return
    if stat.S_ISLNK(mode) or stat.S_ISREG(mode):
        return
    raise InstallError(f"refusing to replace {description}: {path}")


def validate_and_render():
    mandate_path = SHARED / "MANDATE.md"
    if not mandate_path.is_file():
        raise InstallError(f"missing mandate file: {mandate_path}")
    mandate = read_bytes(mandate_path, "mandate")
    if not mandate:
        raise InstallError(f"mandate file is empty: {mandate_path}")
    try:
        mandate.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise InstallError(f"mandate file is not valid UTF-8: {mandate_path}") from exc
    if START.encode("utf-8") in mandate or END.encode("utf-8") in mandate:
        raise InstallError(f"mandate file contains managed marker: {mandate_path}")

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
        parse_agent_profile(content, source, name)
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
        validate_replaceable_destination(destination, "consumer skill destination")

    for destination_root in (Path(".agents/skills"), Path(".codex/agents")):
        for candidate in (destination_root.parent, destination_root):
            if os.path.lexists(candidate) and not candidate.is_dir():
                raise InstallError(f"managed directory path is not a directory: {candidate}")
    for name in AGENTS:
        destination = Path(".codex/agents") / f"{name}.toml"
        validate_replaceable_destination(destination, "Codex agent destination")

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
