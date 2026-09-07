# 3계층 문서 구조(Global Rules / System Map / Detail Spec) 설계

- 날짜: 2026-09-07
- 상태: 승인됨 (사용자 인터뷰 2문항 + 설계안 승인 완료, 스펙 검토 대기)
- 선행 스펙: `2026-07-06-blindspot-agents-skills-design.md` (§4 산출물 경로 계약을 이 문서가 대체)
- 설계 과정: 독립 제안 3건(context-minimalist / lifecycle-preserver / consumer-operator)과 각 제안에 대한 반박 검토 9건(information-loss / context-cost / consumer-ops)을 종합. 반박에서 설계를 바꾼 결함은 §13에 기록

## 1. 목적과 배경

현재 라이프사이클은 기능 하나를 진행할 때마다 날짜 붙은 문서를 만든다. 요구사항, unknowns, explainer, 구현 노트, 보고서, 퀴즈까지 여섯 파일이다. 같은 결정이 네 문서에 반복 기록되고, 인터뷰 스캐너는 매번 `docs/blindspot/` 전체를 훑는다. 사용자는 이것을 "ADR과 퀴즈 문서를 여러 개 생성하는 구조라 Context 낭비가 심하다"고 진단했다.

이 설계는 산출물을 **영역별 고정 3계층 문서**로 바꾼다. 문서는 늘어나지 않고 제자리에서 갱신된다.

| 계층 | 이름 | 담는 것 | 언제 읽나 |
|---|---|---|---|
| Tier 1 | Global Rules (`rules.md`) | 그 영역의 불변 규칙, 관례, 표준 명령, 용어 | 그 영역 코드를 바꾸기 전에 항상 |
| Tier 2 | System Map (`map.md`) | 단위 목록과 위치, 주요 흐름, 통합 지점, 단위 간 위험 | 위치를 찾거나 흐름을 추적할 때 |
| Tier 3 | Detail Spec (`specs/<단위>.md`) | 단위 하나의 목적, 요구사항, 동작, 결정 기록, 엣지케이스, 범위 제외, 열린 질문, 변경 이력 | 작업이 닿는 단위만 |

frontend와 backend가 각각 3계층을 온전히 가진다. 라이프사이클 스킬 다섯 개는 그대로 두되, 읽고 쓰는 대상을 전부 이 계층으로 바꾼다.

## 2. 확정된 결정사항

| # | 결정 | 선택 | 근거 |
|---|---|---|---|
| 1 | 문서 위치 | `docs/<영역>/` 아래에 3계층 전부. 영역마다 자기 rules.md | 사용자 선택. "양쪽 모두 3계층"에 가장 충실하고, 작업과 무관한 반대편 규칙을 읽지 않음 |
| 2 | 보고서 파일 | 없앰. Agent 섹션 내용은 spec으로, 사람용 요약은 퀴즈의 변경 요약과 채팅/PR 본문으로, 인수 기록은 spec 변경 이력 표 한 줄 | 사용자 선택. 보고서는 스냅샷이며 머지 후 아무도 읽지 않음 |
| 3 | 퀴즈 | `docs/quiz.html` 하나, 사이클마다 덮어씀 | 사용자 승인 트리. 통과한 퀴즈는 재독 가치가 없음 |
| 4 | 구현 노트 | `docs/notes/<slug>.md`, 결정 시점에 덧붙이고 인수 시 spec으로 승격 후 삭제 | spec에 직접 쓰면 spec이 없는 단위에서 노트 모드가 멈추고 explainer 재실행이 덮어씀. 노트 파일은 눈 감고 append만 하면 됨 |
| 5 | Tier 3 단위 | 맵의 '단위' 표 행 하나당 spec 하나. 기능이 아니라 모듈 단위 | 기능 단위면 다시 누적됨. 모듈은 고정 집합 |
| 6 | Tier 3 생성 시점 | 작업이 그 단위에 닿을 때만. 부트스트랩은 spec을 만들지 않음 | 단위마다 미리 쓰면 추측성 파일 N개가 생김 |
| 7 | 부트스트랩 담당 | `blindspot-pass` 0단계. 새 스킬 없음 | 부트스트랩은 스캔이며 blindspot-pass가 이미 스캔 팬아웃을 가짐. 스킬을 늘리면 소비자 계약이 깨짐 |
| 8 | 영역 판정 | 증거로 판정하고 결과를 진술. 애매할 때만 한 번 질문 | MANDATE 질문 정책(증거로 정할 수 있으면 묻지 않음) |
| 9 | 영역 기본 이름 | `frontend`, `backend`. 둘 다 아닌 프로젝트는 `core` 하나 | 단일 레이아웃 유지. 영역이 늘어도 이동 없음 |
| 10 | 줄 상한 | rules 60 / map 150 / spec 200 | 컨텍스트 천장을 고정하는 유일한 구조적 장치. 스크립트가 검사 |
| 11 | 검사 스크립트 | `quiz_check.py`를 `docs_check.py`로 개명·확장 | 맵을 검사하는 스크립트가 quiz라는 이름이면 다음 편집자가 헤맴 |
| 12 | 이력 처리 | 이 저장소의 `docs/blindspot/`와 소비 프로젝트의 옛 문서는 그대로 둠. 어떤 스킬도 자동으로 읽지 않음 | 이동은 churn. 수락된 산출물은 바이트 불변(2026-07-10 보고서 §제약) |
| 13 | MANDATE 크기 | 계층 표와 읽기 순서만 추가(15줄 안팎). 상세 라우팅은 각 SKILL.md에 | hook과 @import로 두 번 주입됨 |
| 14 | 언어 | 3계층 문서는 한국어. 근거·경로·명령은 원문 그대로 | 기존 산출물 언어 규칙 유지 |
| 15 | 독자 구분 | 문서 단위가 아니라 섹션 단위로 유지 (§4.4) | Human/Agent 섹션 분리의 기능을 잃지 않으면서 문서 수를 줄임 |

## 3. 소비 프로젝트 문서 구조

```
docs/
├── frontend/
│   ├── rules.md            # Tier 1 (≤60줄)
│   ├── map.md              # Tier 2 (≤150줄)
│   └── specs/
│       └── <단위>.md        # Tier 3 (≤200줄), 단위 = 맵 '단위' 표의 kebab-case 이름
├── backend/                # 동일 3계층
├── notes/
│   └── <slug>.md           # 작업 중 결정 노트. 인수 시 삭제. 진행 중 작업 수만큼만 존재
└── quiz.html               # 최신 머지 전 퀴즈. 덮어씀
```

