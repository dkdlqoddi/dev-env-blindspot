# Claude Code 계획 · Antigravity 스웜 실행 분업 설계

- 날짜: 2026-09-08
- 상태: 구현·실측 완료, 사용자 검토 대기 — 자율 실행 세션이라 인터뷰 없이 결정했다. 결정마다 대안을 적었고 §12에 사용자 확인이 필요한 항목을 모았다
- 브랜치: `antigravity-swarm` (main은 그대로)
- 선행 스펙: `2026-09-07-three-tier-docs-design.md` (3계층 문서 계약은 그대로 유지)

## 1. 목적과 배경

main 브랜치의 전략은 모든 단계를 Claude Code에서 실행한다. 인터뷰, 사각지대 점검, 설계, 구현, 보고가 한 세션의 한 모델(강한 모델)에서 직렬로 돈다. 판단이 필요한 단계에는 맞지만, 구현처럼 "정해진 대로 여러 파일을 고치는" 단계까지 강한 모델이 직렬로 하는 것은 비싸고 느리다.

이 설계는 단계를 **비용 성격**으로 나눈다.

| 성격 | 어디서 | 모델 | 단계 |
|---|---|---|---|
| 판단 — 한 번, 전체 맥락으로 | Claude Code | 고성능 (Fable/Opus) | 인터뷰, 사각지대 점검, 설계, **스웜 계획**, **결과 감사**, 보고·퀴즈 |
| 실행 — 여러 번, 맥락 없이, 병렬로 | Antigravity | 저성능 고속 (Gemini Flash) | 브리프대로 구현, 검증 명령 실행 |

두 하네스는 같은 작업 폴더의 **파일**로만 대화한다. 강한 모델이 `docs/swarm/` 아래에 계획 패키지(계획 한 장 + 작업별 자기완결 브리프)를 쓰고, Antigravity의 빠른 모델이 그것을 읽어 작업마다 서브에이전트를 웨이브 단위로 동시에 띄운다. 결과도 파일로 돌아오고, 강한 모델이 diff와 대조해 감사한 뒤 기존 머지 전 퀴즈 게이트로 넘긴다.

## 2. 확정된 결정사항

