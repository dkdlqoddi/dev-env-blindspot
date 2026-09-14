#!/usr/bin/env python3
"""Deterministic state machine behind the swarm-run skill: the Antigravity dispatcher decides nothing.

Run from the project root, carry out the single ACTION printed, then run the command it names.

  swarm_next.py next               start or resume: check the plan (swarm_check.py), open a new
                                   회차, refuse changes outside the swarm's own work, recover an
                                   interrupted 웨이브, then print the next action
  swarm_next.py collect [--final]  after a dispatch: record each result's 상태 (only when its 시도
                                   matches); --final marks results still missing 실패 (결과 없음)
  swarm_next.py verified           after a check, with the swarm-checker reply on stdin: record it,
                                   then commit the 웨이브, retry (owners of the failing paths first,
                                   then the whole 웨이브), or stop

ACTION: dispatch | verify   one invoke_subagent call with the printed Subagents JSON
ACTION: wait                results are missing: wait for the replies, or collect --final
ACTION: finish | stop       relay the printed Korean text to the user; the run is over

A 웨이브 is done when every task is terminal (완료 / 부분 완료 / 실패 / 보류) and its latest check
since its latest task run is 통과 (or 건너뜀: every task 보류). A run ends with a 통과 of the
plan's 전체 검증 after the last change — a 최종 check is added when the last recorded one is not.
A check that cannot run, or a reply without its 검증 결과 line, stops the run with the 웨이브
uncommitted; the next run checks again without re-dispatching. docs/swarm/status.md is written only
here, from this skill's templates/status.md. Exit codes: 0 action printed, 1 stop, 2 misuse.
"""
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.realpath(__file__))
sys.dont_write_bytecode = True  # never leave __pycache__ inside the shared submodule
for _candidate in (os.path.join(HERE, "..", "..", "..", "..", "skills", "swarm-plan", "scripts"),
                   os.path.join(os.getcwd(), ".claude", "skills", "swarm-plan", "scripts")):
    if os.path.isfile(os.path.join(_candidate, "swarm_check.py")):
        sys.path.insert(0, os.path.abspath(_candidate))
        break
try:
    import swarm_check as sc
except ImportError:
    print("ACTION: stop\nReply to the user with the text below the line, verbatim, and end the run.\n---\n"
          "swarm_check.py를 찾을 수 없습니다. 프로젝트 루트에서 bash .claude/shared/install.sh를 실행한 뒤 다시 시도하세요.")
    sys.exit(1)

SWARM = "docs/swarm"
STATUS = f"{SWARM}/status.md"
SCRIPT = ".agents/skills/swarm-run/scripts/swarm_next.py"
RESULT_TEMPLATE = ".agents/skills/swarm-run/templates/result.md"
STATUS_TEMPLATE = os.path.join(HERE, "..", "templates", "status.md")
WORKER_MODEL = CHECKER_MODEL = "inherit"  # mirrors the agent files (their model: wins over this field, agy 1.2.2): the whole swarm runs on the dispatcher's --model
WORKED = ("완료", "부분 완료", "실패")  # terminal states of a task that ran
PASS, SKIP, UNRUNNABLE = "통과", "건너뜀", "실행 불가"
RETRY_SOME, RETRY_ALL, HALT = "실패 — 일부 재시도", "실패 — 전체 재시도", "실패 — 중단"
FINAL = "최종"
REPLY_MARK = "SWARM_CHECK_REPLY"


class GitError(Exception):
    pass


class StatusFormatError(Exception):
    pass


def git(root, *args, check=True):
    r = subprocess.run(["git", "-C", root, *args], capture_output=True, encoding="utf-8", errors="surrogateescape")
    if check and r.returncode != 0:
        raise GitError(f"git {' '.join(args)}: {(r.stderr or r.stdout).strip()}")
    return r


def number(text):
    return int(text) if (text or "").isdigit() else None


