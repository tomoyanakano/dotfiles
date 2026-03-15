#!/bin/bash
# Uninstall claude-code-hooks-multi-agent-observability
# Usage: ~/.claude/hooks/cleanup-observability.sh

set -e

OBSERVABILITY_DIR="$HOME/projects/claude-code-observability"
SETTINGS_FILE="$HOME/dotfiles/.claude/settings.json"
HOOK_SCRIPT="$HOME/dotfiles/.claude/hooks/send_observability.sh"

echo "=== Claude Code Observability Cleanup ==="

# 1. Stop server
if [ -d "$OBSERVABILITY_DIR" ]; then
  echo "[1/4] Stopping observability server..."
  cd "$OBSERVABILITY_DIR" && just stop 2>/dev/null || true
  echo "  Done."
else
  echo "[1/4] Observability directory not found, skipping server stop."
fi

# 2. Remove repository
echo "[2/4] Removing repository..."
if [ -d "$OBSERVABILITY_DIR" ]; then
  rm -rf "$OBSERVABILITY_DIR"
  echo "  Removed $OBSERVABILITY_DIR"
else
  echo "  Already removed."
fi

# 3. Remove hook script
echo "[3/4] Removing hook script..."
if [ -f "$HOOK_SCRIPT" ]; then
  rm "$HOOK_SCRIPT"
  echo "  Removed $HOOK_SCRIPT"
else
  echo "  Already removed."
fi

# 4. Clean settings.json
echo "[4/4] Removing observability hooks from settings.json..."
if command -v python3 &>/dev/null; then
  python3 - "$SETTINGS_FILE" <<'PYEOF'
import json, sys

path = sys.argv[1]
with open(path, "r") as f:
    settings = json.load(f)

hooks = settings.get("hooks", {})
cleaned = {}

for event_type, entries in hooks.items():
    new_entries = []
    for entry in entries:
        new_hooks = [
            h for h in entry.get("hooks", [])
            if "send_observability.sh" not in h.get("command", "")
        ]
        if new_hooks:
            entry["hooks"] = new_hooks
            new_entries.append(entry)
    if new_entries:
        cleaned[event_type] = new_entries

# Remove event types that only had observability hooks
settings["hooks"] = cleaned

with open(path, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("  Cleaned settings.json")
PYEOF
else
  echo "  python3 not found. Please manually remove send_observability.sh entries from $SETTINGS_FILE"
fi

echo ""
echo "=== Cleanup complete ==="
echo "Observability hooks have been removed. Claude Code will continue to work normally."
