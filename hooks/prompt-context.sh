#!/bin/bash
# UserPromptSubmit: 프롬프트 키워드에 따라 관련 컨벤션 문서 주입
set -euo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
RULES_DIR="$PROJECT_DIR/rules"
OUTPUT=""

# 프론트엔드 키워드 매칭 (대소문자 무시)
if echo "$PROMPT" | grep -iqE '프론트|front|클라이언트|client'; then
  if [[ -f "$RULES_DIR/frontend-conventions.md" ]]; then
    OUTPUT="${OUTPUT}[CONTEXT] frontend-conventions.md 주입:\n"
    OUTPUT="${OUTPUT}$(cat "$RULES_DIR/frontend-conventions.md")\n\n"
  fi
fi

# 백엔드 키워드 매칭 (대소문자 무시)
if echo "$PROMPT" | grep -iqE '백엔드|backend|서버|WAS|api 서버|API 서버'; then
  if [[ -f "$RULES_DIR/backend-conventions.md" ]]; then
    OUTPUT="${OUTPUT}[CONTEXT] backend-conventions.md 주입:\n"
    OUTPUT="${OUTPUT}$(cat "$RULES_DIR/backend-conventions.md")\n\n"
  fi
fi

if [[ -n "$OUTPUT" ]]; then
  echo -e "$OUTPUT"
fi

exit 0
