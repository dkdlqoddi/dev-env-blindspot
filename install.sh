#!/usr/bin/env bash
# Consumer onboarding. Run from a consumer project root after mounting this
# repository at .codex/shared. Idempotent and conservative about consumer data.
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to install blindspot for Codex" >&2
  exit 1
fi

python3 - <<'PY'
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import tempfile

SHARED = Path(".codex/shared")
SKILL_SOURCE = SHARED / "skills/blindspot-pass"
PROFILE_SOURCE = SHARED / "agents/codebase_scanner.toml"
MANDATE_SOURCE = SHARED / "MANDATE.md"
HOOK_SOURCE = SHARED / "hooks/mandate.sh"

SKILL_DESTINATION = Path(".agents/skills/blindspot-pass")
PROFILE_DESTINATION = Path(".codex/agents/codebase_scanner.toml")
HOOKS_PATH = Path(".codex/hooks.json")
AGENTS_PATH = Path("AGENTS.md")
OVERRIDE_PATH = Path("AGENTS.override.md")

HOOK_COMMAND = 'bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"'
START = "<!-- dev-env-blindspot:mandate:start -->"
END = "<!-- dev-env-blindspot:mandate:end -->"

# Exact bytes distributed by the previous Codex full branch. A modified file is
# consumer data and is deliberately preserved.
LEGACY_AGENT_HASHES = {
    "change_analyzer.toml": "638fddacb1a4391b5bef1795566420a0035296354158a474abf8c380a8c684da",
    "check_runner.toml": "7f943fb4a07276fb2ad8e1fc25e8d1bb20221bb52302f6c4d15ec13c3fe55f54",
    "doc_verifier.toml": "2640d6f44d2a98c2848f97dc538c49b5c39720752c411bd4d6934bbaa2edb629",
    "domain_researcher.toml": "00e09a47d432179b576e317d549a93602bbe6f5959a89387a1ddd62219b5ddf5",
}


class InstallError(Exception):
    pass


def read_bytes(path, description):
    try:
        return path.read_bytes()
    except OSError as exc:
        raise InstallError(f"cannot read {description} at {path}: {exc}") from exc


def validate_real_directory(path):
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return
    except OSError as exc:
        raise InstallError(f"cannot inspect managed directory {path}: {exc}") from exc
    if not stat.S_ISDIR(mode):
        raise InstallError(f"managed directory must be a real directory: {path}")


def validate_optional_regular_file(path, description):
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return False
    except OSError as exc:
        raise InstallError(f"cannot inspect {description} at {path}: {exc}") from exc
    if not stat.S_ISREG(mode):
        raise InstallError(f"{description} must be absent or a regular file: {path}")
    return True


def validate_skill_destination(path):
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return
    if not stat.S_ISLNK(mode):
        raise InstallError(f"refusing to replace non-symlink skill destination: {path}")


def validate_profile_destination(path):
    try:
        mode = path.lstat().st_mode
    except FileNotFoundError:
        return
    if not (stat.S_ISREG(mode) or stat.S_ISLNK(mode)):
        raise InstallError(f"refusing to replace special agent destination: {path}")


def validate_profile(content):
    try:
        text = content.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise InstallError(f"agent profile is not valid UTF-8: {PROFILE_SOURCE}") from exc
    required = {
        "name": "codebase_scanner",
        "model": "gpt-5.6-terra",
        "model_reasoning_effort": "medium",
        "sandbox_mode": "read-only",
    }
    for key, expected in required.items():
        match = re.search(rf'(?m)^{re.escape(key)}\s*=\s*"([^"]+)"\s*$', text)
        if match is None or match.group(1) != expected:
            raise InstallError(f"agent profile has invalid {key}: {PROFILE_SOURCE}")
    description = re.search(r'(?m)^description\s*=\s*"([^"]+)"\s*$', text)
    if description is None or not description.group(1).strip():
        raise InstallError(f"agent profile has no description: {PROFILE_SOURCE}")
    if text.count('developer_instructions = """') != 1 or not text.rstrip().endswith('"""'):
        raise InstallError(f"agent profile has invalid developer_instructions: {PROFILE_SOURCE}")


