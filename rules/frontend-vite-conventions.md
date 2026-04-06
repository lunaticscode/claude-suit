# Frontend Convention Rules (Vite)

> TypeScript + Vite + React 기반 SPA 프론트엔드 코드 컨벤션

---

## 1. 폴더 구조

```
public/                               # 정적 파일 (favicon, robots.txt 등)
│
src/
│   ├── main.tsx                      # ReactDOM.createRoot 진입점
│   ├── App.tsx                       # Root 컴포넌트 (Router, Providers 조합)
│   │
│   ├── routes/                       # 라우트 정의
│   │   ├── index.tsx                 # 라우트 트리 (createBrowserRouter)
│   │   └── [feature]/
│   │       └── [Feature]Page.tsx     # 라우트 페이지 컴포넌트
│   │
│   ├── components/                   # shadcn/ui 기반 UI 컴포넌트
│   │   └── ui/                       # shadcn/ui 원본 + 커스텀 오버라이드
│   │       ├── button.tsx
│   │       ├── dialog.tsx
│   │       └── _custom/              # 프로젝트 전용 UI 확장
│   │
│   ├── widgets/                      # Container 컴포넌트 (상태 관리, 데이터 연결)
│   │   └── [feature]/
│   │       └── [Feature]Container.tsx
│   │
│   ├── features/                     # 도메인별 기능 모듈
│   │   └── [feature]/
│   │       ├── ui/                   # 도메인 UI 컴포넌트
│   │       ├── hooks/                # 도메인 커스텀 훅
│   │       └── form/                 # 폼 스키마 & 폼 컴포넌트 (선택)
│   │
│   ├── shared/                       # 기능 간 공유 코드
│   │   ├── components/               # 공통 UI 컴포넌트 (PageTitle, BackLink 등)
│   │   ├── hooks/                    # 공통 커스텀 훅
│   │   ├── api/                      # API 경로, 쿼리 설정
│   │   ├── consts/                   # 상수
│   │   ├── utils/                    # 유틸리티 함수
│   │   └── layout/                   # 레이아웃 컴포넌트 (Header, Footer, Sidebar)
│   │
│   ├── libs/                         # 라이브러리 래퍼 & 어댑터
│   │   ├── api-client.ts             # fetch 래퍼
│   │   ├── query-client.ts           # React Query 클라이언트
│   │   └── utils.ts                  # cn() 등 유틸
│   │
│   ├── services/                     # API 호출 함수 (apiClient를 사용하는 서비스 레이어)
│   │   └── [feature].service.ts
│   │
│   ├── types/                        # 중앙 타입 정의
│   │   ├── index.ts                  # 배럴 export
│   │   └── [feature].type.ts
│   │
│   ├── validators/                   # Zod 스키마 (API 응답 검증)
│   │   ├── index.ts                  # safeParse 래퍼 함수
│   │   └── [feature].ts              # 도메인별 스키마 정의
│   │
│   ├── providers/                    # React Context Provider
│   │   ├── QueryProvider.tsx
│   │   └── AuthProvider.tsx
│   │
│   └── styles/
│       └── index.css                 # Tailwind + CSS 변수
│
index.html                            # Vite HTML 엔트리
vite.config.ts                        # Vite 설정
tsconfig.json
tsconfig.app.json
tsconfig.node.json
```

---

## 2. 컴포넌트 2계층 아키텍처

### Page → Widget(Container) → Feature 패턴

> Vite SPA에서는 SSR/RSC 계층이 없으므로, Page가 최상위 라우트 컴포넌트 역할을 한다.

```
routes/[feature]/Page.tsx  →  Widget/Container (상태 관리)  →  Feature UI
```

### 2.1 Page 컴포넌트 (라우트 진입점)

- **위치**: `src/routes/[feature]/[Feature]Page.tsx`
- **역할**: URL 파라미터 처리, 레이아웃 결정, Container에 위임
- **규칙**: 비즈니스 로직 최소화, 데이터 패칭은 Container 또는 훅에 위임

