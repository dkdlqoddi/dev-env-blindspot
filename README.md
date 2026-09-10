# dev-env-blindspot — `antigravity-pure` 브랜치

모든 프로젝트가 공통으로 쓰는 Google Antigravity Agent/Skill 모음. Thariq의 Unknown Unknowns 탐색과 3계층 문서화 라이프사이클부터 Antigravity 스웜 병렬 실행까지, **계획부터 실행까지 모든 과정이 Google Antigravity 단독 환경에서 진행**된다.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다. `main` 브랜치의 3계층 문서화 및 인터뷰·사각지대·보고 기능과 `antigravity-swarm` 브랜치의 스웜 분업 기능을 **완전한 Google Antigravity 단일 하네스 체제**로 통합했다.

## 0. 이 브랜치의 의도

`main`은 Claude Code에서 직렬로 실행했고, `antigravity-swarm`은 계획은 Claude Code에서, 실행은 Antigravity에서 진행하는 이원화 구조였습니다. 하지만 두 도구를 오가는 것은 컨텍스트 전환 비용과 환경 설정의 복잡도를 유발합니다.

`antigravity-pure` 브랜치는 **Claude Code 의존성을 완전히 제거**하고, 오직 Google Antigravity 메인 세션과 서브에이전트만으로 계획-실행-감사-보고 전 과정을 수행합니다.

| 성격 | 실행 주체 | 모델 | 단계 |
|---|---|---|---|
| **판단** — 한 번, 전체 맥락으로 | Antigravity 메인 세션 | 고성능 (Pro / Strong) | 인터뷰, 사각지대 점검, 스펙 작성, 스웜 **계획**, 결과 **감사**, 보고·퀴즈 |
| **실행** — 여러 번, 맥락 없이, 병렬로 | Antigravity 서브에이전트 | 고속 (Gemini Flash) | 브리프대로 구현(`swarm-worker`), 검증 명령 단독 실행(`swarm-checker`), 코드 탐색 등 |

```
Google Antigravity 메인 세션 (강한 모델)          Google Antigravity 서브에이전트 (고속 Flash)
─────────────────────────────────────             ─────────────────────────────────────────
① requirements-interview ─┐
② blindspot-pass          ├─ 3계층 문서에 기록 (Tier 1 rules.md / Tier 2 map.md / Tier 3 specs/*.md)
③ explainer               ─┘
④ swarm-plan  ──── docs/swarm/plan.md ──────────▶ /swarm-run
                   docs/swarm/tasks/T01.md          ├─ 웨이브 1: worker T01 ‖ worker T02 ‖ worker T03
                   docs/swarm/tasks/T02.md          │            └ checker: 전체 검증 → git commit
                   …                                ├─ 웨이브 2: worker T04 ‖ worker T05
                                                    │            └ checker → git commit
   swarm-review ◀── docs/swarm/status.md ───────────┘
   (swarm-auditor)  docs/swarm/results/*.md
        │ 실패·이탈 → ④ 재계획 회차
        ▼
⑤ work-report 보고 모드 → docs/quiz.html 통과 → 머지
```

설계 원칙 네 가지:

1. **판단은 위로, 지시는 아래로.** 빠른 모델이 결정을 내리는 순간이 없어야 한다. 브리프는 "필요하면 …"이 없는 자기완결 문서고, 스펙 없이는 계획을 쓰지 않는다.
2. **인터페이스는 파일.** 계획·브리프·상태·결과가 전부 `docs/swarm/` 아래 마크다운이라 투명하게 검토할 수 있다. 인수(퀴즈 통과) 시 작업 노트와 함께 지운다.
3. **충돌은 구조로 막는다.** 워커들은 같은 작업 트리를 공유하고 서로 대화하지 않는다. 대신 한 웨이브 안의 작업은 소유 파일이 겹치지 않고, 두 작업이 함께 쓰는 인터페이스는 각 브리프에 원문으로 박힌다. `swarm_check.py`가 실행 전에 기계적으로 검사한다.
4. **게이트는 하나.** 사람의 확인과 이해는 타협하지 않는다. 스웜 결과도 감사를 거쳐 기존 머지 전 퀴즈를 통과해야 머지한다.

