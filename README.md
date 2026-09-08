# dev-env-blindspot — `antigravity-swarm` 브랜치

모든 프로젝트가 공통으로 쓰는 Claude Code Agent/Skill 모음에 **Antigravity 스웜 실행**을 더한 브랜치. 요구사항 이해, Unknown Unknowns 구체화, 문서 작성, 작업 보고는 그대로 Claude Code가 맡고, **구현만** Antigravity의 빠른 모델 여러 개가 병렬로 한다.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다. 라이프사이클과 3계층 문서는 main과 같다. 달라진 것은 ④ 구현 단계와 그것을 위한 설치·스킬·에이전트다.

## 0. 이 브랜치의 의도

main의 전략은 모든 단계를 Claude Code 한 세션에서, 강한 모델 하나가 직렬로 수행한다는 전제 위에 있다. 인터뷰·사각지대 점검·설계처럼 **판단**이 필요한 단계에는 맞는 전제다. 그러나 구현은 "정해진 대로 여러 파일을 고치는" 일이 대부분이고, 그것까지 강한 모델이 한 줄씩 직렬로 하는 것은 비싸고 느리다.

이 브랜치는 단계를 비용 성격으로 나눈다.

| 성격 | 어디서 | 모델 | 단계 |
|---|---|---|---|
| **판단** — 한 번, 전체 맥락으로 | Claude Code | 고성능 (Fable / Opus) | 인터뷰, 사각지대 점검, 설계, 스웜 **계획**, 결과 **감사**, 보고·퀴즈 |
| **실행** — 여러 번, 맥락 없이, 병렬로 | Antigravity | 저성능 고속 (Gemini Flash) | 브리프대로 구현, 검증 명령 실행 |

두 하네스는 같은 작업 폴더의 **파일**로만 대화한다.

```
Claude Code (고성능)                          Antigravity (고속 Flash)
─────────────────────────────                 ─────────────────────────────
① requirements-interview ─┐
② blindspot-pass          ├─ 3계층 문서에 기록
③ explainer               ─┘
④ swarm-plan  ──── docs/swarm/plan.md ──────▶ /swarm-run
                   docs/swarm/tasks/T01.md      ├─ 웨이브 1: worker T01 ‖ worker T02 ‖ worker T03
                   docs/swarm/tasks/T02.md      │            └ checker: 전체 검증 → git commit
                   …                            ├─ 웨이브 2: worker T04 ‖ worker T05
                                                │            └ checker → git commit
   swarm-review ◀── docs/swarm/status.md ───────┘
   (swarm-auditor)  docs/swarm/results/*.md
        │ 실패·이탈 → ④ 재계획 회차
        ▼
⑤ work-report 보고 모드 → docs/quiz.html 통과 → 머지
```

설계 원칙 네 가지:

1. **판단은 위로, 지시는 아래로.** 빠른 모델이 결정을 내리는 순간이 없어야 한다. 브리프는 "필요하면 …"이 없는 자기완결 문서고, 스펙 없이는 계획을 쓰지 않는다.
2. **인터페이스는 파일.** 계획·브리프·상태·결과가 전부 `docs/swarm/` 아래 마크다운이라 어느 쪽에서든 읽고 검토할 수 있다. 인수(퀴즈 통과) 시 작업 노트와 함께 지운다.
3. **충돌은 구조로 막는다.** 워커들은 같은 작업 트리를 공유하고 서로 대화하지 않는다. 대신 한 웨이브 안의 작업은 소유 파일이 겹치지 않고, 두 작업이 함께 쓰는 이름(함수 시그니처, 파일명)은 각 브리프에 원문으로 박힌다. `swarm_check.py`가 실행 전에 기계적으로 검사한다.
4. **게이트는 하나.** 실행 하네스가 바뀌어도 사람이 이해해야 할 것은 같다. 스웜 결과도 감사를 거쳐 기존 머지 전 퀴즈를 통과해야 머지한다.

## 1. 설치 (처음 한 번)

소비하려는 프로젝트의 루트에서:

