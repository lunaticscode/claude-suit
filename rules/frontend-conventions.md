# Frontend Convention Rules

> TypeScript + Next.js App Router 기반 프론트엔드 코드 컨벤션

---

## 1. 폴더 구조

```
app/                              # Next.js App Router (라우팅만 담당)
│   ├── layout.tsx                # Root layout (providers, global styles)
│   ├── page.tsx                  # 각 라우트 진입점 → Route 컴포넌트에 위임
│   ├── [feature]/
│   │   ├── page.tsx
│   │   └── [id]/page.tsx         # Dynamic route
│   └── actions/                  # 공용 Server Actions (선택)
│
components/                       # shadcn/ui 기반 UI 컴포넌트
│   └── ui/                       # shadcn/ui 원본 + 커스텀 오버라이드
│       ├── button.tsx
│       ├── dialog.tsx
│       └── _custom/              # 프로젝트 전용 UI 확장
│
src/
│   ├── routes/                   # Route 컴포넌트 (Server Component, 데이터 패칭)
│   │   └── [Feature]/
│   │       └── [Feature]Route.tsx
│   │
│   ├── widgets/                  # Container 컴포넌트 ("use client", 상태 관리)
│   │   └── [feature]/
│   │       └── [Feature]Container.tsx
│   │
│   ├── features/                 # 도메인별 기능 모듈
│   │   └── [feature]/
│   │       ├── ui/               # 도메인 UI 컴포넌트
│   │       ├── action/           # 도메인 Server Actions
│   │       ├── hooks/            # 도메인 커스텀 훅
│   │       └── form/             # 폼 스키마 & 폼 컴포넌트 (선택)
│   │
│   ├── shared/                   # 기능 간 공유 코드
│   │   ├── components/           # 공통 UI 컴포넌트 (PageTitle, BackLink 등)
│   │   ├── hooks/                # 공통 커스텀 훅
│   │   ├── api/                  # API 경로, 쿼리 설정
│   │   ├── consts/               # 상수
│   │   ├── utils/                # 유틸리티 함수
│   │   └── layout/               # 레이아웃 컴포넌트 (Header, Footer)
│   │
│   ├── libs/                     # 라이브러리 래퍼 & 어댑터
│   │   ├── api-client.ts         # fetch 래퍼 (또는 serverFetch.ts)
│   │   ├── query-client.ts       # React Query 클라이언트
│   │   └── utils.ts              # cn() 등 유틸
│   │
│   ├── services/                 # API 호출 함수 (apiClient를 사용하는 서비스 레이어)
│   │   └── [feature].service.ts
│   │
│   ├── types/                    # 중앙 타입 정의
│   │   ├── index.ts              # 배럴 export
│   │   └── [feature].type.ts
│   │
│   ├── validators/               # Zod 스키마 (API 응답 검증)
│   │   ├── index.ts              # safeParse 래퍼 함수
│   │   └── [feature].ts          # 도메인별 스키마 정의
│   │
│   ├── providers/                # React Context Provider
│   │   └── QueryProvider.tsx
│   │
│   └── styles/
│       └── globals.css           # Tailwind + CSS 변수
```

---

## 2. 컴포넌트 3계층 아키텍처

### Route → Widget(Container) → Feature 패턴

```
app/page.tsx  →  Route (RSC)  →  Widget/Container (CSC)  →  Feature UI
```

### 2.1 Route 컴포넌트 (Server Component)

- **위치**: `src/routes/[Feature]/[Feature]Route.tsx`
- **역할**: 서버 사이드 데이터 패칭, HydrationBoundary 설정
- **규칙**: `async` 함수, `"use client"` 없음

```typescript
// src/routes/schedule/ScheduleRoute.tsx
export const ScheduleRoute = async ({ date }: ScheduleRouteProps) => {
  const queryClient = createSSRQueryClient();
  const sessions = await queryClient.fetchQuery({ queryKey, queryFn });

  return (
    <HydrationBoundary state={dehydrate(queryClient)}>
      <ScheduleContainer sessions={sessions} date={date} />
    </HydrationBoundary>
  );
};
```

### 2.2 Widget/Container 컴포넌트 (Client Component)

- **위치**: `src/widgets/[feature]/[Feature]Container.tsx`
- **역할**: 클라이언트 상태 관리, 이벤트 핸들링, 레이아웃 조합
- **규칙**: `"use client"` 선언 필수