```typescript
// src/routes/schedule/SchedulePage.tsx
import { useParams } from "react-router-dom";
import { ScheduleContainer } from "@/widgets/schedule/ScheduleContainer";

const SchedulePage = () => {
  const { date } = useParams<{ date: string }>();
  return <ScheduleContainer date={date} />;
};

export default SchedulePage;
```

### 2.2 Widget/Container 컴포넌트

- **위치**: `src/widgets/[feature]/[Feature]Container.tsx`
- **역할**: 데이터 패칭 (React Query), 상태 관리, 이벤트 핸들링, 레이아웃 조합
- **규칙**: Feature UI에 데이터와 핸들러를 props로 전달

```typescript
// src/widgets/schedule/ScheduleContainer.tsx
import { useScheduleSessions } from "@/features/schedule/hooks/useScheduleSessions";

export function ScheduleContainer({ date }: { date?: string }) {
  const { data: sessions, isLoading } = useScheduleSessions(date);
  const [selected, setSelected] = useState<string | null>(null);

  if (isLoading) return <Skeleton />;

  return <SessionTimeline sessions={sessions} onSelect={setSelected} />;
}
```

### 2.3 Feature 컴포넌트 (Presentation)

- **위치**: `src/features/[feature]/ui/[Component].tsx`
- **역할**: 도메인 UI 렌더링, 프레젠테이션 로직
- **규칙**: 가능한 한 상태를 가지지 않고, props로 전달받음

```typescript
// src/features/schedule/ui/SessionCard.tsx
export const SessionCard = ({ session, onSelect }: SessionCardProps) => {
  return (
    <div className={cn("rounded-lg p-4", session.active && "bg-primary")}>
      {/* UI 렌더링 */}
    </div>
  );
};
```

---

## 3. 네이밍 컨벤션

### 3.1 파일 & 폴더

| 대상           | 규칙                       | 예시                                   |
| -------------- | -------------------------- | -------------------------------------- |
| 컴포넌트 파일  | PascalCase                 | `TribeCard.tsx`, `SessionTimeline.tsx` |
| 유틸/훅/서비스 | camelCase 또는 kebab-case  | `api-client.ts`, `useRestaurants.ts`   |
| 타입 파일      | kebab-case + `.type.ts`    | `tribe.type.ts`, `challenge.type.ts`   |
| 서비스 파일    | kebab-case + `.service.ts` | `tribe.service.ts`                     |
| 상수 파일      | kebab-case                 | `api-cache.ts`, `filter.ts`            |
| 폴더           | camelCase 또는 kebab-case  | `features/`, `shared/`                 |

### 3.2 변수 & 함수

| 대상          | 규칙                 | 예시                                     |
| ------------- | -------------------- | ---------------------------------------- |
| 일반 변수     | camelCase            | `tribes`, `selectedDate`                 |
| 상수          | SCREAMING_SNAKE_CASE | `STALE_TIME`, `DEFAULT_ERROR_CODE`       |
| Boolean       | is/has/can 접두사    | `isLoading`, `hasMore`, `canParticipate` |
| 이벤트 핸들러 | handle 접두사        | `handleSubmit`, `handleTabChange`        |
| 커스텀 훅     | use 접두사           | `useTribeList`, `useRestaurants`         |
| API 호출 함수 | 동사 + 명사          | `getTribeList`, `updateProfile`          |
| Mutation 함수 | 동사 + 명사          | `joinTribe`, `createSession`             |

### 3.3 타입 & 인터페이스

| 대상          | 규칙               | 예시                                     |
| ------------- | ------------------ | ---------------------------------------- |
| 타입          | PascalCase         | `Tribe`, `TaskStatus`                    |
| Props 타입    | 컴포넌트명 + Props | `TribeCardProps`, `SessionFormProps`     |
| Response 타입 | 동사 + Response    | `GetTribeListResponse`                   |
| Zod 추론 타입 | z.infer 사용       | `type FormData = z.infer<typeof schema>` |

### 3.4 type vs interface 기준

- **`type` 우선 사용** (union, intersection, utility 타입, 일반 객체 모양)
- **`interface`**: 확장이 필요한 경우 또는 컴포넌트 Props 정의 시 선택적 사용

