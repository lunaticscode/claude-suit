# Hooks

> Claude Code 라이프사이클 이벤트에 자동 실행되는 셸 스크립트 모음
> `index.json`의 `hooks` 내용을 `.claude/settings.json`에 병합하여 사용

---

## 파일 목록

### index.json

훅 설정 파일. 이벤트별 매처와 실행할 스크립트를 정의한다.

### session-start.sh

**이벤트**: `SessionStart` (세션 시작/재개 시)

- `.env` 파일에서 key만 있고 value가 비어있는 항목을 찾아 경고
- `rules/` 폴더 내 모든 `.md` 컨벤션 문서를 컨텍스트로 주입
- 현재 git 브랜치명과 최근 10개 커밋 내역 출력

### prompt-context.sh

**이벤트**: `UserPromptSubmit` (프롬프트 제출 시)

- 프롬프트에 프론트엔드 키워드(`프론트`, `front`, `클라이언트`, `client`) 포함 시 `frontend-conventions.md` 주입
- 백엔드 키워드(`백엔드`, `backend`, `서버`, `WAS`, `api 서버`, `API 서버`) 포함 시 `backend-conventions.md` 주입

### block-protected-files.sh

**이벤트**: `PreToolUse` | **매처**: `Edit|Write`

편집 차단 대상:
- 의존성/빌드 폴더: `node_modules/`, `.next/`, `.build/`, `dist/`, `build/`, `__pycache__/`
- 환경 변수 파일: `.env`, `.env.local`, `.env.production`, `.env.development`
- 패키지 매니저 잠금 파일: `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Pipfile.lock`

### block-dangerous-commands.sh

**이벤트**: `PreToolUse` | **매처**: `Bash`

실행 차단 대상:
- DB 파괴 명령: `DROP TABLE/DATABASE/COLLECTION`, `deleteMany`, `.drop()`
- git 비가역 명령: `git reset --hard`, `git checkout .`, `git push --force`

### post-format-lint.sh

**이벤트**: `PostToolUse` | **매처**: `Edit|Write`

코드 수정 후 자동 실행:
- Prettier로 포맷팅
- `.ts/.tsx/.js/.jsx` 파일에 ESLint `--fix` 적용
- `.ts/.tsx` 파일에 `tsc --noEmit` 타입 체크

### stop-check.sh

**이벤트**: `Stop` (Claude 응답 완료 시)

- `tsconfig.json`이 존재하면 `tsc --noEmit` 타입 체크
- `jest.config.*`이 존재하면 Jest 테스트 실행 (프론트엔드)
- `vitest.config.*`이 존재하면 Vitest 테스트 실행 (백엔드)