- **영역의 정의**: `docs/` 바로 아래에서 `map.md`를 가진 폴더. 스킬은 `docs/*/map.md`로 영역을 발견한다. 별도 레지스트리 파일은 없다.
- **프로젝트 공통 규칙**은 소비 프로젝트의 CLAUDE.md가 맡는다. 3계층은 영역별 지식만 담는다.
- **영역 간 계약**(frontend↔backend API 등)은 각 영역 맵의 '통합 지점' 행이 코드 위치(OpenAPI 파일, 타입 파일 등)를 가리키는 방식으로 양쪽에 한 줄씩 적는다. 계약의 진실은 코드에 있으므로 중복 규칙이 필요 없다.
- **단일 영역 프로젝트**(CLI, 라이브러리, 이 저장소)도 같은 레이아웃을 쓴다. `docs/core/`.
- **줄 상한 초과 시**: 상한을 올리지 않는다. spec은 변경 이력의 오래된 행부터, 그다음 코드·테스트에 이미 드러난 결정 기록 행부터 지운다(git이 보존). map은 단위 설명을 spec으로 내린다. rules는 한 단위에만 해당하는 규칙을 그 단위 spec의 엣지케이스로 내린다.
- **이 저장소의 옛 산출물** `docs/blindspot/`(보고서 2, 퀴즈 2)는 3계층 이전 이력으로 그대로 둔다.

## 4. 계층별 템플릿 사양

템플릿은 한국어 산출물 텍스트와 플레이스홀더, 영어 지시 주석(`<!-- -->`)으로 구성한다. 스킬은 **헤딩 이름으로** 섹션을 찾아 쓰므로 헤딩은 계약이다(테스트 §10-9).

### 4.1 Tier 1 — `rules.md` (소유: blindspot-pass, 템플릿 `skills/blindspot-pass/templates/rules.md`)

```
# [영역] 전역 규칙 (Tier 1)

- 최종 갱신: YYYY-MM-DD
- 코드 루트: (이 영역의 코드 경로)
- 읽는 법: 이 영역의 코드를 바꾸기 전에 항상 먼저 읽는다. 60줄을 넘기지 않는다.

## 불변 규칙
| # | 규칙 | 깨지면 생기는 일 | 근거 |

## 관례
| 분류 | 관례 | 근거 |
(분류: 이름 짓기 / 폴더 구조 / 오류 처리 / 로그 / 테스트 / 의존성)

## 표준 명령
| 목적 | 명령 |
(test / lint / build / run — check-runner에 그대로 전달)

## 용어
| 용어 | 쉬운 말 설명 | 출처 |
```

쓰기 규칙: 불변 규칙·관례는 blindspot-pass(conventions 렌즈)가 만들고, requirements-interview는 답변이 영역 전체를 구속할 때 행을 추가한다. work-report는 구현 중 결정이 불변 규칙을 바꿀 때 해당 행을 고치고 이유에 결정 기록 행을 인용한다. 용어는 domain-researcher의 핵심 개념이 정착하는 곳이며 출처 URL을 반드시 남긴다. 둘 이상 단위에서 쓰는 용어만 올린다.

### 4.2 Tier 2 — `map.md` (소유: blindspot-pass, 템플릿 `skills/blindspot-pass/templates/map.md`)

```
# [영역] 시스템 맵 (Tier 2)

- 최종 갱신: YYYY-MM-DD
- 코드 루트:
- 읽는 법: 이 영역을 건드리는 작업이 rules.md 다음에 읽는다. 상세는 '단위' 표의 상세 명세로 내려간다. 150줄을 넘기지 않는다.

## 영역 개요
(3–5문장, 코드를 본 적 없는 독자 기준)

## 단위
| 단위 | 하는 일 | 위치 | 상세 명세 |
(단위 = kebab-case 이름 = specs/<단위>.md 파일명. 위치 = 경로 또는 glob. 상세 명세 = specs/<단위>.md 또는 없음)

## 주요 흐름
| 흐름 | 시작점 | 거치는 단위 순서 |

## 통합 지점
| 상대 | 방식 | 계약 위치 | 관련 단위 |
(상대 = 다른 영역, 외부 서비스, DB, CI 등)

## 알려진 위험
| 위험 | 영향 단위 | 상태 |
(둘 이상 단위에 걸친 것만. 한 단위 것은 그 단위 spec의 엣지케이스로)
```

쓰기 규칙: 단위 표는 부트스트랩(structure 렌즈)이 만들고, requirements-interview·explainer가 새 단위 행을 추가하며, work-report가 change-analyzer의 `문서 갱신 필요`에 따라 위치를 고친다. 주요 흐름은 explainer가 소유한다. 통합 지점은 integration-points 렌즈가 채우고 explainer의 코드 대조가 고친다. 새 행은 표 끝에 붙인다(병렬 브랜치 충돌을 줄 단위로 한정).

### 4.3 Tier 3 — `specs/<단위>.md` (소유: explainer, 템플릿 `skills/explainer/templates/spec.md`)

```
# [단위] 상세 명세 (Tier 3)

- 영역:
- 위치: (코드 경로, 맵 단위 표와 동일)
- 최종 갱신: YYYY-MM-DD
- 상태: 초안 | 확정
- 읽는 법: '목적과 배경', '요구사항', '동작 방식', '의도적 범위 제외'는 코드를 모르는 분도 읽을 수 있게 씁니다. 그 외는 개발자와 AI를 위한 상세입니다.

## 목적과 배경
## 요구사항
1.
## 동작 방식
## 결정 기록
| 날짜 | 결정 | 근거 | 기각한 대안 | 결정 주체 |
(결정 주체: 사용자 | 자체 | 자체(확인 필요). 행은 한 줄. 삭제하지 않고 번복은 새 행으로)
## 엣지케이스와 제약
| 상황 | 처리 | 근거 |
## 의도적 범위 제외
-
## 열린 질문
| 질문 | 해소 계획 | 재방문 시점 |
## 변경 이력
| 날짜 | 변경 요약 | 기준 커밋 | 검증 | 퀴즈 |
```

섹션별 소유와 편집 모드:

