# dev-env-blindspot — `claude-antigravity-cowork` 브랜치

모든 프로젝트가 공통으로 쓰는 Claude Code Agent/Skill 모음에 **Antigravity 스웜 실행**을 더한 브랜치. 요구사항 이해, Unknown Unknowns 구체화, 문서 작성, 작업 보고는 그대로 Claude Code가 맡고, **구현만** Antigravity의 빠른 모델 여러 개가 병렬로 한다.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다. 라이프사이클과 3계층 문서는 main과 같다. 달라진 것은 ④ 구현 단계와 그것을 위한 설치·스킬·에이전트다.

## 0. 이 브랜치의 의도

main의 전략은 모든 단계를 Claude Code 한 세션에서, 강한 모델 하나가 직렬로 수행한다는 전제 위에 있다. 인터뷰·사각지대 점검·설계처럼 **판단**이 필요한 단계에는 맞는 전제다. 그러나 구현은 "정해진 대로 여러 파일을 고치는" 일이 대부분이고, 그것까지 강한 모델이 한 줄씩 직렬로 하는 것은 비싸고 느리다.

이 브랜치는 단계를 비용 성격으로 나눈다.

| 성격 | 어디서 | 모델 | 단계 |
|---|---|---|---|
| **판단** — 한 번, 전체 맥락으로 | Claude Code | Opus xHigh | 인터뷰, 사각지대 점검, 설계, 스웜 **계획**, 결과 **감사**, 보고·퀴즈 |
| **실행** — 여러 번, 맥락 없이, 병렬로 | Antigravity | Gemini 3.8 Flash High (이것만) | 브리프대로 구현, 검증 명령 실행 |

두 하네스는 같은 작업 폴더의 **파일**로만 대화한다.

```
Claude Code (Opus xHigh)                      Antigravity (Gemini 3.8 Flash High)
─────────────────────────────                 ─────────────────────────────
① requirements-interview ─┐
② blindspot-pass          ├─ 3계층 문서에 기록
③ explainer               ─┘
④ swarm-plan  ──── docs/swarm/plan.md ──────▶ /swarm-run ⇄ swarm_next.py (파견·재시도·복구·커밋 결정)
                   docs/swarm/tasks/T01.md      ├─ 웨이브 1: worker T01 ‖ worker T02 ‖ worker T03
                   docs/swarm/tasks/T02.md      │            └ checker: 웨이브별 검증 → git commit
                   …                            ├─ 웨이브 2: worker T04 ‖ worker T05
                                                │            └ checker: 전체 검증 → git commit
   swarm-review ◀── docs/swarm/status.md ───────┘
   (swarm-auditor)  docs/swarm/results/*.md
        │ 실패·이탈 → ④ 재계획 회차 (두 번 실패한 작업은 Claude Code에서 직접 구현)
        ▼
⑤ work-report 보고 모드 → docs/quiz.html 통과 → 머지
```

설계 원칙 네 가지:

1. **판단은 위로, 지시는 아래로.** 빠른 모델이 결정을 내리는 순간이 없어야 한다. 브리프는 "필요하면 …"이 없는 자기완결 문서고, 스펙 없이는 계획을 쓰지 않는다. 실행 쪽에 남는 판단(무엇을 보낼지, 실패하면 누구를 다시 보낼지, 끊긴 뒤 어디서 이어 갈지)은 스크립트 `swarm_next.py`가 정하고, dispatcher는 그 출력을 옮기기만 한다.
2. **인터페이스는 파일.** 계획·브리프·상태·결과가 전부 `docs/swarm/` 아래 마크다운이라 어느 쪽에서든 읽고 검토할 수 있다. 본문은 영어(모델과 개발자만 읽는 기술 문서라 토큰이 적게 드는 쪽), 헤딩과 라벨은 스크립트가 찾는 한국어 계약이다. 인수(퀴즈 통과) 시 작업 노트와 함께 지운다.
3. **충돌은 구조로 막는다.** 워커들은 같은 작업 트리를 공유하고 서로 대화하지 않는다. 대신 한 웨이브 안의 작업은 소유 파일이 겹치지 않고, 두 작업이 함께 쓰는 이름(함수 시그니처, 파일명)은 각 브리프에 원문으로 박힌다. `swarm_check.py`가 실행 전과 재개할 때마다 git 기준으로 검사한다.
4. **게이트는 하나.** 실행 하네스가 바뀌어도 사람이 이해해야 할 것은 같다. 스웜 결과도 감사를 거쳐 기존 머지 전 퀴즈를 통과해야 머지한다.