def cell(text, limit=160):
    text = " ".join(str(text).split()).replace("|", "/")
    return text if len(text) <= limit else text[: limit - 1] + "…"


# --- output -----------------------------------------------------------------------------------

def emit(action, lines):
    print(f"ACTION: {action}")
    print("\n".join(lines))
    return 0


def say(action, text, code):
    print(f"ACTION: {action}")
    print("Reply to the user with the text below the line, verbatim, and end the run.")
    print("---")
    print(text)
    return code


def stop(text):
    return say("stop", text, 1)


def misuse(text):
    print(text, file=sys.stderr)
    return 2


# --- status.md --------------------------------------------------------------------------------

def blank(wave):
    return {"wave": wave, "state": "대기", "tries": 0, "round": None, "commit": "-", "note": ""}


def status_file(pkg):
    return os.path.join(pkg["root"], STATUS)


def read_status(pkg):
    path = status_file(pkg)
    if not os.path.isfile(path):
        return None
    src = sc.read(path)
    if sc.bullet(src, "회차") is None:
        raise StatusFormatError(path)
    st = {"round": number(sc.bullet(src, "회차")) or 1, "started": sc.bullet(src, "시작") or "",
          "progress": sc.bullet(src, "진행") or "실행 중", "final": sc.bullet(src, "전체 검증 최종 결과") or "미실행",
          "tasks": {}, "checks": []}
    for c in sc.table_rows(sc.section(src, "작업") or ""):
        if c[0] != "id" and len(c) >= 7:
            st["tasks"][c[0]] = {"wave": number(c[1]), "state": c[2], "tries": number(c[3]) or 0,
                                 "round": number(c[4]), "commit": c[5], "note": c[6]}
    for c in sc.table_rows(sc.section(src, "웨이브 검증") or ""):
        if c[0] != "웨이브" and len(c) >= 4:
            st["checks"].append({"wave": c[0], "round": number(c[1]) or 0, "result": c[2], "message": c[3]})
    return st


def write_status(pkg, st):
    values = {"회차": st["round"], "시작": st["started"], "진행": st["progress"], "전체 검증 최종 결과": st["final"]}
    out, table = [], None
    for line in sc.read(STATUS_TEMPLATE).splitlines():
        m = re.match(r"^- (회차|시작|진행|전체 검증 최종 결과):", line)
        out.append(f"- {m.group(1)}: {values[m.group(1)]}" if m else line)
        if line.startswith("## "):
            table = line[3:].strip()
        elif re.fullmatch(r"\|(-+\|)+", line.strip()):
            if table == "작업":
                out += [f"| {tid} | {t['wave']} | {t['state']} | {t['tries']} | {t['round'] or '-'} | {t['commit']} | {cell(t['note'])} |"
                        for tid, t in st["tasks"].items()]
            elif table == "웨이브 검증":
                out += [f"| {c['wave']} | {c['round']} | {c['result']} | {cell(c['message'])} |" for c in st["checks"]]
    path = status_file(pkg)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path + ".tmp", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    os.replace(path + ".tmp", path)


def read_result(pkg, tid):
    """(상태, 시도, 막힌 것) of results/<id>.md; 상태 is None when the file is missing or 상태 is not one value."""
    path = os.path.join(pkg["root"], SWARM, "results", tid + ".md")
    if not os.path.isfile(path):
        return None, None, ""
    src = sc.read(path)
    raw = sc.bullet(src, "상태") or ""
    state = None if "|" in raw else next((s for s in WORKED if raw.startswith(s)), None)
    tries = re.match(r"\d+", sc.bullet(src, "시도") or "")
    blocked = sc.bullet(src, "막힌 것") or ""
    return state, int(tries.group()) if tries else None, "" if blocked.startswith("없음") else blocked


# --- git --------------------------------------------------------------------------------------