```typescript
// type 사용 (기본)
type TaskStatus = "scheduled" | "completed" | "cancelled";

type TribeCardProps = {
  tribe: Tribe;
  className?: string;
};

// interface 사용 (확장 필요 시)
interface GetMembersOptions {
  trainerId: string;
  active?: boolean;
}
```

---

## 4. 라우팅

### 4.1 React Router v7 설정

```typescript
// src/routes/index.tsx
import { createBrowserRouter } from "react-router-dom";
import { RootLayout } from "@/shared/layout/RootLayout";

export const router = createBrowserRouter([
  {
    element: <RootLayout />,
    children: [
      {
        path: "/",
        lazy: () => import("./home/HomePage"),
      },
      {
        path: "/tribe",
        lazy: () => import("./tribe/TribeListPage"),
      },
      {
        path: "/tribe/:id",
        lazy: () => import("./tribe/TribeDetailPage"),
      },
    ],
  },
]);
```

### 4.2 Lazy Loading

- 모든 라우트 페이지는 `lazy()` 로 코드 스플리팅
- `default export` 필수 (React Router lazy 요구사항)

```typescript
// src/routes/tribe/TribeListPage.tsx
const TribeListPage = () => {
  return <TribeListContainer />;
};

export default TribeListPage;

// 또는 Component export 방식
export const Component = () => <TribeListContainer />;
```

---

## 5. 데이터 패칭 패턴

### 5.1 React Query (읽기)

```typescript
// features/tribe/hooks/useTribeList.ts
import { useQuery } from "@tanstack/react-query";
import { getTribeList } from "@/services/tribe.service";
import { queryKeys } from "@/shared/api/query-keys";

export const useTribeList = () => {
  return useQuery({
    queryKey: queryKeys.tribe.list(),
    queryFn: getTribeList,
    staleTime: 1000 * 60 * 5,
  });
};
```

### 5.2 React Query Mutation (쓰기/변이)

```typescript
// features/tribe/hooks/useJoinTribe.ts
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { joinTribe } from "@/services/tribe.service";
import { queryKeys } from "@/shared/api/query-keys";

export const useJoinTribe = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (tribeId: string) => joinTribe(tribeId),
    onSuccess: (_data, tribeId) => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.tribe.detail(tribeId),
      });
    },
  });
};
```

### 5.3 Query Key Factory

```typescript
// shared/api/query-keys.ts
export const queryKeys = {
  tribe: {
    all: () => ["tribe"] as const,
    list: (filters?: TribeFilters) =>
      [...queryKeys.tribe.all(), "list", filters] as const,
    detail: (id: string) => [...queryKeys.tribe.all(), "detail", id] as const,
  },
  challenge: {
    all: () => ["challenge"] as const,
    list: () => [...queryKeys.challenge.all(), "list"] as const,
  },
} as const;
```

### 5.4 API Client 패턴

```typescript
// libs/api-client.ts
const BASE_URL = import.meta.env.VITE_API_BASE_URL;

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const token = getAccessToken();
  const response = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token && { Authorization: `Bearer ${token}` }),
      ...options?.headers,
    },
  });

  if (!response.ok) {
    if (response.status === 401) {
      // 토큰 갱신 또는 로그인 리다이렉트
    }
    throw new Error(`API Error: ${response.status}`);
  }

  return response.json() as Promise<T>;
}

export const apiClient = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "POST", body: JSON.stringify(body) }),
  patch: <T>(path: string, body?: unknown) =>
    request<T>(path, { method: "PATCH", body: JSON.stringify(body) }),
  delete: <T>(path: string) =>
    request<T>(path, { method: "DELETE" }),
};
```

### 5.5 서비스 레이어

```typescript
// services/tribe.service.ts
export const getTribeList = async (): Promise<GetTribeListResponse> => {
  const data = await apiClient.get(TRIBE_API.LIST);
  return validateResponse(tribeListResponseSchema, data);
};

export const joinTribe = async (tribeId: string): Promise<void> => {
  await apiClient.post(TRIBE_API.JOIN(tribeId));
};
```

