# dev-env-blindspot

모든 프로젝트가 공통으로 쓰는 Antigravity Agent/Skill 모음 — 사용자 요구사항 이해, Unknown Unknowns 구체화, 문서 작성, 작업사항 보고.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다.

**핵심 아이디어**: 프롬프트는 실제 요구사항의 불완전한 지도일 뿐이다("the map is not the territory"). 이 도구는 코딩을 시작하기 *전에* 당신이 모르는 것(Unknown Unknowns)을 질문으로 바꿔서 해소하고, 작업이 끝나면 리뷰어가 놓치면 안 되는 것을 퀴즈로 확인시킨다.

## 1. 설치 (처음 한 번)

소비하려는 프로젝트의 루트에서 다음 명령을 실행하여 서브모듈로 추가합니다:

```bash
mkdir -p .agents/plugins
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .agents/plugins/dev-env-blindspot
```

그리고 프로젝트의 `.agents/AGENTS.md` 파일에 다음 문장을 추가하여 작업 규칙을 주입합니다:

> "항상 `.agents/plugins/dev-env-blindspot/MANDATE.md`의 워크플로우 규칙을 따르라"

설치가 잘 됐는지 확인:

```bash
ls .agents/plugins/dev-env-blindspot/skills/            # blindspot-flow 등 5개 폴더가 보여야 함
cat .agents/plugins/dev-env-blindspot/plugin.json       # 플러그인 설정이 보여야 함
```

마지막으로 생성/변경된 파일들(`.gitmodules`, `.agents/`)을 커밋하면 팀원들도 같은 환경을 받는다.

## 2. 사용법

설치 후 **새로 시작하는 Antigravity 세션부터** 자동 적용된다. AGENTS.md에 추가한 참조 문장을 통해 "이런 작업에는 이 skill을 쓰라"는 규칙을 주입한다.

### 방법 A — 그냥 평소처럼 말하기 (자동 트리거)

작업 유형을 인식하면 Antigravity가 해당 skill을 스스로 호출한다:

| 이렇게 말하면 | 발동하는 skill | 무슨 일이 일어나나 |
|---|---|---|
| "로그인 기능 추가하고 싶어" | `requirements-interview` | 코드를 먼저 스캔한 뒤, 아키텍처에 영향 큰 질문부터 **한 번에 하나씩** 물어보고 요구사항 문서를 만든다 |
| "이 코드베이스 처음인데 뭘 조심해야 하지?" / "내가 모르는 게 뭐지?" | `blindspot-pass` | 4개 관점(관례/유사기능/통합지점/엣지케이스)으로 병렬 스캔하고 — 코드 밖 도메인 지식이 필요하면 웹 리서치(domain-researcher)로 보강해서 — 놓치기 쉬운 것들을 "결정 가능한 질문"으로 바꿔 확인받는다 |
| "지금까지 결정한 거 문서로 정리해줘" | `explainer` | 결정사항·기각한 대안·의도적으로 뺀 것까지 담긴 독립 설계 문서를 만든다 |
| (구현을 시작하면 자동) | `work-report` 노트 모드 | 비자명한 결정을 내릴 때마다 구현 노트에 즉시 기록한다 |
| "작업 끝났어, 보고서 만들어줘" / 머지 직전 | `work-report` 보고 모드 | diff를 분석해 보고서 + **Pre-Merge Quiz**(HTML)를 생성한다 |

### 방법 B — 전체 라이프사이클 한 번에 (`blindspot-flow`)

새 기능을 처음부터 끝까지 이 체계로 진행하고 싶으면:

```
카테고리별 월 예산 한도 기능을 추가하고 싶어. blindspot-flow로 진행해줘.
```

그러면 아래 순서로 진행되며, **각 단계 사이마다 계속할지 물어본다** (이미 산출물이 있는 단계는 재사용을 제안):

```
① requirements-interview  코드 스캔 → 질문에 하나씩 답하면 → 요구사항 문서
② blindspot-pass          병렬 스캔 → 놓친 결정사항 확인 → unknowns 문서
③ explainer               설계 문서 (대안·범위 제외 포함)
④ (구현 진행)             결정할 때마다 구현 노트 자동 기록
⑤ work-report 보고 모드   보고서 + Pre-Merge Quiz 생성
```