## 1. 설치 (처음 한 번)

소비하려는 프로젝트의 루트에서:

```bash
git submodule add -b claude-antigravity-cowork https://github.com/dkdlqoddi/dev-env-blindspot.git .claude/shared
bash .claude/shared/install.sh               # Claude Code 쪽 (main과 같은 설치 + 세션 모델 고정)
bash .claude/shared/install-antigravity.sh   # Antigravity 쪽
```

`install.sh`가 하는 일 (멱등): `.claude/skills/`, `.claude/agents/` 개별 심링크, `.claude/settings.json`에 SessionStart hook 병합(매 세션 `MANDATE.md` 주입)과 세션 모델 고정(`"model": "opus"`, `"effortLevel": "xhigh"` — 프로젝트에 이미 다른 값이 있으면 지우지 않고 알림만 출력), `CLAUDE.md`에 `@.claude/shared/MANDATE.md` import.

`install-antigravity.sh`가 하는 일 (멱등): Antigravity가 자동 발견하는 `.agents/skills/`, `.agents/agents/`, `.agents/rules/`에 개별 상대 심링크 — 스킬 `swarm-run`(상태 기계 스크립트 `scripts/swarm_next.py` 포함), 서브에이전트 `swarm-worker`·`swarm-checker`, 항상 켜지는 규칙 `swarm-mandate`. 두 하네스가 같은 submodule 마운트(`.claude/shared`)를 쓴다.

확인:

```bash
ls .claude/skills/       # blindspot-flow … swarm-plan swarm-review (7개)
ls .agents/skills .agents/agents .agents/rules
grep -E '"(model|effortLevel)"' .claude/settings.json   # "model": "opus", "effortLevel": "xhigh"
```

생성된 파일들(`.gitmodules`, `.claude/`, `.agents/`, `CLAUDE.md`)을 커밋하면 팀원도 같은 환경을 받는다.

## 2. 사용법

### 문서 3계층 (main과 동일)

| 계층 | 경로 | 담는 것 |
|---|---|---|
| Tier 1 Global Rules | `docs/<영역>/rules.md` | 불변 규칙, 관례, 표준 명령, 용어 (60줄 이하) |
| Tier 2 System Map | `docs/<영역>/map.md` | 단위 목록과 위치, 주요 흐름, 통합 지점, 위험 (150줄 이하) |
| Tier 3 Detail Spec | `docs/<영역>/specs/<단위>.md` | 단위 하나의 목적, 요구사항, 동작, 결정 기록, 엣지케이스, 범위 제외, 열린 질문, 변경 이력 (200줄 이하) |

영역은 `docs/` 아래 `map.md`를 가진 폴더(`frontend`, `backend`, 둘 다 아니면 `core`). 첫 실행 때 `blindspot-pass`가 부트스트랩한다. 스웜은 이 문서를 **읽기만** 한다. 계획은 스펙에서 나오고, 워커는 계층 문서를 고치지 않는다(`swarm_check.py`가 계층 문서를 소유 파일로 둔 브리프를 막는다).

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
- 웨이브 = 동시에 도는 작업 묶음. 보통 계약·골격·테스트 → 구현 → 연결·문서·정리 순. 한 웨이브의 작업 수는 동시 실행 상한(기본 8)을 넘지 않는다.
- 웨이브마다 검증 명령을 정한다(`## 웨이브별 검증`). 구현보다 먼저 들어가는 테스트 웨이브는 수집·린트처럼 그 시점에 통과할 수 있는 명령으로 검증한다. 마지막 웨이브는 반드시 전체 검증이다.
- 한 웨이브 안 작업들의 소유 파일은 겹치지 않고, 같은 웨이브의 다른 작업이 고치는 파일을 참고 파일로 두지 않는다. 작업마다 그 작업만 끝나면 통과하는 검증 명령을 둔다.
- `(신규)`는 기준 커밋에 없는 파일을 만드는 작업의 브리프에만 붙인다. 뒤 웨이브가 그 파일을 고치면 표시 없이 적는다.
- `python3 .claude/skills/swarm-plan/scripts/swarm_check.py docs/swarm/plan.md`로 검사하고 커밋한 뒤 인계한다.

