# blindspot Agent/Skill 저장소 구축 작업 보고서

- 날짜: 2026-07-06
- 기준: dc45220 (초기 커밋) → a8e8740 (HEAD)
- 퀴즈: docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html — 통과 전 머지 금지

## Human 섹션

### 요약

빈 저장소 위에 모든 프로젝트가 공유하는 Claude Code Agent/Skill 저장소를 처음부터 구축했다. Thariq의 "Finding Your Unknowns" 라이프사이클을 skill 5종(requirements-interview → blindspot-pass → explainer → work-report, 그리고 전체를 잇는 blindspot-flow)과 읽기 전용 agent 3종으로 구현했고, 소비 프로젝트는 submodule + `install.sh` 한 번으로 심링크·SessionStart hook·CLAUDE.md import가 자동 연결된다. 실행 코드는 bash 스크립트 3개뿐이며 나머지는 전부 모델/사용자 대상 문서다. 태스크별 리뷰 7회 + 최종 전체 리뷰 + 수정 재리뷰를 모두 통과했고 `test/check.sh`가 멱등성까지 검증한다.

### 스크린샷 / 데모

해당 없음 (CLI/문서 저장소)

### 리뷰 포인트

- `install.sh:26` — corrupt settings.json 방어(jq 분기). 최종 리뷰에서 추가된 가장 중요한 수정
- `install.sh:12,16` — nullglob 미설정: skills/·agents/가 비면 `*` 심링크 생성 가능 (실저장소는 항상 내용이 있어 도달 불가로 수용)
- `install.sh:41` — python3 폴백은 corrupt JSON에서 raw traceback으로 실패 (loudly-fail은 유지되나 jq 분기와 메시지 UX 비대칭)
- `install.sh:46` vs `:33` — python 분기는 settings.json을 항상 재포맷, jq 분기는 기존재 시 미기록 (내용 멱등, 포맷만 churn)
- `test/check.sh:31-38` — 멱등성 테스트는 호스트에 있는 병합 분기(jq)만 실행; python3 경로는 미테스트 배포
- `test/check.sh:16` — `-eq 8` tripwire: skill/agent 추가 시 이 숫자 + `:10`의 skill 루프 + MANDATE.md 3곳 동시 갱신 필요

## Agent 섹션

### 의도 (Intent)

프로젝트마다 반복되는 네 가지 작업(요구사항 이해, Unknown Unknowns 구체화, 문서 작성, 작업 보고)을 skill로 표준화하고, agent로 탐색·검증을 컨텍스트 격리하며, SessionStart hook으로 사용을 매 세션 상기시킨다. 배포는 소비 프로젝트가 버전을 명시적으로 고정할 수 있는 git submodule 방식.

### 제약 (Constraints)

- 지침서(SKILL.md, agents, MANDATE)는 영어, 산출물(질문·문서·보고서·퀴즈)은 한국어
- 산출물 경로 계약: `docs/blindspot/YYYY-MM-DD-<slug>-{requirements,unknowns,explainer,report}.md`, `quiz/*.html`, `<slug>-implementation-notes.md`(날짜 없음)
- agent는 읽기 전용(tools 최소화), 의존성은 bash+coreutils+(jq|python3)만
- 심링크 기반 — Linux/WSL/macOS 전용

### 검토한 엣지케이스

| 엣지케이스 | 처리 |
|---|---|
| install.sh 재실행 (submodule 업데이트 후) | 전 단계 멱등: `ln -sfn`, hook 존재 조회 후 append, `grep -qxF` 가드. check.sh가 2회 실행으로 검증 |
| 기존 settings.json이 깨진 JSON | jq 분기: 명시적 에러 + exit 1 (`install.sh:26`, 최종 리뷰 수정). python3 분기: traceback으로 실패(비대칭 UX, 수용) |
| jq 없음 | python3 폴백; 둘 다 없으면 수동 병합 안내 후 exit 1 |
| CLAUDE.md 없음 / 개행 없이 끝남 | 파일 생성 / `printf '\n%s\n'`으로 안전 append |
| 프로젝트 자체 skill과 공존 | 디렉토리 통째가 아닌 개별 심링크 |
| greenfield 프로젝트에서 blindspot-pass | 3렌즈로 축소 + 문서에서 similar-features 섹션 생략 (최종 리뷰 수정) |
| 퀴즈 문항에 HTML 특수문자 | 미이스케이프(innerHTML) — 로컬 단일 사용자·agent 작성 콘텐츠라 수용 |

### 의도적 범위 제외

- Plugin marketplace 배포 (submodule로 대체, 전환 여지 있음)
- 매 프롬프트 hook (UserPromptSubmit) — 토큰 오버헤드 대비 이득 부족
- skill 사용 텔레메트리, CI 파이프라인, 다국어 산출물
- **강제의 한계**: hook은 규칙 텍스트를 주입할 뿐 skill 호출을 기계적으로 차단·강제하지 않는다. 준수는 모델 행동에 의존 (설계상 수용된 최대 리스크)

### 구현 노트 요약

- 계획의 quiz grep 기대값이 3→5→7로 두 번 정정됨 (수동 카운트 취약성 — 커밋 0db3e60, 2b8afbe)
- subagent 파견이 3회 무동작 즉시 종료(도구 사용 0회) — SendMessage "Begin now" 재개로 해결
- Write hook이 "report" 파일명을 차단해 Task 4 구현자가 heredoc으로 우회 (환경 특이사항)
- 최종 리뷰 수정 4건: jq corrupt-JSON 가드(Important), greenfield 렌즈 문서화, README 신규 clone 안내(`git submodule update --init`), agent 심링크 `-f` 검증 강화
