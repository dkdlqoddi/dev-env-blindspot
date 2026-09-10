# core 전역 규칙 (Tier 1)

- 최종 갱신: 2026-09-10
- 코드 루트: . (skills/, agents/, rules/, hooks/, install.sh, install-antigravity.sh, test/, MANDATE.md)
- 읽는 법: 이 영역의 코드를 바꾸기 전에 항상 먼저 읽는다. 60줄을 넘기지 않는다.

## 불변 규칙

| # | 규칙 | 깨지면 생기는 일 | 근거 |
|---|---|---|---|
| 1 | 지침 파일(SKILL.md, agents, MANDATE)은 영어로, 산출물과 템플릿 본문은 한국어로 쓴다 | 모델 지침이 흔들리고 사용자가 문서를 못 읽는다 | ANTIGRAVITY.md Conventions |
| 2 | swarm-worker만 소유 파일 안에서 코드를 고친다. verifier·reviewer는 검증과 리뷰 피드백만 전달한다 | 탐색·리뷰 결과가 저장소를 오염시키고, 워커끼리 같은 파일을 덮어쓴다 | agents/*.md Rules |
| 3 | 스킬 폴더 이름, 에이전트 파일 이름, rules/ 아래 이름, 훅과 규칙 파일의 경로는 소비 프로젝트와의 약속이다 | 소비 프로젝트의 심링크와 hook이 끊긴다 | ANTIGRAVITY.md Consumer contract, install.sh |
| 4 | 모든 스킬 지침 파일(SKILL.md)은 반복 실패 목록(Gotchas) 섹션을 유지하고 항목을 지우지 않는다 | 한 번 잡은 반복 실패가 되살아난다 | ANTIGRAVITY.md Conventions |
| 5 | 가독성 표준(25 어절 표지)은 네 스킬에 사본으로 둔다 | 스킬을 단독으로 읽을 때 규칙이 사라진다 | test/check.sh 검사 4 |
| 6 | 계층 문서는 줄 상한(60/150/200)을 넘기지 않는다 | 매 작업이 읽는 문서가 다시 컨텍스트 문제가 된다 | skills/work-report/scripts/docs_check.py |
| 7 | 스웜 계획은 명세에서만 나오고, 한 묶음(웨이브) 안의 소유 파일은 겹치지 않는다 | 빠른 모델이 추측으로 구현하거나 공유 트리에서 서로 덮어쓴다 | skills/swarm-plan/SKILL.md, skills/swarm-plan/scripts/swarm_check.py |
| 8 | 작업 중 생성된 중간 문서(docs/swarm/, docs/notes/)는 작업 종료 시 모두 삭제하고 3계층 문서만 남긴다 | 오래된 작업 찌꺼기가 쌓여 다음 사이클의 컨텍스트를 오염시킨다 | MANDATE.md Hard rule 4 |

## 관례

| 분류 | 관례 | 근거 |
|---|---|---|
| 폴더 구조 | skill = skills/<name>/SKILL.md + templates/, agent = agents/<name>.md, rule = rules/<name>.md. 소비 프로젝트 .agents/에 심링크 | install.sh |
| 협업 프로토콜 | 스쿼드(worker ↔ verifier ↔ reviewer)는 send_message로 티키타카(최대 3회) 수행 | skills/swarm-plan/templates/task.md |
| 테스트 | bash test/check.sh 하나가 전부. 검사는 번호 붙은 블록이며 실패 시 fail 함수로 즉시 종료 | test/check.sh |
| 의존성 | bash와 python3 표준 라이브러리만 쓴다 | install.sh, skills/work-report/scripts/docs_check.py |
| 이름 짓기 | 스킬 description은 "Use when ..."으로 시작한다 | ANTIGRAVITY.md Conventions |

## 표준 명령

| 목적 | 명령 |
|---|---|
| test | bash test/check.sh |
| 퀴즈 확인 | python3 -m http.server 8765 --directory docs 후 localhost:8765/quiz.html (Playwright는 file:// 차단) |
| 스웜 실행(소비 프로젝트) | Antigravity에서 `/swarm-run` (또는 agy CLI: `agy --add-dir "$PWD" -p '/swarm-run' ...`) |

## 용어

| 용어 | 쉬운 말 설명 | 출처 |
|---|---|---|
| 협업 스쿼드 | 작업 하나를 구현·검증·리뷰 3인 1조로 상호 소통하며 완수하는 단위 | skills/swarm-plan/SKILL.md |
| 소비 프로젝트 | 이 저장소를 submodule로 붙여 쓰는 다른 프로젝트 | README §1 |
| 머지 전 퀴즈 | 변경을 리뷰어가 이해했는지 확인하는 객관식 관문. 전부 맞혀야 머지 | README §2 |
| 계층 문서 | 영역마다 규칙·지도·상세 명세 세 층으로 고정된 살아 있는 문서 | MANDATE.md Documentation tiers |
| 스웜 | 빠른 모델 여러 개가 계획대로 동시에 구현하는 실행 방식 | README §0 |
| 웨이브 | 한 번에 동시에 도는 작업 묶음. 묶음이 끝날 때마다 전체 검사와 커밋 | skills/swarm-plan/templates/plan.md |
| 브리프 | 작업 하나를 다른 정보 없이 끝낼 수 있게 쓴 지시서 | skills/swarm-plan/templates/task.md |