**Antigravity에서 `/swarm-run`** — 프로젝트 루트에서:

```bash
# CLI (검증됨: agy 1.2.2). --add-dir 없이는 print 모드가 .agents/ 를 읽지 않는다
agy --add-dir "$PWD" -p '/swarm-run' --model gemini-3.8-flash-high --effort high --dangerously-skip-permissions --print-timeout 60m

# 긴 스웜은 대화형이 안전하다 (타임아웃 없음)
agy --add-dir "$PWD" -i '/swarm-run' --model gemini-3.8-flash-high --effort high --dangerously-skip-permissions
```

스웜은 **Gemini 3.8 Flash High로만** 돈다. dispatcher는 실행 명령의 모델로 돌고, `swarm-worker`와 `swarm-checker`의 에이전트 파일은 모두 `model: inherit`라서 같은 모델을 물려받는다. agy 1.2.2에서 실측해 보니 에이전트 파일의 `model`이 호출 때 넘기는 값보다 우선했고, `model: flash`로 두면 `--model`과 상관없이 gemini-3.8-flash-tiered로 돌았다. `--effort high`는 모델 등급과 생각 단계를 맞추려고 함께 적는다. `--effort medium`처럼 모델과 어긋난 값을 주면 agy가 충돌 오류를 내고 실행을 시작하지 않는다. medium·low 변형이나 다른 모델로는 실행하지 않는다.

Antigravity 2.0 앱이면 프로젝트를 열고 모델 선택에서 **Gemini 3.8 Flash (High)**를 고른 뒤 채팅에 `/swarm-run`을 입력한다(문서상 같은 `.agents/` 발견 규칙, 이 브랜치에서는 CLI만 실측). agy는 실행 중인 모델을 스크립트에 알려 주지 않으므로 모델 선택은 사람이 확인해야 한다.

dispatcher(빠른 모델)는 스스로 판단하지 않는다. `swarm_next.py`를 실행하고, 출력된 JSON 그대로 `invoke_subagent`를 한 번 호출하고, 결과를 스크립트에 돌려주는 일을 반복한다.

- 웨이브마다 워커를 동시에 띄운다. 워커는 브리프와 참고 파일만 읽고, 소유 파일만 고치고, 검증을 돌리고, `docs/swarm/results/<id>.md`를 쓴다.
- 웨이브가 끝나면 checker가 그 웨이브의 검증을 돌리고 실패만 보고한다. 통과하면 웨이브를 커밋한다.
- 실패하면 실패 메시지에 나온 파일의 주인 작업만 다시 보낸다. 그래도 실패하면 웨이브 전체를 한 번 더 보낸다. 그래도 실패하면 그 웨이브를 `(검증 실패)` 커밋으로 남기고 **멈춘다** — 다음 웨이브를 깨진 바탕 위에 쌓지 않는다.
- 검증 명령이 아예 실행되지 않거나 checker 답을 읽지 못하면(`실행 불가`) 재시도 없이 멈춘다. 원인을 고치고 같은 명령을 다시 실행하면 검증부터 이어 간다.
- 중간에 끊겨도 같은 명령을 다시 실행하면 된다. 끝난 작업의 결과는 살리고, 결과 없이 끊긴 작업만 소유 파일을 마지막 커밋 상태로 되돌려 다시 보낸다. 그러니 끊긴 작업의 파일을 손으로 고쳐 두지 않는다 — 그 변경도 되돌려진다. 스웜이 소유하지 않은 파일이 바뀌어 있으면 아무것도 되돌리기 전에 멈춘다.
- `--print-timeout`이 끝나도 agy는 exit 0으로 종료되어(changelog 1.1.28, 1.2.2에서 확인) 성공처럼 보인다. `docs/swarm/status.md`의 `진행`이 `끝남`인지 확인한다.