| 섹션 | 만드는 스킬 | 덧붙이는 스킬 | 고쳐 쓰는 스킬 |
|---|---|---|---|
| 목적과 배경 | requirements-interview(초안) | — | explainer |
| 요구사항 | requirements-interview | requirements-interview | — (다른 스킬은 열린 질문으로만 이의 제기) |
| 동작 방식 | explainer | work-report(구현대로 정정) | explainer |
| 결정 기록 | 누구나 | 모든 스킬(append-only) | — (explainer는 빈 '기각한 대안' 칸만 채움) |
| 엣지케이스와 제약 | blindspot-pass | blindspot-pass, work-report | — |
| 의도적 범위 제외 | explainer | work-report | explainer. work-report가 게이트 전 비어 있지 않음을 보장 |
| 열린 질문 | 누구나 | requirements-interview, blindspot-pass, explainer | 답한 스킬이 그 답을 기록하는 편집에서 행 삭제 |
| 변경 이력 | work-report | work-report(인수 후에만) | — |

- 결정 기록 행은 반드시 한 줄이고 날짜로 시작한다. 인접 단위의 결정을 `grep -h '^| 20' docs/<영역>/specs/*.md`로 문서를 열지 않고 찾기 위해서다. 이것이 "이미 답한 것은 다시 묻지 않는다"의 새 구현이다.
- spec이 없는 단위에 처음 쓰는 스킬은 템플릿의 헤딩 전체를 만들고 자기 섹션만 채운다. 나머지는 비워 둔다. 빈 섹션은 결함이 아니다(doc-verifier §7.3).
- 한 작업이 여러 단위에 닿으면: 바뀌는 파일이 가장 많이 속한 단위가 주 단위이고 요구사항·동작 방식·변경 이력은 거기에 쓴다. 다른 단위에는 그 단위에 관한 결정이나 엣지케이스가 실제로 기록될 때만 행을 붙이고, 그런 기록이 없으면 spec을 만들지 않는다. 새 모듈을 만드는 기능은 새 단위 행과 새 spec이다. 두 영역에 걸치면 영역마다 주 단위 spec 하나씩이다.

### 4.4 독자 구분(가독성 표준)

기존 표준(쉬운 말 먼저 용어 병기, 화살표·코드 구문 금지, 문장마다 사실 하나 25어절 이내, 퀴즈 보기 40자)은 그대로이고 적용 위치만 바뀐다.

| 비개발자 기준 | 기술 표현 그대로 |
|---|---|
| spec: 목적과 배경, 요구사항, 동작 방식, 의도적 범위 제외, 결정 기록의 '결정' 칸, 열린 질문의 '질문' 칸 | spec: 근거, 기각한 대안, 엣지케이스 처리, 위치, 변경 이력 |
| map: 영역 개요, 단위의 '하는 일' 칸 | map: 위치, 계약 위치, 흐름 순서 |
| rules: 규칙, 깨지면 생기는 일, 용어 설명 | rules: 근거, 명령 |
| 인터뷰 질문·보기, blindspot 질문·프라이머, 퀴즈 전체, 퀴즈 변경 요약 | 채팅의 리뷰 포인트, notes 항목 |

셀프 체크 문구와 `25 어절` 표지는 지금처럼 네 스킬(requirements-interview, blindspot-pass, explainer, work-report)에 자기완결 사본으로 남는다. 기계 검사는 `docs_check.py`가 퀴즈에 더해 spec의 비개발자 섹션 4개(목적과 배경, 요구사항, 동작 방식, 의도적 범위 제외)까지 맡는다.

### 4.5 작업 파일

- `docs/notes/<slug>.md` (템플릿 `skills/work-report/templates/notes.md`): 오늘의 implementation-notes 형식을 유지한다. 헤더에 `대상 spec` 줄을 두고, 항목 필드 여섯 개(결정 / 이유 / 검토한 대안 / 보수적 선택 여부 / 계획과의 이탈 / 사용자 확인 필요)에 `반영 대상: <spec 경로 · 섹션>`을 하나 더한다. 보고 모드가 이 필드를 보고 승격한다. 상한 없음. 인수 확인 후 삭제.
- `docs/quiz.html` (템플릿 `skills/work-report/templates/quiz.html`): 구조 유지. `<div class="summary">` 바깥에 `<p class="meta">대상: <spec 경로> · 기준: <커밋></p>` 한 줄을 두어 디스크의 오래된 퀴즈가 어느 변경의 것인지 스스로 밝힌다. 변경 요약 안에는 커밋 해시를 넣지 않는다(기존 규칙 유지, 검사 스크립트가 파싱하는 영역).

## 5. 읽기·쓰기 프로토콜 (MANDATE.md)

작업유형 표와 질문 정책 사이에 아래 섹션을 넣는다(영어, 그대로 붙여 넣기). 두 번 주입되므로 이 이상 늘리지 않는다.

```
## Documentation tiers

Project knowledge lives in a fixed set of living documents, updated in place. Never create a dated or per-feature document.

| Tier | Path | Holds | Cap |
|---|---|---|---|
| 1 Global Rules | `docs/<area>/rules.md` | invariants, conventions, standard commands, glossary of one area | 60 lines |
| 2 System Map | `docs/<area>/map.md` | units with locations, main flows, integration points, cross-unit risks | 150 lines |
| 3 Detail Spec | `docs/<area>/specs/<unit>.md` | one unit: purpose, requirements, behavior, decisions, edge cases, out-of-scope, open questions, change log | 200 lines |

`<area>` is a directory under `docs/` holding `map.md` — canonically `frontend` and `backend`; a project that is neither uses one area (default `core`). Working files: `docs/notes/<slug>.md` (this cycle's decision notes, deleted at acceptance) and `docs/quiz.html` (the current pre-merge quiz, overwritten).

Loading order: before changing code in an area, read its `rules.md`. Lifecycle skills then read `map.md` and only the specs of the units the task touches — never every spec, never another area's tiers, never old documents under `docs/`. Agents receive tier file paths, never directories. If the touched area has no `map.md`, `blindspot-pass` bootstraps Tier 1 and 2; other skills offer it and proceed.
```

Hard rules 변경:

- 4번: "Deliverables are the tier files and the two working files above. Creating any other document under `docs/` is a rule violation."
- 5번: "...until the user confirms passing `docs/quiz.html` generated by `work-report`."
- 질문 정책 1번의 괄호: "(자체 해소 recorded as a 결정 기록 row, or a notes entry)".
- 작업유형 표, hard rules 1–3, 질문 정책 2–4는 그대로.

