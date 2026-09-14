# core 시스템 맵 (Tier 2)

- 최종 갱신: 2026-09-14
- 코드 루트: .
- 읽는 법: 이 영역을 건드리는 작업이 rules.md 다음에 읽는다. 상세는 '단위' 표의 상세 명세로 내려간다. 150줄을 넘기지 않는다.

## 영역 개요

이 저장소는 다른 프로젝트가 가져다 쓰는 Claude Code 스킬과 에이전트 묶음이다. 스킬은 작업 순서를 알려주는 지침서이고, 에이전트는 탐색과 검증을 대신 하는 읽기 전용 일꾼이다. 설치 스크립트가 소비 프로젝트에 이것들을 연결하고, 매 세션 시작 때 규칙(MANDATE)을 주입한다. 검사 스크립트 하나가 저장소 전체의 계약을 지킨다. 이 브랜치는 구현 단계를 Antigravity의 빠른 모델 여러 개에 나눠 맡기는 스웜 인계 장치도 담는다. 스웜을 실행하는 동안의 판단은 빠른 모델이 아니라 상태 스크립트가 한다. 모델은 고정이다: 판단은 Claude Code의 Opus, 스웜은 Gemini 3.8 Flash의 높은 등급만 쓴다.

## 단위

| 단위 | 하는 일 | 위치 | 상세 명세 |
|---|---|---|---|
| lifecycle-skills | 요구사항 인터뷰부터 보고까지 다섯 스킬의 지침 | skills/{requirements-interview,blindspot-pass,explainer,work-report,blindspot-flow}/SKILL.md | specs/lifecycle-skills.md |
| templates | 스킬이 만드는 문서의 틀(계층 3종, 노트, 퀴즈) | skills/{blindspot-pass,explainer,work-report}/templates/* | 없음 |
| agents | 코드 탐색, 웹 조사, 문서 검증, 변경 내용(diff) 분석, 검사 실행, 스웜 결과 감사를 맡는 에이전트 6종. 머지 판정을 하는 둘은 Opus, 나머지는 더 가벼운 모델 | agents/*.md | 없음 |
| docs-check | 퀴즈와 계층 문서의 기계 검사 | skills/work-report/scripts/docs_check.py | 없음 |
| installer | 소비 프로젝트에 바로가기 링크(심링크), 세션 시작 훅(hook), 규칙 불러오기 줄(import), 세션 모델 설정(Opus와 가장 깊은 생각 단계)을 설치 | install.sh | 없음 |
| mandate | 매 세션 주입되는 규칙과 그것을 출력하는 세션 시작 훅(hook) | MANDATE.md, hooks/mandate.sh | 없음 |
| repo-check | 저장소 자체 검사와 스웜 실행 순서를 흉내 내는 시나리오 검사 | test/check.sh, test/swarm_scenario.py | 없음 |
| swarm-handoff | 스웜 계획과 결과 검토(Claude Code), 계획대로 병렬 실행(Antigravity)을 맡는 스킬·서브에이전트·설치와, 실행 순서를 정하는 상태 스크립트 | skills/swarm-plan/, skills/swarm-review/, antigravity/, install-antigravity.sh | specs/swarm-handoff.md |

## 주요 흐름

| 흐름 | 시작점 | 거치는 단위 순서 |
|---|---|---|
| 소비 프로젝트 설치 | bash .claude/shared/install.sh | installer → mandate |
| 기능 라이프사이클 | 사용자 요청 (mandate 트리거) | lifecycle-skills → agents → templates → docs-check |
| 저장소 변경 검증 | bash test/check.sh | repo-check → docs-check, swarm-handoff(swarm_check.py 검사 12, swarm_next.py 검사 13) |
| 스웜 사이클 | swarm-plan (Claude Code) | swarm-handoff(swarm-plan, swarm_check.py) → Antigravity swarm-run(swarm_next.py가 파견·재시도·중단 복구·커밋 결정) → swarm-handoff(swarm-review, swarm-auditor) → 재계획 회차로 되돌아가거나, 두 번 실패한 작업은 세션에서 구현 → lifecycle-skills(work-report) |

## 통합 지점

| 상대 | 방식 | 계약 위치 | 관련 단위 |
|---|---|---|---|
| 소비 프로젝트 | git submodule + 상대 심링크 + SessionStart hook + CLAUDE.md @import | install.sh, README §1 | installer, mandate |
| Claude Code | skills/agents frontmatter 규격(에이전트 model·effort), subagent_type 이름, 프로젝트 .claude/settings.json의 model: opus·effortLevel: xhigh(없을 때만 추가, 있으면 유지하고 알림) | skills/*/SKILL.md, agents/*.md, install.sh | lifecycle-skills, agents, installer |
| Antigravity (agy 1.2.2 실측) | .agents/{skills,agents,rules} 자동 발견(--add-dir 필요) + invoke_subagent TypeName. 에이전트 파일의 model이 호출의 Model보다 우선하므로 스웜 에이전트는 모두 model: inherit, 실행은 --model gemini-3.8-flash-high --effort high(어긋난 effort는 시작 거부). invoke_subagent는 워커가 끝나기 전에 반환 | antigravity/agents/*.md frontmatter, antigravity/skills/swarm-run/scripts/swarm_next.py, install-antigravity.sh, test/check.sh 검사 2b | swarm-handoff |
| 소비 프로젝트 docs/swarm/ | 계획·브리프(Claude Code가 씀), status.md(swarm_next.py만 씀), 결과(워커가 씀, 시도 번호가 맞아야 인정) 파일 계약. 본문 영어, 헤딩·라벨·상태 값은 스크립트가 찾는 한국어 문자열 | skills/swarm-plan/templates/*, antigravity/skills/swarm-run/templates/*, swarm_check.py, swarm_next.py | swarm-handoff |
| 소비 프로젝트 git | 경로 판정은 기준 커밋·HEAD 트리. 웨이브 커밋, (검증 실패) 커밋, status.md만 담는 상태 기록 커밋. 중단 복구의 소유 파일 되돌리기(checkout HEAD, 추적 안 된 파일 삭제, 경로는 글자 그대로 먼저) | swarm_check.py check_paths, swarm_next.py commit·revert·finish | swarm-handoff |

## 알려진 위험

| 위험 | 영향 단위 | 상태 |
|---|---|---|
| 스킬·에이전트 이름 변경이 소비 프로젝트 심링크를 끊음 | installer, lifecycle-skills, agents | test/check.sh 검사 3(에이전트 참조)과 검사 5(설치 심링크, 고정 이름 2개)가 감시 |
| MANDATE가 hook과 @import로 두 번 주입되어 크기가 곧 비용 | mandate, installer | 60줄 상한(검사 11). 이중 주입 해소는 후속 과제 |
| Antigravity 도구 이름·발견 규칙·모델 해석·반환 시점이 바뀌면 워커 정의가 조용히 깨짐 | swarm-handoff, repo-check | 검사 2b가 tools 허용목록과 model: inherit를 고정. 발견 규칙과 반환 시점은 스모크 테스트(CLAUDE.md Test, 중단·재개 포함)로만 확인 |
| Antigravity 앱에서 다른 모델을 고른 채 실행하면 스웜 전체가 그 모델로 돎 | swarm-handoff | agy가 실행 모델을 스크립트에 알려 주지 않아 막을 수 없음. README와 swarm-mandate 규칙이 Gemini 3.8 Flash (High) 선택을 안내 |
| 재개 때 끊긴 작업의 소유 파일을 되돌려, 그 파일에 사람이 한 변경이 사라질 수 있음 | swarm-handoff | 스웜 밖 변경이 있으면 되돌리기 전에 멈춤. README에 경고하고 전용 worktree 권장 |
| 템플릿 라벨·상태 값 문자열이 swarm_check.py·swarm_next.py의 계약 | swarm-handoff | 검사 8은 헤딩과 일부 라벨만 감시. 시나리오 테스트(검사 13)가 실제 문자열로 전이를 검사 |
| 스웜 도중 submodule을 올리면 이전 형식 status.md로 이어서 실행할 수 없음 | swarm-handoff, installer | next가 이전 형식이라고 알리고 멈춤. README §4에 진행 중 업데이트 금지 |