def validate_guidance(path, content):
    start = START.encode()
    end = END.encode()
    starts = content.count(start)
    ends = content.count(end)
    if starts == 0 and ends == 0:
        return
    if starts == 1 and ends == 1 and content.index(start) < content.index(end):
        return
    raise InstallError(f"{path} must contain no mandate markers or one ordered pair")


def render_guidance(content, mandate):
    start = START.encode()
    end = END.encode()
    block = start + b"\n" + mandate.rstrip(b"\n") + b"\n" + end
    if start in content:
        start_at = content.index(start)
        end_at = content.index(end, start_at) + len(end)
        return content[:start_at] + block + content[end_at:]
    if not content:
        return block + b"\n"
    boundary = b"" if content.endswith(b"\n\n") else (b"\n" if content.endswith(b"\n") else b"\n\n")
    return content + boundary + block + b"\n"


def render_hooks(existing):
    if existing:
        try:
            data = json.loads(existing.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise InstallError(f"{HOOKS_PATH} is not valid JSON: {exc}") from exc
        if not isinstance(data, dict):
            raise InstallError(f"{HOOKS_PATH} must contain a JSON object")
    else:
        data = {}

    hook_map = data.get("hooks", {})
    if not isinstance(hook_map, dict):
        raise InstallError(f"{HOOKS_PATH}: hooks must be a JSON object")
    groups = hook_map.get("SessionStart", [])
    if not isinstance(groups, list):
        raise InstallError(f"{HOOKS_PATH}: hooks.SessionStart must be a JSON list")

    kept_groups = []
    for group_index, group in enumerate(groups, start=1):
        if not isinstance(group, dict) or not isinstance(group.get("hooks"), list):
            raise InstallError(f"{HOOKS_PATH}: invalid SessionStart group {group_index}")
        kept_handlers = []
        for handler_index, handler in enumerate(group["hooks"], start=1):
            if not isinstance(handler, dict):
                raise InstallError(
                    f"{HOOKS_PATH}: invalid SessionStart handler {group_index}.{handler_index}"
                )
            if handler.get("command") != HOOK_COMMAND:
                kept_handlers.append(handler)
        updated = dict(group)
        updated["hooks"] = kept_handlers
        if kept_handlers:
            kept_groups.append(updated)

    kept_groups.append(
        {
            "hooks": [
                {
                    "type": "command",
                    "command": HOOK_COMMAND,
                    "statusMessage": "Loading blindspot mandate",
                }
            ]
        }
    )
    updated_map = dict(hook_map)
    updated_map["SessionStart"] = kept_groups
    updated_data = dict(data)
    updated_data["hooks"] = updated_map
    return (json.dumps(updated_data, ensure_ascii=False, indent=2) + "\n").encode()


def existing_mode(path, default=0o644):
    try:
        return stat.S_IMODE(path.stat().st_mode)
    except OSError:
        return default


def atomic_write(path, content, mode):
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
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


def dangling_shared_skill_links():
    root = Path(".agents/skills")
    if not root.exists():
        return []
    shared_absolute = str((Path.cwd() / SHARED).absolute())
    result = []
    for candidate in root.iterdir():
        if not candidate.is_symlink() or candidate.exists():
            continue
        target = os.readlink(candidate)
        if target.startswith("../../.codex/shared/") or target.startswith(shared_absolute + "/"):
            result.append(candidate)
    return result


def unchanged_legacy_profiles():
    result = []
    root = Path(".codex/agents")
    for filename, expected_hash in LEGACY_AGENT_HASHES.items():
        candidate = root / filename
        try:
            mode = candidate.lstat().st_mode
        except FileNotFoundError:
            continue
        if not stat.S_ISREG(mode):
            continue
        if hashlib.sha256(candidate.read_bytes()).hexdigest() == expected_hash:
            result.append(candidate)
    return result


def preflight():
    if not (SKILL_SOURCE / "SKILL.md").is_file():
        raise InstallError(f"run from a consumer root containing {SKILL_SOURCE}/SKILL.md")
    if not (SKILL_SOURCE / "templates/decisions.md").is_file():
        raise InstallError(f"missing decision template under {SKILL_SOURCE}")
    for source, description in (
        (PROFILE_SOURCE, "agent profile"),
        (MANDATE_SOURCE, "mandate"),
        (HOOK_SOURCE, "mandate hook"),
    ):
        if not source.is_file():
            raise InstallError(f"missing {description}: {source}")

    profile = read_bytes(PROFILE_SOURCE, "agent profile")
    validate_profile(profile)
    mandate = read_bytes(MANDATE_SOURCE, "mandate")
    if not mandate.strip():
        raise InstallError(f"empty mandate: {MANDATE_SOURCE}")
    try:
        mandate.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise InstallError(f"mandate is not valid UTF-8: {MANDATE_SOURCE}") from exc
    if START.encode() in mandate or END.encode() in mandate:
        raise InstallError("mandate source must not contain installer markers")

    for path in (Path(".agents"), Path(".agents/skills"), Path(".codex"), Path(".codex/agents")):
        validate_real_directory(path)
    validate_skill_destination(SKILL_DESTINATION)
    validate_profile_destination(PROFILE_DESTINATION)

    hooks_exists = validate_optional_regular_file(HOOKS_PATH, "hooks JSON")
    agents_exists = validate_optional_regular_file(AGENTS_PATH, "AGENTS guidance")
    override_exists = validate_optional_regular_file(OVERRIDE_PATH, "AGENTS override guidance")

    hooks = read_bytes(HOOKS_PATH, "hooks JSON") if hooks_exists else b""
    agents = read_bytes(AGENTS_PATH, "AGENTS guidance") if agents_exists else b""
    override = read_bytes(OVERRIDE_PATH, "AGENTS override guidance") if override_exists else None
    validate_guidance(AGENTS_PATH, agents)
    if override is not None:
        validate_guidance(OVERRIDE_PATH, override)

    return {
        "profile": profile,
        "mandate": mandate,
        "hooks": render_hooks(hooks),
        "agents": render_guidance(agents, mandate),
        "override": render_guidance(override, mandate) if override is not None else None,
        "override_exists": override_exists,
        "stale_links": dangling_shared_skill_links(),
        "legacy_profiles": unchanged_legacy_profiles(),
    }


def install():
    rendered = preflight()
    Path(".agents/skills").mkdir(parents=True, exist_ok=True)
    Path(".codex/agents").mkdir(parents=True, exist_ok=True)

    for path in rendered["stale_links"]:
        path.unlink()
    for path in rendered["legacy_profiles"]:
        path.unlink()

    atomic_link(SKILL_DESTINATION, "../../.codex/shared/skills/blindspot-pass")
    atomic_write(PROFILE_DESTINATION, rendered["profile"], existing_mode(PROFILE_SOURCE))
    atomic_write(HOOKS_PATH, rendered["hooks"], existing_mode(HOOKS_PATH))
    atomic_write(AGENTS_PATH, rendered["agents"], existing_mode(AGENTS_PATH))
    if rendered["override_exists"]:
        atomic_write(OVERRIDE_PATH, rendered["override"], existing_mode(OVERRIDE_PATH))

    return len(rendered["stale_links"]), len(rendered["legacy_profiles"])


try:
    stale_links, legacy_profiles = install()
except InstallError as exc:
    raise SystemExit(f"error: {exc}")
except OSError as exc:
    raise SystemExit(f"error: unable to install blindspot: {exc}")

print(
    "blindspot: installed — 1 skill linked, 1 Codex agent copied, "
    f"{stale_links} stale skill link(s) and {legacy_profiles} old profile(s) pruned, "
    "SessionStart hook merged, mandate guidance ensured"
)
PY
