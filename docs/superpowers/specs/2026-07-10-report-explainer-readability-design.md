# 보고서·Explainer 가독성 확장 설계

- 날짜: 2026-07-10
- 상태: 승인됨 (사용자 인터뷰 2문항 + 설계 리뷰 완료)
- 관련: [퀴즈 가독성 설계](2026-07-10-quiz-readability-design.md) — 같은 기준의 확장. 규칙 원문은 work-report SKILL.md 4단계에 이미 존재

## 1. 문제

퀴즈에 적용한 비전문가 문장 기준이 나머지 산출물에는 없다. 실제 보고서(`docs/blindspot/2026-07-06-blindspot-agents-skills-report.md`)의 Human 요약은 화살표 체인("requirements-interview → blindspot-pass → …")과 미풀이 용어(submodule, 심링크, SessionStart hook, 멱등성)로 쓰여 있어 이해관계자가 읽을 수 없다. explainer는 "제로 컨텍스트 독자"가 목적인데 문장 기준이 명문화되어 있지 않다.

핵심 제약: 보고서는 독자가 셋으로 갈린다 — 요약(이해관계자), 리뷰 포인트(코드 리뷰어, 파일:라인이 본질), Agent 섹션(미래 AI, 구조화·기술적이어야 함). 일괄 적용은 기능 파괴.

## 2. 확정된 결정사항 (인터뷰)

| 질문 | 선택 | 의미 |
|---|---|---|
| 보고서 적용 범위 | **요약만** | 리뷰 포인트·Agent 섹션은 각자의 기술 독자 기준 유지. 섹션별 독자에 맞는 기준 |
| 기존 보고서 | **요약만 재작성** | 새 규칙 검증 샘플 겸. 인수 기록·리뷰 포인트·Agent 섹션은 바이트 불변 |

explainer는 문서 전체 적용(질문 불요 — 스킬의 명시된 목적이 제로 컨텍스트 독자).

접근 방식: 각 SKILL.md에 인라인 — work-report는 같은 파일 안의 4단계 규칙을 참조(중복 없음), explainer는 자체 축약 규칙 보유(스킬 자기완결성 — 타 스킬 파일 참조는 단독 로드 시 깨짐). 공유 reference 파일(스킬 간 결합)·템플릿 주석(EN/KO 분리 위반)은 기각.

## 3. 변경 상세 (파일 5개)

### 3.1 `skills/work-report/SKILL.md` — Report mode 3단계 교체

기존:

> 3. **Write the report** following `templates/report.md`, Korean, to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`. Keep the two audiences strictly separate:
>    - Human 섹션 — 3–5문장 요약, 스크린샷/데모 자리, 리뷰 포인트(파일:라인)
>    - Agent 섹션 — 의도, 제약, 검토한 엣지케이스, 의도적 범위 제외 (structured for a future agent to consume)

교체:

> 3. **Write the report** following `templates/report.md`, Korean, to `docs/blindspot/YYYY-MM-DD-<slug>-report.md`. Keep the two audiences strictly separate:
>    - Human 섹션 — 3–5문장 요약, 스크린샷/데모 자리, 리뷰 포인트(파일:라인). The 요약 is read by non-developers: apply the sentence rules from step 4 to it — what happened and what it means for users, never how the code looks; no code syntax, identifiers, file paths, or arrow shorthand; unavoidable technical terms plain Korean first with the term in parentheses. 리뷰 포인트 is for code reviewers — keep it technical; 파일:라인 references are its job.
>    - Agent 섹션 — 의도, 제약, 검토한 엣지케이스, 의도적 범위 제외 (structured for a future agent to consume; technical language is correct here — do not simplify it)

### 3.2 `skills/explainer/SKILL.md` — 2단계 교체

기존:

> 2. **Write.** Follow `templates/explainer.md` in this skill's folder. Korean. The sections that matter most:

교체 (기존 세 불릿은 그대로 뒤에 유지):

> 2. **Write.** Follow `templates/explainer.md` in this skill's folder. Korean. The entire document is for a reader who has never seen the code:
>    - Describe what happens and why, never how the code looks. No arrow shorthand (A→B), no unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
>    - Code identifiers and file paths appear only where they are the subject being explained, introduced by a plain description.
>    - Before saving, self-check every sentence: could someone who has never seen code follow it? If not, rewrite it.
>
>    The sections that matter most:

### 3.3 템플릿 플레이스홀더 2건 (KO, 생성 시 콘텐츠로 교체되므로 산출물에 잔재 없음)

- `skills/work-report/templates/report.md` 요약: `(3–5문장: 무엇이 어떻게 바뀌었고 사용자에게 어떤 의미인지)` → `(3–5문장, 코드를 본 적 없는 사람 기준: 무엇이 어떻게 바뀌었고 사용자에게 어떤 의미인지. 화살표 축약·미풀이 전문용어 금지, 불가피한 용어는 쉬운 말 먼저(용어 병기))`
- `skills/explainer/templates/explainer.md` `## 목적과 배경` 아래 플레이스홀더 추가: `(코드를 본 적 없는 독자가 이 문서만으로 처음부터 끝까지 읽을 수 있게 — 전문용어는 쉬운 말 먼저(용어 병기), 화살표 축약 금지)`