```typescript
"use client";

export function ScheduleContainer({ sessions, date }: Props) {
  const [selected, setSelected] = useState(null);
  // 상태 관리 & 이벤트 핸들링
  return <SessionTimeline sessions={sessions} onSelect={setSelected} />;
}
```

### 2.3 Feature 컴포넌트 (Presentation)

- **위치**: `src/features/[feature]/ui/[Component].tsx`
- **역할**: 도메인 UI 렌더링, 프레젠테이션 로직
- **규칙**: 가능한 한 상태를 가지지 않고, props로 전달받음

```typescript
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

| 대상 | 규칙 | 예시 |
|------|------|------|
| 컴포넌트 파일 | PascalCase | `TribeCard.tsx`, `SessionTimeline.tsx` |
| 유틸/훅/서비스 | camelCase 또는 kebab-case | `api-client.ts`, `useRestaurants.ts` |
| 타입 파일 | kebab-case + `.type.ts` | `tribe.type.ts`, `challenge.type.ts` |
| 서비스 파일 | kebab-case + `.service.ts` | `tribe.service.ts` |
| 상수 파일 | kebab-case | `api-cache.ts`, `filter.ts` |
| 폴더 | camelCase 또는 kebab-case | `features/`, `shared/` |

### 3.2 변수 & 함수

| 대상 | 규칙 | 예시 |
|------|------|------|
| 일반 변수 | camelCase | `tribes`, `selectedDate` |
| 상수 | SCREAMING_SNAKE_CASE | `STALE_TIME`, `DEFAULT_ERROR_CODE` |
| Boolean | is/has/can 접두사 | `isLoading`, `hasMore`, `canParticipate` |
| 이벤트 핸들러 | handle 접두사 | `handleSubmit`, `handleTabChange` |
| Server Action | 동사 + Action 접미사 | `joinTribeAction`, `createSessionsAction` |
| 커스텀 훅 | use 접두사 | `useTribeList`, `useRestaurants` |
| API 호출 함수 | 동사 + 명사 | `getTribeList`, `updateProfile` |

### 3.3 타입 & 인터페이스

| 대상 | 규칙 | 예시 |
|------|------|------|
| 타입 | PascalCase | `Tribe`, `TaskStatus` |
| Props 타입 | 컴포넌트명 + Props | `TribeCardProps`, `SessionFormProps` |
| Response 타입 | 동사 + Response | `GetTribeListResponse` |
| Zod 추론 타입 | z.infer 사용 | `type FormData = z.infer<typeof schema>` |

### 3.4 type vs interface 기준

- **`type` 우선 사용** (union, intersection, utility 타입, 일반 객체 모양)
- **`interface`**: 확장이 필요한 경우 또는 컴포넌트 Props 정의 시 선택적 사용

```typescript
// type 사용 (기본)
type TaskStatus = "scheduled" | "completed" | "cancelled";
type ServerActionResult<T> = Promise<{ success: boolean; data?: T }>;

type TribeCardProps = {
  tribe: Tribe<"List">;
  className?: string;
};

// interface 사용 (확장 필요 시)
interface GetMembersOptions {
  trainerId: string;
  active?: boolean;
}
```

---

## 4. 데이터 패칭 패턴

### 4.1 SSR + React Query Hydration (읽기)

```typescript
// Route 컴포넌트 (서버)
const queryClient = createSSRQueryClient();
await queryClient.fetchQuery({
  queryKey: queryKeys.tribe.list(),
  queryFn: () => getTribeList(),
});

return (
  <HydrationBoundary state={dehydrate(queryClient)}>
    <TribeListContainer />
  </HydrationBoundary>
);
```

### 4.2 Server Actions (쓰기/변이)

```typescript
// features/[feature]/action/index.ts
"use server";