## 6. 스킬별 변경

공통: 산출물 경로 `docs/blindspot/...`와 `YYYY-MM-DD-<slug>-...` 언급을 모두 제거한다. 각 스킬의 frontmatter description을 새 산출물에 맞게 다시 쓴다(§6.6). Gotchas는 §6.7.

### 6.1 requirements-interview

- 0단계(신설): 작업 설명과 언급된 경로로 영역을 정한다(`docs/*/map.md` 탐색). 그 영역의 rules.md와 map.md 단위 표를 읽는다. map.md가 없으면 blindspot-pass 부트스트랩을 제안하고, 거절하면 지금처럼 라이브 스캔으로 진행한다.
- 1단계 4분면 분류: 그대로(문서에는 남기지 않음).
- 2단계 근거 확보: 닿는 단위의 spec을 읽고, `grep -h '^| 20' docs/<영역>/specs/*.md`로 영역 내 결정 기록 행을 모은다. codebase-scanner 하나(conventions)에 rules.md·map.md 경로와 단위 위치 glob을 넘겨 "적힌 것은 빼고 틀린 것은 지적"하게 한다. `docs/blindspot/` 스캔 지시는 삭제.
- 3단계 인터뷰: 그대로. 다시 묻지 않을 때는 rules 행이나 결정 기록 행을 인용한다.
- 4단계 문서: spec의 요구사항(번호 목록, 확정 답변 인용)과 결정 기록(질문당 한 행, 결정 주체 사용자), 열린 질문(남은 Known Unknowns와 Unknown Unknowns 후보, 해소 계획 "blindspot-pass에서 점검")을 쓴다. spec이 없으면 explainer 스킬의 `templates/spec.md`로 만들고 상태 초안, 목적과 배경은 초안만. 답변이 영역 전체를 구속하면 rules.md 불변 규칙 행 추가.
- 5단계 검증: doc-verifier에 파일과 "이번에 채운 섹션" 목록을 넘긴다. `docs_check.py` 실행.
- 6단계 안내: 그대로.
- `templates/requirements.md` 삭제.

### 6.2 blindspot-pass

- 0단계 부트스트랩·갱신(신설): 닿는 영역에 map.md가 없을 때, 또는 사용자가 기능 없이 "맵 갱신"을 요청할 때 실행.
  - 영역 판정(§8).
  - 영역마다 렌즈 4개(structure, conventions, integration-points, edge-cases)를 한 번에 팬아웃. 스캐너는 영역 루트와 함께 이번 작업 설명도 받아 발견이 맵 구축과 작업 양쪽에 쓰이게 한다. 한 번의 호출에서 총 8개 이하. 영역이 셋 이상이면 이번 작업이 닿는 영역만.
  - rules.md와 map.md를 템플릿으로 만들어 발견을 채운다. spec은 만들지 않고 단위 표의 상세 명세는 `없음`.
  - 갱신 모드(이미 있을 때)는 기존 파일 경로를 스캐너에 넘겨 델타만 반영한다. 모순이 결정을 요구할 때만 질문.
  - 부트스트랩 뒤 같은 호출에서 2단계 팬아웃을 반복하지 않는다. 그 발견을 그대로 3단계로 가져간다.
- 1단계: 입력은 작업 설명, rules.md, map.md, 닿는 단위 spec(있으면), 결정 기록 grep 결과. requirements 문서 읽기는 삭제. 영역 구분(코드/도메인)은 그대로.
- 2단계 팬아웃: 렌즈·병렬·greenfield 3렌즈·domain-researcher 추가는 그대로. 각 스캐너에 rules.md·map.md 경로와 단위 위치 glob을 넘기고 "이미 적힌 것은 제외, 틀린 것은 지적, 발견마다 반영 계층 표기"를 지시한다.
- 3·4단계 구체화·해소·7개 상한·프라이머: 그대로.
- 5단계 반영(구 '문서화'): 발견을 렌즈별 고정 목적지로 보낸다.

  | 렌즈 | 목적지 |
  |---|---|
  | conventions | rules 불변 규칙·관례 |
  | structure | map 단위 |
  | integration-points | map 통합 지점 |
  | similar-features | 결정 기록의 근거로 인용(선례), 재사용 관례는 rules 관례 |
  | edge-cases | 한 단위 것은 spec 엣지케이스와 제약, 둘 이상이면 map 알려진 위험 |
  | domain 핵심 개념 | rules 용어(출처 필수) |
  | domain 품질 기준 | spec 요구사항(수용 기준으로, 출처 근거) |
  | 사용자 답변·자체 해소 | spec 결정 기록 |
  | 미해소 | spec 열린 질문(재방문 시점 포함) |

  어느 계층에도 맞지 않는 발견은 버린다. 스캔 원본 요약은 남기지 않는다. spec이 없는 단위에 쓸 것이 있으면 spec을 만든다(§4.3 규칙).
- 6단계 검증: 편집한 파일마다 doc-verifier + `docs_check.py`.
- 7단계 안내: 그대로.
- `templates/unknowns.md` 삭제, `templates/rules.md`·`templates/map.md` 신설.

### 6.3 explainer

- 1단계 입력: rules.md, map.md, 닿는 spec. spec에 요구사항도 결정 기록도 없으면 requirements-interview나 blindspot-pass를 권하고 멈춘다. 사용자가 "인터뷰할 것 없다"고 명시할 때만 spec을 새로 만든다. 요구사항을 지어내지 않는다.
- 2단계 작성: 자기 섹션만. 목적과 배경·동작 방식·의도적 범위 제외를 쓰고, 결정 기록의 빈 '기각한 대안' 칸을 채우고 새 결정은 행으로 붙인다. 열린 질문에 해소 계획을 단다. 다른 스킬이 쓴 요구사항·결정 기록 행은 고치지 않는다. map의 단위 행(새 단위면)과 주요 흐름 행을 갱신한다. 가독성 규칙은 §4.4 비개발자 섹션에 적용.
- 3단계 저장: 제자리 갱신. 상태를 확정으로.
- 4단계 검증: 그대로(doc-verifier + integration-points 대조 병렬). 대조는 map의 통합 지점 행과 단위 위치 glob이 코드와 맞는지도 확인하고 틀린 행을 고친다. `docs_check.py` 실행.
- 5단계 안내: 그대로.
- `templates/explainer.md`를 `templates/spec.md`로 교체.

