# Quiz Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `work-report`-generated pre-merge quizzes readable by non-developers: explicit plain-language rules in the skill, an `explain` (해설) feature in the quiz template, and the existing 2026-07-06 quiz regenerated under the new rules — per the approved spec at `docs/superpowers/specs/2026-07-10-quiz-readability-design.md`.

**Architecture:** Pure content changes, no new files. The readability rules live inline in `skills/work-report/SKILL.md` step 4 (English, model-facing). The template gains an `explain` field per question, revealed by `grade()`. The regenerated quiz is the end-to-end validation sample.

**Tech Stack:** Markdown (SKILL.md), self-contained HTML/vanilla JS (quiz), bash (`test/check.sh`), Playwright MCP for browser verification.

## Global Constraints

- Model-facing instruction files are **English**; deliverables (quiz HTML content) are **Korean**. Do not mix. (CLAUDE.md)
- `## Gotchas` sections: append only, never delete entries. (CLAUDE.md)
- Quiz path contract unchanged: `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`. (CLAUDE.md)
- No files added or removed under `skills/*/SKILL.md` or `agents/*.md` — `test/check.sh` asserts exactly 9. (spec §5)
- Quiz sentence rules (spec §3.1): reader is a non-developer; no code syntax / identifiers / file paths / shell fragments / arrow shorthand / unexplained jargon in question or option sentences; technical terms plain-Korean-first with the term in parentheses; every question has `explain`; summary block plain-language, no commit hashes, no arrows.
- Commit after every task. Commit messages end with:
  `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`
- Push to `origin main` only in the final task.

---

### Task 1: Quiz generation rules in work-report SKILL.md

**Files:**
- Modify: `skills/work-report/SKILL.md` (step 4 of Report mode, line 27; Gotchas list, after line 34)

**Interfaces:**
- Produces: the rule block that Task 3's quiz content must satisfy, including the mandatory `explain` field consumed by Task 2's template.

- [ ] **Step 1: Replace step 4 of Report mode**

In `skills/work-report/SKILL.md`, replace this exact line:

```markdown
4. **Generate the quiz.** Copy `templates/quiz.html` to `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`; replace the title/summary block and the `QUESTIONS` array with 4–6 Korean multiple-choice questions targeting what a reviewer must understand: 위험 지점, 동작 변화, 계획 이탈, 범위 제외. Wrong options must be plausible.
```

with:

```markdown
4. **Generate the quiz.** Copy `templates/quiz.html` to `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`; replace the title/summary block and the `QUESTIONS` array with 4–6 Korean multiple-choice questions targeting what a reviewer must understand: 위험 지점, 동작 변화, 계획 이탈, 범위 제외. Wrong options must be plausible. The quiz reader is a non-developer — write every sentence for someone who has never seen the code:
   - Ask what happens or what could go wrong, never how the code looks. No code syntax, identifiers, file paths, or shell fragments inside question or option sentences; no arrow shorthand (A→B); no unexplained jargon.
   - Unavoidable technical terms: plain Korean first, term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
   - A question is one short scenario sentence plus one question sentence. Options are complete sentences, one idea each, similar length and form — a conspicuously long option must not give away the answer.
   - Every question gets an `explain` field: 2–3 plain Korean sentences on why the answer is right and why the most tempting wrong option is wrong. Technical terms and file paths belong here (in parentheses), not in questions.
   - The summary block follows the same rules: user-visible changes only, no commit hashes, no arrows.
   - Before saving, self-check every sentence: could someone who has never seen code tell what is being asked? If not, rewrite it.
```

- [ ] **Step 2: Append the Gotchas entry**

In the same file's `## Gotchas` list, append after the last entry (`- Quiz questions about trivia ...`):

```markdown
- A quiz written in the author's head-language (code syntax, arrows, compressed jargon) locks out non-developers; every sentence must survive the "reader has never seen the code" test.
```

- [ ] **Step 3: Run the repo check**

