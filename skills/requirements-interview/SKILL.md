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

2. **Ground before asking.** Spawn ONE `codebase-scanner` agent (subagent_type: `codebase-scanner`) with lens `conventions` and the task description BEFORE writing questions. Questions that ignore the actual code waste the user's time. Skip only if the project has no code yet.

3. **Interview.** In Korean, ONE question per message, via AskUserQuestion with 2–4 concrete options where possible.
   - Order by architecture impact: answers that change the design come first.
   - Stop when remaining answers would no longer change what you'd build (typically 3–6 questions).
   - Record every question, answer, and its architecture impact.

4. **Write the document.** Follow `templates/requirements.md` in this skill's folder. Fill every section in Korean. Save to `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` (slug = kebab-case topic, date = today).

5. **Verify.** Spawn `doc-verifier` (subagent_type: `doc-verifier`) on the saved file. Fix every reported issue, re-save. Do not skip on PASS-looking drafts — verification is not optional.

6. **Hand off.** Tell the user (Korean): 다음 단계는 `blindspot-pass`로 Unknown Unknowns를 구체화하는 것.

## Gotchas

<!-- Append recurring failure points here as they surface; do not delete entries. -->
- Never ask the user something answerable by reading the code — that is what the scanner run is for.
- One decision per question. Batched questions get half-answers.