## 1. 설치 (처음 한 번)

소비하려는 프로젝트의 루트에서:

```bash
git submodule add -b antigravity-pure https://github.com/dkdlqoddi/dev-env-blindspot.git .agents/shared
bash .agents/shared/install.sh
```

*(참고: 기존 `install-antigravity.sh`를 실행해도 동일하게 `install.sh`로 연결되어 정상 작동합니다)*

`install.sh`가 하는 일 (멱등):
- `.agents/skills/`에 8개 스킬 개별 상대 심링크
- `.agents/agents/`에 8개 서브에이전트 개별 상대 심링크
- `.agents/rules/`에 상시 주입 규칙(`mandate.md`) 개별 상대 심링크
- `AGENTS.md` 및 `ANTIGRAVITY.md`에 `@.agents/shared/MANDATE.md` import 추가

확인:

```bash
ls .agents/skills/   # blindspot-flow blindspot-pass explainer requirements-interview swarm-plan swarm-review swarm-run work-report (8개)
ls .agents/agents/   # 8개 에이전트 (.md)
ls .agents/rules/    # mandate.md
```

생성된 파일들(`.gitmodules`, `.agents/`, `AGENTS.md`)을 커밋하면 팀원도 같은 환경을 받습니다.

## 2. 사용법

### 문서 3계층

| 계층 | 경로 | 담는 것 |
|---|---|---|
| Tier 1 Global Rules | `docs/<영역>/rules.md` | 불변 규칙, 관례, 표준 명령, 용어 (60줄 이하) |
| Tier 2 System Map | `docs/<영역>/map.md` | 단위 목록과 위치, 주요 흐름, 통합 지점, 위험 (150줄 이하) |
| Tier 3 Detail Spec | `docs/<영역>/specs/<단위>.md` | 단위 하나의 목적, 요구사항, 동작, 결정 기록, 엣지케이스, 범위 제외, 열린 질문, 변경 이력 (200줄 이하) |

영역은 `docs/` 아래 `map.md`를 가진 폴더(`frontend`, `backend`, 둘 다 아니면 `core`). 첫 실행 때 `blindspot-pass`가 부트스트랩합니다.

### 방법 A — 평소처럼 말하기 (자동 트리거)

| 이렇게 말하면 | 발동하는 skill |
|---|---|
| "로그인 기능 추가하고 싶어" | `requirements-interview` |
| "내가 모르는 게 뭐지?" / 맵 없음 / "맵 갱신해줘" | `blindspot-pass` |
| "지금까지 결정한 거 문서로 정리해줘" | `explainer` |
| "스웜으로 나눠줘" / "병렬로 구현하게 계획 짜줘" | `swarm-plan` |
| `/swarm-run` / "스웜 실행해줘" / "이어서 실행" | `swarm-run` |
| "스웜 결과 검토해줘" (status.md가 끝남) | `swarm-review` |
| "작업 끝났어, 보고서 만들어줘" / 머지 직전 | `work-report` 보고 모드 |

### 방법 B — 전체 라이프사이클 한 번에 (`blindspot-flow`)

```
카테고리별 월 예산 한도 기능을 추가하고 싶어. blindspot-flow로 진행해줘.
```

```
⓪ (맵이 없으면) blindspot-pass  코드 스캔 → rules.md·map.md
① requirements-interview        질문에 하나씩 답하면 → 명세에 요구사항·결정
② blindspot-pass                병렬 스캔 → 놓친 결정 확인 → 규칙·맵·명세
③ explainer                     명세의 목적·동작·범위 제외 완성
④ 구현 — 이 세션 직접 구현 / Antigravity 스웜 병렬 구현 중 선택
     스웜: swarm-plan → /swarm-run → swarm-review
           실패·이탈이 있으면 swarm-plan 재계획 회차 → /swarm-run 재개
⑤ work-report 보고 모드         diff 분석 + 명세·맵 반영 + Pre-Merge Quiz → 통과 시 변경 이력, 노트·docs/swarm 삭제
```

