---
name: create-linear-issue
description: Create a Linear issue with the right assignment, status, project, and labels. Use whenever asked to create an issue, sub-issue, or follow-up.
---

Create the Linear issue. When it is an offshoot of the user's current
work (a sub-issue, a follow-up, a prerequisite), judging from the
conversation and the current branch, assign it to the user as "Todo"
and put it in the same project when that fits.

Title: what changes when the issue is done, or the symptom when the fix
isn't decided.

- English: imperative like a commit subject, or a noun phrase.
- Korean: end in a noun form, never "~한다".

Write the description for whoever picks the issue up later, and only
what they need to start that they can't see elsewhere. Linear already
shows the status and dates, and they will read the code as it is then,
so leave out the issue's status, the investigation, option comparisons
and line numbers. Keep a fact from the code when it changes how the
issue reads. Keep it short, with no headers.

Body: open with the problem or the goal, plus the context needed to
understand it. Write the content itself; don't prefix a line with a
label and a colon. What follows depends on how much is settled:

- Spec decided: everything that was decided, so they can build it
  without asking again.
- Only a problem or symptom: where and when it happens, and what was
  and wasn't checked. Add a direction only if one was discussed: state
  the change itself as something that could be done (in Korean, end
  it with ~할 수 있음), without labelling it an option or marking it
  undecided.

Body in Korean: noun-form endings and fragments by default. Never stop
a fragment on a particle or a comma; end it on a noun or ~함/~음.
Use ~다 only for a sentence that links cause and result and would
lose that link if split.

Refer to other issues and PRs as Linear mentions, not as plain text or
URLs.

Always inspect the team's existing labels and apply every label that fits the
issue. Do not create a new label unless the user explicitly asks for one.
