# T01 [제목]

- 역할: (2–5 words, e.g. implementation, test writing, docs update, migration, cleanup)
- 웨이브: 1
- 선행: 없음
- 대상 spec: docs/<영역>/specs/<단위>.md
- 소유 파일: `path/to/existing.py`, `path/to/new_file.py` (신규), `path/to/dir/`
- 참고 파일: `path/to/pattern.py:12-40` (existing code to imitate), `docs/<영역>/rules.md`

<!-- One brief = one worker with no context beyond this file and the files it names. Free text in English; labels and headings stay exactly as written. Every path literal; every interface the worker must match (function names, signatures, file names, schema) spelled out verbatim in 해야 할 일 — parallel workers cannot talk to each other. 소유 파일 = the only paths this worker may create, modify, or delete; a directory ends with /; (신규) marks a path absent at the plan's 기준 커밋, and a later 웨이브 that edits it lists it without (신규). 참고 파일 are read-only and never another same-웨이브 task's 소유 파일. No "필요하면", "적절히", "if needed", "as appropriate" — decide it here. -->

## 목표

(2–4 sentences: what and why, and which spec requirement it satisfies)

## 해야 할 일

1. (in order; point at existing code to imitate as `path:line`)
2.

## 완료 조건

- [ ] (a checkable sentence: not "it works" but "calling X returns Y"; a test written ahead of its implementation says here that it fails until 웨이브 n)
- [ ]

## 검증

`(a command that checks only this task and passes once the task is done in its own 웨이브 — one test file, a lint, a script)` or `없음` (then 목표 names the 웨이브별 검증 that covers this task's files)
