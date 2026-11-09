---
name: focus-session
description: Work through a change where the user owns every design decision. The user settles the core decisions before seeing any proposal, the agent implements in reviewable steps, and the session ends with the user explaining the change from memory. Use when the user starts a focus session or wants to stay in control of an important change.
---

# Focus Session

The value is in the decisions, not the typing. What matters is who decides
first: a design the agent proposes first pulls the user toward it and turns
their part into approval. So the user decides first, and the agent does most
of the typing after that.

## Decide first

Before seeing any proposal from you, the user writes down the core decisions:
how the work is divided, what the types are, and what passes between the
parts. Any form works: a short note, a list, or skeleton code when that is
faster for them.

Until the user has written these down, do not propose a design, a structure,
or a skeleton, and do not write code that implies one. If asked to start
without them, ask for them first. You may gather facts the user needs, such as
existing code and constraints, presented without a recommendation.

## Probe

Read the user's decisions against the actual code and probe them for holes.
Ask only questions whose answer would change what gets built, one at a time.
With each question, give the facts the decision depends on, such as existing
code, constraints, and what each option would affect, but no recommendation.
Make the judgment the user's alone. Recommend only when the user asks for it.
Look up facts yourself.

The user records each decision themselves. Do not edit their notes. Stop when
nothing open would change the build, and confirm that the user considers the
decisions settled.

## Skeleton

The skeleton is the decisions written as code: public interfaces, types, data
shapes, and module boundaries. Keep it to what other code depends on, and leave
internal helpers to emerge during implementation.

If the user wrote skeleton code, read it, ask about anything that conflicts
with their decisions or the codebase, and do not edit it.

Otherwise, write the skeleton from the user's decisions, encoding only what
they decided. Where the skeleton needs a decision they have not made, stop and
ask instead of choosing. Show the skeleton for review, and do not start
implementation until the user confirms it.

## Implement

Implement in steps sized for careful review, each serving one purpose. After
each step, explain what changed with file and line references, report the
checks you ran, and stop for review. Questions are discussion, not approval.

The confirmed skeleton is the user's decision. If implementation suggests
changing it, such as a signature, a type, or a boundary, stop before changing
it. Explain what you found, the options you see, and what each would cost,
including keeping it as is. Do not recommend one unless the user asks. Wait
for the user's decision. Never adjust the skeleton silently to make the
implementation fit.

## Writing by hand

Hand-writing is the user's choice, for when code helps them think or when they
are learning a new concept. When the user wants to write a part, mark the spot
with a `TODO(human)` comment and send a request with three parts:

- Context: what is already built around it.
- Task: what to write and what it must satisfy.
- Guidance: what to weigh, without giving the answer.

Then stop and wait. Do not write that part yourself. When the user is done,
review their code briefly and continue.

## Close

When the change is complete:

1. Ask the user to explain, without looking at the code, what changed and how
   it works. Compare the explanation with the code and point out anything
   missing or wrong, citing files and lines. Do not skip this, even for a
   small change.
2. Write one line on what comes next.
3. List, as facts, where this session lacked something an agent needed: what
   the user corrected or pointed out, questions an instruction or doc would
   have answered, and checks you could not run yourself. Ask which to fix now
   with an instruction, a doc, or a check, and apply only those.
4. If any gaps were listed, write them to a new file in the same place and
   format as a delegate session record, with `Session: focus`, only the
   `Gaps` section, and the fixed ones marked `(fixed)`.

Review approval does not authorize staging, committing, or pushing. Follow the
user's separate instructions for those.
