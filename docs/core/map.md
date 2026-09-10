# core 시스템 맵 (Tier 2)

- 최종 갱신: 2026-09-10
- 코드 루트: .
- 읽는 법: 이 영역을 건드리는 작업이 rules.md 다음에 읽는다. 상세는 '단위' 표의 상세 명세로 내려간다. 150줄을 넘기지 않는다.

## 영역 개요

이 저장소는 다른 프로젝트가 가져다 쓰는 Google Antigravity 스킬, 서브에이전트, 규칙 묶음이다. 스킬은 작업 순서를 알려주는 지침서이고, 서브에이전트는 탐색·검증·스웜 실행을 대신 하는 일꾼이다. 설치 스크립트가 소비 프로젝트의 .agents/에 이것들을 연결하고, 규칙(MANDATE)을 주입한다. 검사 스크립트 하나가 저장소 전체의 계약을 지킨다. 이 브랜치(antigravity-pure)는 계획부터 실행까지 모든 과정을 순수 Antigravity 환경에서 진행한다.

## 단위

| 단위 | 하는 일 | 위치 | 상세 명세 |
|---|---|---|---|
| lifecycle-skills | 요구사항 인터뷰부터 보고까지 다섯 스킬의 지침 | skills/{requirements-interview,blindspot-pass,explainer,work-report,blindspot-flow}/SKILL.md | specs/lifecycle-skills.md |
| templates | 스킬이 만드는 문서의 틀(계층 3종, 노트, 퀴즈, 스웜 계획/결과) | skills/*/templates/* | 없음 |
| agents | 코드 탐색, 웹 조사, 문서 검증, 변경 내용 분석, 검사 실행, 스웜 감사·작업·검증을 맡는 서브에이전트 8종 | agents/*.md | 없음 |
| docs-check | 퀴즈와 계층 문서의 기계 검사 | skills/work-report/scripts/docs_check.py | 없음 |
| installer | 소비 프로젝트 .agents/에 바로가기 링크(심링크)와 규칙 불러오기 줄(import)을 설치 | install.sh, install-antigravity.sh | 없음 |
| mandate | 매 세션 주입되는 규칙과 hook | MANDATE.md, rules/mandate.md, hooks/mandate.sh | 없음 |
| repo-check | 저장소 자체 검사 | test/check.sh | 없음 |
| swarm-handoff | 스웜 계획, 병렬 실행, 결과 검토를 순수 Antigravity 안에서 맡는 스킬·서브에이전트 | skills/swarm-plan/, skills/swarm-run/, skills/swarm-review/, agents/swarm-*.md | specs/swarm-handoff.md |

## 주요 흐름

| 흐름 | 시작점 | 거치는 단위 순서 |
|---|---|---|
| 소비 프로젝트 설치 | bash .agents/shared/install.sh | installer → mandate |
| 기능 라이프사이클 | 사용자 요청 (mandate 트리거) | lifecycle-skills → agents → templates → docs-check |
| 저장소 변경 검증 | bash test/check.sh | repo-check → docs-check |
| 스웜 사이클 | swarm-plan | swarm-handoff(swarm-plan, swarm_check.py) → swarm-handoff(swarm-run, swarm-worker/checker) → swarm-handoff(swarm-review, swarm-auditor) → lifecycle-skills(work-report) |

## 통합 지점

| 상대 | 방식 | 계약 위치 | 관련 단위 |
|---|---|---|---|
| 소비 프로젝트 | git submodule + 상대 심링크 + AGENTS.md/ANTIGRAVITY.md @import | install.sh, README §1 | installer, mandate |
| Antigravity | .agents/{skills,agents,rules} 자동 발견 + invoke_subagent TypeName | skills/*/SKILL.md, agents/*.md, rules/*.md | lifecycle-skills, agents, swarm-handoff |
| 소비 프로젝트 docs/swarm/ | 계획·브리프와 상태·결과 파일 계약 | skills/swarm-plan/templates/*, skills/swarm-run/templates/*, swarm_check.py | swarm-handoff |

## 알려진 위험

| 위험 | 영향 단위 | 상태 |
|---|---|---|
| 스킬·에이전트 이름 변경이 소비 프로젝트 심링크를 끊음 | installer, lifecycle-skills, agents | test/check.sh 검사 3(에이전트 참조)과 검사 5(설치 심링크)가 감시 |
| MANDATE가 session과 @import로 주입되어 크기가 곧 비용 | mandate, installer | 60줄 상한(검사 11). 간결한 유지 |
| Antigravity 도구 이름·발견 규칙이 바뀌면 워커 정의가 조용히 깨짐 | swarm-handoff, repo-check | 검사 2가 tools 허용목록을 실측 이름에 고정. 발견 규칙은 스모크 테스트(ANTIGRAVITY.md Test)로 확인 |
