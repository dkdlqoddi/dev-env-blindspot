# T01 [제목]

- 역할: (2–5 단어. 예: 구현, 테스트 작성, 문서 갱신, 마이그레이션, 정리)
- 웨이브: 1
- 선행: 없음
- 대상 spec: docs/<영역>/specs/<단위>.md
- 소유 파일: `path/to/existing.py`, `path/to/new_file.py` (신규), `path/to/dir/`
- 참고 파일: `path/to/pattern.py:12-40` (따라 할 기존 코드), `docs/<영역>/rules.md`

<!-- One brief = one worker with no context beyond this file and the files it names. Every path literal; every interface the worker must match (function names, signatures, file names, schema) spelled out verbatim in 해야 할 일 — parallel workers cannot talk to each other. 소유 파일 = the only paths this worker may create or modify; a directory (trailing /) means everything under it; (신규) marks a file that does not exist yet. 참고 파일 are read-only. No "필요하면", no "적절히" — decide it here. -->

## 목표

(2–4문장. 무엇을, 왜. 스펙의 어느 요구사항을 만족시키는지)

## 해야 할 일

1. (순서대로. 따라 할 기존 코드가 있으면 `path:line`으로 지목)
2.

## 완료 조건

- [ ] (확인 가능한 문장으로. "동작한다"가 아니라 "X를 호출하면 Y를 돌려준다")
- [ ]

## 검증

`(이 작업만 검사하는 명령 — 테스트 파일 하나, 린트, 스크립트)` 또는 `없음` (없으면 전체 검증이 이 작업의 파일을 덮는다고 목표에 밝힌다)
