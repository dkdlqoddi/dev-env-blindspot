#!/usr/bin/env python3
"""Mechanical checks for a swarm plan package (docs/swarm/plan.md + tasks/<id>.md).

Usage: python3 swarm_check.py docs/swarm/plan.md

plan.md : header bullets 기준 커밋 (a commit of this repository) / 전체 검증 (a backticked
          command) / 동시 실행 상한 (a positive number) / 대상 spec / 작업 노트 present and not
          template guidance; sections 목표 / 작업 / 웨이브별 검증 / 회차 present; the 작업 table
          has rows of id | 제목 | 역할 | 웨이브 | 선행 with unique T01-style ids and a numeric
          웨이브; every id has tasks/<id>.md and every tasks/*.md is listed; 웨이브별 검증 has
          one row per 웨이브, each 전체 검증 or one backticked command, the last 웨이브 전체 검증;
          회차 rows number upward and the latest 범위 is 전체 or ids of the 작업 table
briefs  : header bullets 웨이브 / 선행 / 소유 파일 present and equal to the table; sections
          목표 / 해야 할 일 / 완료 조건 / 검증 present and non-empty; 선행 ids exist and sit in
          an earlier 웨이브; no delegating words (필요하면, 적절히, if needed, as appropriate, ...)
paths   : judged against git (기준 커밋 and HEAD), never the working tree, so the verdict does
          not change when the swarm's own commits land (resume, re-plan round). (신규) = absent
          at 기준 커밋. Every other 소유 파일 / 참고 파일 path exists at 기준 커밋 or HEAD, or lies
          under a (신규) path owned in an earlier 웨이브. A path is a directory when it ends with
          / or is a tree in git. No two tasks of one 웨이브 own overlapping paths; no task reads
          (참고 파일) what another task of its 웨이브 owns; no 소유 파일 under docs/swarm/,
          docs/notes/, docs/quiz.html, or an area's rules.md / map.md / specs/
both    : no template placeholders left ([제목], [주제], YYYY-MM-DD, TODO, TBD, <영역>, <단위>,
          <slug>, path/to/)

Prints violations and exits 1; exits 0 when clean. The swarm-run skill's swarm_next.py imports
load() for the parsed package.
"""
import os
import re
import subprocess
import sys
from fnmatch import fnmatch

PLACEHOLDERS = ("[제목]", "[주제]", "YYYY-MM-DD", "TODO", "TBD", "<영역>", "<단위>", "<slug>", "path/to/")
DELEGATING_WORDS = ("필요하면", "적절히", "if needed", "as needed", "if necessary", "as necessary",
                    "as appropriate", "where appropriate", "appropriately")
PLAN_HEADER = ("기준 커밋", "전체 검증", "동시 실행 상한", "대상 spec", "작업 노트")
PLAN_SECTIONS = ("목표", "작업", "웨이브별 검증", "회차")
BRIEF_SECTIONS = ("목표", "해야 할 일", "완료 조건", "검증")
FULL_CHECK = "전체 검증"
ID_RE = re.compile(r"^T\d{2,3}$")
GLOB_CHARS = "*?["


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def section(src, heading):
    m = re.search(rf"^## {re.escape(heading)}\s*$(.*?)(?=^## |\Z)", src, re.S | re.M)
    return m.group(1) if m else None


def bullet(src, label):
    m = re.search(rf"^- {re.escape(label)}:[ \t]*(.*?)[ \t]*$", src, re.M)
    return m.group(1) if m else None


def strip_comments(text):
    return re.sub(r"<!--.*?-->", " ", text, flags=re.S)


def table_rows(body):
    for line in body.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if not cells[0] or set(cells[0]) <= set("-: "):
            continue
        yield cells


def deps(text):
    text = (text or "").strip()
    if not text or text == "없음":
        return []
    return [d.strip().strip("`") for d in text.split(",") if d.strip()]


def paths(text, owned):
    """(normalized path, ends with /, marked (신규)) per backticked path of a 소유 파일 or 참고 파일 bullet."""
    out = []
    for m in re.finditer(r"`([^`]+)`(\s*\(신규\))?", text or ""):
        raw = m.group(1).strip()
        if not owned:
            raw = re.sub(r":\d+(-\d+)?$", "", raw)  # 참고 파일 may cite path:12-40
        if not raw or any(c.isspace() for c in raw):
            continue
        out.append((os.path.normpath(raw), raw.endswith("/"), owned and bool(m.group(2))))
    return out


