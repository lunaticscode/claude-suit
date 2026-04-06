#!/bin/bash
# Stop: tsc --noEmit + 관련 테스트 실행
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
OUTPUT=""

# TypeScript 타입 체크
if [[ -f "$PROJECT_DIR/tsconfig.json" ]]; then
  TSC_OUTPUT=$(cd "$PROJECT_DIR" && npx tsc --noEmit 2>&1) || true
  if [[ -n "$TSC_OUTPUT" ]]; then
    OUTPUT="${OUTPUT}[TSC] 타입 에러:\n${TSC_OUTPUT}\n\n"
  else
    OUTPUT="${OUTPUT}[TSC] 타입 체크 통과\n\n"
  fi
fi

# 프론트엔드 테스트 (jest)
if [[ -f "$PROJECT_DIR/jest.config.ts" || -f "$PROJECT_DIR/jest.config.js" || -f "$PROJECT_DIR/jest.config.mjs" ]]; then
  TEST_OUTPUT=$(cd "$PROJECT_DIR" && npx jest --passWithNoTests --silent 2>&1) || true
  OUTPUT="${OUTPUT}[TEST:FRONTEND] Jest 결과:\n${TEST_OUTPUT}\n\n"
fi

# 백엔드 테스트 (vitest)
if [[ -f "$PROJECT_DIR/vitest.config.ts" || -f "$PROJECT_DIR/vitest.config.js" ]]; then
  TEST_OUTPUT=$(cd "$PROJECT_DIR" && npx vitest run --silent 2>&1) || true
  OUTPUT="${OUTPUT}[TEST:BACKEND] Vitest 결과:\n${TEST_OUTPUT}\n\n"
fi

if [[ -n "$OUTPUT" ]]; then
  echo -e "$OUTPUT"
fi

exit 0
