#!/bin/bash
# PreToolUse hook: Block access to sensitive files
# Works for Read, Write, Edit tools

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=""

case "$TOOL_NAME" in
  Read)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  Write|Edit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  *)
    exit 0
    ;;
esac

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

# Block SSH private keys
if echo "$FILE_PATH" | grep -qE '(id_rsa|id_ed25519|id_ecdsa|id_dsa)$'; then
  echo '{"decision":"block","reason":"Access to SSH private keys is blocked for security."}' >&2
  exit 2
fi

# Block AWS credentials
if echo "$FILE_PATH" | grep -qE '\.aws/credentials$'; then
  echo '{"decision":"block","reason":"Access to AWS credentials is blocked."}' >&2
  exit 2
fi

# Block token/secret files
if echo "$BASENAME" | grep -qiE '(token|secret|credential|password)'; then
  echo '{"decision":"block","reason":"Access to files containing secrets/tokens is blocked."}' >&2
  exit 2
fi

exit 0