def overlaps(a, b):
    """a, b are (path, is_dir) pairs."""
    # ponytail: equality, fnmatch and directory-prefix on normalized paths; a real path-set intersection only if globs get fancy
    (pa, da), (pb, db) = a, b
    if pa == pb or fnmatch(pa, pb) or fnmatch(pb, pa):
        return True
    return (da and pb.startswith(pa + "/")) or (db and pa.startswith(pb + "/"))


def git(root, *args):
    """stdout of a git command run in root, or None when git is missing or the command fails."""
    try:
        r = subprocess.run(["git", "-C", root, *args], capture_output=True, encoding="utf-8", errors="surrogateescape")
    except OSError:
        return None
    return r.stdout if r.returncode == 0 else None


class Tree:
    """Files and directories of one git revision, relative to root."""

    def __init__(self, root, rev):
        out = git(root, "ls-tree", "-r", "-z", "--name-only", rev) or ""
        self.files = {p for p in out.split("\0") if p}
        self.dirs = {p.rsplit("/", i)[0] for p in self.files for i in range(1, p.count("/") + 1)}

    def has(self, path):
        return path in self.files or path in self.dirs

    def matches(self, pattern):
        return any(fnmatch(p, pattern) for p in self.files | self.dirs)


def placeholders(text, where, violations):
    clean = strip_comments(text)
    for tok in PLACEHOLDERS:
        if tok in clean:
            violations.append(f"{where}: placeholder '{tok}' left in")


def header_value(src, label, where, violations):
    value = bullet(src, label)
    if not value:
        violations.append(f"{where}: header bullet '{label}' missing or empty")
        return None
    if value.lstrip("`").startswith("("):
        violations.append(f"{where}: header bullet '{label}' still holds template guidance: {value}")
        return None
    return value


def check_plan(src, pkg, violations):
    header = {label: header_value(src, label, "plan.md", violations) for label in PLAN_HEADER}
    pkg["base"] = header["기준 커밋"]
    if header["전체 검증"]:
        m = re.search(r"`([^`]+)`", header["전체 검증"])
        if m:
            pkg["full_check"] = m.group(1).strip()
        else:
            violations.append("plan.md: 전체 검증 must be a backticked command")
    cap = header["동시 실행 상한"]
    if cap:
        if cap.isdigit() and int(cap) > 0:
            pkg["cap"] = int(cap)
        else:
            violations.append("plan.md: 동시 실행 상한 must be a positive number")
    placeholders(src, "plan.md", violations)
    for h in PLAN_SECTIONS:
        if section(src, h) is None:
            violations.append(f"plan.md: '## {h}' section not found")

    tasks = pkg["tasks"]
    body = section(src, "작업")
    for cells in table_rows(body or ""):
        if cells[0] == "id":
            continue
        tid = cells[0].strip("`")
        if len(cells) < 5:
            violations.append(f"plan.md: row '{tid}' needs 5 cells (id | 제목 | 역할 | 웨이브 | 선행)")
            continue
        if not ID_RE.match(tid):
            violations.append(f"plan.md: id '{tid}' must look like T01")
        if tid in tasks:
            violations.append(f"plan.md: id '{tid}' listed twice")
        if not cells[3].isdigit():
            violations.append(f"plan.md: row '{tid}' 웨이브 must be a number")
        tasks[tid] = {"title": cells[1], "role": cells[2], "wave": int(cells[3]) if cells[3].isdigit() else None,
                      "deps": deps(cells[4])}
    if body is not None and not tasks:
        violations.append("plan.md: 작업 table has no tasks")

    waves = sorted({t["wave"] for t in tasks.values() if t["wave"] is not None})
    body = section(src, "웨이브별 검증")
    if body is not None:
        seen = set()
        for cells in table_rows(body):
            if cells[0] == "웨이브":
                continue
            if not cells[0].isdigit():
                violations.append(f"plan.md: 웨이브별 검증 row '{cells[0]}' must start with a 웨이브 number")
                continue
            w, cell = int(cells[0]), (cells[1] if len(cells) > 1 else "")
            if w in seen:
                violations.append(f"plan.md: 웨이브별 검증 lists 웨이브 {w} twice")
            seen.add(w)
            m = re.fullmatch(r"`([^`]+)`", cell)
            if cell == FULL_CHECK or (m and m.group(1).strip() == pkg["full_check"]):
                pkg["waves"][w] = None  # None = the plan's 전체 검증
            elif m:
                pkg["waves"][w] = m.group(1).strip()
            else:
                violations.append(f"plan.md: 웨이브 {w} 검증 must be 전체 검증 or one backticked command")
        for w in waves:
            if w not in seen:
                violations.append(f"plan.md: 웨이브 {w} has no row in 웨이브별 검증")
        for w in sorted(seen - set(waves)):
            violations.append(f"plan.md: 웨이브별 검증 names 웨이브 {w}, which has no task")
        if waves and pkg["waves"].get(waves[-1]) is not None:
            violations.append(f"plan.md: the last 웨이브 ({waves[-1]}) must be verified with 전체 검증")

    body = section(src, "회차")
    if body is not None:
        for cells in table_rows(body):
            if cells[0] == "회차":
                continue
            if not cells[0].isdigit():
                violations.append(f"plan.md: 회차 row '{cells[0]}' must start with a number")
                continue
            scope = cells[2] if len(cells) > 2 else ""
            pkg["rounds"].append({"n": int(cells[0]),
                                  "scope": None if scope == "전체" else re.findall(r"T\d{2,3}", scope)})
        numbers = [r["n"] for r in pkg["rounds"]]
        if not numbers:
            violations.append("plan.md: 회차 table has no row")
        elif numbers != sorted(set(numbers)):
            violations.append("plan.md: 회차 numbers must increase row by row")
        else:
            last = pkg["rounds"][-1]
            if last["scope"] is not None and not last["scope"]:
                violations.append(f"plan.md: 회차 {last['n']} 범위 must be 전체 or task ids")
            for tid in last["scope"] or []:
                if tid not in tasks:
                    violations.append(f"plan.md: 회차 {last['n']} 범위 names '{tid}', which is not in the 작업 table")