### 3.4 Gotchas 각 1줄 append

- work-report: `- A 요약 written in engineer-speak (arrows, raw jargon) locks stakeholders out — but only the 요약: 리뷰 포인트 and the Agent 섹션 are technical by design; simplifying them destroys their function.`
- explainer: `- An explainer that reads like an engineering changelog fails its zero-context purpose; every sentence must survive the "reader has never seen the code" test.`

### 3.5 기존 보고서 요약 재작성

`docs/blindspot/2026-07-06-blindspot-agents-skills-report.md`의 `### 요약` 본문(5문장)만 아래로 교체. 그 외 전부(메타 라인의 기준 ref 표기 포함) 바이트 불변:

> 아무것도 없던 빈 저장소를, 여러 프로젝트가 함께 가져다 쓰는 AI 작업 도구 모음으로 처음부터 만들었다. 도구는 두 종류다 — 작업을 단계별 절차로 이끄는 도구 다섯 가지(요구사항 인터뷰, 사각지대 점검, 설명 문서 작성, 작업 보고, 그리고 이 네 단계를 순서대로 진행해 주는 진행 도구), 그리고 조사·검증을 대신해 주는 읽기 전용 보조 조사원 세 가지다. 다른 프로젝트는 설치 프로그램을 한 번 실행하면 연결되고, 그 뒤로는 작업 세션이 시작될 때마다 '작업 유형별 필수 절차' 규칙이 AI에게 자동으로 전달된다. 실제로 실행되는 코드는 작은 스크립트 세 개뿐이고, 나머지는 전부 AI와 사람이 읽는 문서다. 단계마다 검토를 일곱 번, 마지막에 전체 검토까지 거쳤고, 자동 점검이 문서 형식부터 '설치를 두 번 해도 결과가 같은가(멱등성)'까지 검사한다.

## 4. 검증

1. `bash test/check.sh` — 파일 수(9)·frontmatter 불변이므로 통과해야 함
2. 재작성된 요약 블록만 추출해 기계 스캔: `awk '/^### 요약/{f=1;next} /^###/{f=0} f' <report> | grep -E '→|\$\{|\[\['` → 0건 (Agent 섹션의 정당한 기술 표현·화살표는 스캔 대상 아님)
3. 요약 5문장 자가 점검: 코드를 본 적 없는 사람이 읽히는가, 모든 용어가 쉬운 말 먼저인가
4. 브라우저 검증 해당 없음 (마크다운만)

## 5. 의도적 범위 제외

- requirements/unknowns 템플릿 — 개발 협업 산출물, 요청 범위 밖
- 리뷰 포인트·Agent 섹션의 문체 — 기술 독자용이 설계 의도
- 보고서 메타 라인의 `기준: base → HEAD` 표기 — 커밋 참조 메타데이터로 요약이 아님
- 퀴즈(전 사이클 완료), MANDATE.md·install.sh·README·test 파일 수

## 6. 열린 질문

없음 — 인터뷰에서 전부 해소.