**Claude Code에서 `swarm-review`** — `swarm-auditor`(Opus xHigh 고정)가 작업별 "완료했다"는 주장을 brief·diff와 대조해 판정표(완료 확인 / 범위 이탈 / 미완 / 검증 불일치 / 결과 없음)를 만들고, 워커의 결정을 `docs/notes/<slug>.md`로 옮긴다. 테스트를 지우거나 느슨하게 만든 diff는 검증 불일치로 잡는다. 그다음 갈래는 넷이다.

- 전부 확인이면 `work-report` 보고 모드로 넘어간다.
- 작은 결함이면 이 세션에서 고친다.
- 실패·이탈이 있으면 `swarm-plan`이 그 작업만 다시 써서(회차 2) `/swarm-run`을 재개시킨다.
- 이미 한 번 재계획했는데 또 실패한 작업은 스웜에서 빼고 이 세션에서 직접 구현한다. 세 번째 회차는 같은 실패에 비용만 더 든다.

**전용 worktree 권장** — 워커는 `--dangerously-skip-permissions`와 자동 명령 실행으로 돈다. 워커 규칙이 파괴적 명령·패키지 설치·네트워크 사용을 막지만, 사고가 나도 원래 작업 폴더가 무사하도록 스웜 사이클은 전용 브랜치의 전용 worktree에서 돌린다.

```bash
git worktree add ../myproj-swarm -b swarm/<slug>
cd ../myproj-swarm && git submodule update --init   # worktree마다 submodule을 따로 초기화한다
```

Claude Code와 agy 둘 다 이 폴더에서 연다. 두 하네스는 같은 작업 트리를 공유해야 한다.

### 산출물은 어디에 생기나

```
docs/
├── frontend/ · backend/ · core/   # 3계층 (main과 동일)
├── notes/<slug>.md                # 작업 노트 — 인수 시 삭제
├── swarm/                         # 계획 패키지 + 실행 기록 — 인수 시 삭제 (본문 영어, 라벨 한국어)
│   ├── plan.md                    #   목표, 작업 표(id·역할·웨이브·선행), 웨이브별 검증, 회차   ← swarm-plan
│   ├── tasks/T01.md …             #   자기완결 브리프                                        ← swarm-plan
│   ├── status.md                  #   작업별 상태·시도·회차·커밋, 웨이브 검증 기록              ← swarm_next.py
│   └── results/T01.md …           #   상태, 시도, 바꾼 파일, 검증, 결정, 막힌 것              ← swarm-worker
└── quiz.html                      # 최신 Pre-Merge Quiz — 덮어씀
```

### Pre-Merge Quiz (main과 동일)

`docs/quiz.html`을 브라우저로 열어(WSL: `explorer.exe docs/quiz.html`) 전부 맞히기 전에는 머지하지 않는다. 통과 기록은 명세의 '변경 이력'에 한 줄로 남는다.

## 3. 모델

모델 배치는 고정이다. Claude Code는 판단하는 자리를 Opus xHigh로, Antigravity는 스웜 전체를 Gemini 3.8 Flash High로 돌린다. medium은 어디에서도 쓰지 않는다.

| 자리 | 모델 | 지정하는 곳 | 이유 |
|---|---|---|---|
| Claude Code 세션 (인터뷰·설계·`swarm-plan`·`swarm-review`·보고) | Opus, effort xHigh | `install.sh`가 `.claude/settings.json`에 `"model": "opus"`, `"effortLevel": "xhigh"`를 넣는다 | 분해·감사·보고 품질이 스웜 전체의 품질이다. 세션 안에서 `/model`·`/effort`로 바꾸면 그 세션에만 적용된다 |
| `change-analyzer`, `swarm-auditor` | Opus, effort xHigh | 에이전트 frontmatter `model: opus`, `effort: xhigh` | 머지 게이트에 들어가는 판정이다. 세션 effort가 서브에이전트에 상속되는지는 문서에 없어 직접 고정한다 |
| `codebase-scanner`, `domain-researcher` | Sonnet | 에이전트 frontmatter `model: sonnet` | 탐색·조사. Claude 토큰을 아낀다 |
| `doc-verifier`, `check-runner` | Haiku | 에이전트 frontmatter `model: haiku` | 기계적 검사. Claude 토큰을 아낀다 |
| Antigravity dispatcher, `swarm-worker`, `swarm-checker` | Gemini 3.8 Flash High만 | CLI `--model gemini-3.8-flash-high --effort high`(앱은 모델 선택에서 Gemini 3.8 Flash (High)), 에이전트 파일은 모두 `model: inherit` | 스웜 전체가 실행 모델 하나를 따른다. medium·low·flash(tiered)·pro는 쓰지 않는다. `agy models`로 목록 확인 |