Run: `bash test/check.sh`
Expected: `OK: all checks passed` (frontmatter untouched, file count still 9).

- [ ] **Step 4: Commit**

```bash
git add skills/work-report/SKILL.md
git commit -m "feat: quiz generation rules for non-developer readers in work-report

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: `explain` support in the quiz template

**Files:**
- Modify: `skills/work-report/templates/quiz.html` (full rewrite, content below)

**Interfaces:**
- Consumes: rule block from Task 1 (mandatory `explain`).
- Produces: QUESTIONS item shape `{ q: string, options: string[], answer: number, explain: string }`; `grade()` reveals each question's `.explain` div and bolds/greens the correct option's label. Task 3's regenerated quiz must use exactly this shape and markup.

- [ ] **Step 1: Rewrite the template**

Replace the entire content of `skills/work-report/templates/quiz.html` with:

```html
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pre-Merge Quiz: [주제]</title>
<style>
  body { font-family: sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1rem; line-height: 1.6; }
  .q { border: 1px solid #ccc; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
  .q.correct { border-color: #2e7d32; background: #edf7ed; }
  .q.wrong { border-color: #c62828; background: #fdecea; }
  #result { font-size: 1.2rem; font-weight: bold; margin: 1rem 0; }
  button { padding: .6rem 1.2rem; font-size: 1rem; cursor: pointer; }
  .summary { background: #f5f5f5; border-radius: 8px; padding: 1rem; }
  label { display: block; }
  label.answer { color: #2e7d32; font-weight: bold; }
  .explain { background: #fff8e1; border-radius: 6px; padding: .5rem .8rem; margin-top: .5rem; }
</style>
</head>
<body>
<h1>Pre-Merge Quiz: [주제]</h1>
<div class="summary">
<h2>변경 요약</h2>
<!-- SUMMARY: work-report가 이 블록을 실제 변경 요약으로 교체 (비전문가 기준 문장, 커밋 해시·화살표 금지) -->
</div>
<h2>퀴즈 — 전부 맞혀야 머지 가능</h2>
<div id="quiz"></div>
<button onclick="grade()">정답 확인</button>
<div id="result"></div>
<script>
// QUESTIONS: work-report가 이 배열을 실제 문항으로 교체한다.
// 모든 문장은 비전문가 기준(work-report SKILL.md 4단계 규칙). explain은 필수 — 정답 확인 후 표시된다.
const QUESTIONS = [
  { q: "예시 질문?", options: ["보기 A", "보기 B", "보기 C"], answer: 0,
    explain: "예시 해설 — 왜 정답인지, 가장 그럴듯한 오답은 왜 틀렸는지 쉬운 말 2–3문장." },
];
const quiz = document.getElementById("quiz");
QUESTIONS.forEach((it, i) => {
  const d = document.createElement("div");
  d.className = "q"; d.id = "q" + i;
  d.innerHTML = "<p><b>Q" + (i + 1) + ".</b> " + it.q + "</p>" +
    it.options.map((o, j) =>
      '<label><input type="radio" name="q' + i + '" value="' + j + '"> ' + o + "</label>"
    ).join("") +
    '<div class="explain" hidden><b>해설.</b> ' + it.explain + "</div>";
  quiz.appendChild(d);
});
function grade() {
  let ok = 0;
  QUESTIONS.forEach((it, i) => {
    const sel = document.querySelector('input[name="q' + i + '"]:checked');
    const el = document.getElementById("q" + i);
    const good = sel && Number(sel.value) === it.answer;
    el.className = "q " + (good ? "correct" : "wrong");
    el.querySelectorAll("label")[it.answer].classList.add("answer");
    el.querySelector(".explain").hidden = false;
    if (good) ok++;
  });
  const r = document.getElementById("result");
  r.textContent = ok === QUESTIONS.length
    ? "통과 (" + ok + "/" + QUESTIONS.length + ") — 머지 가능"
    : "미통과 (" + ok + "/" + QUESTIONS.length + ") — 오답 확인 후 재시도. 머지 금지";
}
</script>
</body>
</html>
```

(Diff vs current template: 2 CSS rules — `label.answer`, `.explain`; one comment line; `explain` in the example item; the hidden `.explain` div in the render string; 2 lines in `grade()` revealing it and marking the answer label. Nothing else changes.)

- [ ] **Step 2: Verify behavior in a real browser (Playwright MCP)**

1. `browser_navigate` to `file:///home/dkdlqoddi/dev-env-blindspot/skills/work-report/templates/quiz.html`
2. `browser_snapshot` — expect: 1 question card, 3 radio options, NO visible 해설 text.
3. Click `정답 확인` with nothing selected — expect: result text `미통과 (0/1) — 오답 확인 후 재시도. 머지 금지`, and the 해설 block ("예시 해설 …") now visible, `보기 A` label highlighted as answer.
4. Select `보기 A`, click `정답 확인` again — expect: result `통과 (1/1) — 머지 가능`; exactly ONE 해설 block (regrade must not duplicate it).
5. `browser_close`.

- [ ] **Step 3: Run the repo check**

Run: `bash test/check.sh`
Expected: `OK: all checks passed` (templates are not linted; nothing else changed).

- [ ] **Step 4: Commit**

```bash
git add skills/work-report/templates/quiz.html
git commit -m "feat: per-question explanations revealed on grading in quiz template

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Regenerate the 2026-07-06 quiz under the new rules

**Files:**
- Modify: `docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html` (full rewrite, content below)

**Interfaces:**
- Consumes: QUESTIONS shape and markup from Task 2; sentence rules from Task 1.
- Produces: the validation sample proving the rules yield a non-developer-readable quiz. The pass record in `docs/blindspot/2026-07-06-blindspot-agents-skills-report.md` is NOT touched.

- [ ] **Step 1: Rewrite the quiz file**

Replace the entire content of `docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html` with (same 6 topics as the original questions — enforcement, idempotent install, corrupt settings, parallel scanners, file-count tripwire, greenfield — rewritten for non-developers, each with 해설):

```html
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pre-Merge Quiz: blindspot Agent/Skill 저장소 구축</title>
<style>
  body { font-family: sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1rem; line-height: 1.6; }
  .q { border: 1px solid #ccc; border-radius: 8px; padding: 1rem; margin: 1rem 0; }
  .q.correct { border-color: #2e7d32; background: #edf7ed; }
  .q.wrong { border-color: #c62828; background: #fdecea; }
  #result { font-size: 1.2rem; font-weight: bold; margin: 1rem 0; }
  button { padding: .6rem 1.2rem; font-size: 1rem; cursor: pointer; }
  .summary { background: #f5f5f5; border-radius: 8px; padding: 1rem; }
  label { display: block; }
  label.answer { color: #2e7d32; font-weight: bold; }
  .explain { background: #fff8e1; border-radius: 6px; padding: .5rem .8rem; margin-top: .5rem; }
</style>
</head>
<body>
<h1>Pre-Merge Quiz: blindspot Agent/Skill 저장소 구축</h1>
<div class="summary">
<h2>변경 요약</h2>
<ul>
<li>빈 저장소를 여러 프로젝트가 함께 쓰는 AI 작업 도구 모음으로 만들었습니다.</li>
<li><b>작업 절차 도구(스킬) 5종</b>: 요구사항 인터뷰, 사각지대 점검, 설명 문서 작성, 작업 보고, 그리고 이 네 단계를 순서대로 진행해 주는 진행 도구.</li>
<li><b>보조 조사원(에이전트) 3종</b>: 코드 조사, 문서 검증, 변경 분석 — 모두 읽기만 하고 고치지는 않습니다.</li>
<li><b>규칙 강제</b>: 작업 세션이 시작될 때마다 '작업 유형별 필수 절차' 규칙 문서를 AI에게 자동으로 읽혀 주고, 프로젝트 안내문에서도 같은 문서를 참조하는 이중 안전망.</li>
<li><b>설치</b>: 설치 프로그램 한 번 실행으로 프로젝트에 연결되며, 여러 번 실행해도 결과가 같습니다(멱등성).</li>
<li><b>자동 점검</b>: 규칙 알림 동작, 문서 형식, 그리고 가짜 프로젝트에 두 번 설치해 보는 반복 설치 검사까지 포함.</li>
<li><b>마지막 검토 반영</b>: 깨진 설정 파일을 만나면 즉시 멈추고 알리기, 코드가 없는 새 프로젝트의 처리 방식 문서화 등.</li>
</ul>
<p>상세 보고서: <code>docs/blindspot/2026-07-06-blindspot-agents-skills-report.md</code></p>
</div>
<h2>퀴즈 — 전부 맞혀야 머지 가능</h2>
<div id="quiz"></div>
<button onclick="grade()">정답 확인</button>
<div id="result"></div>
<script>
// QUESTIONS: work-report가 이 배열을 실제 문항으로 교체한다.
// 모든 문장은 비전문가 기준(work-report SKILL.md 4단계 규칙). explain은 필수 — 정답 확인 후 표시된다.
const QUESTIONS = [
  { q: "이 저장소는 'AI가 작업을 시작하기 전에 정해진 절차를 반드시 따르라'는 규칙 문서를 갖고 있습니다. AI가 이 규칙을 실제로 지키게 만드는 방법은 무엇일까요?",
    options: [
      "규칙을 지킬 때까지 시스템이 AI의 다른 모든 행동을 자동으로 차단한다",
      "따로 강제하는 장치는 없고, 매 작업 세션이 시작될 때 규칙 문서를 AI에게 자동으로 읽혀 준다",
      "설치 프로그램이 AI가 실행하는 모든 명령을 가로채서 검사하는 감시 장치를 등록한다",
      "AI가 응답을 낼 때마다 설정 파일이 규칙 위반 여부를 하나하나 검사해서 걸러낸다"
    ], answer: 1,
    explain: "이 저장소의 강제 장치는 '자동으로 읽혀 주기'입니다. 작업 세션이 시작될 때마다 실행되는 장치(SessionStart hook)가 규칙 문서(MANDATE.md)를 AI의 작업 맥락에 넣어 주고, 프로젝트 안내문(CLAUDE.md)도 같은 문서를 참조해 이중으로 보여줍니다. 차단이나 검사 같은 기계적 강제는 없으므로, 규칙을 지키는 것 자체는 AI의 행동에 달려 있습니다 — 이것이 이 방식의 한계이자 전제입니다." },
  { q: "이 도구 모음을 프로젝트에 붙이는 설치 프로그램은 '여러 번 실행해도 안전하다'고 안내합니다. 설치를 두 번 실행해도 시작 알림 장치가 두 개로 늘어나지 않는 이유는 무엇일까요?",
    options: [
      "설치할 때마다 설정 파일을 처음부터 완전히 새로 만들어 덮어쓰기 때문이다",
      "두 번째 실행부터는 설치 프로그램이 아무 일도 하지 않고 곧바로 종료되기 때문이다",
      "똑같은 알림이 이미 등록되어 있는지 먼저 확인하고, 없을 때만 새로 추가하기 때문이다",
      "기존 알림을 매번 전부 지운 다음 처음부터 다시 등록하기 때문이다"
    ], answer: 2,
    explain: "설치 프로그램(install.sh)은 설정 파일(settings.json)에 똑같은 알림 항목이 이미 있는지 먼저 찾아보고, 없을 때만 추가합니다. 그래서 몇 번을 실행해도 결과가 같고 — 이런 성질을 멱등성(idempotency)이라고 합니다 — 사용자가 따로 넣어 둔 다른 설정도 그대로 보존됩니다. 설정을 새로 만들거나 지웠다 다시 쓰는 방식이었다면 사용자 설정이 사라졌을 것입니다." },
  { q: "설치를 실행했는데, 프로젝트에 이미 있던 설정 파일의 내용이 깨져 있는(형식이 잘못된) 상태입니다. 설치 프로그램은 어떻게 동작할까요?",
    options: [
      "무엇이 문제인지 알려주는 메시지를 띄우고 설치를 즉시 중단한다",
      "깨진 파일을 빈 설정으로 조용히 덮어쓰고 설치를 계속 진행한다",
      "경고만 남기고 그 부분을 건너뛴 채 설치를 성공으로 마무리한다",
      "다른 처리 방식으로 자동 전환해서 아무 일 없던 것처럼 계속 진행한다"
    ], answer: 0,
    explain: "깨진 설정 파일(잘못된 JSON)을 만나면 설치 프로그램은 명확한 에러 메시지와 함께 즉시 멈춥니다. 조용히 덮어쓰면 사용자가 원래 넣어 둔 설정이 사라지고, 건너뛰면 반쯤만 설치된 어중간한 상태가 남기 때문입니다. 마지막 검토 단계에서 '문제가 있으면 크게 알리고 멈춘다'는 원칙으로 추가된 안전장치입니다." },
  { q: "사각지대 점검 단계에서는 코드를 서로 다른 네 가지 관점으로 조사하는 보조 조사원(에이전트) 네 명을 한꺼번에 출발시키라고 지시합니다. 한 명씩 차례로 시키지 않는 이유는 무엇일까요?",
    options: [
      "네 명이 조사 결과를 실시간으로 공유하며 협력하게 하려는 것이다",
      "도구 규칙상 보조 조사원은 반드시 여러 명을 묶어서만 부를 수 있기 때문이다",
      "보조 조사원을 네 명까지만 쓰도록 개수를 제한하려는 것이다",
      "네 명을 동시에 조사시켜서 전체 대기 시간을 크게 줄이려는 것이다"
    ], answer: 3,
    explain: "네 관점의 조사는 서로 독립적이라 동시에 진행할 수 있습니다. 한 메시지에서 한꺼번에 출발시키면 병렬로 실행되어, 한 명씩 기다렸다 시키는 것보다 전체 시간이 약 4분의 1로 줄어듭니다. 각 조사원은 서로의 결과를 공유하지 않고 각자 조사한 뒤 따로 보고합니다." },
  { q: "저장소를 구축하며 만든 자동 점검에는 '스킬과 에이전트 문서 개수가 정해 둔 숫자와 정확히 일치하는지' 세어 보는 항목이 있습니다. 이 검사의 진짜 목적은 무엇일까요?",
    options: [
      "문서 양식(템플릿) 파일이 빠짐없이 들어 있는지 확인하려는 것이다",
      "구성 요소를 늘리거나 줄일 때 관련 문서와 규칙도 함께 고치도록, 일부러 점검이 실패하게 만든 걸림돌이다",
      "연결해 둔 바로가기(심링크)가 깨지지 않았는지 확인하려는 것이다",
      "각 문서의 머리말 형식이 올바른지만 보는 검사라서 개수와는 상관이 없다"
    ], answer: 1,
    explain: "이 검사는 일부러 깨지라고 심어 둔 걸림돌(tripwire)입니다. 새 스킬이나 에이전트를 추가하면 개수가 어긋나 점검이 실패하는데, 그 실패가 '숫자만 고치지 말고 설치 스크립트와 규칙 문서, 안내서까지 함께 갱신하라'는 신호 역할을 합니다. 구축 당시에는 여덟 개(스킬 5 + 에이전트 3)였고, 이후 에이전트가 하나 늘었을 때 실제로 이 숫자도 함께 갱신되었습니다." },
  { q: "아직 코드가 한 줄도 없는 새 프로젝트에서 사각지대 점검을 실행하면, 평소와 어떻게 달라질까요?",
    options: [
      "네 가지 관점을 모두 조사하고, '비슷한 기존 기능' 항목에는 조사 결과 없음이라고 적는다",
      "코드가 없으므로 요구사항 인터뷰 단계를 통째로 건너뛰고 바로 문서를 쓴다",
      "'비슷한 기존 기능' 관점 하나를 빼고 세 가지 관점만 조사하며, 결과 문서에서도 그 항목을 뺀다",
      "조사는 평소대로 하되, 마지막의 문서 검증 단계만 생략해서 시간을 아낀다"
    ], answer: 2,
    explain: "'비슷한 기존 기능 찾기'는 이미 있는 코드를 뒤지는 조사라서, 코드가 없는 새 프로젝트(greenfield)에서는 조사할 대상 자체가 없습니다. 그래서 그 관점을 아예 빼고 세 가지 관점만 조사하고, 결과 문서에도 그 항목을 싣지 않습니다. 항목을 남겨 두고 '없음'이라고 적는 것과 조사 대상에서 빼는 것은 다른 동작입니다." }
];
const quiz = document.getElementById("quiz");
QUESTIONS.forEach((it, i) => {
  const d = document.createElement("div");
  d.className = "q"; d.id = "q" + i;
  d.innerHTML = "<p><b>Q" + (i + 1) + ".</b> " + it.q + "</p>" +
    it.options.map((o, j) =>
      '<label><input type="radio" name="q' + i + '" value="' + j + '"> ' + o + "</label>"
    ).join("") +
    '<div class="explain" hidden><b>해설.</b> ' + it.explain + "</div>";
  quiz.appendChild(d);
});
function grade() {
  let ok = 0;
  QUESTIONS.forEach((it, i) => {
    const sel = document.querySelector('input[name="q' + i + '"]:checked');
    const el = document.getElementById("q" + i);
    const good = sel && Number(sel.value) === it.answer;
    el.className = "q " + (good ? "correct" : "wrong");
    el.querySelectorAll("label")[it.answer].classList.add("answer");
    el.querySelector(".explain").hidden = false;
    if (good) ok++;
  });
  const r = document.getElementById("result");
  r.textContent = ok === QUESTIONS.length
    ? "통과 (" + ok + "/" + QUESTIONS.length + ") — 머지 가능"
    : "미통과 (" + ok + "/" + QUESTIONS.length + ") — 오답 확인 후 재시도. 머지 금지";
}
</script>
</body>
</html>
```

- [ ] **Step 2: Verify in a real browser (Playwright MCP)**

1. `browser_navigate` to `file:///home/dkdlqoddi/dev-env-blindspot/docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html`
2. `browser_snapshot` — expect: summary list + 6 question cards, no visible 해설.
3. Click `정답 확인` with nothing selected — expect: `미통과 (0/6)`, all 6 해설 blocks visible, each correct option highlighted.
4. Select the correct option in all 6 questions (Q1→2nd option, Q2→3rd, Q3→1st, Q4→4th, Q5→2nd, Q6→3rd), click `정답 확인` again — expect: `통과 (6/6) — 머지 가능`, still exactly 6 해설 blocks (no duplication).
5. `browser_close`.

- [ ] **Step 3: Mechanical sentence scan**

Run: `grep -nE '→|\$\{|\[\[' docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html`
Expected: no matches (exit code 1) — no arrow shorthand or shell fragments anywhere in the prose. (ASCII `=>` in JS is fine and not matched.)

Then re-read the 6 questions and options once, applying the Task 1 self-check: could someone who has never seen code tell what is being asked? Jargon terms (멱등성, tripwire, greenfield 등) may appear only in 해설/summary with a plain-Korean lead-in.

- [ ] **Step 4: Run the repo check**

Run: `bash test/check.sh`
Expected: `OK: all checks passed`

- [ ] **Step 5: Commit and push**

```bash
git add docs/blindspot/quiz/2026-07-06-blindspot-agents-skills.html
git commit -m "docs: regenerate 2026-07-06 pre-merge quiz under non-developer readability rules

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push origin main
```

Expected: push succeeds to `origin main` (includes the spec, plan, and Tasks 1–3 commits).