def dirty_paths(root):
    """Changed and untracked paths (ignored files excluded) relative to root; '../…' when outside it."""
    prefix = git(root, "rev-parse", "--show-prefix").stdout.strip()
    items = git(root, "status", "--porcelain=v1", "-z", "--untracked-files=all").stdout.split("\0")
    found, i = [], 0
    while i < len(items):
        entry, i = items[i], i + 1
        if len(entry) < 4:
            continue
        found.append(entry[3:])
        if (entry[0] in "RC" or entry[1] in "RC") and i < len(items):  # rename / copy in index or work tree: the source path follows
            found.append(items[i])
            i += 1
    return [p[len(prefix):] if p.startswith(prefix) else "../" + p for p in found]


def revert(root, owned):
    """Put 소유 파일 back to HEAD: restore tracked paths, delete untracked files under them (ignored files stay).

    Each path is matched literally first (app/[id]/page.tsx is a file, not a glob) and as a glob only
    when it contains glob characters.
    """
    for path, _, _ in owned:
        for spec in [":(literal)" + path] + ([path] if any(ch in path for ch in sc.GLOB_CHARS) else []):
            if git(root, "ls-files", "-z", "--", spec).stdout.strip("\0"):
                git(root, "checkout", "HEAD", "--", spec, check=False)
            for f in filter(None, git(root, "ls-files", "--others", "--exclude-standard", "-z", "--", spec).stdout.split("\0")):
                if os.path.lexists(os.path.join(root, f)):
                    os.remove(os.path.join(root, f))


def commit(root, message):
    """Stage everything under root and commit; the short hash, or 없음 when nothing changed."""
    git(root, "add", "-A", "--", ".")
    if git(root, "diff", "--cached", "--quiet", check=False).returncode == 0:
        return "없음"
    git(root, "commit", "-q", "-m", message)
    return git(root, "rev-parse", "--short", "HEAD").stdout.strip()


# --- state machine ----------------------------------------------------------------------------

def wave_ids(pkg, wave):
    return [tid for tid, row in pkg["tasks"].items() if row["wave"] == wave]


def is_full(pkg, label):
    return label == FINAL or (label.isdigit() and pkg["waves"].get(int(label)) is None)


def evaluate(pkg, st):
    """Apply holds and skips, then name the next step:
    ('dispatch', wave, ids) | ('running', wave, ids) | ('verify', wave) | ('halted', wave) | ('done',)."""
    tasks = st["tasks"]
    for wave in sorted({row["wave"] for row in pkg["tasks"].values()}):
        ids = wave_ids(pkg, wave)
        for tid in ids:
            unmet = [d for d in pkg["tasks"][tid]["deps"] if tasks[d]["state"] != "완료"]
            if tasks[tid]["state"] == "대기" and unmet:
                tasks[tid].update(state="보류", note="선행 " + ", ".join(f"{d} {tasks[d]['state']}" for d in unmet))
        ready = [tid for tid in ids if tasks[tid]["state"] == "대기"]
        if ready:
            return ("dispatch", wave, ready[: pkg["cap"]])
        running = [tid for tid in ids if tasks[tid]["state"] == "실행 중"]
        if running:
            return ("running", wave, running)
        rows = [c for c in st["checks"] if c["wave"] == str(wave)]
        last_run = max(tasks[tid]["round"] or 0 for tid in ids)
        since = [c for c in rows if c["round"] >= last_run]
        if since and since[-1]["result"] in (PASS, SKIP):
            continue
        if rows and rows[-1]["round"] == st["round"] and rows[-1]["result"] == HALT:
            return ("halted", wave)
        if all(tasks[tid]["state"] == "보류" for tid in ids):
            st["checks"].append({"wave": str(wave), "round": st["round"], "result": SKIP, "message": "모든 작업 보류"})
            continue
        return ("verify", wave)
    last = st["checks"][-1] if st["checks"] else None
    if last and last["result"] == PASS and is_full(pkg, last["wave"]):
        return ("done",)
    if last and last["wave"] == FINAL and last["round"] == st["round"] and last["result"] == HALT:
        return ("halted", FINAL)
    return ("verify", FINAL)


