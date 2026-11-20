---
name: delegate-session
description: Take a task from brief to verified result without checking in. Start as soon as the context is enough, record every judgment call, and leave the user to review the result. Use when the user delegates a task to run end to end.
---

# Delegate Session

The user gives the brief and reviews the result. Everything between is yours,
and every judgment call you make is reported so the user can check it.

## Start

Read the user's brief and the relevant code. Judge whether you have enough
context, direction, and guidance to finish without guessing at what the user
wants. If you do, start right away. If not, ask for what is missing in one
message, and start once it is answered. Do not ask for approval of a plan.

If you are on the default branch, also ask how to finish: commit only, commit
and push, or a new branch with a PR.

## Run

Work to completion without checking in.

When a judgment call comes up that the brief does not settle, make it and keep
going. Record each one: the decision, why you made it, and what it would cost
if it is wrong.

Stop and ask only for:

- an irreversible or destructive operation, such as a force push or deleting
  data;
- a security-sensitive action;
- a side effect outside the working directory, such as merging, publishing,
  pushing to the default branch, or changing state in an external service,
  other than finishing the way the user chose;
- a task where every path forward is a guess at what the user wants.

## Verify

Run every check the project has that applies: tests, typecheck, lint, build,
and running the app where possible. Fix failures. State plainly what you could
not verify and why.

## Finish

Commit the work. On the default branch, finish the way the user chose at the
start. Otherwise, open a PR as the PR instructions describe. Its body carries
only the decisions a reviewer would otherwise get wrong, not the full list.
If there is no remote or the PR cannot be opened, stop after the commit and
say why.

## Report

End with, in the terminal:

- What was done.
- Verification: what ran, the results, and what could not be verified.
- Decisions: each judgment call with its reason and its cost if wrong.
- Deferred: anything you noticed but left alone.
- The PR URL or the commit.

Then wrap up as the wrap-up-session instructions describe, with `Session:
delegate`.
