# Rules

> 프로젝트 코드 컨벤션 및 구조 가이드 문서 모음
> Claude Code `SessionStart` 훅을 통해 세션 시작 시 자동으로 컨텍스트에 주입됨

---

## 파일 목록

### frontend-nextjs-structure.md

Next.js App Router 기반 프론트엔드 폴더 구조, 데이터 흐름, Import 규칙, 기술 스택.

### frontend-vite-structure.md

Vite + React SPA 기반 프론트엔드 폴더 구조, 데이터 흐름, Import 규칙, 기술 스택.

### backend-structure.md

Express + TypeScript 기반 백엔드 폴더 구조, 데이터 흐름, Import 규칙, 기술 스택.

### frontend-nextjs-conventions.md

TypeScript + Next.js App Router 기반 프론트엔드 컨벤션.

- 컴포넌트 3계층 아키텍처 (Route → Widget → Feature)
- 네이밍 컨벤션 (파일, 변수, 타입)
- 데이터 패칭 패턴 (SSR + React Query Hydration, Server Actions)
- 상태 관리 전략
- 스타일링 (Tailwind CSS v4 + shadcn/ui)
- 폼 패턴 (react-hook-form + Zod)
- API Response Validation (Zod safeParse)
- 에러 핸들링
- 테스트 (Jest + React Testing Library)

### frontend-vite-conventions.md

TypeScript + Vite + React SPA 기반 프론트엔드 컨벤션.

- 컴포넌트 2계층 아키텍처 (Page → Widget → Feature)
- 네이밍 컨벤션 (파일, 변수, 타입)
- 라우팅 (React Router v7 + lazy 코드 스플리팅)
- 데이터 패칭 패턴 (React Query useQuery/useMutation)
- 상태 관리 전략
- 스타일링 (Tailwind CSS v4 + shadcn/ui)
- 폼 패턴 (react-hook-form + Zod)
- API Response Validation (Zod safeParse)
- 에러 핸들링
- 환경 변수 (VITE_ 접두사, import.meta.env)
- 테스트 (Vitest + React Testing Library)

### backend-conventions.md

TypeScript + Express 기반 백엔드 API 서버 컨벤션.

- MVC 아키텍처 (Route → Controller → Service → DB)
- 네이밍 컨벤션
- 미들웨어 스택 (helmet, rate-limit, auth, errorHandler)
- 에러 핸들링 (AppError + 에러 코드)
- 인증 패턴 (JWT RS256 + httpOnly Cookie)
- DB 패턴 (MongoDB + Mongoose)
- 유효성 검증 (Zod)
- 테스트 (Vitest + Supertest + DB 스키마 기반 mock 데이터)

### agent-browser-testing.md

Claude Code agent-browser를 활용한 브라우저 레벨 공통 검증 기준.

- 페이지 레벨: 정상 렌더링, 콘솔 에러, 핵심 레이아웃
- 인터랙션 레벨: 네비게이션, 버튼 반응, 폼 입력
- 상태 레벨: 로딩 → 데이터, 빈 상태, 에러 상태
