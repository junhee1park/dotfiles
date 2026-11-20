---
name: session-retro
description: Gather the gaps recorded at the end of recent sessions, find the ones worth fixing, and let the user decide what to fix. Use when the user runs a session retro.
---

# Session Retro

Sessions end with a record of where an agent lacked a method, a guide, or a
design. This retro finds the gaps worth fixing and lets the user decide.

## Gather

Find the records under `~/.local/share/agent-sessions/` with gaps not marked
`(fixed)` or `(dropped)`. For a record with a PR, check whether the work was
fixed after the session, by a review or by later commits. Add that as a gap
only if what was needed to avoid it existed beforehand.

## Narrow

Merge gaps that point to the same missing thing. Rank them by how often they
happened and what they cost, and keep the top five. Leave the rest open for a
later retro.

## Present

First say in two or three plain sentences how many records and gaps you
looked at and how many are left. Then go through them one at a time:

- what happened, with the session and date;
- what was missing;
- a proposed fix, and where it would go: the global instructions, a
  repository doc, a skill, a script, or a test.

Ask the user to pick, change, or drop it, and mark the gaps `(fixed)` or
`(dropped)` to match. Use plain language and explain any term the user may
not know.

## Close

List the fixes the user picked, and apply them only if the user asks.