def worker_prompt(tid, attempt, wave, failure):
    brief, result = f"{SWARM}/tasks/{tid}.md", f"{SWARM}/results/{tid}.md"
    tail = f"Write {result} following {RESULT_TEMPLATE} with '- 시도: {attempt}', and reply with the 상태 line only."
    if failure is None:
        return (f"Task brief: {brief}. Attempt {attempt}. Read the brief fully, then do the work touching only "
                f"the 소유 파일 it lists. Run its 검증. {tail}")
    return (f"Task brief: {brief}. Attempt {attempt}. The 웨이브 {wave} verification failed after your work:\n{failure}\n"
            f"Read the brief and your previous {result}, then fix only what lies inside your 소유 파일. Never weaken, "
            f"skip, or delete a test or an assertion to make the check pass. If nothing in your 소유 파일 causes the "
            f"failure, change nothing. {tail}")


def emit_dispatch(pkg, st, wave, ids, failure=None, notes=()):
    entries = [{"TypeName": "swarm-worker", "Role": f"{tid} {pkg['tasks'][tid]['role']}", "Model": WORKER_MODEL,
                "Workspace": "inherit", "Prompt": worker_prompt(tid, st["tasks"][tid]["tries"], wave, failure)}
               for tid in ids]
    return emit("dispatch", list(notes) + [
        f"웨이브 {wave}: {', '.join(ids)}",
        "Call invoke_subagent exactly once. Its Subagents argument is this JSON array, copied verbatim:",
        json.dumps(entries, ensure_ascii=False, indent=2),
        f"Wait until all {len(ids)} subagents have replied, then run: python3 {SCRIPT} collect"])


def emit_verify(pkg, wave, notes=()):
    command = pkg["full_check"] if is_full(pkg, str(wave)) else pkg["waves"][wave]
    role = "최종 검증" if wave == FINAL else f"웨이브 {wave} 검증"
    entry = [{"TypeName": "swarm-checker", "Role": role, "Model": CHECKER_MODEL, "Workspace": "inherit",
              "Prompt": f"Run exactly this command once and report failures only: {command}"}]
    return emit("verify", list(notes) + [
        f"{role}: {command}",
        "Call invoke_subagent exactly once. Its Subagents argument is this JSON array, copied verbatim:",
        json.dumps(entry, ensure_ascii=False, indent=2),
        "When the checker has replied, run this command with its whole reply in place of the middle line:",
        f"python3 {SCRIPT} verified <<'{REPLY_MARK}'",
        "<checker reply>",
        REPLY_MARK])


def finish(pkg, st, outcome):
    st["progress"], st["final"] = "끝남", outcome
    write_status(pkg, st)
    root = pkg["root"]
    git(root, "add", "--", STATUS)  # status only: an uncommitted 웨이브's results stay with its code until its commit
    if git(root, "diff", "--cached", "--quiet", "--", STATUS, check=False).returncode != 0:
        git(root, "commit", "-q", "-m", "swarm: 상태 기록", "--", STATUS)
    lines = [f"스웜 실행 끝 — 전체 검증 최종 결과: {outcome} (회차 {st['round']})",
             "작업: " + " · ".join(f"{s} {sum(t['state'] == s for t in st['tasks'].values())}"
                                  for s in ("완료", "부분 완료", "실패", "보류", "대기"))]
    lines += [f"- {tid} {t['state']}" + (f": {t['note']}" if t["note"] else "")
              for tid, t in st["tasks"].items() if t["state"] in ("부분 완료", "실패", "보류")]
    last = st["checks"][-1] if st["checks"] else None
    if last and outcome != PASS:
        lines.append(f"마지막 검증: 웨이브 {last['wave']} {last['result']}" + (f" — {last['message']}" if last["message"] else ""))
    lines.append("다음 단계: 검증 명령이 실행되지 않았거나 checker 답을 읽지 못했습니다. 원인을 고친 뒤 /swarm-run을 다시 실행하면 재파견 없이 검증부터 합니다."
                 if outcome == UNRUNNABLE else "다음 단계: Claude Code에서 swarm-review를 실행하세요.")
    return say("finish", "\n".join(lines), 0)