### 5.6 API 경로 중앙화

```typescript
// shared/api/path.ts
export const TRIBE_API = {
  LIST: "/api/tribe",
  BY_ID: (id: string) => `/api/tribe/${id}`,
  JOIN: (id: string) => `/api/tribe/${id}/join`,
} as const;
```

---

## 6. 상태 관리 전략

| 관심사                 | 방법                                |
| ---------------------- | ----------------------------------- |
| 서버 데이터            | React Query (TanStack Query v5)     |
| 폼 상태                | react-hook-form + Zod               |
| UI 상태 (모달, 드로어) | 로컬 useState                       |
| 인증                   | Context + localStorage/cookie       |
| 페이지네이션/필터      | URL Search Params (useSearchParams) |
| 전역 UI 상태           | Zustand (필요한 경우에만)           |

> React Query로 서버 상태를 관리하고, 클라이언트 전용 전역 상태가 필요한 경우에만 Zustand를 도입한다.
> 대부분의 UI 상태는 로컬 useState + props drilling 또는 Context로 해결한다.

---

## 7. 스타일링

### 7.1 기본 스택

- **Tailwind CSS v4** + PostCSS
- **shadcn/ui** (Radix UI 기반)
- **CVA** (Class Variance Authority) - 컴포넌트 variant
- **cn()** 유틸리티 (clsx + tailwind-merge)

### 7.2 공통 컴포넌트 규칙

> Button, Dialog, Drawer, Select, Tabs, Tooltip, Popover 등 **공통 UI 컴포넌트는 shadcn/ui를 적극 활용**한다.
> 직접 구현하기 전에 shadcn/ui에 해당 컴포넌트가 있는지 먼저 확인하고, 있다면 그것을 기반으로 사용한다.

- **shadcn/ui 컴포넌트 우선 사용**: 새 공통 컴포넌트가 필요할 때, shadcn/ui에서 제공하는지 먼저 확인
- **커스터마이징은 `_custom/` 폴더에서**: shadcn/ui 원본은 `components/ui/`에 유지하고, 프로젝트 전용 확장은 `components/ui/_custom/`에 작성
- **래핑보다 조합**: shadcn/ui 컴포넌트를 불필요하게 래핑하지 말고, props와 `cn()`으로 스타일만 확장

```typescript
// O: shadcn/ui 컴포넌트를 직접 사용
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogTrigger } from "@/components/ui/dialog";

// X: shadcn/ui에 있는 걸 직접 구현하지 않는다
const CustomButton = ({ children }) => (
  <button className="rounded px-4 py-2 bg-primary">{children}</button>
);
```

### 7.3 스타일링 규칙

```typescript
// cn() 으로 조건부 클래스 결합
import { cn } from "@/libs/utils";

className={cn(
  "rounded-lg p-4 text-sm",
  isActive && "bg-primary text-white",
  className,
)}
```

### 7.4 CSS 변수 (oklch 색상 공간)

```css
:root {
  --primary: oklch(0.216 0.006 56.043);
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0.004 49.75);
}
```

### 7.5 아이콘

- **lucide-react** 사용

---

## 8. 폼 패턴

### react-hook-form + Zod

```typescript
// 1. 스키마 정의 (validators/ 또는 features/[feature]/form/schema.ts)
export const sessionCreateSchema = z.object({
  memberId: z.string().min(1, "회원을 선택해주세요."),
  category: z.enum(["diet", "weight"]),
});
export type SessionCreateFormData = z.infer<typeof sessionCreateSchema>;

// 2. 폼 컴포넌트
const methods = useForm<SessionCreateFormData>({
  resolver: zodResolver(sessionCreateSchema),
  defaultValues: { memberId: "", category: "diet" },
});

const mutation = useCreateSession();

const onSubmit = async (data: SessionCreateFormData) => {
  mutation.mutate(data, {
    onSuccess: () => {
      /* 성공 처리 */
    },
  });
};
```

---

## 9. API Response Validation

> API 응답 데이터를 Zod 스키마로 검증하여 런타임 타입 안전성을 보장한다.

