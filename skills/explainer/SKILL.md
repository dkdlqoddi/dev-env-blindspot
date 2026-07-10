---
name: explainer
description: Use when the user asks for a spec, design document, explainer, pitch, or "문서로 정리해줘" — bundles requirements, resolved unknowns, and code reality into one standalone Korean document with decisions, alternatives with trade-offs, and explicit out-of-scope items.
---

# Explainer

One document a zero-context reader can use to understand what is being built, what was decided, and what was deliberately left out.

## Workflow

1. **Gather inputs.** Read `docs/blindspot/*-requirements.md` and `*-unknowns.md` for this topic if they exist; skim the code areas they reference. If neither exists, tell the user and recommend `requirements-interview` or `blindspot-pass` first — never fabricate requirements.

2. **Write.** Follow `templates/explainer.md` in this skill's folder. Korean. The entire document is for a reader who has never seen the code:
   - Describe what happens and why, never how the code looks. No arrow shorthand (A→B), no unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses — e.g. "설정 파일이 깨져 있으면(잘못된 JSON)".
   - Code identifiers and file paths appear only where they are the subject being explained, introduced by a plain description.
   - Before saving, self-check every sentence: could someone who has never seen code follow it? If not, rewrite it.

   The sections that matter most:
   - 검토한 대안과 트레이드오프 — every real decision shows at least one rejected alternative and why
   - 의도적 범위 제외 — mandatory and never empty; if truly nothing was cut, state why the scope is total
   - 열린 질문 — each unresolved item gets an owner or a resolution plan

3. **Save** to `docs/blindspot/YYYY-MM-DD-<slug>-explainer.md`.

4. **Verify.** Spawn `doc-verifier` (subagent_type: `doc-verifier`) on the file; fix every issue, re-save.

5. **Hand off.** Tell the user (Korean): 구현 시작 시 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- An explainer is not a concatenation of the other two docs; it must stand alone for a reader with zero context.
- An explainer that reads like an engineering changelog fails its zero-context purpose; every sentence must survive the "reader has never seen the code" test.