def check_brief(tid, path, pkg, violations):
    src = read(path)
    where = f"tasks/{tid}.md"
    row = pkg["tasks"][tid]
    placeholders(src, where, violations)
    wave = bullet(src, "웨이브")
    if not (wave and wave.isdigit()):
        violations.append(f"{where}: '- 웨이브: N' missing")
        wave = None
    else:
        wave = int(wave)
        if wave != row["wave"]:
            violations.append(f"{where}: 웨이브 {wave} differs from plan.md ({row['wave']})")
    dep_line = bullet(src, "선행")
    if dep_line is None:
        violations.append(f"{where}: '- 선행:' missing (use 없음 when there is none)")
    elif deps(dep_line) != row["deps"]:
        violations.append(f"{where}: 선행 differs from plan.md")
    own = paths(bullet(src, "소유 파일"), owned=True)
    if not own:
        violations.append(f"{where}: '- 소유 파일:' missing or names no backticked path")
    for h in BRIEF_SECTIONS:
        body = section(src, h)
        if body is None:
            violations.append(f"{where}: '## {h}' section not found")
            continue
        clean = strip_comments(body)
        if not clean.strip():
            violations.append(f"{where}: '## {h}' is empty")
        lower = clean.lower()
        for word in DELEGATING_WORDS:
            if word in lower:
                violations.append(f"{where}: '## {h}' delegates a decision to the worker with '{word}' — decide it in the brief")
    refs = [(p, slash) for p, slash, _ in paths(bullet(src, "참고 파일"), owned=False)]
    return {"wave": wave, "own": own, "refs": refs}


def check_deps(pkg, briefs, violations):
    for tid, info in briefs.items():
        for dep in pkg["tasks"][tid]["deps"]:
            if dep not in briefs:
                violations.append(f"{tid}: 선행 '{dep}' is not a task")
            elif info["wave"] is not None and briefs[dep]["wave"] is not None and briefs[dep]["wave"] >= info["wave"]:
                violations.append(f"{tid}: 선행 '{dep}' must sit in an earlier 웨이브")


