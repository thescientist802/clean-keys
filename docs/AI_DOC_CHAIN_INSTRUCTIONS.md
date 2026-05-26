# AI_DOC_CHAIN_INSTRUCTIONS

Use this checklist at the **end of every AI session** so the next session can continue smoothly.

## Required Update Order (do these in sequence)
1. **`docs/SESSION_SUMMARY.md`**
   - Append what changed in this session (code + docs).
   - Record key decisions and why they were made.
   - Add current end-state in 2–4 bullets.

2. **`docs/TASKS.md`**
   - Move finished items from `Active` to `Completed`.
   - Add newly discovered work to `Active`.
   - Keep `Next Immediate Steps` to the next 1–3 concrete actions.
   - Update `Blockers` with owner + unblock condition.

3. **`docs/KNOWN_ISSUES.md`**
   - Add any new reproducible issue with status (`open`, `mitigated`, or `resolved`).
   - Remove or mark resolved issues with the commit/PR reference when fixed.

4. **`docs/AI_ONBOARDING.md`**
   - Update only if architecture, build/test commands, constraints, or stack changed.
   - Keep this doc stable and high-signal; avoid session noise.

## Quality Bar
- Write short, factual bullets; avoid speculation.
- Include exact file paths and command names when relevant.
- Keep each doc internally consistent with the others.

## Handoff Rule
Before ending a session, quickly re-read all four docs and ensure they tell one coherent story of: 
**what was done, what remains, what is broken, and what to do next**.
