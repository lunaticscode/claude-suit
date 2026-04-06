#!/bin/bash
# PreToolUse (Edit|Write): 보호 파일/폴더 편집 차단
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" ]] && exit 0

# 차단 대상 패턴
BLOCKED_DIRS=(
  "node_modules/"
  ".next/"
  ".build/"
  "dist/"
  "build/"
  "__pycache__/"
)

BLOCKED_FILES=(
  ".env"
  ".env.local"
  ".env.production"
  ".env.development"
  "package-lock.json"
  "pnpm-lock.yaml"
  "yarn.lock"
  "Pipfile.lock"
)

# 디렉토리 패턴 체크
for pattern in "${BLOCKED_DIRS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "차단: $FILE_PATH — 의존성/빌드 폴더($pattern) 내 파일은 편집할 수 없습니다." >&2
    exit 2
  fi
done

# 파일 패턴 체크
BASENAME=$(basename "$FILE_PATH")
for pattern in "${BLOCKED_FILES[@]}"; do
  if [[ "$BASENAME" == "$pattern" || "$BASENAME" == *.env || "$BASENAME" == .env.* ]]; then
    echo "차단: $FILE_PATH — 환경변수/잠금 파일($pattern)은 편집할 수 없습니다." >&2
    exit 2
  fi
done

exit 0