| # | 결정 | 선택 | 근거 | 기각한 대안 |
|---|---|---|---|---|
| 1 | 기존 스킬·에이전트 | 5+5 그대로. Claude Code 쪽에 `swarm-plan`, `swarm-review`, `swarm-auditor`를 더한다 | 소비자 계약(이름·수) 유지. 생각 단계는 이미 있는 스킬이 맡는다 | `origin/antigravity`처럼 전체 이식 — 강한 모델의 계획 단계가 사라져 요청과 어긋남 |
| 2 | Antigravity 쪽 파일 | `antigravity/{skills,agents,rules}` 폴더에 별도 보관, `install-antigravity.sh`가 소비 프로젝트 `.agents/`에 심링크 | 사용자 요청("별도로 생성"). Antigravity는 `.agents/{skills,agents,rules}`를 자동 발견한다(실측) | 이 저장소 루트에 `.agents/` 직접 배치 — 소비 프로젝트에서는 `.claude/shared/.agents`라 발견되지 않음 |
| 3 | 하네스 간 인터페이스 | `docs/swarm/` 작업 파일: `plan.md`, `tasks/<id>.md`, `status.md`, `results/<id>.md`. 인수 시 notes와 함께 삭제 | 파일이 유일한 공통 매체. notes와 같은 수명 주기면 규칙이 하나 | 루트 `.swarm/` / 영구 보관 — docs 규칙과 어긋나거나 사이클마다 파일이 쌓임 |
| 4 | 계획의 단위 | 작업(task) = 빠른 모델이 브리프만 읽고 끝낼 수 있는 S–M 크기. 웨이브 = 동시에 도는 작업 묶음. 한 웨이브 안 작업의 소유 파일은 겹치지 않는다 | 워커끼리 대화가 없으므로 충돌은 구조로 막아야 함 | 작업별 격리 워크트리(`branch`) + 병합 — 병합을 빠른 모델에 맡기게 됨 |
| 5 | 검사 | `skills/swarm-plan/scripts/swarm_check.py` — 계획 머리글 5항목(안내문 잔존 포함), id·브리프 대응, 선행의 웨이브 순서, 소유 파일 존재·겹침(정규화, 폴더 판정), 필수 섹션, 플레이스홀더, 금지어 | 셀 수 있는 것은 스크립트. 빠른 실행자에게 눈대중을 맡기지 않는다 | doc-verifier에게 맡김 — haiku 판단에 안전성을 맡길 수 없음 |
| 6 | 워커의 워크스페이스 | `invoke_subagent` Workspace `inherit`(공유 트리), Model `flash`. 웨이브마다 dispatcher가 `git commit` | 실측: 한 호출로 여러 항목 동시 실행, 두 워커가 같은 트리에 정상 기록. 커밋이 있어야 실패한 웨이브를 되돌리고 작업별 diff를 감사할 수 있다 | 커밋 없이 진행 — 감사와 복구 불가 |
| 7 | 웨이브 실패 처리 | 전체 검증 실패 → 웨이브의 완료 작업을 실패 내용과 함께 한 번 재시도 → 여전히 실패면 **멈춘다**(뒤 웨이브 대기). Claude Code가 재계획하고 `/swarm-run`이 status.md에서 재개 | 깨진 바탕 위에 다음 웨이브를 쌓으면 쿼터만 태움. 계획 수정은 강한 모델의 일 | 실패한 웨이브를 건너뛰고 계속 — 연쇄 실패 |
| 8 | 서브에이전트 정의 방식 | 파일(`.agents/agents/*.md`, `subagent: true`, `model: flash`, 도구 허용목록) 우선. TypeName을 못 찾으면 파일 본문으로 `define_subagent` 후 재시도 | 파일은 버전 관리·리뷰 가능. 실측: `--add-dir` 없이 print 모드로 실행하면 파일이 발견되지 않아 대체 경로가 필요 | define_subagent만 사용 — 정의가 대화 안에만 존재 |
| 9 | 결과 감사 | `swarm-auditor`(sonnet)가 브리프·결과·diff를 대조해 작업별 판정표 반환. `swarm-review`는 그 표로 라우팅만 | 결과 파일 N개를 메인 컨텍스트에 읽는 것은 옛 원본 더미 | change-analyzer 확장 — 머지 게이트를 먹이는 에이전트를 건드리지 않음 |
| 10 | 게이트 | 스웜 결과도 기존 `work-report` 보고 모드와 `docs/quiz.html`을 통과해야 머지 | 실행 하네스가 바뀌어도 사람이 이해해야 할 것은 같다 | 스웜 전용 게이트 — 규칙 중복 |
| 11 | 언어 | 지침(SKILL.md, agents, rules)은 영어. 계획·브리프·결과·상태는 한국어(경로·명령·인터페이스는 원문) | 저장소 규칙. Gemini Flash도 한국어 지시를 정확히 따랐다(실측) | 브리프만 영어 — 사용자가 검토하는 산출물이라 한국어 유지 |
| 12 | Antigravity 규칙 주입 | `.agents/rules/swarm-mandate.md`(`trigger: always_on`) 한 장 | Antigravity에는 SessionStart hook이 없고 규칙 파일은 항상 주입된다 | `AGENTS.md`에 줄 추가 — 다른 도구(Codex 등)도 읽는 파일이라 침범 |

## 3. 구조

```
(이 저장소)
skills/
├── swarm-plan/                 # Claude Code: 스펙 → 계획 패키지
│   ├── SKILL.md
│   ├── templates/{plan.md, task.md}
│   └── scripts/swarm_check.py  # 계획 패키지 기계 검사 (양쪽 하네스가 호출)
├── swarm-review/SKILL.md       # Claude Code: 결과 감사·노트 반영·라우팅
agents/swarm-auditor.md         # Claude Code: 결과 대 diff 감사 (sonnet)
antigravity/
├── skills/swarm-run/           # Antigravity: 계획을 읽어 웨이브별로 동시 실행
│   ├── SKILL.md
│   └── templates/{status.md, result.md}
├── agents/{swarm-worker.md, swarm-checker.md}   # 서브에이전트 (flash)
└── rules/swarm-mandate.md      # 항상 켜지는 규칙
install-antigravity.sh          # 소비 프로젝트 .agents/ 심링크

(소비 프로젝트)
.claude/shared/                 # submodule (양쪽 하네스가 같은 마운트를 씀)
.claude/skills/*, .claude/agents/*        ← install.sh
.agents/skills/swarm-run, .agents/agents/*, .agents/rules/*   ← install-antigravity.sh
docs/<영역>/{rules.md, map.md, specs/}    # 3계층 (그대로)
docs/notes/<slug>.md                      # 작업 노트 (그대로)
docs/swarm/                               # 계획 패키지 + 실행 기록 — 인수 시 삭제
├── plan.md · tasks/<id>.md               ← swarm-plan (Claude Code)
└── status.md · results/<id>.md           ← swarm-run / swarm-worker (Antigravity)
docs/quiz.html                            # 머지 전 퀴즈 (그대로)
```