### 6.4 work-report

노트 모드:

- 1단계: `docs/notes/<slug>.md`가 없으면 `templates/notes.md`로 만든다. spec은 읽지 않는다.
- 2단계: 결정 시점에 항목을 덧붙인다. `반영 대상` 필드를 채운다.
- 3·4단계(되돌릴 수 있는 결정은 보수적 기본값 + 기록 + 체크포인트, 절대 막지 않음): 그대로.

보고 모드:

1. 분석: change-analyzer(기준 ref + 닿는 spec 경로 + map 경로 + 있으면 계획 문서)와 check-runner(rules.md 표준 명령을 그대로 전달)를 병렬로.
2. 확인 질문: notes의 사용자 확인 필요 항목을 **먼저** 묶어서 묻는다. 답이 승격 내용을 바꾸므로 승격보다 앞에 둔다.
3. 승격: notes 항목을 spec 결정 기록 행으로(결정 주체 사용자/자체), 구현하며 드러난 엣지케이스를 엣지케이스와 제약로, 구현 중 뺀 것을 의도적 범위 제외로, 동작 방식을 구현대로 정정. change-analyzer의 `문서 갱신 필요`를 map(위치·단위 행)과 rules(바뀐 불변 규칙)에 적용. 닿는 spec의 의도적 범위 제외가 비어 있으면 채우거나 "이번 범위가 전부인 이유"를 쓴다. 편집한 계층 파일마다 doc-verifier + `docs_check.py`.
4. 퀴즈: `docs/quiz.html`을 덮어쓴다. 변경 요약(비개발자 요약 3–5문장)과 문항 4–6개, meta 줄. 기존 문항 규칙 전부 유지. `docs_check.py` 실행. 사람용 요약과 리뷰 포인트(파일:라인)는 채팅에 출력하고, PR을 쓰는 프로젝트면 PR 본문에 넣는다.
5. 게이트: 퀴즈 통과 전 머지 금지 안내. 사용자가 통과를 확인하면 주 단위 spec(두 영역이면 영역마다)에 변경 이력 행(날짜 · 변경 요약 한 문장 · 기준 커밋 · 검증 결과 · 퀴즈 통과)을 붙이고 `docs/notes/<slug>.md`를 지운다. 확인 전에는 완료를 선언하지 않는다.

- `templates/report.md`·`templates/implementation-notes.md` 삭제, `templates/notes.md` 신설, `templates/quiz.html`은 meta 줄만 추가.
- `scripts/quiz_check.py`를 `scripts/docs_check.py`로 개명·확장(§7.5).

### 6.5 blindspot-flow

- 0단계(신설): 닿는 영역에 map.md가 없으면 한국어로 알리고 blindspot-pass 부트스트랩을 제안한다.
- 재사용 감지: 닿는 단위의 spec 존재와 채워진 섹션(요구사항 있음 / 결정 기록 있음 / 동작 방식 있음)을 보고 단계마다 실행·건너뛰기를 제안한다. 디렉터리 스캔은 삭제.
- 5단계 뒤: 인수 확인 후 work-report가 변경 이력과 notes 삭제를 처리함을 명시.
- 나머지 그대로. 얇은 오케스트레이터 원칙 유지.

### 6.6 frontmatter description (트리거 계약)

다섯 스킬 모두 새 산출물을 말하도록 다시 쓴다. 폐지된 이름(requirements document, unknowns document, standalone document, report with Human/Agent sections, implementation-notes)이 남지 않게 한다. 트리거 조건("Use when ...")은 유지하고, blindspot-pass에는 "or when an area has no `docs/<area>/map.md` yet (bootstrap or map refresh)"를 더한다.

### 6.7 Gotchas 처리

CLAUDE.md의 "never delete entries"는 유지하되 "사실이 아니게 된 항목은 새 대상을 가리키도록 고쳐 쓴다. 대상 정정은 삭제가 아니다"를 명문화한다. 고쳐 쓰는 항목:

| 파일 | 현재 | 고친 뒤 |
|---|---|---|
| requirements-interview 마지막 항목 | 스캐너가 `docs/blindspot/` 이력을 훑는다 | 과거 결정은 영역 spec들의 결정 기록 행에 있다. grep으로 모아 인용하고 다시 묻지 않는다 |
| blindspot-pass "evidence and scan summaries stay technical" | 스캔 요약 | 근거 칸은 기술 표현. 스캔 원본은 남기지 않으며 계층에 못 들어가는 발견은 버린다 |
| explainer "not a concatenation of the other two docs" | 두 문서 | spec의 목적과 배경·동작 방식은 인터뷰와 스캔 출력의 나열이 아니라 그 단위만으로 읽히는 글 |
| work-report Human/Agent 항목 | Agent 섹션 | 변경 요약과 spec 비개발자 섹션만 쉬운 말. 근거·엣지케이스 처리·리뷰 포인트는 기술 표현 |
| work-report quiz_check.py 항목 | quiz_check.py | docs_check.py |

새로 붙이는 항목(스킬별 1–2개): "계층에 못 들어가는 발견을 어딘가에 쌓아 두고 싶은 충동이 곧 예전 unknowns 파일이다. 버린다", "spec 전부를 읽으면 안 된다. 단위 표에서 닿는 것만", "노트는 notes 파일에만. 구현 중 spec을 열지 않는다", "explainer는 남이 쓴 요구사항·결정 행을 고치지 않는다".

## 7. 에이전트 변경

에이전트 파일 이름·수·읽기 전용·model 고정은 그대로다.

### 7.1 codebase-scanner

- 렌즈에 `structure` 추가: 모듈 목록. 각 모듈의 책임과 위치. 부트스트랩과 맵 갱신에 사용.
- 입력에 선택 항목 추가: 계층 문서 경로(rules.md, map.md, 관련 spec)와 단위 위치 glob.
- 규칙 추가: 받은 계층 문서를 먼저 읽고, 거기 없는 것과 모순되는 것만 보고한다. glob을 받았으면 탐색을 그 범위로 좁힌다.
- 출력 발견마다 `- 반영 계층: rules | map | spec(<단위>) | 없음` 한 줄 추가. 맵이 있으면 발견이 고치는 맵 행을 인용.

### 7.2 domain-researcher

- 핵심 개념은 용어 표에 그대로 들어갈 한 문장 정의 + 출처로 쓴다.
- 발견마다 `- 반영 계층:` 추가(보통 rules 용어, spec 요구사항, spec 결정 기록 근거).