export const joinTribeAction = async (
  tribeId: string,
): ServerActionResult<{ needsAuth?: boolean }> => {
  try {
    const result = await joinTribe(tribeId);
    revalidatePath(REVALIDATE_PATH.TRIBE_DETAIL(tribeId));
    return { success: true };
  } catch (err) {
    return handleActionError(err);
  }
};
```

### 4.3 API Client 패턴

```typescript
// libs/api-client.ts
// Custom fetch 래퍼 - Base URL, 쿼리 파라미터, 에러 핸들링, Next.js 캐시 옵션 지원
apiClient.get<T>(path, { params?, next?: { revalidate?, tags? } });
apiClient.post<T>(path, body);
apiClient.patch<T>(path, body);
apiClient.delete<T>(path);
```

### 4.4 서비스 레이어

```typescript
// services/tribe.service.ts
export const getTribeList = async (): Promise<GetTribeListResponse> => {
  return apiClient.get(TRIBE_API.LIST, {
    next: { revalidate: REVALIDATE_TIME.TRIBE },
  });
};
```

### 4.5 API 경로 중앙화

```typescript
// shared/api/path.ts
export const TRIBE_API = {
  LIST: "/api/tribe",
  BY_ID: (id: string) => `/api/tribe/${id}`,
  JOIN: (id: string) => `/api/tribe/${id}/join`,
} as const;
```

---

## 5. 상태 관리 전략

| 관심사 | 방법 |
|--------|------|
| 서버 데이터 | React Query + Next.js Data Cache |
| 폼 상태 | react-hook-form + Zod |
| UI 상태 (모달, 드로어) | 로컬 useState |
| 인증 | Cookie (httpOnly JWT) |
| 페이지네이션/필터 | URL Search Params |
| 테마 | next-themes |

> Zustand, Redux 등 글로벌 상태 라이브러리는 사용하지 않음.
> React Query와 Server Actions 조합으로 대부분의 서버 상태를 관리.

---

## 6. 스타일링

### 6.1 기본 스택

- **Tailwind CSS v4** + PostCSS
- **shadcn/ui** (Radix UI 기반)
- **CVA** (Class Variance Authority) - 컴포넌트 variant
- **cn()** 유틸리티 (clsx + tailwind-merge)

### 6.2 공통 컴포넌트 규칙

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

### 6.3 스타일링 규칙

```typescript
// cn() 으로 조건부 클래스 결합
import { cn } from "@/src/libs/utils";

className={cn(
  "rounded-lg p-4 text-sm",
  isActive && "bg-primary text-white",
  className,
)}
```

### 6.3 CSS 변수 (oklch 색상 공간)

```css
:root {
  --primary: oklch(0.216 0.006 56.043);
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0.004 49.75);
}
```

### 6.4 아이콘

- **lucide-react** 사용

---

## 7. 폼 패턴

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

const onSubmit = async (data: SessionCreateFormData) => {
  const result = await createSessionsAction(data);
  if (result.success) { /* 성공 처리 */ }
};
```

---

## 8. API Response Validation

> API 응답 데이터를 Zod 스키마로 검증하여 런타임 타입 안전성을 보장한다.

### 8.1 파일 구조

```
src/validators/
├── index.ts                      # safeParse 래퍼 함수
├── tribe.ts                      # Tribe 도메인 스키마
├── challenge.ts                  # Challenge 도메인 스키마
├── member.ts                     # Member 도메인 스키마
└── profile.ts                    # Profile 도메인 스키마
```

### 8.2 래퍼 함수 (validators/index.ts)

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

### 8.3 도메인 스키마 (validators/[feature].ts)

```typescript
// validators/tribe.ts
import { z } from "zod";

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

export const tribeDetailResponseSchema = tribeSchema.extend({
  members: z.array(z.object({
    _id: z.string(),
    name: z.string(),
    profileImage: z.string().nullable(),
  })),
  challenges: z.array(z.object({
    _id: z.string(),
    title: z.string(),
    status: z.enum(["active", "completed", "upcoming"]),
  })),
});
```

### 8.4 서비스에서 사용

```typescript
// services/tribe.service.ts
import { validateResponse } from "@/src/validators";
import { tribeListResponseSchema, tribeDetailResponseSchema } from "@/src/validators/tribe";

export const getTribeList = async () => {
  const data = await apiClient.get(TRIBE_API.LIST, {
    next: { revalidate: REVALIDATE_TIME.TRIBE },
  });

  return validateResponse(tribeListResponseSchema, data);
};

export const getTribeDetail = async (id: string) => {
  const data = await apiClient.get(TRIBE_API.BY_ID(id));

  return validateResponse(tribeDetailResponseSchema, data);
};
```

### 8.5 타입 추론