```bash
git submodule add -b antigravity-swarm https://github.com/dkdlqoddi/dev-env-blindspot.git .claude/shared
bash .claude/shared/install.sh               # Claude Code 쪽 (main과 동일)
bash .claude/shared/install-antigravity.sh   # Antigravity 쪽
```

`install.sh`가 하는 일 (멱등): `.claude/skills/`, `.claude/agents/` 개별 심링크, `.claude/settings.json`에 SessionStart hook 병합(매 세션 `MANDATE.md` 주입), `CLAUDE.md`에 `@.claude/shared/MANDATE.md` import.

`install-antigravity.sh`가 하는 일 (멱등): Antigravity가 자동 발견하는 `.agents/skills/`, `.agents/agents/`, `.agents/rules/`에 개별 상대 심링크 — 스킬 `swarm-run`, 서브에이전트 `swarm-worker`·`swarm-checker`, 항상 켜지는 규칙 `swarm-mandate`. 두 하네스가 같은 submodule 마운트(`.claude/shared`)를 쓴다.

확인:

```bash
ls .claude/skills/       # blindspot-flow … swarm-plan swarm-review (7개)
ls .agents/skills .agents/agents .agents/rules
```

생성된 파일들(`.gitmodules`, `.claude/`, `.agents/`, `CLAUDE.md`)을 커밋하면 팀원도 같은 환경을 받는다.

## 2. 사용법

### 문서 3계층 (main과 동일)

| 계층 | 경로 | 담는 것 |
|---|---|---|
| Tier 1 Global Rules | `docs/<영역>/rules.md` | 불변 규칙, 관례, 표준 명령, 용어 (60줄 이하) |
| Tier 2 System Map | `docs/<영역>/map.md` | 단위 목록과 위치, 주요 흐름, 통합 지점, 위험 (150줄 이하) |
| Tier 3 Detail Spec | `docs/<영역>/specs/<단위>.md` | 단위 하나의 목적, 요구사항, 동작, 결정 기록, 엣지케이스, 범위 제외, 열린 질문, 변경 이력 (200줄 이하) |

영역은 `docs/` 아래 `map.md`를 가진 폴더(`frontend`, `backend`, 둘 다 아니면 `core`). 첫 실행 때 `blindspot-pass`가 부트스트랩한다. 스웜은 이 문서를 **읽기만** 한다. 계획은 스펙에서 나오고, 워커는 계층 문서를 고치지 않는다.

### 방법 A — 평소처럼 말하기 (자동 트리거)

| 이렇게 말하면 | 발동하는 skill | 어디서 |
|---|---|---|
| "로그인 기능 추가하고 싶어" | `requirements-interview` | Claude Code |
| "내가 모르는 게 뭐지?" / 맵 없음 / "맵 갱신해줘" | `blindspot-pass` | Claude Code |
| "지금까지 결정한 거 문서로 정리해줘" | `explainer` | Claude Code |
| "스웜으로 나눠줘" / "병렬로 구현하게 계획 짜줘" | `swarm-plan` | Claude Code |
| `/swarm-run` / "스웜 실행해줘" / "이어서 실행" | `swarm-run` | **Antigravity** |
| "스웜 결과 검토해줘" (status.md가 끝남) | `swarm-review` | Claude Code |
| "작업 끝났어, 보고서 만들어줘" / 머지 직전 | `work-report` 보고 모드 | Claude Code |

### 방법 B — 전체 라이프사이클 한 번에 (`blindspot-flow`)

```
카테고리별 월 예산 한도 기능을 추가하고 싶어. blindspot-flow로 진행해줘.
```

```
⓪ (맵이 없으면) blindspot-pass  코드 스캔 → rules.md·map.md
① requirements-interview        질문에 하나씩 답하면 → 명세에 요구사항·결정
② blindspot-pass                병렬 스캔 → 놓친 결정 확인 → 규칙·맵·명세
③ explainer                     명세의 목적·동작·범위 제외 완성
④ 구현 — 이 세션 / Antigravity 스웜 중 선택
     스웜: swarm-plan → (Antigravity) /swarm-run → swarm-review
           실패·이탈이 있으면 swarm-plan 재계획 회차 → /swarm-run 재개
⑤ work-report 보고 모드         diff 분석 + 명세·맵 반영 + Pre-Merge Quiz → 통과 시 변경 이력, 노트·docs/swarm 삭제
```

