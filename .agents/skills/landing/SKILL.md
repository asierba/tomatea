---
name: landing
description: Validate and transfer changes from a Delta worktree into the user's primary Pomodoro checkout when asked to land work.
---

# Landing changes

In Delta, landing changes from a managed worktree is not complete when they are only committed in that worktree. The destination is the user's primary project checkout. A request to land authorizes transferring the changes there, but does not authorize publishing to an external remote.

## Before changing Git state

1. Inspect the current branch, working tree, recent commits, and configured remotes. Identify the primary checkout's remote from `git remote -v`; Delta commonly names it `local`, but verify its URL and do not assume.
2. Review the complete diff, including untracked files that are part of the change. Identify unrelated or pre-existing edits and preserve them.
3. Determine the intended destination branch in the primary checkout; do not assume the worktree's branch name is the destination. If the branch or primary-checkout remote cannot be verified, ask before transferring.
4. Do not discard edits, rewrite shared history, force-push, or push to an external remote. If the primary checkout rejects an update because it has uncommitted edits, stop and preserve them rather than trying to overwrite or clean the checkout.

## Validate this repository

This is a Swift package for a macOS 13+ menu-bar app. It uses the Xcode Swift toolchain and AppKit, so run validation on macOS:

```sh
swift test
swift build
```

Report any command that could not run because the environment is not macOS or lacks the required Swift toolchain; do not present an unrun check as passing.

When reviewing timer changes, check that the behavior remains consistent with the product contract in `README.md`: 25-minute focus sessions, 5-minute short breaks, and a 15-minute break after each fourth focus session. A completed session advances to the next session but does not start it automatically; Reset returns to a stopped focus session. Run or update tests for affected timer behavior.

For UI changes, inspect the menu-bar entry point and `PomodoroView`, and verify the relevant behavior in the macOS app when the environment permits. The package test suite alone does not validate menu-bar presentation or accessibility.

## Complete the requested landing

1. Run the applicable checks and inspect the final diff again. Keep unrelated working-tree changes out of the landing.
2. Commit the intended changes in the Delta worktree if they are not already committed.
3. Transfer the worktree's commit(s) to the verified primary-checkout remote and destination branch using a normal, non-force update (for example, `git push <primary-checkout-remote> HEAD:<destination-branch>`). Delta's `local` remote normally points to the original checkout; it is distinct from any shared upstream used for review or publication.
4. Verify that the destination branch now contains the landed commit and confirm the primary checkout updated when that can be checked safely. A commit that exists only in the worktree is not a completed landing.
5. Summarize the destination checkout and branch, landed commit, and checks that passed or could not run. If transfer fails, report the worktree commit separately and do not claim it was landed.