### 9.1 래퍼 함수 (validators/index.ts)

```typescript
// validators/index.ts
import { z } from "zod";

export function validateResponse<T extends z.ZodTypeAny>(
  schema: T,
  data: unknown,
): z.infer<T> {
  const result = schema.safeParse(data);

  if (!result.success) {
    console.error("[API Response Validation Error]", result.error.flatten());
    throw new Error("API 응답 데이터가 예상 형식과 일치하지 않습니다.");
  }

  return result.data;
}
```

### 9.2 도메인 스키마 & 타입 추론

```typescript
// validators/tribe.ts
export const tribeSchema = z.object({
  _id: z.string(),
  name: z.string(),
  description: z.string(),
  memberCount: z.number(),
  maxMembers: z.number(),
  createdAt: z.string(),
});

export const tribeListResponseSchema = z.object({
  tribes: z.array(tribeSchema),
  pagination: z.object({
    total: z.number(),
    page: z.number(),
    limit: z.number(),
  }),
});

// types/tribe.type.ts — 스키마에서 타입 추론
export type Tribe = z.infer<typeof tribeSchema>;
export type GetTribeListResponse = z.infer<typeof tribeListResponseSchema>;
```

---

## 10. 에러 핸들링

### 10.1 API 에러 처리

```typescript
// libs/api-client.ts 에서 fetch 래퍼로 공통 에러 처리
// 401: 토큰 갱신 또는 로그인 리다이렉트
// 403: 권한 없음 안내
// 500: 일반 에러 토스트
```

### 10.2 React Query 에러 바운더리

```typescript
// React Query의 throwOnError + ErrorBoundary 조합
import { ErrorBoundary } from "react-error-boundary";

<ErrorBoundary fallback={<ErrorFallback />}>
  <Suspense fallback={<Skeleton />}>
    <TribeListContainer />
  </Suspense>
</ErrorBoundary>
```

### 10.3 Mutation 에러 처리

```typescript
const mutation = useMutation({
  mutationFn: joinTribe,
  onError: (error) => {
    toast.error(error.message || "요청에 실패했습니다.");
  },
});
```

---

## 11. Import 규칙

### 11.1 Path Alias

```typescript
// vite.config.ts
import { defineConfig } from "vite";
import path from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

```json
// tsconfig.app.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] }
  }
}
```

### 11.2 Import 순서

```typescript
// 1. React
import { useState, useCallback } from "react";

// 2. 외부 라이브러리
import { useQuery } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { z } from "zod";

// 3. 타입 (import type)
import type { Challenge } from "@/types";

// 4. 내부 절대 경로
import { useTribeList } from "@/features/tribe/hooks/useTribeList";
import { cn } from "@/libs/utils";

// 5. 상대 경로 (가급적 피함)
import { SubComponent } from "./SubComponent";
```

---

## 12. Export 규칙

```typescript
// 컴포넌트: Named export
export const TribeCard = ({ tribe }: TribeCardProps) => { ... };

// 라우트 페이지: Default export (React Router lazy 호환)
export default function TribeListPage() { ... }

