# Pre-Merge Quiz 가독성 보강 설계

- 날짜: 2026-07-10
- 상태: 승인됨 (사용자 인터뷰 3문항 + 설계 리뷰 완료)
- 관련: [2026-07-06 저장소 설계](2026-07-06-blindspot-agents-skills-design.md) §2 (산출물 한국어 원칙)

## 1. 문제

`work-report`가 생성하는 pre-merge 퀴즈가 비전문가에게 읽히지 않는다. 실제 산출물(`docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html`)에서 확인된 증상:

- 질문 문장에 셸 구문 그대로 인용 — "test/check.sh의 `[[ ${#files[@]} -eq 8 ]]` 검사는…"
- 화살표 축약 — "작업유형→필수 skill", "dc45220 → a8e8740"
- 3중 절 압축 보기 — 한 보기에 메커니즘·안전망·의존성 세 개념을 욱여넣음
- 풀어쓰지 않은 전문용어 — 멱등성, frontmatter lint, tripwire, greenfield

원인: `skills/work-report/SKILL.md` 4단계의 퀴즈 생성 지침이 한 문장뿐이며 가독성 규칙이 전혀 없다.

## 2. 확정된 결정사항 (인터뷰)

| 질문 | 선택 | 의미 |
|---|---|---|
| 독자 수준 | **개발 비전문가** | 코드를 본 적 없는 사람(기획자/PM)이 모든 문장을 이해해야 함. 가장 엄격한 기준 |
| 해설 기능 | **추가** | 정답 확인 후 문항별 해설 표시. 틀린 사람이 배울 수 있는 유일한 장치 |
| 기존 퀴즈 | **재생성** | 새 규칙의 검증 샘플 겸. 보고서의 통과 기록은 불변 |

접근 방식: 규칙을 `work-report` SKILL.md 4단계에 인라인 (별도 reference 파일·템플릿 주석 방식은 기각 — 규칙이 ~12줄로 짧고, 템플릿 주석은 EN 지침/KO 산출물 분리 컨벤션 위반).

## 3. 변경 상세 (파일 4개)

### 3.1 `skills/work-report/SKILL.md` — 4단계 교체 (핵심)

기존 한 문장을 아래 규칙 블록으로 교체 (영어, 모델 지침):

> 4. **Generate the quiz.** Copy `templates/quiz.html` to `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`; replace the title/summary block and the `QUESTIONS` array with 4–6 Korean multiple-choice questions targeting what a reviewer must understand: 위험 지점, 동작 변화, 계획 이탈, 범위 제외. Wrong options must be plausible. The quiz reader is a non-developer — write every sentence for someone who has never seen the code:
>    - Ask what happens or what could go wrong, never how the code looks. No code syntax, identifiers, file paths, or shell fragments inside question or option sentences; no arrow shorthand (A→B); no unexplained jargon.
>    - Unavoidable technical terms: plain Korean first, term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
>    - A question is one short scenario sentence plus one question sentence. Options are complete sentences, one idea each, similar length and form — a conspicuously long option must not give away the answer.
>    - Every question gets an `explain` field: 2–3 plain Korean sentences on why the answer is right and why the most tempting wrong option is wrong. Technical terms and file paths belong here (in parentheses), not in questions.
>    - The summary block follows the same rules: user-visible changes only, no commit hashes, no arrows.
>    - Before saving, self-check every sentence: could someone who has never seen code tell what is being asked? If not, rewrite it.

### 3.2 `skills/work-report/templates/quiz.html` — 해설 지원 (~10줄)

- `QUESTIONS` 예시 항목에 `explain` 필드 추가
- 렌더 시 문항마다 숨긴 해설 블록(`<div class="explain" hidden>`)을 미리 생성
- `grade()`에서 해설 표시 + 정답 보기에 시각 표시(굵게/녹색). 재채점해도 중복 생성 없음(idempotent)
- CSS 소폭 추가 (해설 배경, 정답 라벨 강조)

### 3.3 `skills/work-report/SKILL.md` — Gotchas 1줄 append

> - A quiz written in the author's head-language (code syntax, arrows, compressed jargon) locks out non-developers; every sentence must survive the "reader has never seen the code" test.

### 3.4 `docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html` — 재생성

기존 6문항이 묻는 내용은 유지하되 새 규칙으로 문장 재작성 + `explain` 추가 + 요약 블록 평문화. 새 템플릿 구조 사용. `docs/blindspot/2026-07-06-...-report.md`의 통과 기록은 수정하지 않음.

## 4. 검증

1. `bash test/check.sh` — 파일 수·frontmatter 불변이므로 통과해야 함
2. 재생성된 퀴즈를 브라우저(Playwright)로 열어: 문항 렌더링, 정답 확인 클릭, 해설 표시, 재채점 시 중복 없음 확인
3. 재생성 문항 전수 자가 점검: 코드 구문·화살표·미풀이 용어 0건

## 5. 의도적 범위 제외

- `report.md`·explainer 템플릿의 가독성 — 이번 요청은 퀴즈 한정. 같은 증상이 보고서에서 확인되면 별도 작업
- 퀴즈 채점 로직·통과 기준(전부 정답) 변경 — 문장 품질만 다룸
- MANDATE.md·install.sh·test 파일 수 변경 — 없음 (스킬 개수 불변)

## 6. 열린 질문

없음 — 인터뷰에서 전부 해소.
