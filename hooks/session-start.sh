#!/bin/bash
# SessionStart: 환경변수 빈 값 체크 + rules 컨텍스트 주입 + git 정보
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
OUTPUT=""

# 1. .env 파일에서 key만 있고 value가 비어있는 항목 찾기
ENV_FILES=$(find "$PROJECT_DIR" -maxdepth 2 -name "*.env" -o -name ".env.*" 2>/dev/null | grep -v node_modules || true)
EMPTY_KEYS=""
for envfile in $ENV_FILES; do
  while IFS= read -r line; do
    # 주석, 빈 줄 무시
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2-)
    if [[ -z "$value" ]]; then
      EMPTY_KEYS="${EMPTY_KEYS}\n  - ${envfile}: ${key}"
    fi
  done < "$envfile"
done

if [[ -n "$EMPTY_KEYS" ]]; then
  OUTPUT="${OUTPUT}[ENV WARNING] 값이 비어있는 환경변수:${EMPTY_KEYS}\n\n"
fi

# 2. rules 폴더 내 md 파일 컨텍스트 주입
RULES_DIR="$PROJECT_DIR/rules"
if [[ -d "$RULES_DIR" ]]; then
  OUTPUT="${OUTPUT}[RULES] 다음 컨벤션 문서를 참고하세요:\n"
  for mdfile in "$RULES_DIR"/*.md; do
    [[ -f "$mdfile" ]] || continue
    filename=$(basename "$mdfile")
    OUTPUT="${OUTPUT}  - ${filename}\n"
    OUTPUT="${OUTPUT}$(cat "$mdfile")\n\n"
  done
fi

# 3. git 현재 브랜치명 + 최근 10개 커밋
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "detached")
  COMMITS=$(git -C "$PROJECT_DIR" log --oneline -10 2>/dev/null || echo "(커밋 없음)")
  OUTPUT="${OUTPUT}[GIT INFO]\n  브랜치: ${BRANCH}\n  최근 커밋:\n${COMMITS}\n"
fi

echo -e "$OUTPUT"
exit 0