### ④ 스웜 단계 자세히

**Claude Code에서 `swarm-plan`** — 스펙(요구사항·동작 방식)이 있어야 시작한다. codebase-scanner로 닿는 파일과 따라 할 기존 코드를 모은 뒤 작업을 나눈다.

- 작업 하나 = 빠른 모델이 브리프만 읽고 끝낼 수 있는 크기. 역할을 다양하게(구현, 테스트 작성, 문서 갱신, 마이그레이션, 정리).
- 웨이브 = 동시에 도는 작업 묶음. 보통 계약·골격·테스트 → 구현 → 연결·문서·정리 순.
- 한 웨이브 안 작업들의 소유 파일은 겹치지 않는다. 작업마다 스스로 돌릴 수 있는 검증 명령을 둔다.
- `python3 .claude/skills/swarm-plan/scripts/swarm_check.py docs/swarm/plan.md`로 검사하고 커밋한 뒤 인계한다.

**Antigravity에서 `/swarm-run`** — 프로젝트 루트에서:

```bash
# CLI (검증됨: agy 1.1.27). --add-dir 없이는 print 모드가 .agents/ 를 읽지 않는다
agy --add-dir "$PWD" -p '/swarm-run' --model gemini-3.8-flash-medium --dangerously-skip-permissions --print-timeout 60m

# 긴 스웜은 대화형이 안전하다 (타임아웃 없음)
agy --add-dir "$PWD" -i '/swarm-run' --model gemini-3.8-flash-medium --dangerously-skip-permissions
```

Antigravity 2.0 앱이면 프로젝트를 열고 채팅에 `/swarm-run`을 입력한다(문서상 같은 `.agents/` 발견 규칙, 이 브랜치에서는 CLI만 실측).

dispatcher(빠른 모델)는 계획 표만 읽고 웨이브마다 `invoke_subagent` 한 번으로 워커를 동시에 띄운다. 워커는 브리프와 참고 파일만 읽고, 소유 파일만 고치고, 검증을 돌리고, `docs/swarm/results/<id>.md`를 쓴다. 웨이브가 끝나면 checker가 전체 검증을 돌리고 실패만 보고한다. 실패면 한 번 재시도, 그래도 실패면 **멈춘다** — 다음 웨이브를 깨진 바탕 위에 쌓지 않는다. 웨이브마다 `git commit`이 남는다.

**Claude Code에서 `swarm-review`** — `swarm-auditor`가 작업별로 "완료했다"는 주장을 brief·diff와 대조해 판정표(완료 확인 / 범위 이탈 / 미완 / 검증 불일치 / 결과 없음)를 만들고, 워커의 결정을 `docs/notes/<slug>.md`로 옮긴다. 그다음 세 갈래 중 하나: 전부 확인이면 `work-report` 보고 모드로, 작은 결함이면 이 세션에서 고치고, 실패·이탈이 있으면 `swarm-plan`이 그 작업만 다시 써서(회차 2) `/swarm-run`을 재개시킨다.

### 산출물은 어디에 생기나

```
docs/
├── frontend/ · backend/ · core/   # 3계층 (main과 동일)
├── notes/<slug>.md                # 작업 노트 — 인수 시 삭제
├── swarm/                         # 계획 패키지 + 실행 기록 — 인수 시 삭제
│   ├── plan.md                    #   목표, 작업 표(id·역할·웨이브·선행), 회차   ← swarm-plan
│   ├── tasks/T01.md …             #   자기완결 브리프                           ← swarm-plan
│   ├── status.md                  #   작업별 상태·시도·커밋, 웨이브 검증 결과     ← swarm-run
│   └── results/T01.md …           #   상태, 바꾼 파일, 검증, 결정, 막힌 것       ← swarm-worker
└── quiz.html                      # 최신 Pre-Merge Quiz — 덮어씀
```