def advance(pkg, st, notes=()):
    step = evaluate(pkg, st)
    if step[0] == "done":
        return finish(pkg, st, PASS)
    if step[0] == "halted":
        return finish(pkg, st, "실패")
    st["progress"], st["final"] = "실행 중", "미실행"
    if step[0] == "dispatch":
        for tid in step[2]:
            st["tasks"][tid].update(state="실행 중", tries=st["tasks"][tid]["tries"] + 1, round=st["round"], commit="-", note="")
    write_status(pkg, st)
    if step[0] == "dispatch":
        return emit_dispatch(pkg, st, step[1], step[2], notes=notes)
    if step[0] == "verify":
        return emit_verify(pkg, step[1], notes)
    return emit("wait", list(notes) + [f"Still 실행 중: {', '.join(step[2])}. Wait for their replies, then run: python3 {SCRIPT} collect"])


def recover(pkg, st):
    """Settle tasks left 실행 중 by an interrupted run: keep a matching result, otherwise reset the task's files and re-queue it."""
    notes = []
    for tid, t in st["tasks"].items():
        if t["state"] != "실행 중":
            continue
        state, tries, blocked = read_result(pkg, tid)
        if state and tries == t["tries"]:
            t.update(state=state, note=blocked)
            notes.append(f"Note: {tid} finished before the interruption (시도 {tries}); recorded as {state}.")
            continue
        revert(pkg["root"], pkg["briefs"][tid]["own"])
        result = os.path.join(pkg["root"], SWARM, "results", tid + ".md")
        if os.path.exists(result):
            os.remove(result)
        t.update(state="대기", note="중단 복구")
        notes.append(f"Note: {tid} was interrupted without a result; its 소유 파일 were reset to HEAD and it runs again.")
    return notes


def sync_round(pkg, st, latest):
    """Open 회차 latest: re-queue the ids in its 범위 (전체 = every task not 완료) and every 보류 task."""
    scope = pkg["rounds"][-1]["scope"]
    notes = [f"Note: 회차 {latest} — {tid} left the plan." for tid in st["tasks"] if tid not in pkg["tasks"]]
    tasks = {}
    for tid, row in pkg["tasks"].items():
        t = st["tasks"].get(tid) or blank(row["wave"])
        t["wave"] = row["wave"]
        rerun = (tid in scope) if scope is not None else (t["state"] != "완료")
        if rerun or t["state"] == "보류":
            t.update(state="대기", commit="-", note="")
        tasks[tid] = t
    st.update(tasks=tasks, round=latest, progress="실행 중", final="미실행")
    return notes


def parse_reply(reply):
    """(verdict, key message, failure text) of a swarm-checker reply; no 검증 결과 line reads as 실행 불가."""
    lines = [l.strip() for l in reply.splitlines() if l.strip() and l.strip() != REPLY_MARK]
    head = next((i for i, l in enumerate(lines) if l.startswith("검증 결과:")), None)
    if head is None:
        return UNRUNNABLE, "checker 답 판독 불가: " + (lines[0] if lines else "(빈 답)"), ""
    first, rest = lines[head], lines[head + 1:]
    if first.startswith("검증 결과: 통과"):
        return PASS, "", ""
    if first.startswith("검증 결과: 실행 불가"):
        return UNRUNNABLE, first.split("실행 불가", 1)[1].strip(" —-:"), ""
    return "실패", (rest[0].lstrip("- ") if rest else first), "\n".join([first] + rest[:30])


