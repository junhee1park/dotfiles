---
name: session-retro
description: Review recorded focus and delegate sessions. Check what became of the agent's judgment calls, whether the work was delegated well, and what the agent's environment lacked, with the user making every judgment. Use when the user runs a session retro.
---

# Session Retro

Sessions leave records: judgment calls an agent made on its own, and gaps
where it lacked something it needed. This retro turns them into two things the
user can act on: a sense for what to delegate and how, and improvements to the
agent's environment. The user judges. You gather the facts.

## Collect

Find the records under `~/.local/share/agent-sessions/` that have an empty
`Verdict` or a gap not marked `(fixed)` or `(dropped)`. If the user named a
repo or a period, keep to that. List the sessions, grouped by repo, with the
number of open decisions and gaps in each.

Then go through the sessions one at a time.

## Decisions

For each decision with an empty `Verdict`, look up what happened after it, in
the repository at `Path`:

- whether the PR was merged, closed, or is still open, and what reviewers said
  about this part;
- later commits that changed or reverted the code this decision shaped;
- bugs, issues, or fixes that trace back to it.

Show the decision, its reason, its cost if wrong, and what you found and
where, or that you found nothing. Do not say whether the decision was right.
Ask for a verdict: right, wrong, or unknown. For a wrong one, also ask the
cause: delegation (the brief lacked it), environment (no instruction, doc, or
check covered it), or agent (the information was there and was missed). Write
it as given:

    Verdict: wrong, environment. <the user's reason>

If the user wants to wait, leave the `Verdict` empty.

## Delegation

For a delegate session, show the brief, the questions asked before starting,
the verdicts just given, and any later rework you found. Ask the user whether
the task's size, the information they gave, and the direction were right for
delegating. Add their answer to the record under `## Delegation`.

## Environment

Show the open gaps and the decisions judged wrong for environment reasons.
Ask the user which to address and how. Do not propose improvements unless
asked. Mark the gaps the user handles `(fixed)` or `(dropped)`.

## Summarize

When every session has been handled, describe what the wrong decisions and
the gaps have in common, using only what the records show. Then list the
environment improvements the user chose. Apply them only if the user asks.