### 7.3 doc-verifier

- 입력: 파일 경로 + 선택적으로 "호출 스킬이 이번에 채운 섹션" 목록.
- 규칙 추가: 계층 문서에서 `없음`, `해당 없음`, 그리고 아직 차례가 오지 않은 빈 섹션은 미기입이 아니다. 목록을 받았으면 그 섹션만 미기입 검사한다.
- 검사 5 `계층 위치` 추가: 다른 계층에 있어야 할 내용(불변 규칙이 spec에, 한 단위 엣지케이스가 map에, 사이클 한정 내용이 계층 파일에). 목적지 계층을 지적. 판단이 분명한 경우만.
- description의 호출자 목록에 work-report(보고 모드의 계층 편집)를 추가. "work-report gates via the quiz instead"는 퀴즈 파일에만 해당.
- 링크 무결성(상세 명세 경로 존재, 등록 안 된 spec)은 이 에이전트가 아니라 `docs_check.py`가 맡는다(기계 검사는 스크립트로).

### 7.4 change-analyzer

- 입력: 기준 ref + 닿는 spec 경로들 + 영역 map 경로 (+ 있으면 계획 문서). 단수 "a plan document path"를 복수로.
- 4단계: spec의 요구사항·동작 방식(과 계획 문서)을 계획으로 삼아 이탈을 잰다. `계획 대비 이탈` 섹션 유지.
- 새 절차: 바뀐 파일을 map 단위 표의 위치 glob과 대조한다.
- 새 출력 `### 문서 갱신 필요`: `<계층 파일> · <섹션> — <반영할 내용>` 행. 어느 단위 위치에도 맞지 않는 바뀐 파일, 이제 존재하지 않는 위치, 바뀐 통합 지점, 바뀐 불변 규칙, 동작 변화를 포함.
- 규칙 추가: `docs/` 아래 문서 편집은 위험 지점으로 세지 않는다.

### 7.5 `docs_check.py` (구 quiz_check.py)

분기 순서: 상위 폴더 이름이 `specs`면 Tier 3, 아니면 파일명이 `rules.md`면 Tier 1, `map.md`면 Tier 2, `spec.md`면 Tier 3(템플릿), `.html`이면 퀴즈, 그 외는 검사 없음. `specs/rules.md`라는 단위가 있어도 Tier 3로 잡히고, 템플릿 폴더의 파일도 제 계층으로 잡힌다.

| 대상 | 검사 |
|---|---|
| 퀴즈 `.html` | 기존 퀴즈 검사 전부(변경 요약 25어절, 문항·해설 25어절, 보기 40자) |
| Tier 1 | 60줄 이하 |
| Tier 2 | 150줄 이하. 단위 표의 상세 명세 칸이 `specs/`로 시작하면 그 파일이 map과 같은 폴더 기준으로 존재(`없음`과 플레이스홀더는 통과). 같은 폴더의 `specs/*.md`가 모두 어떤 단위 행에 등록됨 |
| Tier 3 | 200줄 이하. 목적과 배경·요구사항·동작 방식·의도적 범위 제외 섹션의 문장 25어절 이하 |
| 그 외 `.md` | 검사 없음(notes 등) |

위반이 있으면 목록 출력 후 종료 코드 1, 없으면 `OK`와 0. 기존 `### 요약` 마크다운 분기는 보고서와 함께 폐지.

### 7.6 check-runner

변경 없음. 호출 측이 rules.md 표준 명령을 넘긴다.

## 8. 부트스트랩과 영역 판정

1. `docs/*/map.md`가 있으면 그것이 영역이다. 끝.
2. 없으면 저장소 루트에서 깊이 2까지 본다.
   - frontend 신호: `frontend|web|client|ui|app|apps/*` 이름의 폴더에 UI 매니페스트(react·vue·svelte·next·nuxt·angular 의존 package.json, 또는 index.html과 src/).
   - backend 신호: `backend|server|api|service|services/*` 이름의 폴더, 또는 서버 매니페스트(go.mod, pom.xml, build.gradle*, Cargo.toml, django·fastapi·flask가 있는 pyproject/requirements, Gemfile, composer.json, *.csproj, mix.exs, express·fastify·nest·hono·koa 의존 package.json).
3. 서로 다른 폴더가 각각 매치되면 frontend와 backend 두 영역. 하나만이면 그 하나. 같은 폴더가 둘 다 매치(Next.js 같은 풀스택)되거나 아무것도 없으면 영역 하나, 이름은 `core`. 증거가 정말 갈리면 후보를 보기로 한 번 질문한다.
4. 판정 결과는 map.md 헤더의 코드 루트에 적는다. 별도 레지스트리 없음. 잘못된 판정은 폴더 이름 변경과 spec 헤더의 영역 줄 수정으로 고친다.
5. 두 영역에 걸치는 작업: notes 하나, 퀴즈 하나, 영역마다 spec 하나. 스캐너는 렌즈마다 하나씩 두 영역 루트를 함께 받는다.
6. 다른 스킬이 map.md 부재를 만나면: 부트스트랩을 **제안**하고 거절하면 지금 방식(라이브 스캔, spec만 생성, 맵 갱신 생략)으로 진행한다. MANDATE 규칙 1(트리거 즉시 호출)과 충돌하지 않도록 map.md 부재를 MANDATE 트리거로 만들지 않는다.

## 9. 저장소 구조 변경

```
skills/
├── requirements-interview/SKILL.md            # templates/ 폴더 삭제
├── blindspot-pass/
│   ├── SKILL.md
│   └── templates/{rules.md, map.md}           # unknowns.md 대체
├── explainer/
│   ├── SKILL.md
│   └── templates/spec.md                      # explainer.md 대체
├── work-report/
│   ├── SKILL.md
│   ├── templates/{notes.md, quiz.html}        # report.md·implementation-notes.md 삭제
│   └── scripts/docs_check.py                  # quiz_check.py 개명
└── blindspot-flow/SKILL.md
agents/*.md                                    # 5개 유지, 본문 편집 4개
MANDATE.md, README.md, CLAUDE.md, test/check.sh
```

