---
name: linear-issue
description: Write a Linear issue's title and description, and set assignment, status, project, and labels when creating it. Use whenever asked to create an issue, sub-issue, or follow-up, or to change an existing issue's title or description.
---

When creating an issue: if it is an offshoot of the user's current work
(a sub-issue, a follow-up, a prerequisite), judging from the
conversation and the current branch, assign it to the user as "Todo"
and put it in the same project when that fits. Always inspect the
team's existing labels and apply every label that fits the issue. Do
not create a new label unless the user explicitly asks for one.

The rest applies both when creating an issue and when changing its
title or description. When done, give the user a link to each issue
created or changed.

Title: what changes when the issue is done, or the symptom when the fix
isn't decided.

- English: imperative like a commit subject, or a noun phrase.
- Korean: never "~한다". End an action in ~기, or write a noun phrase
  from terms the product and its UI already use. Don't coin nouns to
  force a noun ending.

Write the description for whoever picks the issue up later, and only
what they need to start that they can't see elsewhere. Linear already
shows the status and dates, and they will read the code as it is then,
so leave out the issue's status, the investigation, option comparisons
and line numbers. Keep a fact from the code when it changes how the
issue reads. Keep it short, with no headers.

Body: open with the problem or the goal, plus the context needed to
understand it. Write sentences, not labelled fields. What follows
depends on how much is settled:

- Spec decided: everything that was decided, so they can build it
  without asking again.
- Only a problem or symptom: where and when it happens, and what was
  and wasn't checked. Add a direction only if one was discussed: state
  the change itself as something that could be done (in Korean, end
  it with ~할 수 있음), without labelling it an option or marking it
  undecided.

When something is left for later, say where it will be decided: later
in this issue, or in another one.

In Korean titles and bodies, keep terms that are used in English as
they are (UI labels, product and technical terms); translating them
reads awkwardly.

Body in Korean: mostly terse. Use ~다 only for a sentence that walks
through how a situation unfolds; a single fact, decision, or task stays
terse even in the opening.

In the terse form, when the verb has an action-noun form, end on the
noun itself rather than adding ~함; otherwise end on ~함/~음. Never end
on a bare noun, a particle, or the ㅁ-form of a native Korean verb;
rephrase that sentence around an action noun or a 하다 verb instead.
Write a negative as a predicate (~없음, ~하지 않음), not as a
negative-prefix noun.

Mention, as a Linear mention, any issue this one depends on or overlaps
with; never refer to issues or PRs as plain text or URLs. A parent
issue's scope covers all its sub-issues; when a sub-issue falls outside
it, update the parent.
