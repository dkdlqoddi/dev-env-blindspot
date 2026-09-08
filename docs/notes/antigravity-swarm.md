# Antigravity 스웜 분업 작업 노트

- 시작일: 2026-09-08
- 대상 spec: docs/core/specs/lifecycle-skills.md, docs/core/specs/swarm-handoff.md
- 처리: 보고 모드에서 work-report가 항목을 spec으로 옮기고, 퀴즈 통과 확인 시 이 파일을 지운다

## 2026-09-08 10:00 — 새 브랜치에서 두 하네스 분업, 기존 스킬은 유지

- 결정: main의 라이프사이클 스킬 5개와 에이전트 5개는 그대로 두고, 구현 단계만 Antigravity 스웜으로 넘기는 스킬 2개(swarm-plan, swarm-review)와 에이전트 1개(swarm-auditor)를 Claude Code 쪽에 더한다. Antigravity 쪽은 `antigravity/` 폴더에 스킬 1개(swarm-run), 서브에이전트 2개(swarm-worker, swarm-checker), 규칙 1개를 둔다.
- 이유: 생각(인터뷰·사각지대·설계·감사)은 강한 모델이 한 번, 실행은 빠른 모델이 병렬로 여러 번 하는 것이 사용자의 요청. 기존 스킬을 바꾸면 소비자 계약이 깨진다.
- 검토한 대안: 기존 `origin/antigravity` 브랜치처럼 전체를 Antigravity로 이식 — 강한 모델의 계획 단계가 사라져 요청과 어긋남. 한 스킬에 plan/review 두 모드 — 하네스 경계에서 사용자가 이름으로 부르기 쉬운 두 스킬을 택함.
- 보수적 선택 여부: 아니오
- 계획과의 이탈: 없음
- 사용자 확인 필요: 아니오
- 반영 대상: docs/core/specs/swarm-handoff.md · 결정 기록

## 2026-09-08 10:20 — 계획 패키지는 docs/swarm/ 에 두고 인수 시 지운다

- 결정: 계획(plan.md), 브리프(tasks/<id>.md), 실행 상태(status.md), 작업별 결과(results/<id>.md)를 `docs/swarm/` 아래 작업 파일로 두고, work-report 게이트 통과 시 notes와 함께 지운다. MANDATE 작업 파일 목록에 추가.
- 이유: 두 하네스가 같은 작업 폴더를 읽으므로 파일이 유일한 인터페이스. notes와 같은 수명 주기를 주면 규칙이 하나로 유지된다.
- 검토한 대안: 저장소 루트 `.swarm/` — docs 아래 작업 파일 규칙과 어긋남. 영구 보관 — 사이클마다 파일이 쌓이는 옛 문제로 회귀.
- 보수적 선택 여부: 아니오
- 계획과의 이탈: 없음
- 사용자 확인 필요: 예 (인수 시 삭제가 맞는지, 아니면 git 이력만으로 충분한지)
- 반영 대상: docs/core/specs/swarm-handoff.md · 결정 기록

## 2026-09-08 10:40 — 워커는 같은 작업 트리를 공유하고 소유 파일로 충돌을 막는다

- 결정: 서브에이전트 Workspace는 `inherit`(공유 트리). 한 웨이브 안의 작업은 소유 파일이 겹치지 않아야 하며 `swarm_check.py`가 기계적으로 검사한다. 웨이브마다 dispatcher가 커밋한다.
- 이유: `branch`(작업별 격리 워크트리)는 빠른 모델에게 병합을 맡기게 되어 위험. 실측: agy 1.1.27에서 `invoke_subagent` 한 호출로 여러 항목을 동시 실행할 수 있고(Model flash, Workspace inherit) 두 워커가 같은 트리에 파일을 썼다.
- 검토한 대안: 작업별 워크트리 + 오케스트레이터 병합 / 커밋 없이 진행 — 실패한 웨이브를 되돌릴 수 없어 기각.
- 보수적 선택 여부: 예 (웨이브 검증이 재시도 후에도 실패하면 다음 웨이브로 가지 않고 멈춘다)
- 계획과의 이탈: 없음
- 사용자 확인 필요: 예 (웨이브마다 자동 커밋해도 되는지)
- 반영 대상: docs/core/specs/swarm-handoff.md · 결정 기록, 엣지케이스와 제약

## 2026-09-08 11:00 — Antigravity print 모드는 --add-dir 없이는 워크스페이스를 읽지 않는다

- 결정: 스킬과 README의 CLI 명령을 `agy --add-dir "$PWD" -p '/swarm-run' …` 으로 고정한다. 서브에이전트 파일(.agents/agents/*.md)이 안 잡히면 `define_subagent`로 정의하는 대체 경로를 swarm-run에 한 줄 둔다.
- 이유: 실측 — `--add-dir` 없이 `agy -p`를 실행하면 `.agents/skills`, `.agents/agents`가 보이지 않았고(`subagent "…" not found`), `--add-dir` 지정 후에는 심링크된 스킬과 에이전트가 모두 동작했다.
- 검토한 대안: define_subagent만 사용 — 파일로 버전 관리되는 정의를 잃음.
- 보수적 선택 여부: 아니오
- 계획과의 이탈: 없음
- 사용자 확인 필요: 아니오
- 반영 대상: docs/core/specs/swarm-handoff.md · 엣지케이스와 제약, docs/core/rules.md · 표준 명령
