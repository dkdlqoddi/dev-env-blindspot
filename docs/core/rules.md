# core 전역 규칙 (Tier 1)

- 최종 갱신: 2026-09-07
- 코드 루트: . (skills/, agents/, hooks/, install.sh, test/, MANDATE.md)
- 읽는 법: 이 영역의 코드를 바꾸기 전에 항상 먼저 읽는다. 60줄을 넘기지 않는다.

## 불변 규칙

| # | 규칙 | 깨지면 생기는 일 | 근거 |
|---|---|---|---|
| 1 | 지침 파일(SKILL.md, agents, MANDATE)은 영어로, 산출물과 템플릿 본문은 한국어로 쓴다 | 모델 지침이 흔들리고 사용자가 문서를 못 읽는다 | CLAUDE.md Conventions |
| 2 | 에이전트는 파일을 만들거나 고치지 않는다 | 탐색 결과가 저장소와 메인 컨텍스트를 오염시킨다 | agents/*.md Rules |
| 3 | 스킬 폴더 이름, 에이전트 파일 이름, hooks/mandate.sh, MANDATE.md 경로는 소비자 계약이다 | 소비 프로젝트의 심링크와 hook이 끊긴다 | CLAUDE.md Consumer contract, install.sh:13-20 |
| 4 | 모든 SKILL.md는 Gotchas 섹션을 유지하고 항목을 지우지 않는다 | 한 번 잡은 반복 실패가 되살아난다 | CLAUDE.md Conventions |
| 5 | 가독성 표준(25 어절 표지)은 네 스킬에 사본으로 둔다 | 스킬을 단독으로 읽을 때 규칙이 사라진다 | test/check.sh 검사 4 |
| 6 | 계층 문서는 줄 상한(60/150/200)을 넘기지 않는다 | 매 작업이 읽는 문서가 다시 컨텍스트 문제가 된다 | skills/work-report/scripts/docs_check.py |

## 관례

| 분류 | 관례 | 근거 |
|---|---|---|
| 폴더 구조 | skill = skills/<name>/SKILL.md + templates/, agent = agents/<name>.md | install.sh:13-20 |
| 테스트 | bash test/check.sh 하나가 전부. 검사는 번호 붙은 블록이며 실패 시 fail 함수로 즉시 종료 | test/check.sh |
| 의존성 | bash와 python3 표준 라이브러리만 쓴다 | install.sh:25, skills/work-report/scripts/docs_check.py |
| 이름 짓기 | 스킬 description은 "Use when ..."으로 시작한다 | CLAUDE.md Conventions |

## 표준 명령

| 목적 | 명령 |
|---|---|
| test | bash test/check.sh |
| 퀴즈 확인 | python3 -m http.server 8765 --directory docs 후 localhost:8765/quiz.html (Playwright는 file:// 차단) |

## 용어

| 용어 | 쉬운 말 설명 | 출처 |
|---|---|---|
| 소비 프로젝트 | 이 저장소를 submodule로 붙여 쓰는 다른 프로젝트 | README §1 |
| 머지 전 퀴즈 | 변경을 리뷰어가 이해했는지 확인하는 객관식 관문. 전부 맞혀야 머지 | README §2 |
| 계층 문서 | 영역마다 규칙·지도·상세 명세 세 층으로 고정된 살아 있는 문서 | MANDATE.md Documentation tiers |