### Pre-Merge Quiz (main과 동일)

`docs/quiz.html`을 브라우저로 열어(WSL: `explorer.exe docs/quiz.html`) 전부 맞히기 전에는 머지하지 않는다. 통과 기록은 명세의 '변경 이력'에 한 줄로 남는다.

## 3. 모델 권장

| 자리 | 권장 | 이유 |
|---|---|---|
| Claude Code 세션 | Fable / Opus | 계획과 감사의 품질이 스웜 전체의 품질 |
| Antigravity dispatcher (`--model`) | `gemini-3.8-flash-medium` | 표 읽고 dispatch·기록만 한다. `agy models`로 목록 확인 |
| 워커·checker (에이전트 파일의 `model`) | `flash` | 브리프가 자기완결이면 충분. `flash_lite`도 가능(미검증) |

## 4. 업데이트

```bash
git submodule update --remote .claude/shared
bash .claude/shared/install.sh && bash .claude/shared/install-antigravity.sh
```

main에서 올라오는 경우 추가로 할 일은 `install-antigravity.sh` 한 번뿐이다. 3계층 문서와 기존 스킬은 그대로다.

## 5. 제공 Skill / Agent

### Claude Code용

| Skill | 용도 | 갱신하는 문서 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 | `specs/<단위>.md` 요구사항·결정 기록·열린 질문 |
| `blindspot-pass` | 병렬 스캔으로 Unknown Unknowns를 결정 가능한 질문으로. 맵 없으면 부트스트랩 | `rules.md`, `map.md`, `specs/<단위>.md` |
| `explainer` | 결정·대안·범위 제외를 담은 상세 명세 완성 | `specs/<단위>.md`, `map.md` |
| `swarm-plan` | 스펙을 웨이브·브리프로 분해, `swarm_check.py` 검사, 인계. 재계획 회차 | `docs/swarm/plan.md`, `docs/swarm/tasks/`, notes 한 항목 |
| `swarm-review` | 스웜 결과 감사 → 노트 반영 → 수용 / 소규모 수정 / 재계획 라우팅 | `docs/notes/<slug>.md` |
| `work-report` | (노트) 구현 중 결정 즉시 기록 / (보고) diff 분석 + 명세·맵 반영 + Pre-Merge Quiz | `docs/notes/`, `docs/quiz.html`, 명세 변경 이력 |
| `blindspot-flow` | 위 전체를 순서대로 (④에서 세션/스웜 선택) | (하위 skill 산출물) |

| Agent (모두 읽기 전용) | 역할 |
|---|---|
| `codebase-scanner` | 렌즈별 코드 탐색. swarm-plan은 integration-points·similar-features 렌즈로 닿는 파일과 따라 할 코드를 모은다 |
| `domain-researcher` | 코드 밖 도메인 지식 웹 리서치 |
| `doc-verifier` | 문서의 placeholder·모순·모호성 검사 (계획·브리프에도 사용) |
| `change-analyzer` | base 대비 diff 분석. 스웜 사이클에서는 `docs/swarm/plan.md`를 계획 문서로 받아 이탈을 잰다 |
| `check-runner` | 프로젝트 표준 검사 실행, 실패만 반환 |
| `swarm-auditor` | 작업별 완료 주장을 브리프·결과·diff와 대조. 범위 이탈, 통합 위험, 워커 결정 원문 |

### Antigravity용 (`antigravity/` 폴더, `.agents/`에 심링크)

| 이름 | 종류 | 역할 |
|---|---|---|
| `swarm-run` | skill (`/swarm-run`) | 계획 표를 읽어 웨이브별로 워커를 동시에 띄우고, checker로 검증하고, 커밋하고, `status.md`에 기록. 재개 가능 |
| `swarm-worker` | subagent (`model: flash`) | 브리프 하나를 소유 파일 안에서 구현, 검증 실행, `results/<id>.md` 작성 |
| `swarm-checker` | subagent (`model: flash`, 읽기 전용) | 전체 검증 명령을 한 번 돌리고 실패만 30줄 이내로 보고 |
| `swarm-mandate` | rule (`trigger: always_on`) | 계획은 Claude Code가 쓴다, 계층 문서를 고치지 않는다, 실행 요청이 오면 `swarm-run` |