def route(pkg, text, ids):
    """The tasks among ids whose 소유 파일 are, contain, or lie under a path named in the failure text."""
    tokens = set()
    for raw in re.findall(r"[\w./-]+", text):
        if "/" not in raw and not re.search(r"\.\w{1,8}$", raw):
            continue
        path = os.path.normpath(os.path.relpath(raw, pkg["root"]) if os.path.isabs(raw) else raw)
        if not path.startswith(".."):
            tokens.add(path)
    return [tid for tid in ids
            if any(sc.overlaps((tok, True), own[:2]) for tok in tokens for own in pkg["briefs"][tid]["own"])]


def commit_wave(pkg, st, wave, suffix=""):
    ran = [tid for tid in wave_ids(pkg, wave) if st["tasks"][tid]["commit"] == "-" and st["tasks"][tid]["state"] in WORKED]
    if not ran:
        return
    write_status(pkg, st)
    short = commit(pkg["root"], f"swarm: 웨이브 {wave} — {', '.join(ran)}{suffix}")
    for tid in ran:
        st["tasks"][tid]["commit"] = short


# --- commands ---------------------------------------------------------------------------------

def cmd_next(plan):
    pkg, violations = sc.load(plan)
    if not os.path.isfile(pkg["plan"]):
        return stop("docs/swarm/plan.md가 없습니다. Claude Code에서 swarm-plan으로 계획을 먼저 만드세요.")
    if violations:
        return stop("계획 검사(swarm_check.py)를 통과하지 못했습니다. Claude Code에서 계획을 고쳐야 합니다.\n" + "\n".join(violations[:15]))
    root, notes, resuming = pkg["root"], [], False
    latest = pkg["rounds"][-1]["n"]
    st = read_status(pkg)
    if st is None:
        st = {"round": latest, "started": time.strftime("%Y-%m-%d %H:%M"), "progress": "실행 중", "final": "미실행",
              "tasks": {tid: blank(row["wave"]) for tid, row in pkg["tasks"].items()}, "checks": []}
    elif latest > st["round"]:
        running = [tid for tid, t in st["tasks"].items() if t["state"] == "실행 중"]
        if running:
            return stop(f"중단된 실행(실행 중: {', '.join(running)})을 복구하기 전에 회차 {latest}가 추가되었습니다. "
                        "새 회차 행과 바꾼 브리프를 잠시 되돌리고 /swarm-run으로 먼저 복구한 뒤 다시 적용하세요.")
        notes += sync_round(pkg, st, latest)
    elif latest < st["round"] or set(st["tasks"]) != set(pkg["tasks"]) or any(
            st["tasks"][tid]["wave"] != row["wave"] for tid, row in pkg["tasks"].items()):
        return stop("plan.md의 작업 표나 회차가 status.md와 맞지 않습니다. 계획을 바꿨다면 Claude Code의 swarm-plan 재계획 회차로 회차 행을 추가해야 합니다.")
    else:
        resuming = True
    # refuse foreign changes before recovery resets anything: the swarm's own uncommitted work is every
    # task that ran (or was interrupted) since its 웨이브's last commit
    pending = [(SWARM, True)] + [own[:2] for tid, t in st["tasks"].items()
                                 if t["commit"] == "-" and t["state"] in WORKED + ("실행 중",) for own in pkg["briefs"][tid]["own"]]
    stray = [p for p in dirty_paths(root) if not any(sc.overlaps((p, False), a) for a in pending)]
    if stray:
        return stop("스웜이 소유하지 않은 변경이 트리에 있습니다. 커밋하거나 stash한 뒤 /swarm-run을 다시 실행하세요.\n"
                    + "\n".join(f"- {p}" for p in stray[:15]))
    if resuming:
        notes += recover(pkg, st)
    os.makedirs(os.path.join(root, SWARM, "results"), exist_ok=True)
    write_status(pkg, st)
    return advance(pkg, st, notes)