## 4. 계획 패키지 계약

헤딩과 머리글 항목은 계약이다. 출하 템플릿은 `test/check.sh` 검사 8이, 생성된 패키지는 `swarm_check.py`가 지킨다.

- `plan.md` — 머리글: 작성일, 기준 커밋, 대상 spec, 작업 노트, 동시 실행 상한(기본 8), 전체 검증(rules.md 표준 명령의 test), 실행 방법. 섹션: `## 목표`, `## 작업`(`| id | 제목 | 역할 | 웨이브 | 선행 |`), `## 회차`. 실행자는 이 표만 읽고 브리프를 열지 않는다.
- `tasks/<id>.md` — 머리글: 역할, 웨이브, 선행, 대상 spec, 소유 파일(백틱 경로, 폴더는 끝에 `/`, 새 파일은 `(신규)`), 참고 파일. 섹션: `## 목표`, `## 해야 할 일`, `## 완료 조건`, `## 검증`. 자기완결: 경로는 전부 실제 값, 두 작업이 함께 쓰는 인터페이스는 각 브리프에 원문 그대로, "필요하면"·"적절히" 금지.
- `status.md` — swarm-run만 쓴다. 머리글 진행(실행 중 | 끝남), 전체 검증 최종 결과. `## 작업` 표(상태: 대기/실행 중/완료/부분 완료/실패/보류, 시도, 커밋, 비고), `## 웨이브 검증` 표. 재개의 기준점.
- `results/<id>.md` — 워커가 쓴다. 상태, 시도, 바꾼 파일, 검증, 브리프와 다르게 한 것, 결정, 막힌 것. 40줄 이하, 로그 없음.

## 5. 실행 프로토콜 (swarm-run)

1. 전제: plan.md 존재, `swarm_check.py` 통과, `git status` 깨끗함(docs/swarm 제외). 하나라도 아니면 멈추고 알린다.
2. status.md가 있으면 재개(완료 행 유지), 없으면 생성.
3. 웨이브마다: 선행이 모두 완료인 작업만 골라 **한 번의 `invoke_subagent` 호출**에 작업 수만큼 항목(TypeName `swarm-worker`, Model `flash`, Workspace `inherit`, 프롬프트는 브리프 경로·결과 경로와 고정 지시문 한 단락). 결과 메시지를 기다리고 결과 파일의 상태 줄만 status.md에 옮긴다.
4. `swarm-checker` 한 항목으로 전체 검증. 실패면 웨이브의 완료 작업을 실패 내용과 함께 한 번 재시도, 다시 검증. 여전히 실패면 진행 끝남·최종 결과 실패로 멈춘다.
5. `git add -A && git commit -m "swarm: 웨이브 n — ids"`, 커밋 해시를 status.md에.
6. 끝나면 status.md와 결과 파일을 한 번 더 커밋하고(바뀐 것이 없으면 생략), 한국어 요약과 다음 단계(`swarm-review`)를 알린다.

dispatcher는 브리프·소스·로그를 읽지 않는다. 계획 표, status.md, 상태 줄, 검사 요약이 전부다.

## 6. 스킬·에이전트 요약