// 타입 배럴: Re-export
// types/index.ts
export * from "./tribe.type";
export * from "./challenge.type";
```

---

## 13. 주요 의존성 스택

| 카테고리        | 라이브러리                           |
| --------------- | ------------------------------------ |
| 빌드 도구       | Vite 6                               |
| 프레임워크      | React 19                             |
| 라우팅          | React Router v7                      |
| 스타일링        | Tailwind CSS v4, shadcn/ui, CVA      |
| 서버 상태       | @tanstack/react-query v5             |
| 폼              | react-hook-form, @hookform/resolvers |
| 유효성 검증     | Zod                                  |
| HTTP 클라이언트 | fetch 래퍼 (네이티브 fetch)           |
| 아이콘          | lucide-react                         |
| 토스트          | sonner                               |
| 날짜            | date-fns                             |
| 애니메이션      | framer-motion                        |
| 테스트          | Vitest, React Testing Library        |
| 린터            | ESLint (Flat Config)                 |

---

## 14. 테스트

### 14.1 테스트 스택

| 도구                      | 용도                              |
| ------------------------- | --------------------------------- |
| Vitest                    | 테스트 러너 (Vite 네이티브)       |
| React Testing Library     | 컴포넌트 렌더링 & 인터랙션 테스트 |
| @testing-library/jest-dom | DOM assertion 매처 확장           |
| MSW (Mock Service Worker) | API 요청 모킹 (선택)              |

### 14.2 폴더 구조

```
src/
├── __tests__/                    # 통합 테스트
│   ├── setup.ts                  # Vitest 글로벌 설정
│   └── utils.tsx                 # 테스트 유틸 (renderWithProviders 등)
│
├── libs/
│   └── __tests__/                # 유틸 함수 단위 테스트
│       └── utils.test.ts
│
├── validators/
│   └── __tests__/                # Zod 스키마 검증 테스트
│       └── tribe.test.ts
│
├── services/
│   └── __tests__/                # 서비스 레이어 테스트
│       └── tribe.service.test.ts
│
├── features/
│   └── [feature]/
│       ├── ui/
│       │   └── __tests__/        # 컴포넌트 렌더링 테스트
│       │       └── TribeCard.test.tsx
│       └── hooks/
│           └── __tests__/        # 커스텀 훅 테스트
│               └── useTribeList.test.ts
```

### 14.3 Vitest 설정

```typescript
// vite.config.ts
export default defineConfig({
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: ["./src/__tests__/setup.ts"],
    css: true,
  },
});
```

### 14.4 테스트 대상 & 기준

| 대상              | 위치                          | 테스트 기준                                          |
| ----------------- | ----------------------------- | ---------------------------------------------------- |
| **유틸 함수**     | `libs/`, `shared/utils/`      | 입출력 검증, 엣지 케이스, 에러 케이스                |
| **Zod 스키마**    | `validators/`                 | 유효 데이터 통과, 무효 데이터 실패, 에러 메시지 확인 |
| **서비스 레이어** | `services/`                   | API mock → 응답 파싱 → validateResponse 검증         |
| **커스텀 훅**     | `hooks/`, `features/*/hooks/` | 반환값, 상태 변이, 콜백 호출 검증                    |
| **컴포넌트**      | `features/*/ui/`              | 조건부 렌더링, 이벤트 핸들러, props 반영             |

### 14.5 테스트 유틸

```typescript
// __tests__/utils.tsx
import { render, RenderOptions } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";

const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
    },
  });

export const renderWithProviders = (
  ui: React.ReactElement,
  options?: Omit<RenderOptions, "wrapper"> & { initialEntries?: string[] },
) => {
  const queryClient = createTestQueryClient();
  const { initialEntries = ["/"], ...renderOptions } = options ?? {};

  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <MemoryRouter initialEntries={initialEntries}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </MemoryRouter>
  );

  return render(ui, { wrapper: Wrapper, ...renderOptions });
};
```

---

## 15. 환경 변수

### 15.1 규칙

- Vite에서는 `VITE_` 접두사가 붙은 변수만 클라이언트에 노출
- 민감 정보(API Secret 등)는 절대 `VITE_` 접두사를 붙이지 않음

```
# .env
VITE_API_BASE_URL=https://api.example.com
VITE_APP_TITLE=MyApp
```

### 15.2 타입 안전한 환경 변수

```typescript
// src/vite-env.d.ts
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string;
  readonly VITE_APP_TITLE: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

### 15.3 사용

```typescript
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;
```

---

## 16. 프로젝트 설정 파일

### vite.config.ts

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  server: {
    port: 3000,
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: "dist",
    sourcemap: true,
  },
});
```

### tsconfig.app.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "react-jsx",
    "skipLibCheck": true,
    "noEmit": true,
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src"]
}
```

### ESLint (Flat Config)

```javascript
// eslint.config.js
import js from "@eslint/js";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist/"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    plugins: {
      "react-hooks": reactHooks,
      "react-refresh": reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      "react-refresh/only-export-components": [
        "warn",
        { allowConstantExport: true },
      ],
    },
  },
);
```
