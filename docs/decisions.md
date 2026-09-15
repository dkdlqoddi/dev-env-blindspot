# 결정 기록

<!-- Append-only: one decision per row, one line per row, newest at the bottom; supersede a row by appending a new one instead of editing it. 영역: frontend, backend, core, or a module name. 결정 주체: 사용자 or 자체. Every row starts with "| 20" so grep finds it. -->

| 날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체 |
|---|---|---|---|---|---|
| 2026-09-07 | core | 사이클마다 보고서 파일을 만들지 않는다 | 스냅샷은 머지 후 읽히지 않음. 사용자 선택. 옮김: 392598a의 lifecycle-skills 명세 결정 기록 | CHANGELOG 하나에 누적 / 사이클별 보고서 유지 | 사용자 |
| 2026-09-07 | core | 과거 결정은 날짜로 시작하는 결정 행을 한 번에 검색(grep)해 찾는다 | 작업이 닿는 문서만 읽으면 인접 단위의 결정을 다시 묻게 됨 (반박 검토 3건). 옮김: 392598a의 lifecycle-skills 명세 결정 기록 | 결정 색인 파일 / 명세 전부 읽기 | 자체 |
| 2026-09-07 | core | 옛 문서의 결정은 자동으로 수확하지 않고 사용자가 파일을 지목할 때만 옮긴다 | 2026-09-07 3계층 설계 §12 마이그레이션과 §15 범위 제외. 옮김: 392598a의 lifecycle-skills 명세 범위 제외 항목 | 첫 실행 때 옛 문서 자동 수확 | 자체 |
| 2026-09-14 | core | 스킬을 blindspot-pass 하나로, 에이전트를 codebase-scanner 하나로 줄인다 | 사이클당 스캐너 6회→2회, verifier 8회→0, 강한 모델 산문 2회→0, 사용자 턴 15회→1~2회 | full 유지 + 단계 건너뛰기 기본값 / 스킬 3개로 축소 | 사용자 |
| 2026-09-14 | core | 3계층 문서(rules/map/specs)를 없애고 docs/decisions.md 하나로 대체한다 | 읽는 사람이 없는 문서는 순수 비용. 표준 명령·규칙은 CLAUDE.md가 이미 맡음 | rules.md만 유지 / 영역별 decisions.md | 사용자 |
| 2026-09-14 | core | 영역 폴더와 부트스트랩을 없애고 영역은 열로 둔다 | 영역 판정 로직 제거, 한 파일이 grep에 충분 | `docs/<영역>/decisions.md` 유지 | 자체 |
| 2026-09-14 | core | 퀴즈 게이트를 PR 리뷰로 대체한다 | 10명 팀의 실제 게이트는 PR 리뷰. 퀴즈는 HTML 생성과 사람 대기 비용 | 퀴즈 유지 / 체크리스트만 남김 | 사용자 |
| 2026-09-14 | core | 문서 검증(doc-verifier, docs_check.py)과 비개발자 문장 규칙을 없앤다 | 문서 시스템이 없으면 지킬 대상이 없음. 재작성 루프의 주원인 | hook으로 docs_check 자동화 | 자체 |
| 2026-09-14 | core | 스캐너 렌즈를 integration-points와 edge-cases 둘로 고정하고, 질문 상한을 넘는 분량은 추가 스캔이 아니라 보류 행으로 돌린다 | 추가 스캔은 토큰 배수. 상한을 넘으면 근거가 얇다는 신호 | 4렌즈 유지 / 7개 상한 + 추가 스캔 | 자체 |
| 2026-09-14 | core | 질문 상한은 4개이며 AskUserQuestion 한 번 호출로 묻는다 | 이 도구는 한 번 호출에 최대 4문항이라 상한 5개와 한 번 호출이 함께 성립하지 않음. 질문 1턴과 계획 승인 1턴으로 사용자 턴 1~2회 목표와 맞음 | 상한 5개 + 두 번 호출 / 상한 5개 + 5번째는 채팅 질문 | 사용자 |
| 2026-09-14 | core | 소비자 계약(스킬·에이전트 이름과 수 유지)을 폐기한다 | 소비 프로젝트가 적을 때 깨는 게 가장 싸다. install.sh가 옛 심링크를 정리 | 이름 유지하고 내용만 비움 | 사용자 |
| 2026-09-14 | core | 계획 모드에서는 결정 행을 계획 본문에 싣고, 계획 승인 직후 코드보다 먼저 docs/decisions.md에 추가한다 | 계획 모드는 계획 파일 외 편집을 막아 스킬의 파일 생성과 행 추가가 실행되지 않음 | 계획 모드를 쓰지 않음 / 행을 쓴 뒤 계획 모드 진입 | 사용자 |
| 2026-09-14 | core | MANDATE의 탐색 위임 규칙은 blindspot-pass 안의 탐색에만 적용한다 | MANDATE는 매 세션 주입됨. 범위가 없으면 작은 작업의 파일 찾기에도 스캐너가 떠 토큰 절감을 깎음 | 비자명한 작업 전체 / 모든 탐색 | 사용자 |
| 2026-09-14 | core | install.sh는 옛 링크를 이름 목록이 아니라 .claude/shared를 가리키면서 대상이 없는 링크로 판정해 지운다 | 폐기된 이름을 스크립트에 남기지 않음. 프로젝트 자체 파일과 다른 곳을 가리키는 링크는 보존. 로컬 소비 프로젝트 15곳 모두 ../shared/ 상대 링크 (2026-09-14 실측) | 폐기 이름 목록 하드코딩 / 대상 없는 링크 전부 삭제 | 자체 |
| 2026-09-14 | core | MANDATE 이중 주입(SessionStart hook과 CLAUDE.md import)은 유지한다 | 10줄 이하라 중복 비용이 작고, hook이 실패해도 import가 남음. 2026-09-07 설계 §15의 후속 과제를 닫음 | hook 제거 / import 제거 | 사용자 |
| 2026-09-15 | core | codex 브랜치는 main의 lite를 기준으로 다시 만들고 기존 origin/codex 이력을 대체한다 | 2026-09-15 사용자 승인. 기존 origin/codex는 full 버전에서 갈라져 최신 lite와 양방향으로 분기됨 | 기존 브랜치 병합 / 이중 런타임 유지 | 사용자 |
| 2026-09-15 | core | 질문 상한은 request_user_input 한 번에 맞춰 3개로 변경한다 | 2026-09-15 사용자 승인. Codex 구조화 질문 도구는 한 번에 최대 3문항을 받음. 2026-09-14 질문 상한 결정을 대체 | 네 번째 질문을 별도 턴으로 질문 / 구조화 입력 미사용 | 사용자 |
| 2026-09-15 | core | Codex 소비 경로는 .codex/shared, .agents/skills, .codex/agents, .codex/hooks.json, AGENTS.md로 둔다 | Codex 공식 발견 위치와 2026-09-15 사용자 승인. 2026-09-14 설치 및 이중 주입 결정을 Codex 방식으로 대체 | 사용자 홈 설치 / 플러그인 패키징 | 자체 |
| 2026-09-15 | core | codebase_scanner는 gpt-5.6-terra medium의 읽기 전용 TOML profile로 배포한다 | 스캔은 누락된 결정을 찾는 판단 작업이며 프로젝트 custom agent는 .codex/agents의 TOML을 사용 | 부모 모델 상속 / 경량 모델 low | 자체 |
| 2026-09-15 | core | 과거 설계·계획 문서는 모두 삭제하고 docs/blindspot 과거 기록은 Codex 관점으로 변환한다 | 2026-09-15 사용자 요청. 과거 기록까지 Codex 브랜치와 일관되어야 함 | 과거 문서 유지 / 활성 파일만 변환 | 사용자 |
| 2026-09-15 | core | 옛 Codex full agent 사본은 배포 당시 바이트와 정확히 같을 때만 설치기가 정리한다 | skill 링크와 달리 복사된 profile은 대상 소멸로 식별할 수 없으며 수정본 삭제는 소비자 데이터 손실 위험 | 옛 이름 전부 강제 삭제 / 옛 profile 모두 보존 | 자체 |
| 2026-09-15 | core | Codex 스캐너도 main과 같이 기존 결정에 모순되는 증거를 결정 행과 함께 보고하고, 전달된 경로 또는 glob 안에서만 탐색한다 | main:agents/codebase-scanner.md:18의 충돌 감지와 탐색 경계가 Codex 프로필에서 누락된 리뷰 결과 | 결정되지 않은 항목만 보고 / 저장소 전체 탐색 허용 | 자체 |
| 2026-09-15 | core | 서브에이전트를 실행할 수 없으면 blindspot pass를 중단하고 부모 컨텍스트에서 대체 스캔하지 않는다 | main:MANDATE.md:9의 raw scan main-context 격리를 유지해야 함 | 부모가 두 렌즈를 순차 탐색 / 저장소 산출물만 금지 | 자체 |