| 이름 | 하네스 | 역할 | 읽는 것 | 쓰는 것 |
|---|---|---|---|---|
| `swarm-plan` | Claude Code | 스펙을 웨이브·브리프로 분해, 검사, 노트, 인계 | rules·map·spec, codebase-scanner(integration-points, similar-features) | `docs/swarm/plan.md`, `tasks/`, notes 한 항목 |
| `swarm-review` | Claude Code | 감사 결과로 라우팅(수용 / 소규모 수정 / 재계획), 워커 결정을 notes로 | status.md, swarm-auditor, check-runner | `docs/notes/<slug>.md` |
| `swarm-auditor` | Claude Code (sonnet) | 작업별 완료 주장 대 diff 대조, 범위 이탈·통합 위험 | plan, tasks, results, git diff | 없음(읽기 전용) |
| `swarm-run` | Antigravity | 웨이브별 동시 dispatch, 검증, 커밋, 상태 기록 | plan.md 표, status.md | `status.md`, 웨이브 커밋 |
| `swarm-worker` | Antigravity (flash) | 브리프 하나 구현, 검증, 결과 파일 | 브리프, 참고 파일 | 소유 파일, `results/<id>.md` |
| `swarm-checker` | Antigravity (flash) | 전체 검증 한 번 실행, 실패만 보고 | — | 없음(읽기 전용) |
| `swarm-mandate` | Antigravity 규칙 | 계획은 Claude Code가, 실행은 swarm-run이. 계층 문서 금지 | — | — |

기존 스킬 변경: `blindspot-flow` 4단계에 "이 세션 구현 / 스웜 구현" 선택 추가. `work-report` 보고 모드가 계획 문서로 `docs/swarm/plan.md`를 change-analyzer에 넘기고, 게이트 통과 시 `docs/swarm/`도 지운다. `MANDATE.md`에 트리거 2행과 작업 파일 1개 추가(47줄).

## 7. 실측 (agy 1.1.27, 2026-09-08, WSL)

| 확인 | 결과 |
|---|---|
| `.agents/skills/<name>` 심링크 → `/<name>` 슬래시 명령 | 동작 (`--add-dir "$PWD"` 필요) |
| `.agents/agents/<name>.md` 심링크 → `invoke_subagent` TypeName | 동작 (`--add-dir` 필요; 없으면 `subagent "…" not found`) |
| `invoke_subagent` 한 호출 다중 항목, Model `flash`, Workspace `inherit` | 두 워커가 공유 트리에 각자 파일 기록 |
| `define_subagent` (enable_write_tools) 후 invoke | 동작 |
| 사용 가능한 모델 | `agy models`: gemini-3.8/3.7/3.6-flash-{high,medium,low}, gemini-3.1-pro-{high,low}, claude-sonnet-4-6, claude-opus-4-6-thinking, gpt-oss-120b-medium |
| 서브에이전트 Model 값 | `inherit`, `flash_lite`, `flash`, `pro` |
| 도구 이름 | view_file, list_dir, find_by_name, grep_search, run_command, write_to_file, replace_file_content, read_url_content, search_web, ask_question, invoke_subagent, define_subagent, manage_subagents, send_message, manage_task, schedule, generate_image |
| 끝에서 끝까지 — 3작업 2웨이브 스크래치 프로젝트(파이썬 calc 라이브러리)에 `agy --add-dir "$PWD" -p '/swarm-run' --model gemini-3.8-flash-medium` | 2분 38초에 완료. 웨이브 1은 T01·T02 동시 실행 → checker 통과 → 커밋, 웨이브 2는 T03 → 통과 → 커밋, `status.md`·`results/*.md`가 템플릿대로, 웨이브 커밋은 소유 파일만 포함, 테스트 3개 통과, 한국어 요약과 다음 단계 안내 |

Antigravity 2.0 데스크톱 앱은 문서상 같은 `.agents/` 발견 규칙을 쓰지만 이 세션에서는 검증하지 않았다.

## 8. 테스트 변경 (`test/check.sh`)