사용자가 할 일은 **질문에 답하는 것**뿐이다. 질문은 객관식 위주로, 한 번에 하나씩 온다.

### 산출물은 어디에 생기나

전부 한국어로, 프로젝트의 `docs/blindspot/` 아래에 생긴다:

```
docs/blindspot/
├── 2026-07-06-budget-limit-requirements.md   ① 요구사항 (4분면 표 포함)
├── 2026-07-06-budget-limit-unknowns.md       ② 해소된/미해소 unknowns
├── 2026-07-06-budget-limit-explainer.md      ③ 설계 문서
├── budget-limit-implementation-notes.md      ④ 구현 노트 (날짜 접두사 없음)
├── 2026-07-06-budget-limit-report.md         ⑤ 작업 보고서 (Human/Agent 섹션)
└── quiz/2026-07-06-budget-limit.html         ⑤ Pre-Merge Quiz
```

### Pre-Merge Quiz 사용법

작업 완료 시 생성되는 퀴즈는 "리뷰어가 이 변경에서 반드시 이해해야 할 것"(동작 변화·위험 지점·계획 이탈)을 묻는 객관식 4~6문항이다.

1. 브라우저로 연다 — WSL이면: `explorer.exe docs/blindspot/quiz/<파일명>.html`
2. 문항에 답하고 **정답 확인** 버튼을 누른다
3. **전부 맞히기 전에는 머지하지 않는다** — 틀린 문항은 보고서를 다시 읽고 재시도

## 3. 업데이트

이 저장소가 갱신되면, 소비 프로젝트에서:

```bash
git submodule update --remote .agents/plugins/dev-env-blindspot
```

이미 submodule이 등록된 소비 프로젝트를 새로 clone한 경우에는 먼저 초기화가 필요하다:

```bash
git submodule update --init --recursive
```

## 4. 제공 Skill (라이프사이클 순)

| Skill | 용도 | 산출물 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 (한 번에 한 질문, 아키텍처 영향 순) | `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` |
| `blindspot-pass` | codebase-scanner 병렬 스캔으로 Unknown Unknowns를 결정 가능한 질문으로 구체화 | `...-unknowns.md` |
| `explainer` | 결정사항·대안·범위 제외를 담은 독립 설계 문서 | `...-explainer.md` |
| `work-report` | (노트) 구현 중 결정 즉시 기록 / (보고) diff 분석 + Human/Agent 분리 보고서 + Pre-Merge Quiz | `...-report.md`, `quiz/*.html`, `<slug>-implementation-notes.md` |
| `blindspot-flow` | 위 전체를 순서대로 실행하는 오케스트레이터 | (하위 skill 산출물) |

## 5. 제공 Agent (모두 읽기 전용)

skill들이 탐색·검증을 위임하는 하위 에이전트로, 직접 부를 일은 거의 없다:

| Agent | 역할 |
|---|---|
| `codebase-scanner` | 렌즈(conventions/similar-features/integration-points/edge-cases)별 코드 탐색, `파일:라인` 근거 반환 |
| `domain-researcher` | 코드 밖 도메인 지식 웹 리서치 — 핵심 개념·품질 기준·함정을 출처 URL 근거와 함께 반환 |
| `doc-verifier` | 산출 문서의 placeholder·모순·모호성·범위 검사 |
| `change-analyzer` | base 대비 diff 분석: 변경 요약, 위험 지점, 테스트 유무, 퀴즈 후보 |

## 6. 규칙

- 산출물은 전부 한국어, `docs/blindspot/` 아래에 저장
- Pre-Merge Quiz를 전부 맞히기 전에는 머지 금지

## 7. 문제 해결

| 증상 | 원인/해결 |
|---|---|
| 플러그인 로드 안됨 | submodule이 정상적으로 초기화되었는지, `.agents/plugins/dev-env-blindspot` 경로에 있는지 확인 |
| skill이 자동으로 발동하지 않음 | `.agents/AGENTS.md`에 참조 문장이 올바르게 포함되어 있는지 확인 |

## 8. 이 저장소 개발

```bash
bash test/check.sh   # mandate 내용 검사 + frontmatter lint + plugin.json
```

설계 문서: `docs/superpowers/specs/`, 구현 계획: `docs/superpowers/plans/`, 실동작 검증 기록: `docs/blindspot/`