Claude Code 스킬 frontmatter에는 model·effort 필드가 없어서, 세션은 프로젝트 설정으로, 에이전트는 frontmatter로 고정한다.

## 4. 업데이트

```bash
git submodule update --remote .claude/shared
bash .claude/shared/install.sh && bash .claude/shared/install-antigravity.sh
```

main에서 올라오는 경우 추가로 할 일은 `install-antigravity.sh` 한 번뿐이다. 3계층 문서와 기존 스킬은 그대로다. 이미 설치한 프로젝트도 `install.sh`를 다시 실행하면 세션 모델 설정(`model`, `effortLevel`)이 추가된다.

스웜이 진행 중일 때(`docs/swarm/status.md`의 `진행: 실행 중`)는 submodule을 올리지 않는다. 상태 파일 형식이 바뀌면 그 스웜을 이어서 실행할 수 없다.

## 5. 제공 Skill / Agent

### Claude Code용

| Skill | 용도 | 갱신하는 문서 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 | `specs/<단위>.md` 요구사항·결정 기록·열린 질문 |
| `blindspot-pass` | 병렬 스캔으로 Unknown Unknowns를 결정 가능한 질문으로. 맵 없으면 부트스트랩 | `rules.md`, `map.md`, `specs/<단위>.md` |
| `explainer` | 결정·대안·범위 제외를 담은 상세 명세 완성 | `specs/<단위>.md`, `map.md` |
| `swarm-plan` | 스펙을 웨이브·영어 브리프·웨이브별 검증으로 분해, `swarm_check.py` 검사, 인계. 재계획 회차 | `docs/swarm/plan.md`, `docs/swarm/tasks/`, notes 한 항목 |
| `swarm-review` | 스웜 결과 감사 → 노트 반영 → 수용 / 소규모 수정 / 재계획 / 세션 직접 구현 라우팅 | `docs/notes/<slug>.md` |
| `work-report` | (노트) 구현 중 결정 즉시 기록 / (보고) diff 분석 + 명세·맵 반영 + Pre-Merge Quiz | `docs/notes/`, `docs/quiz.html`, 명세 변경 이력 |
| `blindspot-flow` | 위 전체를 순서대로 (④에서 세션/스웜 선택) | (하위 skill 산출물) |

| Agent (모두 읽기 전용) | 모델 | 역할 |
|---|---|---|
| `codebase-scanner` | Sonnet | 렌즈별 코드 탐색. swarm-plan은 integration-points·similar-features 렌즈로 닿는 파일과 따라 할 코드를 모은다 |
| `domain-researcher` | Sonnet | 코드 밖 도메인 지식 웹 리서치 |
| `doc-verifier` | Haiku | 문서의 placeholder·모순·모호성 검사 (계획·브리프에도 사용) |
| `change-analyzer` | Opus xHigh | base 대비 diff 분석. 스웜 사이클에서는 `docs/swarm/plan.md`를 계획 문서로 받아 이탈을 잰다 |
| `check-runner` | Haiku | 프로젝트 표준 검사 실행, 실패만 반환 |
| `swarm-auditor` | Opus xHigh | 작업별 완료 주장을 브리프·결과·diff와 대조. 범위 이탈, 테스트 약화, 통합 위험, 워커 결정 원문 |

### Antigravity용 (`antigravity/` 폴더, `.agents/`에 심링크)

