# Requirements/Unknowns 가독성 확장 설계

- 날짜: 2026-07-10
- 상태: 승인됨 (사용자 인터뷰 1문항 + 설계 리뷰 완료)
- 개정: 2026-07-10 — 최종 리뷰 반영: 5단계 칼럼 명명을 두 표 모두로 일반화(미해소 표의 `질문` 칸 포함), 발견(근거) 단수 표기, 저장 전 자가 점검 문장 추가
- 관련: [퀴즈 가독성](2026-07-10-quiz-readability-design.md), [보고서·Explainer 가독성](2026-07-10-report-explainer-readability-design.md) — 같은 기준의 세 번째 확장. 이로써 라이프사이클 산출물 전체 커버

## 1. 문제

비전문가 문장 기준이 퀴즈·보고서 요약·explainer에는 적용됐지만 라이프사이클의 앞 단계 산출물(requirements, unknowns)에는 없다. 특히:

- 두 스킬 모두 **살아있는 인터뷰 단계**(AskUserQuestion)가 있고, 질문이 그대로 문서의 인터뷰 기록에 남는다. 사용자가 못 읽는 질문은 추측 답변을 낳고, 추측 답변은 잘못된 요구사항이 된다.
- unknowns 문서는 두 얼굴이다: 구체화된 질문·결정(사용자가 읽고 답하는 칸) vs 발견 근거 파일:라인·출처 URL·스캔 원본 요약(증거·기술 정찰 기록, 후속 단계인 explainer가 소비).

## 2. 확정된 결정사항 (인터뷰)

| 질문 | 선택 | 의미 |
|---|---|---|
| unknowns 적용 범위 | **질문·결정만** | 구체화된 질문·결정·보류 이유 칸만 비전문가 기준. 발견 근거(파일:라인·URL)·스캔 원본 요약은 기술 기록 유지 — 보고서의 섹션별 독자 기준과 같은 패턴 |

설계 리뷰에서 함께 승인된 포인트 2건:
- **인터뷰 질문 문구에도 동일 기준** — 질문·보기·(blindspot-pass의) 프라이머까지. requirements 문서는 원천이 사용자 발화라 문서 전체 적용.
- **unknowns 템플릿에는 힌트를 넣지 않음** — 표 구조라 플레이스홀더 자리가 없고 어중간한 힌트 줄은 산출물에 잔재로 남을 위험. 규칙 전달은 SKILL.md 5단계가 담당(생성 모델은 SKILL.md와 템플릿을 함께 읽는다).

접근 방식: 각 SKILL.md 인라인(자기완결) — 기존 두 사이클과 동일. 공유 reference 파일·템플릿 단독 방식 기각(동일 논리).

## 3. 변경 상세 (파일 3개)

### 3.1 `skills/requirements-interview/SKILL.md`

**3단계(Interview)** — 첫 불릿으로 질문 문구 규칙 추가 (기존 세 불릿은 그대로 뒤에 유지):

> 3. **Interview.** In Korean, ONE question per message, via AskUserQuestion with 2–4 concrete options where possible.
>    - Write every question and option for someone who has never seen the code: unavoidable technical terms plain Korean first with the term in parentheses; code identifiers only after a plain description of what they do.
>    - Order by architecture impact: answers that change the design come first.
>    - Stop when remaining answers would no longer change what you'd build (typically 3–6 questions).
>    - Record every question, answer, and its architecture impact.

**4단계(Write the document)** — 교체:

기존:
> 4. **Write the document.** Follow `templates/requirements.md` in this skill's folder. Fill every section in Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` (slug = kebab-case topic, date = today).

신규:
> 4. **Write the document.** Follow `templates/requirements.md` in this skill's folder. Fill every section in Korean, for a reader who has never seen the code: no arrow shorthand (A→B) or unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses. Evidence links and 관련 문서 paths stay as they are. Before saving, self-check every sentence: could someone who has never seen code follow it? Save to `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` (slug = kebab-case topic, date = today).

**Gotchas append** (기존 마지막 항목 `- One decision per question. ...` 뒤):

> - A question the user cannot parse gets a guessed answer; guessed answers become wrong requirements. Every question and every document sentence must survive the "reader has never seen the code" test.

