# Frontend Project Structure (Vite)

> TypeScript + Vite + React 기반 SPA 폴더 구조 및 데이터 흐름

---

## 1. 폴더 구조

```
├── src/
│   ├── main.tsx                  # ReactDOM.createRoot 진입점
│   ├── App.tsx                   # Root (Router + Providers 조합)
│   │
│   ├── routes/                   # 라우트 정의 (React Router v7)
│   │   ├── index.tsx             # createBrowserRouter 라우트 트리
│   │   └── [feature]/
│   │       └── [Feature]Page.tsx # 라우트 페이지 (lazy 로딩)
│   │
│   ├── components/               # shadcn/ui 컴포넌트
│   │   └── ui/
│   │       ├── button.tsx
│   │       ├── dialog.tsx
│   │       └── _custom/          # 프로젝트 전용 확장
│   │
│   ├── widgets/                  # Container: 데이터 패칭 + 상태 관리
│   │   └── [feature]/
│   │       └── [Feature]Container.tsx
│   │
│   ├── features/                 # 도메인 모듈
│   │   └── [feature]/
│   │       ├── ui/               # UI 컴포넌트
│   │       ├── hooks/            # 커스텀 훅 (useQuery, useMutation)
│   │       └── form/             # 폼 스키마 & 컴포넌트
│   │
│   ├── shared/                   # 공통 코드
│   │   ├── components/           # 공통 컴포넌트
│   │   ├── hooks/                # 공통 훅
│   │   ├── api/                  # API 경로, Query Key Factory
│   │   ├── consts/               # 상수
│   │   ├── utils/                # 유틸리티
│   │   └── layout/               # Header, Footer, Sidebar
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
│   │   ├── QueryProvider.tsx
│   │   └── AuthProvider.tsx
│   │
│   └── styles/
│       └── index.css             # Tailwind + CSS 변수
│
├── public/                       # 정적 에셋
├── index.html                    # Vite HTML 엔트리
├── vite.config.ts
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
├── postcss.config.js
├── eslint.config.js
├── components.json               # shadcn/ui 설정
└── package.json
```

---

## 2. 데이터 흐름

### 읽기

```
routes/[Feature]Page.tsx
  → Widget/Container (useQuery로 데이터 패칭 + 상태 관리)
    → Feature UI (프레젠테이션)
```

### 쓰기

```
Feature UI (폼 제출 / 버튼 클릭)
  → Widget/Container (useMutation 호출)
    → Service (fetch 래퍼로 API 호출)
      → onSuccess: invalidateQueries()
```

---

## 3. Import 규칙

### Path Alias

```json
// tsconfig.app.json
{ "paths": { "@/*": ["./src/*"] } }
```

```typescript
// vite.config.ts
resolve: { alias: { "@": path.resolve(__dirname, "./src") } }
```

```typescript
import { cn } from "@/libs/utils";
import type { Task } from "@/types";
import { TribeCard } from "@/features/tribe/ui/TribeCard";
```

---

## 4. 기술 스택

| 레이어         | 기술                               |
| -------------- | ---------------------------------- |
| **빌드 도구**  | Vite 6                            |
| **프레임워크** | React 19, TypeScript 5             |
| **라우팅**     | React Router v7                    |
| **스타일링**   | Tailwind CSS v4 + shadcn/ui        |
| **상태 관리**  | React Query v5 + react-hook-form   |
| **유효성 검증**| Zod                                |
| **HTTP**       | fetch 래퍼 (네이티브 fetch)        |
| **테스트**     | Vitest + React Testing Library     |
