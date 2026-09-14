#!/usr/bin/env python3
"""Scenario test for swarm_next.py: plays the Antigravity dispatcher, workers, and checker against a scratch git repo.

Usage: python3 test/swarm_scenario.py [repo root]    (test/check.sh check 13)

회차 1: a tests-first 웨이브 behind a light check; an interrupted 웨이브 (finished task kept, unfinished one
reset); a retry of the failing path's owner, then of the whole 웨이브; an unrunnable check that stops
without committing and resumes straight into the check; a stray change that blocks a resume.
회차 2: a re-planned 웨이브 1 task, closed by a 최종 전체 검증. 회차 3: a 웨이브 that keeps failing is
committed as (검증 실패) and halts. 회차 4: a stale result file and collect --final.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), ".."))
NEXT = os.path.join(ROOT, "antigravity", "skills", "swarm-run", "scripts", "swarm_next.py")
CHECK = os.path.join(ROOT, "skills", "swarm-plan", "scripts", "swarm_check.py")
TMP = tempfile.mkdtemp()
PROJ = os.path.join(TMP, "proj")
PLAN = os.path.join(PROJ, "docs", "swarm", "plan.md")
FULL = "sh verify.sh"
LIGHT = "test -f tests/expect.txt"

PLAN_TEXT = """# x 스웜 계획

- 작성일: 2026-09-14
- 기준 커밋: {base}
- 대상 spec: docs/core/specs/x.md
- 작업 노트: docs/notes/x.md
- 동시 실행 상한: 8
- 전체 검증: `sh verify.sh`

## 목표

x

## 작업

| id | 제목 | 역할 | 웨이브 | 선행 |
|---|---|---|---|---|
| T01 | expected output | test | 1 | 없음 |
| T02 | implementation | implementation | 2 | T01 |
| T03 | readme | docs | 2 | 없음 |
| T04 | extra | cleanup | 3 | T02 |

## 웨이브별 검증

| 웨이브 | 검증 | 이유 |
|---|---|---|
| 1 | `test -f tests/expect.txt` | the implementation lands in 웨이브 2 |
| 2 | 전체 검증 | |
| 3 | 전체 검증 | |

## 회차

