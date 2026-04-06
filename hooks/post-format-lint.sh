#!/bin/bash
# PostToolUse (Edit|Write): Prettier + ESLint --fix + tsc 자동 실행
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
OUTPUT=""

# Prettier 실행
if command -v npx &> /dev/null; then
  npx prettier --write "$FILE_PATH" 2>/dev/null && OUTPUT="${OUTPUT}[FORMAT] Prettier 완료: $(basename "$FILE_PATH")\n"
fi

# ESLint --fix 실행
if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx || "$FILE_PATH" == *.js || "$FILE_PATH" == *.jsx ]]; then
  npx eslint --fix "$FILE_PATH" 2>/dev/null && OUTPUT="${OUTPUT}[LINT] ESLint --fix 완료: $(basename "$FILE_PATH")\n"
fi

# TypeScript 파일인 경우 tsc --noEmit
if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]]; then
  TSC_OUTPUT=$(npx tsc --noEmit 2>&1) || true
  if [[ -n "$TSC_OUTPUT" ]]; then
    OUTPUT="${OUTPUT}[TSC] 타입 에러 발견:\n${TSC_OUTPUT}\n"
  else
    OUTPUT="${OUTPUT}[TSC] 타입 체크 통과\n"
  fi
fi

if [[ -n "$OUTPUT" ]]; then
  echo -e "$OUTPUT"
fi

exit 0
