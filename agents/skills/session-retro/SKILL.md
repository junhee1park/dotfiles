---
name: session-retro
description: Review recorded focus and delegate sessions. Check what became of the agent's judgment calls, whether the work was delegated well, and what the agent's environment lacked, with the user making every judgment. Use when the user runs a session retro.
---

# Session Retro

Sessions leave records: judgment calls an agent made on its own, and gaps
where it lacked something it needed. This retro turns them into two things the
user can act on: a sense for what to delegate and how, and improvements to the
agent's environment. The user judges what happened, and you only gather the
facts. For improvements, you propose and the user decides.

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

## Improvements

Gather candidates for improving how agents work, from three sources:

- the open gaps in the records;
- the decisions just judged wrong for environment reasons;
- recent conversations, including ones that were neither focus nor delegate
  sessions. List the Claude Code transcripts under `~/.claude/projects/` and
  the Codex transcripts under `~/.codex/sessions/` modified since the time in
  `~/.local/share/agent-sessions/last-harvest`, or in the last two weeks if
  that file is missing, leaving out this session. For each, extract its text
  with `scripts/extract-transcript.sh <file>` and have a subagent pull out
  what the user corrected or pointed out, steps repeated by hand, checks left
  to the user, questions an instruction or doc would have answered, and
  skills that behaved differently from what the user wanted, each with the
  session and a quote.

Merge candidates that describe the same thing, noting how often each came up.
Present them one at a time: what happened, with evidence; the user's intent
and direction as you infer them, marked as inferred; a proposed change; and
where it would go: the global instructions, a repository doc, a skill, a
script, or a test. Ask the user to correct the intent and to pick, change, or
drop the change. Mark the gaps the user handles `(fixed)` or `(dropped)`.
When done, write the current time to `last-harvest`.

## Summarize

When everything has been handled, describe what the wrong decisions and the
picked improvements have in common, using only what was found. Then list the
improvements the user picked. Apply them only if the user asks.