### ④ 스웜 단계 자세히

**`swarm-plan`** — 스펙(요구사항·동작 방식)이 있어야 시작합니다. `codebase-scanner`로 닿는 파일과 참고 코드를 모은 뒤 작업을 나눕니다.
- 작업 하나 = 빠른 모델이 브리프만 읽고 끝낼 수 있는 크기.
- 웨이브 = 동시에 도는 작업 묶음. 소유 파일이 서로 겹치지 않아야 합니다.
- `python3 .agents/skills/swarm-plan/scripts/swarm_check.py docs/swarm/plan.md`로 유효성을 검증합니다.

**`/swarm-run`** — Antigravity 세션에서 슬래시 커맨드 `/swarm-run`을 입력하거나 CLI에서 실행합니다:
```bash
agy --add-dir "$PWD" -p '/swarm-run' --model gemini-3.8-flash-medium --dangerously-skip-permissions --print-timeout 60m
```
dispatcher는 웨이브마다 `invoke_subagent`로 `swarm-worker`를 동시에 띄우고, 웨이브가 끝나면 `swarm-checker`로 전체 검증을 수행하고 커밋합니다.

**`swarm-review`** — `swarm-auditor`가 작업별 완료 주장을 brief 및 diff와 대조하여 판정표를 만들고, 결정을 `docs/notes/<slug>.md`로 옮긴 뒤 `work-report` 보고 모드로 인계합니다.

### 산출물 위치

```
docs/
├── frontend/ · backend/ · core/   # 3계층
├── notes/<slug>.md                # 작업 노트 — 인수 시 삭제
├── swarm/                         # 계획 패키지 + 실행 기록 — 인수 시 삭제
│   ├── plan.md                    #   목표, 작업 표(id·역할·웨이브·선행), 회차   ← swarm-plan
│   ├── tasks/T01.md …             #   자기완결 브리프                           ← swarm-plan
│   ├── status.md                  #   작업별 상태·시도·커밋, 웨이브 검증 결과     ← swarm-run
│   └── results/T01.md …           #   상태, 바꾼 파일, 검증, 결정, 막힌 것       ← swarm-worker
└── quiz.html                      # 최신 Pre-Merge Quiz — 덮어씀
```

### Pre-Merge Quiz

`docs/quiz.html`을 브라우저로 열어 전부 맞히기 전에는 머지하지 않습니다. 통과 기록은 명세의 '변경 이력'에 한 줄로 남습니다.

## 3. 모델 권장

| 자리 | 권장 모델 | 이유 |
|---|---|---|
| Antigravity 메인 세션 | Pro / Strong model | 계획과 감사의 품질이 작업 전체의 품질을 결정 |
| Antigravity dispatcher (`--model`) | `gemini-3.8-flash-medium` | 표 읽고 dispatch 및 기록만 수행 |
| 워커·checker·탐색 (서브에이전트) | `flash` | 자기완결 지시를 고속 병렬로 수행 |

## 4. 업데이트

```bash
git submodule update --remote .agents/shared
bash .agents/shared/install.sh
```

## 5. 제공 Skill / Agent

### Skills (8종)

| Skill | 용도 | 갱신하는 문서 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 | `specs/<단위>.md` 요구사항·결정 기록·열린 질문 |
| `blindspot-pass` | 병렬 스캔으로 Unknown Unknowns를 질문으로 구체화. 맵 없으면 부트스트랩 | `rules.md`, `map.md`, `specs/<단위>.md` |
| `explainer` | 결정·대안·범위 제외를 담은 상세 명세 완성 | `specs/<단위>.md`, `map.md` |
| `swarm-plan` | 스펙을 웨이브·브리프로 분해, `swarm_check.py` 검사, 인계 | `docs/swarm/plan.md`, `docs/swarm/tasks/`, notes |
| `swarm-run` | 계획 표를 읽어 웨이브별로 워커를 동시에 띄우고 검증·커밋·기록 | `docs/swarm/status.md`, `docs/swarm/results/` |
| `swarm-review` | 스웜 결과 감사 → 노트 반영 → 수용 / 재계획 라우팅 | `docs/notes/<slug>.md` |
| `work-report` | 구현 중 결정 즉시 기록(노트) / diff 분석 + 명세 반영 + 퀴즈 생성(보고) | `docs/notes/`, `docs/quiz.html`, 명세 변경 이력 |
| `blindspot-flow` | 전체 라이프사이클을 순서대로 오케스트레이션 | (하위 skill 산출물) |

