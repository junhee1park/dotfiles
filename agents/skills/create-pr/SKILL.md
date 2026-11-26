---
name: create-pr
description: Open a pull request for the current branch, and decide what goes in its title and body. Use whenever asked to open, create, or raise a PR.
allowed-tools: Bash(gh *) Bash(git *)
---

Open a pull request for the current branch with `gh pr create`, targeting the
branch this one was cut from — `main` unless it is stacked on another branch.
Push first if the branch has no upstream.

When the work is a chain of branches, each built on the one below, open it as
one GitHub stack with the `gh stack` extension instead of separate PRs based
on each other. If the branches split like a tree, ask how to divide them
first. Read its full help (`gh stack --help`, then the subcommand's `--help`)
before any stack operation, and use its commands rather than `gh pr` or the
REST API, which refuse or bypass stacked PRs.

The PR covers the whole branch against its base, including commits made
before this session or by someone else.

Title: same style as a commit subject — imperative mood, capitalized, no
trailing period. It names the branch's change as a whole, not its last commit.

Body: say what the branch changes, and anything a reviewer could misjudge from
the diff alone, such as an unexpected choice, a constraint the code doesn't
show, or a sequencing dependency. Keep it short and use whatever form reads
fastest; add a table or a diagram when it shows the change better than text.

When the diff changes what a user sees, show it in the PR as the project's
guidance describes. Put the before, from the base branch with the same data
and theme, next to the after so the reviewer can compare them; a new screen
needs only the after. Add a GIF when the change moves, since a still cannot
show it. Attach images with the `gh image` extension when it is installed. If
you can't capture what the guidance asks for, say what you tried and ask how
to proceed before opening the PR.

Report the PR URL.

Don't:
- Invent a reason for a change you weren't part of; describe what it does.
- Link the Linear issue. The branch name already links it and closes it on
  merge.
- Merge the PR or set the Linear issue to Done.
