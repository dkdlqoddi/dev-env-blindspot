---
name: requirements-interview
description: Use when the user starts discussing a new feature, change request, or any task with unclear requirements — runs a structured Korean interview (one question at a time, architecture-changing questions first) grounded in codebase reality, then writes a requirements document with a four-quadrant unknowns map.
---

# Requirements Interview

The user's first prompt is a lossy map of what they actually need. Recover the territory by interviewing before building.

## Workflow

1. **Classify first.** Sort what you know into the four quadrants:
   - Known Knowns — explicitly stated in the request
   - Known Unknowns — questions you already know need answers
   - Unknown Knowns — preferences the user likely holds but hasn't said (naming, style, existing patterns)
   - Unknown Unknowns — territory nobody has looked at; note candidates, leave the digging to `blindspot-pass`

2. **Ground before asking.** Run the custom agent `codebase_scanner` with lens `conventions` and the task description BEFORE writing questions. Select the named custom-agent profile, not merely the same task label. If this Codex surface cannot select it, read that exact file under `.codex/agents/` and include its complete `developer_instructions` with the task input in a general subagent. Thread-cap handling is mandatory. Keep a rejected role pending. Wait for a subagent slot to become available, then retry it. Never continue to the next step or drop the role. If subagent spawning remains unavailable, run the required role in the parent using that exact profile's complete `developer_instructions` and the same task input; do not skip it. Include `docs/blindspot/` in its scan targets: past requirements/unknowns/report docs on adjacent topics record decisions the user already made. Questions that ignore the actual code waste the user's time. Skip only if the project has no code yet.

3. **Interview.** Ask exactly one Korean question per turn. Use `request_user_input` with one question and no auto-resolution when available and when 2–3 options cover the decision; otherwise end the turn with one direct Korean question. Use direct text when four meaningful options are required.
   - Write every question and option for someone who has never seen the code: unavoidable technical terms plain Korean first with the term in parentheses; code identifiers only after a plain description of what they do. One fact per sentence, ≤25 어절 each.
   - Order by architecture impact: answers that change the design come first.
   - Never re-ask what a past `docs/blindspot/` deliverable already answers — cite the earlier decision and move on.
   - Stop when remaining answers would no longer change what you'd build (typically 3–6 questions).
   - Record every question, answer, and its architecture impact.

4. **Write the document.** Follow `templates/requirements.md` in this skill's folder. Fill every section in Korean, for a reader who has never seen the code: no arrow shorthand (A→B) or unexplained jargon; unavoidable technical terms plain Korean first with the term in parentheses; one fact per sentence, ≤25 어절 each — split long compound sentences. Evidence links and 관련 문서 paths stay as they are. Before saving, self-check every sentence: could someone who has never seen code follow it, and is it one fact within 25 어절? Save to `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` (slug = kebab-case topic, date = today).

5. **Verify.** Run the custom agent `doc_verifier` on the saved file. Select the named custom-agent profile, not merely the same task label. If this Codex surface cannot select it, read that exact file under `.codex/agents/` and include its complete `developer_instructions` with the task input in a general subagent. Thread-cap handling is mandatory. Keep a rejected role pending. Wait for a subagent slot to become available, then retry it. Never continue to the next step or drop the role. If subagent spawning remains unavailable, run the required role in the parent using that exact profile's complete `developer_instructions` and the same task input; do not skip it. Fix every reported issue, re-save. Do not skip on PASS-looking drafts — verification is not optional.

6. **Hand off.** Tell the user (Korean): 다음 단계는 `blindspot-pass`로 Unknown Unknowns를 구체화하는 것.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Never ask the user something answerable by reading the code — that is what the scanner run is for.
- One decision per question. Batched questions get half-answers.
- A question the user cannot parse gets a guessed answer; guessed answers become wrong requirements. Every question and every document sentence must survive the "reader has never seen the code" test.
- Clean vocabulary does not equal readable: a 40+ 어절 sentence with nested clauses locks out the same readers even with zero jargon — the one-fact / ≤25 어절 bar is part of the standard.
- A question the user answered in a past cycle wastes the budget twice — the scanner covers `docs/blindspot/` history precisely so the interview can cite instead of re-ask.
