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
   - One fact per sentence, ≤25 어절 each — split long compound sentences. Name concrete actors and actions ("사용자가 저장을 누르면"); on first appearance of an abstract concept, add one everyday example or comparison.
   - Code identifiers and file paths appear only where they are the subject being explained, introduced by a plain description.
   - Before saving, self-check every sentence: could someone who has never seen code follow it, and is it one fact within 25 어절? If not, rewrite it.

   The sections that matter most:
   - 검토한 대안과 트레이드오프 — every real decision shows at least one rejected alternative and why
   - 의도적 범위 제외 — mandatory and never empty; if truly nothing was cut, state why the scope is total
   - 열린 질문 — each unresolved item gets an owner or a resolution plan

3. **Save** to `docs/blindspot/YYYY-MM-DD-<slug>-explainer.md`.

4. **Verify.** Submit the independent roles together and use all runtime concurrency available: run the custom agent `doc_verifier` on the file, and the custom agent `codebase_scanner` with lens `integration-points`, the saved file's path, and instructions to cross-check the design against code reality — every integration point the document assumes (APIs, schemas, configs, files) must exist and match, mismatches cited as `file:line`. For each role, select the named custom-agent profile, not merely the same task label. If this Codex surface cannot select it, read that exact file under `.codex/agents/` and include its complete `developer_instructions` with the task input in a general subagent. Thread-cap handling is mandatory. Attempt to spawn every role, submitting as many pending roles in parallel as the runtime accepts. Keep every rejected role pending. Wait for a subagent slot to become available, then retry each pending role. Never synthesize early or drop a role. If subagent spawning remains unavailable, run every pending role in the parent using that role profile's complete `developer_instructions` and the same task input. Fix every issue from both, re-save. Skip the cross-check only when the project has no code.

5. **Hand off.** Tell the user (Korean): 구현 시작 시 `work-report` 노트 모드로.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- An explainer is not a concatenation of the other two docs; it must stand alone for a reader with zero context.
- An explainer that reads like an engineering changelog fails its zero-context purpose; every sentence must survive the "reader has never seen the code" test.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