```typescript
// types/tribe.type.ts
import type { z } from "zod";
import type { tribeSchema, tribeListResponseSchema } from "@/src/validators/tribe";

// 스키마에서 타입 추론 → 별도 타입 정의 불필요
export type Tribe = z.infer<typeof tribeSchema>;
export type GetTribeListResponse = z.infer<typeof tribeListResponseSchema>;
```

---

## 9. 에러 핸들링

### 9.1 AppError 클래스

```typescript
// 커스텀 에러 클래스
class AppError extends Error {
  constructor(message: string, code: ErrorCode) { ... }
}
```

### 9.2 에러 코드 중앙화

```typescript
// shared/utils/error/codes/
export const ERROR_CODES = {
  USER_NOT_FOUND: { statusCode: 404, message: "사용자를 찾을 수 없습니다." },
  UNAUTHORIZED: { statusCode: 401, message: "인증이 필요합니다." },
} as const;
```

### 9.3 Server Action 에러 패턴

```typescript
export type ServerActionResult<T = Record<string, any>> = Promise<
  { success: boolean; message?: string } & T
>;
```

---

## 10. Import 규칙

### 10.1 Path Alias

```json
// tsconfig.json
{ "paths": { "@/*": ["./*", "./src/*"] } }
```

### 10.2 Import 순서

```typescript
// 1. React / Next.js
import { useState, useCallback } from "react";
import Link from "next/link";

// 2. 외부 라이브러리
import { useQuery } from "@tanstack/react-query";
import { z } from "zod";

// 3. 타입 (import type)
import type { Challenge } from "@/types";

// 4. 내부 절대 경로
import { joinChallengeAction } from "@/src/features/challenge/action";
import { cn } from "@/src/libs/utils";

// 5. 상대 경로 (가급적 피함)
import { SubComponent } from "./SubComponent";
```

---

## 11. Export 규칙

```typescript
// 컴포넌트: Named export
export const TribeCard = ({ tribe }: TribeCardProps) => { ... };

// 페이지: Default export
export default function Page() { ... }

// 타입 배럴: Re-export
// types/index.ts
export * from "./tribe.type";
export * from "./challenge.type";

// Server Action: Named export
export const joinTribeAction = async (...) => { ... };
```

---

## 12. 주요 의존성 스택

| 카테고리 | 라이브러리 |
|----------|-----------|
| 프레임워크 | Next.js 16, React 19 |
| 스타일링 | Tailwind CSS v4, shadcn/ui, CVA |
| 서버 상태 | @tanstack/react-query v5 |
| 폼 | react-hook-form, @hookform/resolvers |
| 유효성 검증 | Zod |
| 아이콘 | lucide-react |
| 토스트 | sonner |
| 날짜 | date-fns |
| 애니메이션 | framer-motion |
| JWT | jose |
| 테스트 | Jest, React Testing Library |

---

## 13. 테스트

### 13.1 테스트 스택

| 도구 | 용도 |
|------|------|
| Jest | 테스트 러너 |
| React Testing Library | 컴포넌트 렌더링 & 인터랙션 테스트 |
| @testing-library/jest-dom | DOM assertion 매처 확장 |
| MSW (Mock Service Worker) | API 요청 모킹 (선택) |

### 13.2 폴더 구조

```
src/
├── __tests__/                    # 통합 테스트
│   ├── setup.ts                  # Jest 글로벌 설정
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

### 13.3 테스트 대상 & 기준

| 대상 | 위치 | 테스트 기준 |
|------|------|-------------|
| **유틸 함수** | `libs/`, `shared/utils/` | 입출력 검증, 엣지 케이스, 에러 케이스 |
| **Zod 스키마** | `validators/` | 유효 데이터 통과, 무효 데이터 실패, 에러 메시지 확인 |
| **서비스 레이어** | `services/` | API mock → 응답 파싱 → validateResponse 검증 |
| **커스텀 훅** | `hooks/`, `features/*/hooks/` | 반환값, 상태 변이, 콜백 호출 검증 |
| **컴포넌트** | `features/*/ui/` | 조건부 렌더링, 이벤트 핸들러, props 반영 |

### 13.4 유틸 함수 테스트

```typescript
// libs/__tests__/utils.test.ts
import { cn } from "../utils";

