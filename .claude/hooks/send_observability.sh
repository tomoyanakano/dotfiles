#!/bin/bash
# Wrapper script to send events to the observability server.
# Derives --source-app from the current working directory name.
# Usage: send_observability.sh <event-type> [extra-args...]

OBSERVABILITY_DIR="$HOME/projects/claude-code-observability"
SEND_SCRIPT="$OBSERVABILITY_DIR/.claude/hooks/send_event.py"
EVENT_TYPE="$1"
shift

# Derive source-app from current directory name (basename of cwd)
SOURCE_APP="$(basename "$PWD")"

# Pass stdin through to the Python script
cd "$OBSERVABILITY_DIR" && exec uv run "$SEND_SCRIPT" --source-app "$SOURCE_APP" --event-type "$EVENT_TYPE" "$@"