| # | 검사 | 변경 |
|---|---|---|
| 1 | mandate 출력 | 스킬 7개, `docs/swarm/` 경로 추가 |
| 2 | frontmatter | 13파일(7 스킬 + 6 에이전트) |
| 2b | Antigravity 파일(신설) | 4파일. 에이전트는 `subagent: true`, `mainAgent: false`, `model: flash`, `commandExecutionPolicy: auto`, 블록 시퀀스로 적은 도구 허용목록이 실측 이름 9개(파일·검색·실행·웹) 안에 있음. 규칙은 `trigger:` |
| 5 | 설치 멱등성 | `install-antigravity.sh` 두 번 실행, `.agents` 링크 4개 불변, 링크를 지나는 경로 5개 해석 |
| 7 | 폐지 경로 | `antigravity/`도 검사 |
| 8 | 템플릿 헤딩 | plan/task/status 헤딩, result 머리글 항목 |
| 10 | 템플릿 참조 | Antigravity SKILL.md의 `templates/<파일>`도 자기 트리에서 해석 |
| 12 | swarm_check(신설) | 정상 패키지 통과, 깨진 패키지(슬래시 없는 폴더 겹침·선행 순서·브리프 누락·없는 경로·플레이스홀더·금지어·머리글 안내문 잔존) 실패 |
| 3 | 에이전트 참조 | 모든 agents/*.md 이름이 MANDATE 하드 룰 2에도 있어야 함 |

## 9. 의도적 범위 제외

- Antigravity 쪽에 인터뷰·사각지대·설계 스킬을 옮기지 않는다. 판단은 Claude Code에 남긴다.
- 워커 간 메시지(`send_message`)는 쓰지 않는다. 인터페이스는 브리프에 원문으로 고정한다.
- 작업별 모델 선택(`flash_lite`/`pro`)은 계획에 두지 않는다. 필요해지면 브리프 머리글 한 줄로 추가할 수 있다.
- 웨이브 실패 시 자동 재계획은 하지 않는다. 재계획은 `swarm-plan`의 회차 모드로, 사람이 본 뒤에.
- Antigravity 앱 UI 검증, `hooks.json`, 플러그인 패키징은 하지 않는다.
- `origin/antigravity`, `origin/codex` 브랜치는 건드리지 않는다.

## 10. 위험과 수용

| 위험 | 완화 |
|---|---|
| 빠른 모델이 브리프를 "해석"해 다른 일을 함 | 브리프 자기완결 규칙 + 워커 규칙("계획을 고치지 않는다, 막히면 적고 멈춘다") + 감사에서 범위 이탈 판정 |
| 소유 파일이 겹쳐 공유 트리에서 덮어씀 | `swarm_check.py`가 실행 전에 막음 |
| print 모드 타임아웃으로 스웜이 중간에 끊김 | status.md 기반 재개. README에 `--print-timeout`과 대화형(`agy -i`) 안내 |
| 웨이브 커밋이 사용자의 커밋 습관과 충돌 | 전용 브랜치 권장(README). §12 확인 항목 |
| 쿼터 소진(워커 수 × 재시도) | 동시 실행 상한 8, 재시도 1회, 실패 시 멈춤 |
| Antigravity 도구 이름·발견 규칙 변경 | check.sh 2b가 도구 허용목록을 실측 목록에 고정 — 바뀌면 검사가 먼저 깨진다 |

## 11. 비용 계산

| 항목 | main | 이 브랜치 |
|---|---|---|
| 구현 단계의 모델 | 강한 모델 1개, 직렬 | 빠른 모델 N개, 웨이브 병렬 (+ dispatcher 1개) |
| 강한 모델의 구현 관련 컨텍스트 | 소스·로그 전부 | 스펙·맵 → 브리프 작성, 감사 표 하나 |
| 추가되는 파일 | 없음 | `docs/swarm/` (인수 시 삭제) |
| 새로 생기는 실패 지점 | — | 브리프 품질. 감사와 재계획 회차가 흡수 |

## 12. 열린 질문 (사용자 확인 필요)

| 질문 | 현재 선택 | 대안 |
|---|---|---|
| 웨이브마다 dispatcher가 자동 커밋해도 되는가 | 예(전용 브랜치에서) | 커밋 없이 status.md만 기록 |
| `docs/swarm/`를 인수 시 지우는가 | 예(git이 보존) | 마지막 계획만 남김 |
| 브리프 언어 | 한국어(경로·명령 원문) | 영어 |
| 오케스트레이터 모델 | `gemini-3.8-flash-medium` 권장 | flash-low(더 쌈, 미검증) |
| Antigravity 앱에서의 `/swarm-run` | 문서 기준으로 같은 발견 규칙, 미검증 | CLI만 지원으로 명시 |
| 오케스트레이터가 flash-low 로도 안정적인가 | medium만 실측(성공) | flash-low 실측 후 권장값 조정 |