## 6. 규칙

- 산출물은 전부 한국어. 3계층 문서, `docs/notes/`, `docs/swarm/`, `docs/quiz.html`에만 저장한다
- 스펙 없이 스웜 계획을 쓰지 않는다. 계획은 프롬프트가 아니라 명세에서 나온다
- 한 웨이브 안의 소유 파일은 겹치지 않는다. 두 작업이 함께 쓰는 인터페이스는 각 브리프에 원문으로 적는다
- 워커는 소유 파일 밖을 고치지 않고, 질문하지 않고, 계획을 고치지 않는다. 막히면 결과 파일에 적고 멈춘다
- dispatcher는 브리프·소스·로그를 읽지 않는다. 웨이브 검증이 재시도 후에도 실패하면 멈춘다
- Pre-Merge Quiz를 전부 맞히기 전에는 머지 금지 (스웜 결과도 같다)

## 7. 문제 해결

| 증상 | 원인/해결 |
|---|---|
| `agy -p '/swarm-run'`이 "not a recognized slash command"라고 답함 | print 모드는 현재 폴더를 워크스페이스로 잡지 않는다 — `--add-dir "$PWD"`를 붙인다 |
| `subagent "swarm-worker" not found or not allowed to be invoked` | 같은 원인(`--add-dir`). swarm-run은 `.agents/agents/swarm-worker.md` 본문으로 `define_subagent`한 뒤 재시도하도록 되어 있다 |
| 스웜이 중간에 끊김 (print-timeout) | `--print-timeout 60m` 또는 대화형 `agy -i`. `/swarm-run`을 다시 실행하면 `status.md`에서 재개한다 |
| `swarm_check.py`가 "소유 파일 overlap" | 두 작업이 같은 파일을 같은 웨이브에서 소유 — 하나로 합치거나 뒤 웨이브로 |
| status.md가 진행 끝남·최종 결과 실패로 멈춤 | 웨이브 검증이 재시도 후에도 실패. `swarm-review` → `swarm-plan` 재계획 회차 → `/swarm-run` |
| 워커가 소유 파일 밖을 고침 | `swarm-auditor`가 범위 이탈로 잡는다. 브리프의 소유 파일을 넓히거나 작업을 나눈다 |
| Antigravity 쿼터 초과 | 동시 실행 상한(plan.md)을 낮추거나 웨이브를 늘린다. 쿼터는 앱·CLI·SDK가 공유 |
| 웨이브 커밋에 `__pycache__` 같은 산출물이 섞임 | dispatcher는 `git add -A`로 커밋한다 — 프로젝트 `.gitignore`가 막아야 한다. 감사에서 주인 없음 파일로 잡힌다 |
| `install.sh`·심링크·JSON 오류 | main README와 동일 — submodule 초기화(`git submodule update --init --recursive`) 후 재실행 |

## 8. 이 저장소 개발

```bash
bash test/check.sh   # main의 11개 검사 + Antigravity 파일 frontmatter·도구 허용목록(2b) + install-antigravity 멱등성(5) + 스웜 템플릿 헤딩(8) + swarm_check 정상·음성 fixture(12)
```

skill/agent를 추가·제거하면 `test/check.sh`의 파일 수(`-eq 13`, Antigravity `-eq 4`)와 `MANDATE.md` 매핑표를 함께 갱신한다 (`CLAUDE.md`의 Consumer contract 참고).

설계 문서: `docs/superpowers/specs/2026-09-08-antigravity-swarm-design.md` (결정과 대안, 실측, 열린 질문). 이 저장소 자체의 3계층 문서: `docs/core/`. main의 설계 이력: `docs/superpowers/specs/`, 3계층 이전 이력: `docs/blindspot/`.
