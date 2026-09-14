# core 전역 규칙 (Tier 1)

- 최종 갱신: 2026-09-14
- 코드 루트: . (skills/, agents/, antigravity/, hooks/, install.sh, install-antigravity.sh, test/, MANDATE.md)
- 읽는 법: 이 영역의 코드를 바꾸기 전에 항상 먼저 읽는다. 60줄을 넘기지 않는다.

## 불변 규칙

| # | 규칙 | 깨지면 생기는 일 | 근거 |
|---|---|---|---|
| 1 | 지침 파일(SKILL.md, agents, MANDATE)은 영어로, 산출물과 템플릿 본문은 한국어로 쓴다. 스웜 계획·지시서·결과만 본문을 영어로 쓰고 제목·항목 이름·상태 값은 한국어로 둔다 | 모델 지침이 흔들리고 사용자가 문서를 못 읽는다. 스웜 항목 이름이 바뀌면 스크립트가 항목을 못 찾는다 | CLAUDE.md Conventions |
| 2 | Claude Code 에이전트는 파일을 만들거나 고치지 않는다. Antigravity 워커만 브리프의 소유 파일 안에서 고치고, 테스트를 약하게 만들거나 지우기·설치·네트워크 명령을 쓰지 않는다 | 탐색 결과가 저장소를 오염시키고, 워커끼리 같은 파일을 덮어쓰거나 검사를 속인다 | agents/*.md Rules, antigravity/agents/swarm-worker.md Rules |
| 3 | 스킬 폴더 이름, 에이전트 파일 이름, antigravity/ 아래 이름, 세션 시작 훅과 규칙 파일의 경로는 소비 프로젝트와의 약속이다 | 소비 프로젝트의 심링크와 hook이 끊긴다 | CLAUDE.md Consumer contract, install.sh:13-20, install-antigravity.sh |
| 4 | 모든 스킬 지침 파일(SKILL.md)은 반복 실패 목록(Gotchas) 섹션을 유지하고 항목을 지우지 않는다 | 한 번 잡은 반복 실패가 되살아난다 | CLAUDE.md Conventions |
| 5 | 가독성 표준(25 어절 표지)은 네 스킬에 사본으로 둔다 | 스킬을 단독으로 읽을 때 규칙이 사라진다 | test/check.sh 검사 4 |
| 6 | 계층 문서는 줄 상한(60/150/200)을 넘기지 않는다 | 매 작업이 읽는 문서가 다시 컨텍스트 문제가 된다 | skills/work-report/scripts/docs_check.py |
| 7 | 스웜 계획은 명세에서만 나온다. 한 묶음(웨이브) 안의 소유 파일은 겹치지 않고, 묶음의 작업 수는 동시 실행 상한 안이며, 마지막 묶음의 검사는 전체 검사다. 파일 유무는 변경 기록(기준 커밋) 기준으로 판정한다 | 빠른 모델이 추측으로 구현하거나, 공유 트리에서 서로 덮어쓰거나, 검증 안 된 변경으로 끝나거나, 재개가 막힌다 | skills/swarm-plan/SKILL.md, skills/swarm-plan/scripts/swarm_check.py |
| 8 | 스웜 실행의 순서, 재시도, 중단 복구, 커밋, 상태 기록은 상태 스크립트만 정하고 빠른 모델은 그 출력만 옮긴다 | 빠른 모델이 상태 표를 잘못 고치거나 일하는 워커를 실패로 적고, 끊긴 실행을 이어 가지 못한다 | antigravity/skills/swarm-run/scripts/swarm_next.py, test/swarm_scenario.py |
| 9 | 구현 워커의 에이전트 파일은 실행 명령의 모델을 물려받는다(model: inherit) | 실행 명령에서 고른 모델과 상관없이 가벼운 모델로 구현한다 | antigravity/agents/swarm-worker.md, test/check.sh 검사 2b |

## 관례

| 분류 | 관례 | 근거 |
|---|---|---|
| 폴더 구조 | skill = skills/<name>/SKILL.md + templates/ (스크립트가 있으면 scripts/), agent = agents/<name>.md. Antigravity 쪽은 antigravity/{skills,agents,rules}, 소비 프로젝트 .agents/에 심링크 | install.sh:13-20, install-antigravity.sh |
| 테스트 | bash test/check.sh 하나가 전부. 검사는 번호 붙은 블록이며 실패 시 fail 함수로 즉시 종료. 스웜 상태 전이는 검사 13이 부르는 test/swarm_scenario.py가 agy 없이 흉내 | test/check.sh |
| 의존성 | bash와 python3 표준 라이브러리만 쓴다. 스웜 스크립트는 git 명령도 쓴다 | install.sh:25, skills/work-report/scripts/docs_check.py, skills/swarm-plan/scripts/swarm_check.py |
| 이름 짓기 | 스킬 description은 "Use when ..."으로 시작한다 | CLAUDE.md Conventions |

## 표준 명령

| 목적 | 명령 |
|---|---|
| test | bash test/check.sh |
| 퀴즈 확인 | python3 -m http.server 8765 --directory docs 후 localhost:8765/quiz.html (Playwright는 file:// 차단) |
| 스웜 실행(소비 프로젝트) | agy --add-dir "$PWD" -p '/swarm-run' --model gemini-3.8-flash-high --dangerously-skip-permissions --print-timeout 60m (끊기면 같은 명령을 다시 실행) |

## 용어

| 용어 | 쉬운 말 설명 | 출처 |
|---|---|---|
| 소비 프로젝트 | 이 저장소를 submodule로 붙여 쓰는 다른 프로젝트 | README §1 |
| 머지 전 퀴즈 | 변경을 리뷰어가 이해했는지 확인하는 객관식 관문. 전부 맞혀야 머지 | README §2 |
| 계층 문서 | 영역마다 규칙·지도·상세 명세 세 층으로 고정된 살아 있는 문서 | MANDATE.md Documentation tiers |
| 스웜 | 빠른 모델 여러 개가 계획대로 동시에 구현하는 실행 방식 | README §0 |
| 웨이브 | 한 번에 동시에 도는 작업 묶음. 계획이 정한 묶음별 검사(마지막은 전체 검사)를 통과하면 커밋 | skills/swarm-plan/templates/plan.md |
| 브리프 | 작업 하나를 다른 정보 없이 끝낼 수 있게 쓴 지시서 | skills/swarm-plan/templates/task.md |
| 회차 | 끝난 스웜을 검토한 뒤 일부 작업만 다시 계획해 돌리는 한 차례 | skills/swarm-plan/templates/plan.md |
| 시도 | 한 작업을 하위 에이전트에게 보낸 횟수. 회차를 넘어 누적되고, 결과 파일에 같은 번호가 있어야 인정 | antigravity/skills/swarm-run/templates/result.md |
| 기준 커밋 | 계획을 세운 시점의 변경 기록. 새 파일 판정과 감사가 이 시점을 기준으로 한다 | skills/swarm-plan/templates/plan.md |
