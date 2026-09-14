# [주제] 스웜 계획

- 작성일: YYYY-MM-DD
- 기준 커밋: (git rev-parse --short HEAD at planning time; a re-plan round never changes it)
- 대상 spec: docs/<영역>/specs/<단위>.md
- 작업 노트: docs/notes/<slug>.md
- 동시 실행 상한: 8
- 전체 검증: `(the test command from rules.md 표준 명령)`
- 실행 방법: Antigravity `/swarm-run`; progress in docs/swarm/status.md, per-task results in docs/swarm/results/<id>.md

<!-- Written by the swarm-plan skill (Claude Code, strong model) and executed by the swarm-run skill (Antigravity, fast model) through its swarm_next.py script, which reads only the tables below and never opens a brief. Free text in English; headings, header labels, table headers, and the words 전체 검증, 전체, 없음 stay exactly as written — scripts match them. id = T01, T02, ... = the brief file tasks/<id>.md. 웨이브 = execution round; tasks in one 웨이브 run concurrently, so their 소유 파일 (in the briefs) must not overlap — scripts/swarm_check.py enforces this. 선행 = comma-separated ids from earlier 웨이브, or 없음. -->

## 목표

(2–4 sentences in English: what must be true when this swarm ends, and what is not this swarm's job)

## 작업

| id | 제목 | 역할 | 웨이브 | 선행 |
|---|---|---|---|---|

## 웨이브별 검증

<!-- One row per 웨이브. 검증 = 전체 검증 when the whole project check must pass right after that 웨이브; otherwise one backticked command that must pass at that point — e.g. test collection or a lint for a 웨이브 that lands tests or contracts ahead of their implementation. The last 웨이브 is always 전체 검증. 이유 = why a lighter check, or empty. -->

| 웨이브 | 검증 | 이유 |
|---|---|---|

## 회차

<!-- One row per handoff. 범위 = 전체 in the first round; in a re-plan round exactly the ids re-planned — swarm_next.py re-runs those ids and every 보류 task, nothing else. -->

| 회차 | 날짜 | 범위 | 비고 |
|---|---|---|---|