- 템플릿 소유: rules·map은 blindspot-pass, spec은 explainer, notes·quiz는 work-report. 다른 스킬이 남의 템플릿을 쓸 때는 "`explainer` 스킬의 `templates/spec.md`"처럼 스킬 이름으로 가리킨다(소비 프로젝트에서는 `.claude/skills/explainer/templates/spec.md`, 이 저장소에서는 `skills/explainer/templates/spec.md`). 템플릿은 중복하지 않는다. 가독성 규칙의 4중 사본은 산문 규칙이라 자기완결이 필요하지만, 템플릿은 파일 참조라 한 곳이면 된다.
- install.sh: 변경 없음. 스킬 폴더·에이전트 파일·hook·MANDATE 경로가 그대로라 소비 프로젝트는 `git submodule update --remote .claude/shared`만으로 새 구조를 받는다.

## 10. 테스트 변경 (`test/check.sh`)

| # | 검사 | 변경 |
|---|---|---|
| 1 | mandate 출력에 스킬 5개 | 유지. 같은 블록에 계층 경로 tripwire 추가: 출력에 `docs/<area>/rules.md`, `map.md`, `specs/`, `docs/quiz.html`, `docs/notes/` 문자열 존재 |
| 2 | frontmatter 10파일 | 유지 |
| 3 | skill→agent 참조 무결성 | 유지. blindspot-pass의 doc-verifier 스폰 문장에 `subagent_type` 표지를 붙여 세 스폰이 모두 잡히게 함. 에이전트 5개 모두 어떤 SKILL.md에서 참조됨을 추가 assert |
| 4 | `25 어절` 4파일 | 유지(같은 네 파일) |
| 5 | install.sh 멱등성 | 유지 |
| 6 | 검사 스크립트가 템플릿에서 clean | `docs_check.py`로. 인자: quiz.html, rules.md, map.md, spec.md. 템플릿의 플레이스홀더 문장은 규칙을 통과하도록 작성 |
| 7 | 폐지 경로 tripwire(신설) | `skills/`, `agents/`, `MANDATE.md`에 `docs/blindspot`, `YYYY-MM-DD-`, `quiz_check.py`, `implementation-notes`가 없음. `grep ... || true`로 set -e 안전 |
| 8 | 템플릿 헤딩 계약(신설) | rules.md·map.md·spec.md·notes.md가 §4의 `##` 헤딩을 모두 포함 |
| 9 | docs_check 음성 fixture(신설) | 임시 폴더에 201줄 spec, 없는 상세 명세를 가리키는 map, 등록 안 된 spec을 만들고 종료 코드가 0이 아니고 메시지에 각 원인이 있음을 assert |
| 10 | 템플릿 참조 해석(신설) | 모든 SKILL.md의 `templates/<파일>` 언급이 `skills/*/templates/`에 실존 |
| 11 | MANDATE 상한(신설) | `MANDATE.md` 60줄 이하 |

## 11. README·CLAUDE.md 변경

README (한국어):

- §2 앞에 "문서 3계층" 소절: 계층 표(계층 · 경로 · 담는 것 · 언제 읽나), "문서는 늘어나지 않고 갱신된다", 첫 실행 부트스트랩 안내(맵이 없으면 blindspot-pass가 만들고 영역 판정을 진술).
- §2 방법 A 표의 "무슨 일이 일어나나" 열을 계층 반영으로 다시 씀. 방법 B 흐름 블록의 산출물 이름 교체, 0단계 부트스트랩 추가.
- "산출물은 어디에 생기나" 트리를 §3 트리로 교체.
- Pre-Merge Quiz 절: 경로 `docs/quiz.html`, 덮어쓴다는 문장, 통과 기록은 spec 변경 이력에 남는다는 문장.
- §3 업데이트: 기존 소비 프로젝트 마이그레이션 문단(옛 `docs/blindspot/`는 그대로 두면 되고 어떤 스킬도 읽지 않는다. 특정 옛 문서의 결정을 옮기고 싶으면 그 파일을 지목해 요청).
- §4 스킬 표 산출물 열을 계층 대상으로. §5 에이전트 표에 structure 렌즈, 반영 계층, 문서 갱신 필요, 계층 위치 검사.
- §6 규칙: "산출물은 docs/blindspot/" 문장을 3계층 문장으로. "새 사실은 그것을 온전히 담는 가장 낮은 계층에 한 번만" 추가.
- §7 문제 해결: 병렬 브랜치가 quiz.html·notes에서 충돌하면 내 브랜치 것 유지(둘 다 일회용). map·spec 충돌은 양쪽 행을 모두 취함. 맵이 코드와 다르면 "맵 갱신해줘".
- §8: check.sh 설명 갱신. "실동작 검증 기록: docs/blindspot/"는 "3계층 이전 이력: docs/blindspot/, 현재 이 저장소의 계층 문서: docs/core/"로.

CLAUDE.md:

- Test 문단: 검사 목록 갱신(§10).
- Conventions: 산출물 경로 계약 항목을 §3 경로로 교체. Gotchas 항목에 "대상 정정은 삭제가 아니다" 추가. 가독성 항목의 단계 번호 갱신, 기계 검사 범위(퀴즈 + spec 비개발자 섹션 4개) 갱신, 스크립트 이름 갱신. 템플릿 소유·참조 규칙 항목 추가. "Human/Agent 섹션" 식별자 언급을 섹션별 독자 구분(§4.4)으로 교체.
- Consumer contract: `docs/<area>/` 계층 경로와 `docs/quiz.html`·`docs/notes/`, 그리고 스킬 간에 참조되는 템플릿 파일명을 추가.
- Design docs: 이 스펙과 플랜 추가.

## 12. 마이그레이션과 실전 검증

- **기존 소비 프로젝트**: `git submodule update --remote .claude/shared` (install.sh 재실행은 무해하나 불필요). 옛 `docs/blindspot/`는 그대로 둔다. 첫 라이프사이클 스킬 실행 때 부트스트랩이 제안된다. 옛 문서의 결정을 옮기고 싶으면 사용자가 파일을 지목해 요청하고, 스킬은 그 파일만 읽어 결정 기록·요구사항 행으로 옮긴다. 자동 수확은 없다.
- **이 저장소**: `docs/blindspot/`는 그대로. 마지막 작업으로 새 스킬을 이 저장소에 실행해 `docs/core/rules.md`, `docs/core/map.md`(단위: skills, agents, templates, scripts, installer, hook, test), 이번 변경이 닿는 단위의 spec, 그리고 `docs/quiz.html`을 만든다. 이것이 이번 사이클의 머지 전 퀴즈다. 퀴즈 통과 확인 후 spec 변경 이력에 행을 붙인다.
- **커밋 순서**(중간 상태에서도 `bash test/check.sh`가 깨지지 않게): ① 템플릿 5개 + docs_check.py + check.sh 6·8·9·10번, ② SKILL.md 5개 + 에이전트 4개 + check.sh 3·7번, ③ MANDATE + check.sh 1·11번, ④ README + CLAUDE.md, ⑤ 이 저장소 계층 문서 + 퀴즈. ①과 ②는 폐지 경로 tripwire 때문에 한 커밋으로 합쳐도 된다.