### 3.2 `skills/blindspot-pass/SKILL.md`

**3단계(Synthesize)** — 교체:

기존:
> 3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의"), assign a quadrant, sort by architecture impact. Keep evidence attached — `file:line` for code findings, source URL for domain findings.

신규:
> 3. **Synthesize.** Merge findings yourself (plain reasoning, no extra agent). For each finding: restate it as a concrete, decidable question ("X를 어떻게 할지", not "X 주의") written for someone who has never seen the code — unavoidable technical terms plain Korean first with the term in parentheses, code identifiers only after a plain description. Assign a quadrant, sort by architecture impact. Keep evidence attached — `file:line` for code findings, source URL for domain findings; evidence stays technical.

**4단계(Resolve with the user)** — 교체:

기존:
> 4. **Resolve with the user.** Present questions in Korean via AskUserQuestion, architecture-changing first. If domain findings exist, open with a short primer (5–10 lines in Korean, from the researcher's 핵심 개념) — the user must understand the concepts to answer the questions. Questions the findings already answer: decide yourself and mark 자체 해소 with the evidence.

신규:
> 4. **Resolve with the user.** Present questions in Korean via AskUserQuestion, architecture-changing first. Questions, options, and the primer follow the same non-developer bar as step 3. If domain findings exist, open with a short primer (5–10 lines in Korean, from the researcher's 핵심 개념) — the user must understand the concepts to answer the questions. Questions the findings already answer: decide yourself and mark 자체 해소 with the evidence.

**5단계(Document)** — 교체:

기존:
> 5. **Document.** Follow `templates/unknowns.md` in this skill's folder. Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`. Omit lenses that did not run from the 스캔 렌즈 line and drop their `### <lens>` sections (greenfield drops `similar-features`; code-only tasks drop `domain`).

신규:
> 5. **Document.** Follow `templates/unknowns.md` in this skill's folder. Korean. The question, decision, and hold-reason cells across both tables (구체화된 질문·질문·결정·보류 이유) are read by non-developers — apply the step 3 sentence bar to them; before saving, self-check every sentence in those cells: could someone who has never seen code follow it? The 발견(근거) column and the 스캔 원본 요약 sections are technical evidence for later stages — technical language is correct there; do not simplify it. Save to `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`. Omit lenses that did not run from the 스캔 렌즈 line and drop their `### <lens>` sections (greenfield drops `similar-features`; code-only tasks drop `domain`).

**Gotchas append** (기존 마지막 항목 `- Domain unknowns don't live in the repo — ...` 뒤):

> - A concretized question the user cannot parse defeats the whole pass — the decision gets guessed, not made. Questions and decisions in plain Korean; evidence and scan summaries stay technical.

### 3.3 `skills/requirements-interview/templates/requirements.md` — 요청 배경 플레이스홀더 교체

기존: `(사용자가 이 요청을 하게 된 맥락 1–3문장)`

신규: `(사용자가 이 요청을 하게 된 맥락 1–3문장 — 문서 전체: 코드를 본 적 없는 독자 기준, 전문용어는 쉬운 말 먼저(용어 병기), 화살표 축약 금지)`

`templates/unknowns.md`는 §2 결정대로 변경 없음.

## 4. 검증

1. `bash test/check.sh` — 파일 수(9)·frontmatter 불변이므로 통과해야 함
2. 태스크 리뷰(전사 정확성) + 최종 전체 리뷰(4개 스킬에 걸친 기준의 상호 일관성)
3. **재생성 샘플 없음** — 이 저장소에 requirements/unknowns 산출물이 존재하지 않음(원 구축은 설계 인터뷰+스펙으로 대체). 규칙은 소비 프로젝트 첫 실행 때 실전 검증

## 5. 의도적 범위 제외

- 발견 근거(파일:라인·URL)·스캔 원본 요약의 문체 — 증거·후속 단계 소비 기능
- 에이전트 지시문(codebase-scanner, domain-researcher, doc-verifier) — 모델 간 통신, 사용자 비노출
- `templates/unknowns.md` — §2 결정(힌트 없음)
- MANDATE.md·install.sh·README·test 파일 수

## 6. 열린 질문

없음 — 인터뷰와 설계 리뷰에서 전부 해소.