describe("cn", () => {
  it("여러 클래스를 병합한다", () => {
    expect(cn("px-2", "py-1")).toBe("px-2 py-1");
  });

  it("충돌하는 Tailwind 클래스를 후자 우선으로 병합한다", () => {
    expect(cn("px-2", "px-4")).toBe("px-4");
  });

  it("falsy 값을 무시한다", () => {
    expect(cn("px-2", false && "hidden", undefined)).toBe("px-2");
  });
});
```

### 13.5 Zod 스키마 검증 테스트

```typescript
// validators/__tests__/tribe.test.ts
import { tribeSchema, tribeListResponseSchema } from "../tribe";

describe("tribeSchema", () => {
  const validTribe = {
    _id: "abc123",
    name: "러닝 크루",
    description: "매주 달리기",
    memberCount: 5,
    maxMembers: 20,
    createdAt: "2026-01-01T00:00:00.000Z",
  };

  it("유효한 데이터를 통과시킨다", () => {
    const result = tribeSchema.safeParse(validTribe);
    expect(result.success).toBe(true);
  });

  it("필수 필드 누락 시 실패한다", () => {
    const { name, ...invalid } = validTribe;
    const result = tribeSchema.safeParse(invalid);
    expect(result.success).toBe(false);
  });

  it("잘못된 타입 시 실패한다", () => {
    const result = tribeSchema.safeParse({ ...validTribe, memberCount: "five" });
    expect(result.success).toBe(false);
  });
});

describe("tribeListResponseSchema", () => {
  it("빈 목록도 유효하다", () => {
    const result = tribeListResponseSchema.safeParse({
      tribes: [],
      pagination: { total: 0, page: 1, limit: 10 },
    });
    expect(result.success).toBe(true);
  });
});
```

### 13.6 커스텀 훅 테스트

```typescript
// features/tribe/hooks/__tests__/useTribeList.test.ts
import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useTribeList } from "../useTribeList";

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe("useTribeList", () => {
  it("데이터를 정상 반환한다", async () => {
    const { result } = renderHook(() => useTribeList(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data?.tribes).toBeDefined();
  });
});
```

### 13.7 컴포넌트 테스트

```typescript
// features/tribe/ui/__tests__/TribeCard.test.tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { TribeCard } from "../TribeCard";

const mockTribe = {
  _id: "abc123",
  name: "러닝 크루",
  description: "매주 달리기",
  memberCount: 5,
  maxMembers: 20,
  createdAt: "2026-01-01T00:00:00.000Z",
};

describe("TribeCard", () => {
  it("트라이브 이름을 렌더링한다", () => {
    render(<TribeCard tribe={mockTribe} />);
    expect(screen.getByText("러닝 크루")).toBeInTheDocument();
  });

  it("인원수를 표시한다", () => {
    render(<TribeCard tribe={mockTribe} />);
    expect(screen.getByText(/5.*\/.*20/)).toBeInTheDocument();
  });

  it("클릭 시 상세 페이지로 링크된다", () => {
    render(<TribeCard tribe={mockTribe} />);
    const link = screen.getByRole("link");
    expect(link).toHaveAttribute("href", "/tribe/abc123");
  });
});
```

### 13.8 테스트 유틸

```typescript
// __tests__/utils.tsx
import { render, RenderOptions } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
    },
  });

export const renderWithProviders = (
  ui: React.ReactElement,
  options?: Omit<RenderOptions, "wrapper">,
) => {
  const queryClient = createTestQueryClient();
  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );

  return render(ui, { wrapper: Wrapper, ...options });
};
```

---

## 14. 메타데이터 & SEO

```typescript
// 동적 메타데이터 생성
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const data = await fetchData(params.id);
  return {
    title: data.title,
    description: data.description,
    openGraph: { title: data.title, images: [data.image] },
  };
}
```

---

## 15. 프로젝트 설정 파일

### next.config.ts

```typescript
const nextConfig: NextConfig = {
  experimental: {
    serverActions: { bodySizeLimit: "5mb" },
  },
  compiler: {
    removeConsole: isProd,
  },
  images: {
    formats: ["image/webp"],
    remotePatterns: [/* S3, CDN 등 */],
  },
};
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "strict": true,
    "jsx": "react-jsx",
    "module": "esnext",
    "moduleResolution": "bundler",
    "paths": { "@/*": ["./*", "./src/*"] }
  }
}
```

### ESLint (Flat Config)

```javascript
// eslint.config.mjs
import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";

export default [
  ...nextCoreWebVitals,
  ...nextTypescript,
  { ignores: [".next/", "out/", "build/"] },
];
```