| 회차 | 날짜 | 범위 | 비고 |
|---|---|---|---|
{rounds}"""


def fail(message):
    print(f"swarm_scenario: {message}", file=sys.stderr)
    shutil.rmtree(TMP, ignore_errors=True)
    sys.exit(1)


def expect(condition, message):
    if not condition:
        fail(message)


def sh(*args, stdin=None):
    return subprocess.run(args, cwd=PROJ, input=stdin, capture_output=True, text=True)


def git(*args):
    r = sh("git", *args)
    expect(r.returncode == 0, f"git {' '.join(args)} failed: {r.stderr}")
    return r.stdout


def write(path, text):
    full = os.path.join(PROJ, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(text)


def read(path):
    with open(os.path.join(PROJ, path), encoding="utf-8") as f:
        return f.read()


def swarm(*args, stdin=None, code=0):
    r = sh(sys.executable, NEXT, "--plan", PLAN, *args, stdin=stdin)
    expect(r.returncode == code, f"swarm_next.py {' '.join(args)} exited {r.returncode}, expected {code}:\n{r.stdout}{r.stderr}")
    return r.stdout


def action(out):
    return out.splitlines()[0].replace("ACTION: ", "", 1)


def entries(out):
    lines = out.splitlines()
    start = lines.index("[")
    return json.loads("\n".join(lines[start:lines.index("]", start) + 1]))


def dispatch(out, ids):
    expect(action(out) == "dispatch", f"expected a dispatch of {ids}, got:\n{out}")
    got = entries(out)
    expect([e["Role"].split()[0] for e in got] == ids, f"expected a dispatch of {ids}, got {[e['Role'] for e in got]}")
    expect(all(e["TypeName"] == "swarm-worker" and e["Model"] == "inherit" and e["Workspace"] == "inherit" for e in got),
           f"malformed worker entries: {got}")
    return {e["Role"].split()[0]: e["Prompt"] for e in got}


def verify(out, command):
    expect(action(out) == "verify", f"expected a check `{command}`, got:\n{out}")
    (entry,) = entries(out)
    expect(entry["TypeName"] == "swarm-checker" and entry["Prompt"].endswith(": " + command), f"malformed checker entry: {entry}")


def checker(command, detail):
    return "검증 결과: 통과\n" if sh("sh", "-c", command).returncode == 0 else f"검증 결과: 실패 1건\n- {detail}\n"


def work(tid, attempt, files=None, state="완료"):
    for path, text in (files or {}).items():
        write(path, text)
    write(f"docs/swarm/results/{tid}.md", f"# {tid} 결과\n\n- 상태: {state}\n- 시도: {attempt}\n- 바꾼 파일: 없음\n"
          "- 검증: 통과\n- 브리프와 다르게 한 것: 없음\n- 결정: 없음\n- 막힌 것: 없음\n")


def row(tid):
    for line in read("docs/swarm/status.md").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells[0] == tid:
            return cells
    fail(f"status.md has no row for {tid}")


def header(label):
    for line in read("docs/swarm/status.md").splitlines():
        if line.startswith(f"- {label}:"):
            return line.split(":", 1)[1].strip()
    fail(f"status.md has no '{label}' line")


def brief(tid, wave, deps, own, refs="없음"):
    write(f"docs/swarm/tasks/{tid}.md", f"# {tid} x\n\n- 역할: implementation\n- 웨이브: {wave}\n- 선행: {deps}\n"
          f"- 대상 spec: docs/core/specs/x.md\n- 소유 파일: {own}\n- 참고 파일: {refs}\n\n## 목표\n\nx\n\n"
          "## 해야 할 일\n\n1. x\n\n## 완료 조건\n\n- [ ] x\n\n## 검증\n\n`true`\n")


def replan(base, rounds, message):
    write("docs/swarm/plan.md", PLAN_TEXT.format(base=base, rounds=rounds))
    git("add", "-A")
    git("commit", "-qm", message)


def main():
    os.makedirs(PROJ)
    git("init", "-q")
    git("config", "user.name", "scenario")
    git("config", "user.email", "scenario@localhost")
    write("README.txt", "readme\n")
    write("verify.sh", "cmp -s tests/expect.txt src/impl.txt || exit 1\n! grep -qs boom src/extra.txt\n")
    git("add", "-A")
    git("commit", "-qm", "base")
    base = git("rev-parse", "--short", "HEAD").strip()
    rounds = "| 1 | 2026-09-14 | 전체 | |\n"
    brief("T01", 1, "없음", "`tests/expect.txt` (신규)")
    brief("T02", 2, "T01", "`src/impl.txt` (신규)", "`tests/expect.txt`")
    brief("T03", 2, "없음", "`README.txt`")
    brief("T04", 3, "T02", "`src/extra.txt` (신규)")
    replan(base, rounds, "swarm: 계획")

    # 회차 1 — 웨이브 1 lands the expected output ahead of the implementation; only its light check runs
    prompts = dispatch(swarm("next"), ["T01"])
    expect("Attempt 1" in prompts["T01"] and row("T01")[2] == "실행 중", "T01 was not started as attempt 1")
    work("T01", 1, {"tests/expect.txt": "ok\n"})
    verify(swarm("collect"), LIGHT)
    dispatch(swarm("verified", stdin=checker(LIGHT, "")), ["T02", "T03"])
    expect("swarm: 웨이브 1 — T01" in git("log", "--format=%s"), "웨이브 1 was not committed")
    expect(sh(sys.executable, CHECK, PLAN).returncode == 0, "swarm_check.py rejects the plan after its own 웨이브 1 commit")

    # the run dies mid-웨이브 2: T03 finished, T02 left a partial file and no result
    work("T03", 1, {"README.txt": "readme v2\n"})
    write("src/impl.txt", "partial\n")
    prompts = dispatch(swarm("next"), ["T02"])
    expect("Attempt 2" in prompts["T02"], "the re-queued T02 did not get attempt 2")
    expect(not os.path.exists(os.path.join(PROJ, "src/impl.txt")), "the interrupted task's partial file survived recovery")
    expect(read("README.txt") == "readme v2\n" and row("T03")[2] == "완료", "the finished T03 was not kept")
    expect(action(swarm("collect")) == "wait", "collect did not wait for a result that is not written yet")

    # the check fails on T02's file: only T02 retries; failing again sends the whole 웨이브 once more
    failure = "`src/impl.txt:1` — differs from tests/expect.txt"
    work("T02", 2, {"src/impl.txt": "bad\n"})
    verify(swarm("collect"), FULL)
    prompts = dispatch(swarm("verified", stdin=checker(FULL, failure)), ["T02"])
    expect("Attempt 3" in prompts["T02"] and "src/impl.txt:1" in prompts["T02"], "the targeted retry prompt lacks the attempt or the failure")
    work("T02", 3, {"src/impl.txt": "still bad\n"})
    verify(swarm("collect"), FULL)
    prompts = dispatch(swarm("verified", stdin=checker(FULL, failure)), ["T02", "T03"])
    expect("Attempt 4" in prompts["T02"] and "Attempt 2" in prompts["T03"], "the whole-웨이브 retry carries wrong attempts")
    work("T02", 4, {"src/impl.txt": "ok\n"})
    work("T03", 2)
    verify(swarm("collect"), FULL)
    dispatch(swarm("verified", stdin=checker(FULL, "")), ["T04"])
    expect("swarm: 웨이브 2 — T02, T03" in git("log", "--format=%s"), "웨이브 2 was not committed")

    # the checker cannot run: stop without committing, then resume straight into the check
    work("T04", 1, {"src/extra.txt": "fine\n"})
    verify(swarm("collect"), FULL)
    out = swarm("verified", stdin="검증 결과: 실행 불가 — sh not found\n")
    expect(action(out) == "finish" and header("전체 검증 최종 결과") == "실행 불가", f"실행 불가 did not end the run:\n{out}")
    expect("src/extra.txt" not in git("ls-files"), "an unverified 웨이브 was committed")
    verify(swarm("next"), FULL)
    out = swarm("verified", stdin=checker(FULL, ""))
    expect(action(out) == "finish" and header("전체 검증 최종 결과") == "통과" and header("진행") == "끝남", f"the run did not finish green:\n{out}")
    expect(sh("git", "status", "--porcelain").stdout == "", "the tree is not clean after a finished run")

    # a change nobody owns blocks a resume
    write("scratch.txt", "x\n")
    out = swarm("next", code=1)
    expect(action(out) == "stop" and "scratch.txt" in out, f"a stray change did not stop the run:\n{out}")
    os.remove(os.path.join(PROJ, "scratch.txt"))

    # 회차 2 re-plans T01 only; its light check is not the last word, so a 최종 전체 검증 closes the round
    rounds += "| 2 | 2026-09-14 | T01 | re-plan |\n"
    replan(base, rounds, "swarm: 재계획 회차 2")
    dispatch(swarm("next"), ["T01"])
    expect(row("T02")[2] == "완료", "a 완료 task outside the 회차 범위 was re-queued")
    work("T01", 2, {"tests/expect.txt": "ok\n"})
    verify(swarm("collect"), LIGHT)
    verify(swarm("verified", stdin=checker(LIGHT, "")), FULL)
    out = swarm("verified", stdin=checker(FULL, ""))
    expect(action(out) == "finish" and header("전체 검증 최종 결과") == "통과", f"회차 2 did not finish green:\n{out}")
    expect("| 최종 | 2 | 통과 |" in read("docs/swarm/status.md"), "the closing check was not recorded as 최종")

    # 회차 3 re-plans T04, which keeps breaking the full check: one retry, then a (검증 실패) commit and a halt
    rounds += "| 3 | 2026-09-14 | T04 | re-plan |\n"
    replan(base, rounds, "swarm: 재계획 회차 3")
    dispatch(swarm("next"), ["T04"])
    work("T04", 2, {"src/extra.txt": "boom\n"})
    verify(swarm("collect"), FULL)
    dispatch(swarm("verified", stdin=checker(FULL, "`src/extra.txt` — contains boom")), ["T04"])
    work("T04", 3, {"src/extra.txt": "boom again\n"})
    verify(swarm("collect"), FULL)
    out = swarm("verified", stdin=checker(FULL, "`src/extra.txt` — contains boom"))
    expect(action(out) == "finish" and header("전체 검증 최종 결과") == "실패", f"a 웨이브 failing twice did not halt:\n{out}")
    expect("swarm: 웨이브 3 — T04 (검증 실패)" in git("log", "--format=%s"), "the failed 웨이브 was not committed")
    out = swarm("next")
    expect(action(out) == "finish" and "실패" in out, f"a halted round restarted work:\n{out}")
    expect(sh(sys.executable, CHECK, PLAN).returncode == 0, "swarm_check.py rejects the plan after a halted 웨이브")

    # 회차 4: the worker ends without writing a new result — the stale attempt-3 file must not count
    rounds += "| 4 | 2026-09-14 | T04 | re-plan |\n"
    replan(base, rounds, "swarm: 재계획 회차 4")
    dispatch(swarm("next"), ["T04"])
    expect(action(swarm("collect")) == "wait", "a stale result file was accepted")
    out = swarm("collect", "--final")
    expect(row("T04")[2] == "실패" and row("T04")[6] == "결과 없음", "collect --final did not fail the missing result")
    verify(out, FULL)
    out = swarm("verified", stdin=checker(FULL, "`src/extra.txt` — contains boom"))
    expect(action(out) == "finish" and header("전체 검증 최종 결과") == "실패", f"a failed 웨이브 with nothing to retry did not halt:\n{out}")

    # helpers checked directly: a failing directory routes to the task owning a file inside it, and a
    # work-tree rename (git add -N) is read as two intact paths
    sys.dont_write_bytecode = True
    sys.path.insert(0, os.path.dirname(NEXT))
    import swarm_next
    pkg, _ = swarm_next.sc.load(PLAN)
    expect(swarm_next.route(pkg, "- `src/` — 2 failures", ["T02", "T03"]) == ["T02"], "a failing directory did not route to its owner")
    write("renamed_src.txt", "a line long enough for rename detection\nsecond line\nthird line\n")
    git("add", "-A")
    git("commit", "-qm", "rename fixture")
    os.rename(os.path.join(PROJ, "renamed_src.txt"), os.path.join(PROJ, "renamed_dst.txt"))
    git("add", "-N", "renamed_dst.txt")
    paths = swarm_next.dirty_paths(PROJ)
    expect(sorted(paths) == ["renamed_dst.txt", "renamed_src.txt"], f"dirty_paths mangled a work-tree rename: {paths}")

    shutil.rmtree(TMP, ignore_errors=True)
    print("OK: swarm_next.py scenario passed")


if __name__ == "__main__":
    main()
