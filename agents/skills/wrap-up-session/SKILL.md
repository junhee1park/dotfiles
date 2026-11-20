---
name: wrap-up-session
description: Close out the current session by recording its goal, its result, and where a method, a guide, or a design was missing, so a later retro can act on it. Use when the user wraps up a session.
---

# Wrap Up Session

Look back over this session while you still have its full context, and
record what a later retro needs.

## Look back

Work out from the conversation:

- the goal: what the user set out to do;
- the result: done, partly done, or changed direction;
- the gaps: where a method, a guide, or a design was missing. Look for
  friction the user hit, such as corrections, re-explanations, and repeated
  requests, and for struggle you got through on your own, such as commands
  that failed and were retried, workarounds, long exploration, guessing,
  skipped checks, and scripts improvised on the spot.

Keep a gap only if what was needed to avoid it existed beforehand: in the
codebase, in a doc, in what the user already knew, or in a check that could
have run. Leave out what could only be learned by building. Be honest about
your own struggle. It is the part the user cannot see.

## Record

If there are no gaps, say so and stop. Otherwise write a new file:

    ~/.local/share/agent-sessions/<owner>/<repo>/YYYY-MM-DD-HHMM-<slug>.md

Take `<owner>/<repo>` from the `origin` remote. Without one, use
`local/<directory name>`. If the session covered separate tasks, write one
file per task.

    # <the goal in one line>
    Session: <work, focus, or delegate>
    Path: <absolute path of the repository>
    Branch: <branch or none>
    PR: <url or none>
    Result: <done, partly done, or changed direction>

    ## Gaps
    - <what happened>. Needed: <the missing method, guide, or design>

## Report

Show the gaps in a few short lines, in the user's language. Ask which to fix
now with an instruction, a doc, a skill, a script, or a test. Apply only what
the user picks, and mark those `(fixed)` in the record.