## 13. 반박 검토가 바꾼 것

| 반박 발견 | 반영 |
|---|---|
| "닿는 단위 spec만 읽으면 인접 단위의 과거 결정을 다시 묻게 된다"(3건 모두 HIGH) | 결정 기록 행을 한 줄로 강제하고 영역 spec 전체를 grep. 문서를 열지 않고 O(행) 비용 |
| "구현 노트를 spec에 쓰면 spec이 없을 때 노트 모드가 멈추고 explainer가 덮어쓴다" | notes 파일 분리(§2-4) |
| "부트스트랩을 MANDATE 트리거로 두면 규칙 1과 충돌하고 첫 접촉에서 스캐너 8개가 돈다" | 트리거로 두지 않음. 다른 스킬은 제안만 하고 진행(§8-6) |
| "영역 확인 질문은 증거로 정할 수 있어 질문 정책 위반" | 판정 진술, 애매할 때만 질문(§2-8) |
| "doc-verifier가 의도적으로 빈 섹션과 `없음`을 결함으로 잡아 지어내게 만든다" | 채운 섹션 목록 전달, `없음` 합법(§7.3) |
| "사용자 확인 필요 답변이 공유 문서 승격 뒤에 와서 잘못된 내용이 계층에 남는다" | 보고 모드 순서를 질문 → 승격 → 퀴즈로(§6.4) |
| "Gotchas append-only라 거짓이 된 항목이 소비자 세션에 주입된다" | 대상 정정 규칙 명문화(§6.7) |
| "메인 컨텍스트 절감이 아니라 서브에이전트·쓰기·중복 절감이다" | §14에 솔직하게 기록. 상한으로 천장 고정 |
| "단일 quiz.html은 병렬 브랜치에서 전체 파일 충돌" | 사용자 결정 유지. README 문제 해결에 처리법 기록 |
| "change-analyzer가 계획 문서를 잃어 계획 이탈 퀴즈 대상이 사라진다" | spec을 계획으로 삼고 계획 문서는 선택 입력으로 유지(§7.4) |
| "링크 무결성을 haiku 에이전트에 맡기면 안 된다" | docs_check.py로(§7.5) |
| "explainer의 요구사항 날조 금지 규칙이 사라진다" | 유지(§6.3) |

## 14. 비용 계산(솔직한 버전)

| 항목 | 현재 | 새 구조 |
|---|---|---|
| 사이클당 새 파일 | 6개, 약 425줄 | 0개. 계층 편집 약 60줄 + notes(삭제됨) + quiz 덮어쓰기 |
| 같은 결정의 기록 횟수 | 4회(요구사항·unknowns·explainer·보고서) | 1회(결정 기록 행) |
| 인터뷰 스캐너의 이력 읽기 | `docs/blindspot/` 전체, 사이클당 약 220줄씩 증가(서브에이전트 안) | 0. rules·map 경로만 |
| 작은 수정의 메인 컨텍스트 | MANDATE + 노트 템플릿 | + 영역 rules.md ≤60줄 |
| 라이프사이클 스킬의 메인 컨텍스트 | 주제별 선행 문서 1–2개 | rules ≤60 + map ≤150 + 닿는 spec ≤200×n |
| 천장 | 없음(문서 수 비례) | 상한 고정, 스크립트 검사 |

메인 컨텍스트는 작은 작업에서 약간 늘고 큰 작업에서 비슷하다. 줄어드는 것은 파일 수, 중복 기록, 서브에이전트의 이력 스캔이며 천장이 생긴다. MANDATE는 두 번 주입되므로 §5 이상 늘리지 않는다.

## 15. 의도적 범위 제외

- 여섯 번째 스킬(맵 전용) — blindspot-pass 0단계로 충분
- install.sh 변경 — 경로 계약이 그대로라 불필요. 끊어진 심링크 정리(prune)와 MANDATE 이중 주입(hook + @import) 해소는 별도 후속 과제
- 브랜치별 퀴즈 파일 — 사용자가 단일 파일을 선택. 팀 병렬 작업이 잦아지면 `docs/quiz/<slug>.html` + 인수 시 삭제로 전환 가능
- 옛 문서 자동 수확 — 사용자가 파일을 지목할 때만
- 열린 질문의 재방문 시점 자동 알림 — 오늘도 없는 기능
- 영어 계층 문서 — 산출물 한국어 규칙 유지
- CI — 로컬 `bash test/check.sh` 유지

## 16. 위험과 수용

| 위험 | 완화 |
|---|---|
| 계층 문서가 상한까지 자라 새 컨텍스트 문제가 됨 | docs_check.py가 실패시킴. 초과 시 아래 계층으로 내리는 규칙(§3) |
| 잘못된 계층에 기록되어 옆 단위 작업이 못 봄 | 렌즈별 고정 목적지, doc-verifier 계층 위치 검사, 결정 기록 grep |
| 부트스트랩 맵이 큰 저장소에서 얕음 | explainer 코드 대조와 change-analyzer 문서 갱신 필요가 사이클마다 고침. "맵 갱신" 요청 가능 |
| 영역 오판 | 폴더 이름 변경과 헤더 수정으로 복구. 애매하면 질문 |
| 병렬 브랜치 충돌(quiz·notes 전체, map·spec 행) | README 처리법. 행은 표 끝에 붙임 |
| 프로토콜이 산문이라 강제 불가 | 오늘의 mandate와 같은 수용된 한계. 기계 검사 가능한 것은 전부 스크립트로 |
| 중단된 사이클이 초안 spec과 notes를 남김 | 상태 초안 표시, blindspot-flow가 재개·폐기를 물음. notes는 사용자가 지움 |

## 17. 열린 질문

없음. 조정 가능한 값(영역 기본 이름 `core`, 상한 60/150/200, notes 위치)은 스펙 검토에서 바꿀 수 있다.
