#!/bin/bash
# PreToolUse (Bash): 위험한 DB/git 명령 차단
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ -z "$COMMAND" ]] && exit 0

# DB Drop/Delete 차단
if echo "$COMMAND" | grep -iqE 'drop\s+(table|database|collection|index)|db\.(drop|remove)|\.deleteMany|\.drop\(\)'; then
  echo "차단: DB Drop/Delete 명령은 실행할 수 없습니다. — $COMMAND" >&2
  exit 2
fi

# git 위험 명령 차단
if echo "$COMMAND" | grep -iqE 'git\s+reset\s+--hard'; then
  echo "차단: git reset --hard는 실행할 수 없습니다." >&2
  exit 2
fi

if echo "$COMMAND" | grep -iqE 'git\s+checkout\s+\.'; then
  echo "차단: git checkout .은 실행할 수 없습니다." >&2
  exit 2
fi

if echo "$COMMAND" | grep -iqE 'git\s+push\s+--force|git\s+push\s+-f\b'; then
  echo "차단: git push --force는 실행할 수 없습니다." >&2
  exit 2
fi

exit 0
