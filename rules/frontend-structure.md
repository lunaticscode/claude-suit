# Frontend Project Structure

> Next.js App Router 기반 프론트엔드 폴더 구조 및 데이터 흐름

---

## 1. 폴더 구조

```
├── app/                          # App Router (라우팅 전용)
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Home → Route 컴포넌트에 위임
│   ├── globals.css
│   └── [feature]/
│       ├── page.tsx
│       └── [id]/page.tsx
│
├── components/                   # shadcn/ui 컴포넌트
│   └── ui/
│       ├── button.tsx
│       ├── dialog.tsx
│       └── _custom/              # 프로젝트 전용 확장
│
├── src/
│   ├── routes/                   # RSC: 서버 데이터 패칭
│   │   └── [Feature]Route.tsx
│   │
│   ├── widgets/                  # CSC: 상태 관리 컨테이너
│   │   └── [feature]/
│   │       └── [Feature]Container.tsx
│   │
│   ├── features/                 # 도메인 모듈
│   │   └── [feature]/
│   │       ├── ui/               # UI 컴포넌트
│   │       ├── action/           # Server Actions
│   │       ├── hooks/            # 커스텀 훅
│   │       └── form/             # 폼 스키마 & 컴포넌트
│   │
│   ├── shared/                   # 공통 코드
│   │   ├── components/           # 공통 컴포넌트
│   │   ├── hooks/                # 공통 훅
│   │   ├── api/                  # API 경로, 쿼리 설정
│   │   ├── consts/               # 상수
│   │   ├── utils/                # 유틸리티
│   │   └── layout/               # Header, Footer
│   │
│   ├── libs/                     # 라이브러리 래퍼
│   │   ├── api-client.ts         # fetch 래퍼
│   │   ├── query-client.ts       # React Query 설정
│   │   └── utils.ts              # cn() 등
│   │
│   ├── services/                 # API 서비스 레이어
│   │   └── [feature].service.ts
│   │
│   ├── types/                    # 타입 정의
│   │   ├── index.ts
│   │   └── [feature].type.ts
│   │
│   ├── validators/               # Zod 스키마
│   │   ├── index.ts              # safeParse 래퍼 함수
│   │   └── [feature].ts          # 도메인별 스키마 정의
│   │
│   ├── providers/                # Context Providers
│   │   └── QueryProvider.tsx
│   │
│   └── styles/
│       └── globals.css
│
├── public/                       # 정적 에셋
├── next.config.ts
├── tsconfig.json
├── postcss.config.mjs
├── eslint.config.mjs
├── components.json               # shadcn/ui 설정
└── package.json
```

---

## 2. 데이터 흐름

### 읽기

```
app/page.tsx
  → Route (RSC: 서버 데이터 패칭 + HydrationBoundary)
    → Widget/Container (CSC: 클라이언트 상태)
      → Feature UI (프레젠테이션)
```

### 쓰기

```
Feature UI (폼 제출 / 버튼 클릭)
  → Server Action ("use server")
    → Service (API 호출)
      → revalidatePath() / updateTag()
```

---

## 3. Import 규칙

### Path Alias

```json
// tsconfig.json
{ "paths": { "@/*": ["./*", "./src/*"] } }
```

```typescript
import { cn } from "@/src/libs/utils";
import type { Task } from "@/src/types";
import { TribeCard } from "@/src/features/tribe/ui/TribeCard";
```

---

## 4. 기술 스택

| 레이어 | 기술 |
|--------|------|
| **프레임워크** | Next.js 16, React 19, TypeScript 5 |
| **스타일링** | Tailwind CSS v4 + shadcn/ui |
| **상태 관리** | React Query v5 + react-hook-form |
| **유효성 검증** | Zod |
| **빌드** | Turbopack |
| **테스트** | Jest + React Testing Library |