### Agents (8종)

| Agent | 권한 | 역할 |
|---|---|---|
| `codebase-scanner` | 읽기 전용 | 렌즈별 코드베이스 탐색 (structure, conventions, integration-points 등) |
| `domain-researcher` | 읽기 전용 (웹) | 도메인 지식 웹 리서치 (search_web, read_url_content) |
| `doc-verifier` | 읽기 전용 | 문서의 placeholder, 모순, 모호성, 스코프, 계층 적합성 검증 |
| `change-analyzer` | 읽기 전용 | base 대비 git diff 분석 및 명세·맵 대조 |
| `check-runner` | 읽기 전용 | 프로젝트 표준 검사(테스트, 린트) 실행 후 실패만 요약 |
| `swarm-auditor` | 읽기 전용 | 스웜 브리프-결과-diff 대조 감사 (범위 이탈, 미완, 검증 불일치 판정) |
| `swarm-worker` | 쓰기 허용 | 단일 브리프 전담 구현 (소유 파일 내 수정, 결과 파일 작성) |
| `swarm-checker` | 읽기 전용 | 전체 검증 명령 실행 후 통과/실패 결과 반환 |

## 6. 규칙

- 산출물은 전부 한국어. 3계층 문서, `docs/notes/`, `docs/swarm/`, `docs/quiz.html`에만 저장한다
- 스펙 없이 스웜 계획을 쓰지 않는다. 계획은 프롬프트가 아니라 명세에서 나온다
- 한 웨이브 안의 소유 파일은 겹치지 않는다. 두 작업이 함께 쓰는 인터페이스는 각 브리프에 원문으로 적는다
- 워커는 소유 파일 밖을 고치지 않고, 임의 판단을 내리지 않는다. 막히면 결과 파일에 적고 멈춘다
- dispatcher는 브리프·소스·로그를 읽지 않는다. 웨이브 검증이 재시도 후에도 실패하면 멈춘다
- Pre-Merge Quiz를 전부 맞히기 전에는 머지 금지

## 7. 이 저장소 개발 및 검증

```bash
bash test/check.sh
```

모든 테스트는 `test/check.sh` 스크립트 하나로 실행되며 다음을 보장합니다:
1. 세션 주입 훅(`mandate.sh`)의 8개 스킬 및 3계층 경로 출력 검증
2. 8개 스킬, 8개 서브에이전트, 1개 규칙의 Antigravity 규격 및 도구 허용목록 검증
3. 스킬↔서브에이전트 상호 참조 및 `MANDATE.md` 규칙 2의 참조 무결성
4. 가독성 표준(`25 어절`) 4개 사본 보존 검증
5. `install.sh` 및 `install-antigravity.sh`의 온보딩 멱등성 및 심링크 검증
6. `docs_check.py` 템플릿 검사 및 오류 탐지(negative fixture)
7. 퇴역/레거시 경로 잔존 방지
8. 템플릿 헤딩 및 불릿 계약 검증
9. `MANDATE.md` 60줄 이하 상한(48줄) 준수 검증
10. `swarm_check.py` 정상 패키지 및 7가지 오류 패키지 검증

설계 문서:
- 순수 Antigravity 일원화 설계: `docs/superpowers/specs/2026-09-10-antigravity-pure-design.md`
- 스웜 분업 설계: `docs/superpowers/specs/2026-09-08-antigravity-swarm-design.md`
- 3계층 문서 설계: `docs/superpowers/specs/2026-09-07-three-tier-docs-design.md`