| 이름 | 종류 | 역할 |
|---|---|---|
| `swarm-run` | skill (`/swarm-run`) | `scripts/swarm_next.py`가 출력한 동작을 옮기는 루프. 스크립트가 파견·재시도·중단 복구·커밋을 정하고 `status.md`를 쓴다. 재실행하면 이어서 한다 |
| `swarm-worker` | subagent (`model: inherit`) | 브리프 하나를 소유 파일 안에서 구현, 검증 실행, `results/<id>.md` 작성. 테스트 약화·파괴적 명령·설치·네트워크 금지 |
| `swarm-checker` | subagent (`model: inherit`, 읽기 전용) | 검증 명령을 한 번 돌리고 실패만 30줄 이내로, 스크립트가 읽는 고정 형식으로 보고 |
| `swarm-mandate` | rule (`trigger: always_on`) | 계획은 Claude Code가 쓴다, 계층 문서를 고치지 않는다, 실행 요청이 오면 `swarm-run`, 스웜은 Gemini 3.8 Flash High로만 |

## 6. 규칙

- 사람이 읽는 산출물(3계층 문서, `docs/notes/`, `docs/quiz.html`, 사용자 메시지)은 한국어. `docs/swarm/` 패키지는 본문 영어, 헤딩·라벨·상태 값은 한국어. 이 경로들에만 저장한다
- 모델 배치: Claude Code 세션과 `change-analyzer`·`swarm-auditor`는 Opus xHigh, 탐색·검사 에이전트는 Sonnet·Haiku. Antigravity 스웜은 전부 Gemini 3.8 Flash High. medium은 쓰지 않는다
- 스펙 없이 스웜 계획을 쓰지 않는다. 계획은 프롬프트가 아니라 명세에서 나온다
- 한 웨이브 안의 소유 파일은 겹치지 않고, 작업 수는 동시 실행 상한 안이다. 두 작업이 함께 쓰는 인터페이스는 각 브리프에 원문으로 적는다. 웨이브마다 검증 명령이 있고 마지막 웨이브는 전체 검증이다
- 워커는 소유 파일 밖을 고치지 않고, 테스트를 약화하지 않고, 질문하지 않고, 계획을 고치지 않는다. 막히면 결과 파일에 적고 멈춘다
- dispatcher는 브리프·소스·로그를 읽지 않고 판단하지 않는다. `status.md`는 `swarm_next.py`만 쓴다. 재시도 후에도 웨이브 검증이 실패하면 멈춘다
- 한 번 재계획한 작업이 또 실패하면 스웜에서 빼고 Claude Code 세션에서 구현한다
- Pre-Merge Quiz를 전부 맞히기 전에는 머지 금지 (스웜 결과도 같다)

## 7. 문제 해결

