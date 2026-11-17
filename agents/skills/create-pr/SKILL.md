---
name: create-pr
description: Open a pull request for the current branch, and decide what goes in its title and body. Use whenever asked to open, create, or raise a PR.
allowed-tools: Bash(gh *) Bash(git *)
---

Open a pull request for the current branch with `gh pr create`, targeting the
branch this one was cut from — `main` unless it is stacked on another branch.
Push first if the branch has no upstream.

When the work is a chain of branches that each build on the one below, open
it as a GitHub stack with the `gh stack` extension. Do not open separate PRs
whose bases point at each other. Create the stack with
`gh stack init <bottom> ... <top>` and `gh stack submit`. Add PRs that are
already open with `gh stack link <pr> ...`, listed from the bottom. After
changing a lower branch, update the branches above it with `gh stack rebase`
and `gh stack push`. A stack is one straight chain, so if the branches form a
tree, say so and ask how to split them before opening anything. Each PR in
the stack still gets its own title and body by the rules below; set them with
`gh pr edit` when `submit` fills them in.

Take the scope from the full diff against the base branch — the PR covers the
whole branch, including commits made before this session or by someone else.

Don't invent a rationale for a change you weren't part of. For those, describe
what it does and leave it at that.

Title: same style as a commit subject — imperative mood, capitalized, no
trailing period. It names the branch's change as a whole, not its last commit.

Body: two or three sentences saying what the branch does. Then bullets only
for decisions a reviewer would otherwise get wrong — an unexpected choice, a
constraint that isn't visible in the code, a sequencing dependency — one
sentence each. Usually there are none, and the body is just the summary. A PR
body with no bullets is a good one, not a lazy one; never pad the list to have
something in it.

When the branch does two or more separable things, give each its own sentence
instead of compressing them into one.

The diff says what changed, CI says whether it works, and the issue says why
it was asked for. Anything the body repeats from those three makes it longer
without making it more useful. What's left over is the body, and it is short.

Durable reasoning belongs in none of them — it goes in a code comment, where
the next reader of that code finds it, rather than in a body that stops being
read once the PR merges.

Keep the body under 120 words, screenshots and their captions aside. When it
runs longer, that isn't a body to trim: move what overflows to the comment or
the issue where it belongs.

No section headers. A body that needs them is too long. No test plan or
checklist unless the user asks for one.

Never link the Linear issue. The branch name already carries the issue
identifier, which is what links the two and closes the issue on merge.

When the diff touches the UI, judge whether screenshots would help the
reviewer. If so, capture them by running the app when that is possible;
when it isn't, create the PR without them and note that screenshots can
be added later. Don't block PR creation waiting on screenshots.

Attach images with the `gh image` extension when it is installed. The markdown
it prints renders at the full width of the body; when that is too large, size
the image with an `<img width>` tag instead.

Report the PR URL. Do not merge it, and do not set the Linear issue to Done.