def cmd_collect(plan, final):
    pkg, _ = sc.load(plan)
    st = read_status(pkg)
    if st is None:
        return misuse(f"{STATUS} is missing — run: python3 {SCRIPT} next")
    missing = []
    for tid, t in st["tasks"].items():
        if t["state"] != "실행 중":
            continue
        state, tries, blocked = read_result(pkg, tid)
        if state and tries == t["tries"]:
            t.update(state=state, note=blocked)
        elif final:
            t.update(state="실패", note="결과 없음")
        else:
            missing.append(tid)
    write_status(pkg, st)
    if missing:
        return emit("wait", [
            f"No result file with the current 시도 yet for: {', '.join(missing)}.",
            f"If one of these subagents has not replied yet, wait for its reply, then run: python3 {SCRIPT} collect",
            f"If all of them have already replied, run: python3 {SCRIPT} collect --final"])
    return advance(pkg, st)


def cmd_verified(plan):
    reply = sys.stdin.read()
    pkg, _ = sc.load(plan)
    st = read_status(pkg)
    if st is None:
        return misuse(f"{STATUS} is missing — run: python3 {SCRIPT} next")
    step = evaluate(pkg, st)
    if step[0] != "verify":
        write_status(pkg, st)
        return misuse(f"No check is pending (next step: {step[0]}) — run: python3 {SCRIPT} next")
    wave = step[1]
    verdict, message, failure = parse_reply(reply)
    row = {"wave": str(wave), "round": st["round"], "result": verdict, "message": message}
    if verdict == PASS:
        st["checks"].append(row)
        if wave != FINAL:
            commit_wave(pkg, st, wave)
        return advance(pkg, st)
    if verdict == UNRUNNABLE:
        st["checks"].append(row)
        return finish(pkg, st, UNRUNNABLE)
    ids = [] if wave == FINAL else wave_ids(pkg, wave)
    earlier = [c["result"] for c in st["checks"]
               if c["wave"] == str(wave) and c["round"] == st["round"] and c["result"].startswith("실패")]
    eligible = [tid for tid in ids if st["tasks"][tid]["round"] == st["round"] and st["tasks"][tid]["state"] in ("완료", "부분 완료")]
    targets = []
    if eligible and not earlier:
        matched = route(pkg, failure, eligible)
        targets, row["result"] = (matched, RETRY_SOME) if 0 < len(matched) < len(eligible) else (eligible, RETRY_ALL)
    elif eligible and earlier == [RETRY_SOME]:
        targets, row["result"] = eligible, RETRY_ALL
    else:
        row["result"] = HALT
    st["checks"].append(row)
    if not targets:
        if wave != FINAL:
            commit_wave(pkg, st, wave, " (검증 실패)")
        return finish(pkg, st, "실패")
    for tid in targets:
        st["tasks"][tid].update(state="실행 중", tries=st["tasks"][tid]["tries"] + 1, note="")
    write_status(pkg, st)
    return emit_dispatch(pkg, st, wave, targets, failure)


def main(argv):
    args, plan = list(argv), os.path.join(SWARM, "plan.md")
    if args[:1] == ["--plan"] and len(args) >= 2:
        plan, args = args[1], args[2:]
    commands = {("next",): lambda: cmd_next(plan), ("collect",): lambda: cmd_collect(plan, False),
                ("collect", "--final"): lambda: cmd_collect(plan, True), ("verified",): lambda: cmd_verified(plan)}
    if tuple(args) not in commands:
        return misuse("usage: swarm_next.py [--plan docs/swarm/plan.md] next | collect [--final] | verified < checker-reply")
    try:
        return commands[tuple(args)]()
    except GitError as e:
        return stop(f"git 명령이 실패했습니다. 저장소 상태를 확인한 뒤 /swarm-run을 다시 실행하세요.\n{e}")
    except StatusFormatError:
        return stop("docs/swarm/status.md가 이전 버전의 형식입니다. 스웜 도중 이 저장소(submodule)를 올렸다면 "
                    "이전 커밋으로 되돌려 이 스웜을 끝낸 뒤 다시 올리세요.")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
