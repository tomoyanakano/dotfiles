#!/bin/bash
# PreToolUse hook: Block dangerous git operations
# Receives JSON on stdin with tool_input.command

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block git push --force (including -f shorthand)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)'; then
  echo '{"decision":"block","reason":"git push --force is blocked. Use regular push or ask the user to override."}' >&2
  exit 2
fi

# Block git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo '{"decision":"block","reason":"git reset --hard is blocked. This discards uncommitted changes."}' >&2
  exit 2
fi

# Block git add . / git add -A (wildcard staging)
if echo "$COMMAND" | grep -qE 'git\s+add\s+(\.|(-A|--all))'; then
  echo '{"decision":"block","reason":"git add . / git add -A is blocked. Stage specific files instead."}' >&2
  exit 2
fi

# Block --no-verify flag
if echo "$COMMAND" | grep -qE '--no-verify'; then
  echo '{"decision":"block","reason":"--no-verify is blocked. Do not bypass git hooks."}' >&2
  exit 2
fi

# Block git clean -f
if echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
  echo '{"decision":"block","reason":"git clean -f is blocked. This permanently deletes untracked files."}' >&2
  exit 2
fi

# Block git checkout . / git restore . (discard all changes)
if echo "$COMMAND" | grep -qE 'git\s+(checkout|restore)\s+\.$'; then
  echo '{"decision":"block","reason":"Discarding all changes is blocked. Specify files explicitly."}' >&2
  exit 2
fi

exit 0