| 증상 | 원인/해결 |
|---|---|
| `agy -p '/swarm-run'`이 "not a recognized slash command"라고 답함 | print 모드는 현재 폴더를 워크스페이스로 잡지 않는다 — `--add-dir "$PWD"`를 붙인다 |
| `subagent "swarm-worker" not found or not allowed to be invoked` | 같은 원인(`--add-dir`). swarm-run은 `.agents/agents/swarm-worker.md` 본문으로 `define_subagent`한 뒤 재시도하도록 되어 있다 |
| `--model gemini-3.8-flash-high conflicts with --effort=medium` | 모델 등급과 생각 단계가 어긋나 agy가 시작을 거부했다. `--effort high`로 실행한다 |
| 스웜 에이전트가 High가 아닌 모델로 돎 | 에이전트 파일이 모두 `model: inherit`인지(검사 2b가 강제), 명령에 `--model gemini-3.8-flash-high --effort high`가 있는지, 앱이면 모델 선택이 Gemini 3.8 Flash (High)인지 확인한다. `model: flash`면 `--model`과 무관하게 flash-tiered로 돈다 |
| `install.sh`가 `note: .claude/settings.json keeps model=...`를 출력 | 프로젝트 설정에 다른 모델·effort가 이미 있어 그대로 두었다. 이 작업 흐름은 Opus xHigh를 쓰므로, 그 값을 지운 뒤 `install.sh`를 다시 실행한다 |
| 스웜이 중간에 끊김 (print-timeout) | exit 0으로 끝나 성공처럼 보인다(changelog 1.1.28, 1.2.2에서 확인). 같은 명령을 다시 실행하면 `swarm_next.py`가 끝난 결과는 살리고, 끝나지 않은 작업만 소유 파일을 되돌려 다시 보낸다 — 그 파일에 손으로 한 변경도 되돌려진다. 긴 스웜은 대화형 `agy -i` |
| `'<path>' is marked (신규) but exists at 기준 커밋` | `(신규)`는 기준 커밋에 없는 경로에만 붙인다. 원래 있던 파일이면 표시를 뺀다 |
| `'<path>' is already created by T0n in an earlier 웨이브` | 앞 웨이브 작업이 이미 만드는 파일이다. 뒤 브리프에서는 `(신규)` 없이 적는다 |
| `웨이브 n has k tasks, more than 동시 실행 상한` | 한 웨이브의 작업 수가 상한을 넘는다. 웨이브를 나누거나 plan.md의 상한을 올린다 |
| `swarm_check.py`가 "소유 파일 overlap" 또는 "same 웨이브" | 두 작업이 같은 파일을 같은 웨이브에서 소유하거나 읽는다 — 하나로 합치거나 뒤 웨이브로 |
| 테스트 먼저 웨이브에서 스웜이 멈춤 | 그 웨이브의 웨이브별 검증이 전체 검증이면 구현 전 테스트가 실패한다 — 수집·린트처럼 그 시점에 통과할 명령으로 |
| status.md가 `전체 검증 최종 결과: 실행 불가` | 검증 명령이 시작조차 못했거나(도구 없음 등) checker 답을 읽지 못했다. 원인을 고치고 `/swarm-run`을 다시 실행하면 재파견 없이 검증부터 한다 |
| status.md가 진행 끝남·최종 결과 실패로 멈춤 | 재시도(실패 파일의 주인 → 웨이브 전체) 후에도 검증 실패. 그 웨이브는 `(검증 실패)` 커밋으로 남는다. `swarm-review` → `swarm-plan` 재계획 회차 → `/swarm-run` |
| "스웜이 소유하지 않은 변경이 트리에 있습니다" | 사용자 변경이나 워커의 범위 이탈. 커밋하거나 stash한 뒤 다시 실행한다 |
| "status.md가 이전 버전의 형식입니다" | 스웜 도중 submodule을 올렸다. submodule을 이전 커밋으로 되돌려 그 스웜을 끝낸 뒤 다시 올린다 |
| 워커가 소유 파일 밖을 고침 | `swarm-auditor`가 범위 이탈로 잡는다. 브리프의 소유 파일을 넓히거나 작업을 나눈다 |
| Antigravity 쿼터 초과 | 동시 실행 상한(plan.md)을 낮추거나 웨이브를 늘린다. 모델 등급은 낮추지 않는다. 쿼터는 앱·CLI·SDK가 공유 |
| 웨이브 커밋에 `__pycache__` 같은 산출물이 섞임 | `swarm_next.py`는 `git add -A`로 커밋한다 — 프로젝트 `.gitignore`가 막아야 한다. 감사에서 주인 없음 파일로 잡힌다 |
| `install.sh`·심링크·JSON 오류 | main README와 동일 — submodule 초기화(`git submodule update --init --recursive`) 후 재실행 |

## 8. 이 저장소 개발

```bash
bash test/check.sh   # main의 11개 검사 + 판정 에이전트 Opus xHigh 고정(2) + Antigravity 파일 frontmatter·model inherit·도구 허용목록(2b) + 설치 멱등성·세션 모델 설정·설치 경로의 swarm_next.py(5) + 스웜 템플릿 계약(8) + swarm_check git 기준 정상·음성 fixture(12) + swarm_next 상태 전이 시나리오(13, test/swarm_scenario.py)
```

skill/agent를 추가·제거하면 `test/check.sh`의 파일 수(`-eq 13`, Antigravity `-eq 4`)와 `MANDATE.md` 매핑표를 함께 갱신한다 (`CLAUDE.md`의 Consumer contract 참고).

설계 문서: `docs/superpowers/specs/2026-09-08-antigravity-swarm-design.md` (두 하네스 분업의 결정과 대안, agy 1.1.27 실측)와 후속 `docs/superpowers/specs/2026-09-14-swarm-hardening-design.md` (외부 리뷰 반영, swarm_next.py 상태 기계, 모델 고정, agy 1.2.2 실측). 이 저장소 자체의 3계층 문서: `docs/core/`. main의 설계 이력: `docs/superpowers/specs/`, 3계층 이전 이력: `docs/blindspot/`.