def check_paths(pkg, briefs, violations):
    """Resolve directories from git, then check existence and reserved paths; skipped without a valid 기준 커밋."""
    root, base = pkg["root"], pkg["base"]
    if not base:
        return
    if git(root, "rev-parse", "--verify", "--quiet", base + "^{commit}") is None:
        violations.append(f"plan.md: 기준 커밋 '{base}' is not a commit of the git repository at {root}")
        return
    at_base, at_head = Tree(root, base), Tree(root, "HEAD")
    for info in briefs.values():
        info["own"] = [(p, slash or p in at_base.dirs or p in at_head.dirs, new) for p, slash, new in info["own"]]
        info["refs"] = [(p, slash or p in at_base.dirs or p in at_head.dirs) for p, slash in info["refs"]]
    created = [(info["wave"], p, d) for info in briefs.values() if info["wave"] is not None
               for p, d, new in info["own"] if new]
    areas = sorted({f.split("/")[1] for f in at_base.files | at_head.files if re.fullmatch(r"docs/[^/]+/map\.md", f)})
    reserved = [("docs/swarm", True), ("docs/notes", True), ("docs/quiz.html", False)]
    reserved += [e for a in areas for e in ((f"docs/{a}/rules.md", False), (f"docs/{a}/map.md", False), (f"docs/{a}/specs", True))]

    def reachable(p, d, wave):
        if any(ch in p for ch in GLOB_CHARS):
            return at_base.matches(p) or at_head.matches(p)
        if at_base.has(p) or at_head.has(p):
            return True
        return wave is not None and any(w < wave and overlaps((p, d), (q, qd)) for w, q, qd in created)

    for tid, info in sorted(briefs.items()):
        where = f"tasks/{tid}.md"
        for p, d, new in info["own"]:
            if os.path.isabs(p) or p == ".." or p.startswith("../"):
                violations.append(f"{where}: '{p}' must be a path relative to the project root")
                continue
            if any(overlaps((p, d), r) for r in reserved):
                violations.append(f"{where}: 소유 파일 '{p}' is reserved — workers never write docs/swarm/, docs/notes/, docs/quiz.html, or tier documents")
            if new:
                if at_base.has(p):
                    violations.append(f"{where}: '{p}' is marked (신규) but exists at 기준 커밋 {base}")
            elif not reachable(p, d, info["wave"]):
                violations.append(f"{where}: '{p}' does not exist at 기준 커밋 or HEAD and no earlier 웨이브 creates it (mark it (신규) if this task creates it)")
        for p, d in info["refs"]:
            if not reachable(p, d, info["wave"]):
                violations.append(f"{where}: 참고 파일 '{p}' does not exist at 기준 커밋 or HEAD and no earlier 웨이브 creates it")


def check_overlaps(briefs, violations):
    ids = sorted(briefs)
    for i, a in enumerate(ids):
        for b in ids[i + 1:]:
            wave = briefs[a]["wave"]
            if wave is None or wave != briefs[b]["wave"]:
                continue
            for pa in briefs[a]["own"]:
                for pb in briefs[b]["own"]:
                    if overlaps(pa[:2], pb[:2]):
                        violations.append(f"{a}/{b}: 소유 파일 overlap in 웨이브 {wave}: '{pa[0]}' vs '{pb[0]}'")
            for reader, owner in ((a, b), (b, a)):
                for r in briefs[reader]["refs"]:
                    if any(overlaps(r, o[:2]) for o in briefs[owner]["own"]):
                        violations.append(f"tasks/{reader}.md: 참고 파일 '{r[0]}' is owned by {owner} in the same 웨이브 {wave} — it may change while {reader} reads it; move {reader} to a later 웨이브 or drop the reference")


def load(plan):
    """Parse and check a plan package. Returns (package, violations); the package is best effort when violations exist.

    package: plan, root, base, full_check, cap, tasks {id: title, role, wave, deps} in table order,
    waves {웨이브: command, or None for 전체 검증}, rounds [{n, scope: None for 전체 or [ids]}],
    briefs {id: wave, own [(path, is_dir, is_new)], refs [(path, is_dir)]}.
    """
    plan = os.path.abspath(plan)
    swarm_dir = os.path.dirname(plan)
    pkg = {"plan": plan, "root": os.path.abspath(os.path.join(swarm_dir, "..", "..")), "base": None,
           "full_check": None, "cap": 8, "tasks": {}, "waves": {}, "rounds": [], "briefs": {}}
    if not os.path.isfile(plan):
        return pkg, [f"{plan}: file not found"]
    violations = []
    check_plan(read(plan), pkg, violations)
    tasks_dir = os.path.join(swarm_dir, "tasks")
    brief_ids = {f[:-3] for f in os.listdir(tasks_dir) if f.endswith(".md")} if os.path.isdir(tasks_dir) else set()
    for tid in sorted(set(pkg["tasks"]) - brief_ids):
        violations.append(f"{tid}: listed in plan.md but tasks/{tid}.md is missing")
    for tid in sorted(brief_ids - set(pkg["tasks"])):
        violations.append(f"tasks/{tid}.md: not listed in the plan.md 작업 table")
    briefs = pkg["briefs"]
    for tid in sorted(set(pkg["tasks"]) & brief_ids):
        briefs[tid] = check_brief(tid, os.path.join(tasks_dir, tid + ".md"), pkg, violations)
    check_deps(pkg, briefs, violations)
    check_paths(pkg, briefs, violations)
    check_overlaps(briefs, violations)
    return pkg, violations


def main(argv):
    if len(argv) != 1:
        print("usage: swarm_check.py docs/swarm/plan.md", file=sys.stderr)
        return 2
    pkg, violations = load(argv[0])
    if violations:
        for v in violations:
            print(v)
        print(f"{len(violations)} violation(s)")
        return 1
    print(f"OK — {len(pkg['briefs'])} task(s), {len({b['wave'] for b in pkg['briefs'].values()})} 웨이브")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
