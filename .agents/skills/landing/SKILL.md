---
name: landing
description: Safely validate and land changes to this macOS Pomodoro app when asked to merge, commit, or publish work.
---

# Landing changes

Use this skill when asked to land, merge, commit, or publish work in the Pomodoro repository. Do not interpret “land” as permission to push or publish: confirm the destination and operation when they are not explicit.

## Before changing Git state

1. Inspect the current branch, working tree, recent commits, and configured remotes.
2. Review the complete diff, including untracked files that are part of the change. Identify unrelated or pre-existing edits and preserve them.
3. Do not discard edits, rewrite shared history, force-push, or publish a branch without explicit authorization. Never assume a remote name or merge strategy.
4. If the requested destination or whether to create a commit is unclear, ask before taking that step.

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

1. Run the applicable checks and inspect the final diff again.
2. Perform only the explicitly requested Git operation. Keep unrelated working-tree changes out of commits.
3. Verify the resulting branch/commit state and, if explicitly authorized, the published destination.
4. Summarize what was landed, the resulting commit or destination, and the checks that passed or could not run.
