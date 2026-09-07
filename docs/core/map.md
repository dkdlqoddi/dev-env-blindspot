# core 시스템 맵 (Tier 2)

- 최종 갱신: 2026-09-07
- 코드 루트: .
- 읽는 법: 이 영역을 건드리는 작업이 rules.md 다음에 읽는다. 상세는 '단위' 표의 상세 명세로 내려간다. 150줄을 넘기지 않는다.

## 영역 개요

이 저장소는 다른 프로젝트가 가져다 쓰는 Claude Code 스킬과 에이전트 묶음이다. 스킬은 작업 순서를 알려주는 지침서이고, 에이전트는 탐색과 검증을 대신 하는 읽기 전용 일꾼이다. 설치 스크립트가 소비 프로젝트에 이것들을 연결하고, 매 세션 시작 때 규칙(MANDATE)을 주입한다. 검사 스크립트 하나가 저장소 전체의 계약을 지킨다.

## 단위

| 단위 | 하는 일 | 위치 | 상세 명세 |
|---|---|---|---|
| lifecycle-skills | 요구사항 인터뷰부터 보고까지 다섯 스킬의 지침 | skills/*/SKILL.md | specs/lifecycle-skills.md |
| templates | 스킬이 만드는 문서의 틀(계층 3종, 노트, 퀴즈) | skills/*/templates/* | 없음 |
| agents | 코드 탐색, 웹 조사, 문서 검증, 변경 내용(diff) 분석, 검사 실행을 맡는 에이전트 5종 | agents/*.md | 없음 |
| docs-check | 퀴즈와 계층 문서의 기계 검사 | skills/work-report/scripts/docs_check.py | 없음 |
| installer | 소비 프로젝트에 바로가기 링크(심링크), 세션 시작 훅(hook), 규칙 불러오기 줄(import)을 설치 | install.sh | 없음 |
| mandate | 매 세션 주입되는 규칙과 그것을 출력하는 세션 시작 훅(hook) | MANDATE.md, hooks/mandate.sh | 없음 |
| repo-check | 저장소 자체 검사 | test/check.sh | 없음 |

## 주요 흐름

| 흐름 | 시작점 | 거치는 단위 순서 |
|---|---|---|
| 소비 프로젝트 설치 | bash .claude/shared/install.sh | installer → mandate |
| 기능 라이프사이클 | 사용자 요청 (mandate 트리거) | lifecycle-skills → agents → templates → docs-check |
| 저장소 변경 검증 | bash test/check.sh | repo-check → docs-check |

## 통합 지점

| 상대 | 방식 | 계약 위치 | 관련 단위 |
|---|---|---|---|
| 소비 프로젝트 | git submodule + 상대 심링크 + SessionStart hook + CLAUDE.md @import | install.sh, README §1 | installer, mandate |
| Claude Code | skills/agents frontmatter 규격, subagent_type 이름 | skills/*/SKILL.md, agents/*.md | lifecycle-skills, agents |

## 알려진 위험

| 위험 | 영향 단위 | 상태 |
|---|---|---|
| 스킬·에이전트 이름 변경이 소비 프로젝트 심링크를 끊음 | installer, lifecycle-skills, agents | test/check.sh 검사 3(에이전트 참조)과 검사 5(설치 심링크, 고정 이름 2개)가 감시 |
| MANDATE가 hook과 @import로 두 번 주입되어 크기가 곧 비용 | mandate, installer | 60줄 상한(검사 11). 이중 주입 해소는 후속 과제 |
