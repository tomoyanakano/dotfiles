---
description: Create a git worktree with consistent naming. Usage: /worktree <number|name>
---

# Worktree

Create a git worktree following the project's branch naming conventions.

## Usage

- `/worktree 42` → worktree name: `issue-42`
- `/worktree my-feature` → worktree name: `my-feature`

## Instructions

1. Parse the argument: `$ARGUMENTS`
2. If the argument is a number, prefix it with `issue-` (e.g., `42` → `issue-42`)
3. If the argument is a string, use it as-is
4. If no argument is provided, ask the user for a name
5. Use the `EnterWorktree` tool with the resolved name
