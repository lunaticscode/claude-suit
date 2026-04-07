# Electron Frontend Convention Rules

> TypeScript + Electron + React + Vite + HashRouter 기반 데스크톱 앱 코드 컨벤션
>
> 본 문서는 [`electron-folder-structure.md`](./electron-folder-structure.md)의 폴더/파일 구조를 기준으로 한 코드 작성 규칙을 정의합니다.

---

## 1. 아키텍처 개요

Electron 앱은 **4개의 독립된 영역**으로 구성되며, 각 영역은 신뢰 경계(trust boundary)를 가집니다.

| 영역            | 신뢰 수준 | 역할                                 |
| --------------- | --------- | ------------------------------------ |
| `src/main/`     | 신뢰      | Node 전권, OS 자원 접근, 도메인 로직 |
| `src/preload/`  | 경계      | contextBridge로 좁은 API만 노출      |
| `src/renderer/` | 신뢰 불가 | React UI (브라우저 환경 가정)        |
| `src/shared/`   | 공통      | 타입, 스키마, IPC 채널 상수          |

> 모든 통신은 **shared(계약) → main(구현) → preload(노출) → renderer(소비)** 의 단방향으로 흐릅니다.

---

## 2. 폴더 구조

```
src/
├── main/                           # [신뢰] Node 전권
│   ├── index.ts                    # 앱 부트스트랩
│   ├── bootstrap/                  # 보안 가드, 단일 인스턴스, 프로토콜
│   ├── windows/                    # BrowserWindow 팩토리
│   ├── ipc/                        # ipcMain.handle 등록 (검증 + 위임만)
│   │   └── [domain].handler.ts
│   ├── services/                   # 순수 도메인 로직 (Electron 객체 금지)
│   │   └── [domain].service.ts
│   ├── store/                      # 영속 저장소 (electron-store, SQLite)
│   ├── menu/ · tray/
│   └── utils/                      # path-guard, logger 등
│
├── preload/                        # [경계] contextBridge
│   ├── index.ts                    # window.api 조립 & 노출
│   ├── api/
│   │   └── [domain].api.ts         # ipcRenderer.invoke 래퍼
│   └── types.ts                    # AppApi 타입
│
├── renderer/                       # [신뢰 불가] React
│   ├── index.html                  # CSP meta
│   └── src/
│       ├── main.tsx
│       ├── App.tsx                 # <RouterProvider />
│       ├── routes/                 # 라우트 정의 + Route 컴포넌트
│       │   ├── index.tsx           # createHashRouter(...) default export
│       │   └── [domain]/
│       │       └── [Feature]Route.tsx
│       ├── features/               # 도메인별 기능 모듈
│       │   └── [domain]/
│       │       ├── components/     # 도메인 UI
│       │       ├── hooks/          # 도메인 훅
│       │       ├── api.ts          # window.api.[domain] 래퍼
│       │       └── form/           # 폼 스키마 (선택)
│       ├── components/             # 공용 UI (shadcn/ui 등)
│       ├── hooks/                  # 공용 훅
│       ├── stores/                 # 전역 상태 (zustand)
│       ├── lib/                    # 순수 유틸 (cn 등)
│       ├── providers/              # Context Provider
│       ├── styles/
│       └── types/
│           └── window.d.ts         # window.api 타입 주입
│
└── shared/                         # [공통]
    ├── ipc-channels.ts             # 채널명 상수
    ├── schemas/                    # zod 스키마 (IPC 페이로드)
    │   └── [domain].schema.ts
    ├── types/                      # 도메인 DTO
    │   └── [domain].type.ts
    └── errors.ts                   # 공통 에러
```

---

## 3. 컴포넌트 3계층 아키텍처

### Route → Container → Feature 패턴

```
routes/[domain]/[Feature]Route.tsx
    ↓ (라우트 진입, 데이터 로딩 트리거, 레이아웃)
features/[domain]/components/[Feature]Container.tsx
    ↓ (상태/이벤트 관리, 조립)
features/[domain]/components/[Presentation].tsx
    (순수 프레젠테이션)
```

### 3.1 Route 컴포넌트

- **위치**: `src/renderer/src/routes/[domain]/[Feature]Route.tsx`
- **역할**: URL 파라미터 해석, 데이터 로딩 훅 호출, Container에 위임
- **규칙**: 얇게 유지, 도메인 로직 금지

```typescript
// routes/notes/NoteDetailRoute.tsx
import { useParams } from 'react-router-dom';
import { NoteDetailContainer } from '@/features/notes/components/NoteDetailContainer';

export const NoteDetailRoute = () => {
  const { id } = useParams<{ id: string }>();
  if (!id) return null;
  return <NoteDetailContainer noteId={id} />;
};
```

### 3.2 Container 컴포넌트

- **위치**: `src/renderer/src/features/[domain]/components/[Feature]Container.tsx`
- **역할**: React Query 쿼리 실행, 상태 관리, 이벤트 핸들링
- **규칙**: `window.api` 직접 호출 금지 → `features/[domain]/api.ts` 경유

```typescript
// features/notes/components/NoteDetailContainer.tsx
export function NoteDetailContainer({ noteId }: { noteId: string }) {
  const { data, isLoading } = useNote(noteId);
  const [isEditing, setIsEditing] = useState(false);

  if (isLoading) return <Spinner />;
  if (!data) return <EmptyState />;

  return (
    <NoteDetailView
      note={data}
      isEditing={isEditing}
      onEditToggle={() => setIsEditing((v) => !v)}
    />
  );
}
```

### 3.3 Presentation 컴포넌트

- **위치**: `src/renderer/src/features/[domain]/components/[Name].tsx`
- **역할**: props 기반 순수 렌더링, 도메인 로직 없음
- **규칙**: 상태 가급적 없음, `window.api` 접근 금지

```typescript
export const NoteCard = ({ note, onSelect }: NoteCardProps) => {
  return (
    <div className={cn('rounded-lg p-4', note.pinned && 'bg-primary/10')}>
      <h3>{note.title}</h3>
      <button onClick={() => onSelect(note.id)}>열기</button>
    </div>
  );
};
```

---

## 4. 네이밍 컨벤션

### 4.1 파일 & 폴더

| 대상               | 규칙                      | 예시                                |
| ------------------ | ------------------------- | ----------------------------------- |
| React 컴포넌트     | PascalCase                | `NoteCard.tsx`, `NoteList.tsx`      |
| Route 컴포넌트     | `<Feature>Route.tsx`      | `NoteDetailRoute.tsx`               |
| Container 컴포넌트 | `<Feature>Container.tsx`  | `NoteListContainer.tsx`             |
| 커스텀 훅          | camelCase, `use` 접두사   | `useNotes.ts`, `useNoteMutation.ts` |
| IPC 핸들러         | `<domain>.handler.ts`     | `note.handler.ts`                   |
| 서비스 (main)      | `<domain>.service.ts`     | `note.service.ts`                   |
| 프리로드 API       | `<domain>.api.ts`         | `note.api.ts`                       |
| zod 스키마         | `<domain>.schema.ts`      | `note.schema.ts`                    |
| 타입 파일          | `<domain>.type.ts`        | `note.type.ts`                      |
| 창 팩토리          | `<name>-window.ts`        | `main-window.ts`                    |
| 유틸               | kebab-case                | `path-guard.ts`, `format-date.ts`   |
| 폴더               | kebab-case 또는 camelCase | `features/`, `notes/`               |

### 4.2 변수 & 함수

| 대상                 | 규칙                    | 예시                                     |
| -------------------- | ----------------------- | ---------------------------------------- |
| 일반 변수            | camelCase               | `selectedNote`, `currentWindow`          |
| 상수                 | SCREAMING_SNAKE_CASE    | `MAX_NOTE_LENGTH`, `DEFAULT_WINDOW_SIZE` |
| Boolean              | `is`/`has`/`can` 접두사 | `isLoading`, `hasUnsavedChanges`         |
| 이벤트 핸들러        | `handle` 접두사         | `handleSave`, `handleTabChange`          |
| 커스텀 훅            | `use` 접두사            | `useNotes`, `useWindowState`             |
| IPC 채널명           | `<domain>:<action>`     | `note:save`, `file:read`                 |
| IPC 핸들러 등록 함수 | `register<Domain>Ipc`   | `registerNoteIpc`                        |
| Preload API 호출     | 동사 + 명사             | `saveNote`, `listNotes`                  |

### 4.3 타입 & 인터페이스

| 대상             | 규칙                             | 예시                                          |
| ---------------- | -------------------------------- | --------------------------------------------- |
| 도메인 타입      | PascalCase                       | `Note`, `WindowState`                         |
| Props 타입       | 컴포넌트명 + `Props`             | `NoteCardProps`                               |
| IPC Input/Output | `<Action>Input`/`<Action>Result` | `NoteSaveInput`, `NoteSaveResult`             |
| Zod 추론 타입    | `z.infer` 사용                   | `type NoteInput = z.infer<typeof NoteSchema>` |

### 4.4 type vs interface

- **`type` 우선** (union, intersection, 일반 객체)
- **`interface`**: 확장 필요 시 또는 Props 정의 시 선택적

```typescript
type NoteStatus = "draft" | "published" | "archived";
type NoteCardProps = {
  note: Note;
  onSelect: (id: string) => void;
  className?: string;
};

interface WindowOptions {
  width: number;
  height: number;
  resizable?: boolean;
}
```

---

## 5. IPC 통신 패턴

### 5.1 전체 흐름

```
renderer                preload              main
────────                ───────              ────
useNotes()
  └─ notesClient.list()
       └─ window.api.note.list()
            └─ ipcRenderer.invoke('note:list')
                 └─────────────────────────> ipcMain.handle('note:list', ...)
                                                └─ NoteListInput.parse(raw)
                                                     └─ noteService.list()
                                                          └─ store.query()
```

### 5.2 채널명은 반드시 상수로

```typescript
// shared/ipc-channels.ts
export const IPC = {
  NOTE_SAVE: "note:save",
  NOTE_LIST: "note:list",
  NOTE_DELETE: "note:delete",
  NOTE_CHANGED: "note:changed", // main → renderer 이벤트
} as const;

export type IpcChannel = (typeof IPC)[keyof typeof IPC];
```

> 문자열 리터럴 직접 사용 금지. 오타 방지 + 채널 추적 가능.

### 5.3 Main — IPC 핸들러

**핸들러는 검증 + 위임만**. 도메인 로직은 서비스로.

```typescript
// main/ipc/note.handler.ts
import { ipcMain } from "electron";
import { IPC } from "@shared/ipc-channels";
import { NoteSaveSchema, NoteIdSchema } from "@shared/schemas/note.schema";
import { noteService } from "../services/note.service";

export function registerNoteIpc() {
  ipcMain.handle(IPC.NOTE_SAVE, async (_e, raw) => {
    const input = NoteSaveSchema.parse(raw); // 1) 검증
    return noteService.save(input); // 2) 위임
  });

  ipcMain.handle(IPC.NOTE_LIST, async () => {
    return noteService.list();
  });

  ipcMain.handle(IPC.NOTE_DELETE, async (_e, raw) => {
    const { id } = NoteIdSchema.parse(raw);
    return noteService.remove(id);
  });
}
```

### 5.4 Main — 서비스

**Electron 객체 import 금지**. 순수 도메인 로직만.

```typescript
// main/services/note.service.ts
import { noteStore } from "../store";
import type { NoteSaveInput, Note } from "@shared/types/note.type";

export const noteService = {
  save: async (input: NoteSaveInput): Promise<Note> => {
    const now = Date.now();
    const note = {
      id: crypto.randomUUID(),
      ...input,
      updatedAt: now,
    };
    await noteStore.set(note.id, note);
    return note;
  },

  list: async (): Promise<Note[]> => {
    return noteStore.all();
  },

  remove: async (id: string): Promise<void> => {
    await noteStore.delete(id);
  },
};
```

### 5.5 Preload — API 노출

**얇은 래퍼**. 로직 금지. 이벤트 리스너는 해제 함수 반환.

```typescript
// preload/api/note.api.ts
import { ipcRenderer } from "electron";
import { IPC } from "@shared/ipc-channels";
import type { NoteSaveInput, Note } from "@shared/types/note.type";

export const noteApi = {
  save: (input: NoteSaveInput): Promise<Note> =>
    ipcRenderer.invoke(IPC.NOTE_SAVE, input),

  list: (): Promise<Note[]> => ipcRenderer.invoke(IPC.NOTE_LIST),

  remove: (id: string): Promise<void> =>
    ipcRenderer.invoke(IPC.NOTE_DELETE, { id }),

  onChanged: (cb: (note: Note) => void) => {
    const listener = (_: unknown, note: Note) => cb(note);
    ipcRenderer.on(IPC.NOTE_CHANGED, listener);
    return () => ipcRenderer.off(IPC.NOTE_CHANGED, listener); // cleanup
  },
};
```

```typescript
// preload/index.ts
import { contextBridge } from "electron";
import { noteApi } from "./api/note.api";
import { fileApi } from "./api/file.api";
import { systemApi } from "./api/system.api";

const api = {
  note: noteApi,
  file: fileApi,
  system: systemApi,
} as const;

contextBridge.exposeInMainWorld("api", api);
export type AppApi = typeof api;
```

### 5.6 Renderer — 타입 주입

```typescript
// renderer/src/types/window.d.ts
import type { AppApi } from "../../../preload";

declare global {
  interface Window {
    api: AppApi;
  }
}
export {};
```

### 5.7 Renderer — Feature API 래퍼

**컴포넌트/훅은 `window.api`를 직접 호출하지 않음.** 래퍼 경유.

```typescript
// features/notes/api.ts
import type { NoteSaveInput } from "@shared/types/note.type";

export const notesClient = {
  list: () => window.api.note.list(),
  save: (input: NoteSaveInput) => window.api.note.save(input),
  remove: (id: string) => window.api.note.remove(id),
};
```

---

## 6. 데이터 패칭 패턴 (React Query)

### 6.1 쿼리 훅

```typescript
// features/notes/hooks/useNotes.ts
import { useQuery } from "@tanstack/react-query";
import { notesClient } from "../api";

export const noteKeys = {
  all: ["notes"] as const,
  list: () => [...noteKeys.all, "list"] as const,
  detail: (id: string) => [...noteKeys.all, "detail", id] as const,
};

export function useNotes() {
  return useQuery({
    queryKey: noteKeys.list(),
    queryFn: () => notesClient.list(),
  });
}
```

### 6.2 뮤테이션 훅

```typescript
// features/notes/hooks/useNoteMutation.ts
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { notesClient } from "../api";
import { noteKeys } from "./useNotes";

export function useSaveNote() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: notesClient.save,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: noteKeys.list() });
    },
  });
}
```

### 6.3 IPC 이벤트 구독 훅

```typescript
// features/notes/hooks/useNotesSync.ts
import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { noteKeys } from "./useNotes";

export function useNotesSync() {
  const queryClient = useQueryClient();
  useEffect(() => {
    const off = window.api.note.onChanged(() => {
      queryClient.invalidateQueries({ queryKey: noteKeys.all });
    });
    return off; // cleanup 필수
  }, [queryClient]);
}
```

---

## 7. 상태 관리 전략

| 관심사                  | 방법                                   |
| ----------------------- | -------------------------------------- |
| 서버(main) 데이터       | React Query (`@tanstack/react-query`)  |
| 폼 상태                 | `react-hook-form` + Zod                |
| UI 로컬 상태 (모달, 탭) | `useState` / `useReducer`              |
| 전역 클라이언트 상태    | `zustand` (필요 시)                    |
| 라우팅 상태             | `react-router-dom` URL params          |
| 영속 설정               | main의 `electron-store` + IPC로 동기화 |
| 테마                    | `zustand` + main 저장소 동기화         |

> **데스크톱 앱의 "서버"는 main 프로세스입니다.** React Query를 통해 main 데이터를 캐싱·동기화하는 것을 기본으로 합니다.

---

## 8. 라우팅 패턴 (HashRouter)

### 8.1 왜 HashRouter인가

Electron 렌더러는 프로덕션에서 `file://` 또는 `app://`로 HTML을 로드합니다. 이 환경에서 `BrowserRouter`는 새로고침·딥링크·빌드 경로 해석 문제를 일으킵니다. **`createHashRouter` (또는 `createMemoryRouter`)를 필수**로 사용합니다.

### 8.2 라우트 정의의 단일 출처

```typescript
// renderer/src/routes/index.tsx
import { createHashRouter } from 'react-router-dom';
import { HomeRoute } from './home/HomeRoute';
import { NotesListRoute } from './notes/NotesListRoute';
import { NoteDetailRoute } from './notes/NoteDetailRoute';
import { SettingsRoute } from './settings/SettingsRoute';
import { RootLayout } from '@/components/layout/RootLayout';

const router = createHashRouter([
  {
    path: '/',
    element: <RootLayout />,
    children: [
      { index: true, element: <HomeRoute /> },
      { path: 'notes', element: <NotesListRoute /> },
      { path: 'notes/:id', element: <NoteDetailRoute /> },
      { path: 'settings', element: <SettingsRoute /> },
    ],
  },
]);

export default router;
```

```typescript
// renderer/src/App.tsx
import { RouterProvider } from 'react-router-dom';
import router from './routes';

export function App() {
  return <RouterProvider router={router} />;
}
```

### 8.3 Route 컴포넌트 규칙

- `routes/[domain]/[Feature]Route.tsx`에 위치
- 라우트 파라미터 해석 + Container 조립만
- 도메인 UI·로직 금지 → 모두 `features/[domain]/`로

---

## 9. 폼 패턴 (react-hook-form + Zod)

### 9.1 스키마 정의

```typescript
// features/notes/form/noteForm.schema.ts
import { z } from "zod";

export const noteFormSchema = z.object({
  title: z.string().min(1, "제목을 입력하세요").max(200),
  body: z.string().max(100_000),
  tags: z.array(z.string()).default([]),
});

export type NoteFormData = z.infer<typeof noteFormSchema>;
```

### 9.2 폼 컴포넌트

```typescript
// features/notes/components/NoteForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { noteFormSchema, type NoteFormData } from '../form/noteForm.schema';
import { useSaveNote } from '../hooks/useNoteMutation';

export function NoteForm({ defaultValues }: { defaultValues?: NoteFormData }) {
  const { mutateAsync, isPending } = useSaveNote();
  const methods = useForm<NoteFormData>({
    resolver: zodResolver(noteFormSchema),
    defaultValues: defaultValues ?? { title: '', body: '', tags: [] },
  });

  const onSubmit = async (data: NoteFormData) => {
    await mutateAsync(data);
  };

  return (
    <form onSubmit={methods.handleSubmit(onSubmit)}>
      {/* 필드들 */}
      <button type="submit" disabled={isPending}>저장</button>
    </form>
  );
}
```

---

## 10. IPC 입출력 검증 (Zod)

### 10.1 파일 구조

```
src/shared/schemas/
├── index.ts                        # validateIpcInput 래퍼
├── note.schema.ts                  # Note 도메인 IPC 스키마
├── file.schema.ts
└── system.schema.ts
```

### 10.2 래퍼 함수

```typescript
// shared/schemas/index.ts
import { z } from "zod";

export function validateIpcInput<T extends z.ZodTypeAny>(
  schema: T,
  data: unknown,
): z.infer<T> {
  const result = schema.safeParse(data);
  if (!result.success) {
    console.error("[IPC Input Validation Error]", result.error.flatten());
    throw new Error("IPC 입력 데이터가 예상 형식과 일치하지 않습니다.");
  }
  return result.data;
}
```

### 10.3 도메인 스키마

```typescript
// shared/schemas/note.schema.ts
import { z } from "zod";

export const NoteSaveSchema = z.object({
  id: z.string().uuid().optional(),
  title: z.string().min(1).max(200),
  body: z.string().max(100_000),
  tags: z.array(z.string()).default([]),
});
export type NoteSaveInput = z.infer<typeof NoteSaveSchema>;

export const NoteIdSchema = z.object({
  id: z.string().uuid(),
});
```

### 10.4 핸들러에서 사용

```typescript
import { validateIpcInput } from "@shared/schemas";
import { NoteSaveSchema } from "@shared/schemas/note.schema";

ipcMain.handle(IPC.NOTE_SAVE, async (_e, raw) => {
  const input = validateIpcInput(NoteSaveSchema, raw);
  return noteService.save(input);
});
```

### 10.5 타입 추론

```typescript
// shared/types/note.type.ts
import type { z } from "zod";
import type { NoteSaveSchema } from "../schemas/note.schema";

export type NoteSaveInput = z.infer<typeof NoteSaveSchema>;

export type Note = {
  id: string;
  title: string;
  body: string;
  tags: string[];
  updatedAt: number;
};
```

---

## 11. 스타일링

### 11.1 기본 스택

- **Tailwind CSS v4** + PostCSS
- **shadcn/ui** (Radix UI 기반)
- **CVA** (Class Variance Authority)
- **cn()** 유틸 (clsx + tailwind-merge)

### 11.2 공통 컴포넌트 규칙

- **shadcn/ui 우선 사용**: 새 공통 컴포넌트가 필요할 때 shadcn에서 먼저 확인
- **커스터마이징은 `components/ui/_custom/`**: 원본은 건드리지 않음
- **래핑보다 조합**: 불필요한 래퍼 컴포넌트 금지

```typescript
import { cn } from '@/lib/utils';

className={cn(
  'rounded-lg p-4 text-sm',
  isActive && 'bg-primary text-white',
  className,
);
```

### 11.3 네이티브 창 테마 연동

- `nativeTheme`(main)과 `next-themes` 스타일 전환 훅을 IPC로 동기화
- 테마 변경은 main의 `electron-store`에 영속 저장

---

## 12. 에러 핸들링

### 12.1 공통 에러 클래스

```typescript
// shared/errors.ts
export type ErrorCode =
  | "VALIDATION_FAILED"
  | "NOT_FOUND"
  | "PERMISSION_DENIED"
  | "PATH_ESCAPE"
  | "UNKNOWN";

export class AppError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly cause?: unknown,
  ) {
    super(message);
    this.name = "AppError";
  }
}
```

### 12.2 IPC 에러 전파

Electron의 `ipcMain.handle`은 throw한 에러를 자동으로 렌더러의 Promise rejection으로 전달합니다. **직렬화 가능한 형태로 변환**합니다.

```typescript
// main/ipc/_helpers.ts
import { AppError } from "@shared/errors";

export function toSerializable(err: unknown) {
  if (err instanceof AppError) {
    return { name: err.name, code: err.code, message: err.message };
  }
  if (err instanceof Error) {
    return { name: err.name, code: "UNKNOWN", message: err.message };
  }
  return { name: "Error", code: "UNKNOWN", message: String(err) };
}
```

```typescript
ipcMain.handle(IPC.NOTE_SAVE, async (_e, raw) => {
  try {
    const input = NoteSaveSchema.parse(raw);
    return await noteService.save(input);
  } catch (err) {
    throw toSerializable(err);
  }
});
```

### 12.3 렌더러 에러 바운더리

```typescript
// components/ErrorBoundary.tsx
// React 컴포넌트 트리의 런타임 에러를 캐치하는 ErrorBoundary 배치
// Route 최상위 + 주요 Container 주위
```

---

## 13. Import 규칙

### 13.1 Path Alias

```json
// tsconfig.json (루트)
{
  "compilerOptions": {
    "paths": {
      "@main/*": ["./src/main/*"],
      "@preload/*": ["./src/preload/*"],
      "@shared/*": ["./src/shared/*"],
      "@/*": ["./src/renderer/src/*"]
    }
  }
}
```

- `@/*` → renderer 내부 (컴포넌트에서 자주 사용)
- `@shared/*` → 공통 계약 (3자 모두 사용 가능)
- `@main/*`, `@preload/*` → **import 대상이 제한됨** (아래 규칙 참조)

### 13.2 계층별 금지 import

| 계층        | 금지                                                                                 |
| ----------- | ------------------------------------------------------------------------------------ |
| `renderer/` | `electron`, `fs`, `path`, `child_process`, `os`, `@main/*`, `@preload/*` (타입 제외) |
| `preload/`  | `@main/*`, `@/*` (renderer), `fs`, `child_process`                                   |
| `main/`     | `@/*` (renderer), `@preload/*`                                                       |
| `shared/`   | `electron`, `fs`, `react`, DOM 전역 API                                              |

ESLint `eslint-plugin-boundaries` 또는 `no-restricted-imports`로 강제.

### 13.3 Import 순서

```typescript
// 1. React / 외부 라이브러리
import { useState, useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { z } from "zod";

// 2. 타입 (import type)
import type { Note } from "@shared/types/note.type";

// 3. shared (공통 계약)
import { IPC } from "@shared/ipc-channels";
import { NoteSaveSchema } from "@shared/schemas/note.schema";

// 4. 같은 영역 내부 절대 경로
import { notesClient } from "@/features/notes/api";
import { cn } from "@/lib/utils";

// 5. 상대 경로 (같은 feature 내부만 권장)
import { NoteCard } from "./NoteCard";
```

---

## 14. Export 규칙

```typescript
// 컴포넌트: Named export
export const NoteCard = ({ note }: NoteCardProps) => { ... };

// Route 컴포넌트: Named export
export const NoteDetailRoute = () => { ... };

// routes/index.tsx: Default export (router 인스턴스)
export default router;

// 커스텀 훅: Named export
export function useNotes() { ... }

// IPC 핸들러 등록: Named export
export function registerNoteIpc() { ... }

// 서비스: Named object export
export const noteService = { ... };

// 타입 배럴 export
// shared/types/index.ts
export * from './note.type';
export * from './file.type';
```

---

## 15. 보안 규칙 (필수)

### 15.1 webPreferences 고정

```typescript
new BrowserWindow({
  webPreferences: {
    preload: path.join(__dirname, "../preload/index.js"),
    contextIsolation: true, // 필수
    nodeIntegration: false, // 필수
    sandbox: true, // 필수
    webSecurity: true,
    allowRunningInsecureContent: false,
  },
});
```

### 15.2 금지 목록

- `contextBridge.exposeInMainWorld('ipcRenderer', ipcRenderer)` — 통째 노출 금지
- `window.api.exec`, `eval`, `require` 같은 범용 실행 API 노출 금지
- `dangerouslySetInnerHTML`에 외부 데이터 직접 삽입 금지
- 외부 CDN 스크립트 로드 금지 (번들에 포함)
- `<iframe src="외부">`, `<webview>` 사용 금지
- 렌더러에서 `fs`, `path`, `child_process` import 금지

### 15.3 전역 보안 가드

`main/bootstrap/security.ts`에서 앱 시작 시 실행:

- `web-contents-created` 이벤트에서 새 창/네비게이션 차단 (외부 URL은 `shell.openExternal`)
- `setPermissionRequestHandler`로 권한 기본 거부
- CSP 헤더 강제 (+ HTML meta 이중 방어)
- `will-attach-webview` 차단

### 15.4 경로 가드

파일시스템에 접근하는 모든 핸들러는 `assertInsideUserData`(또는 화이트리스트) 통과 필수.

```typescript
import { assertInsideUserData } from "../utils/path-guard";

export const fileService = {
  read: async (relPath: string) => {
    const safe = assertInsideUserData(relPath);
    return fs.promises.readFile(safe, "utf8");
  },
};
```

---

## 16. 주요 의존성 스택

| 카테고리    | 라이브러리                                      |
| ----------- | ----------------------------------------------- |
| 런타임      | Electron, Node.js                               |
| 빌드        | electron-vite 또는 Electron Forge + Vite        |
| 프레임워크  | React 19, TypeScript 5                          |
| 라우팅      | react-router-dom (`createHashRouter`)           |
| 스타일링    | Tailwind CSS v4, shadcn/ui, CVA                 |
| 서버 상태   | @tanstack/react-query v5                        |
| 폼          | react-hook-form, @hookform/resolvers            |
| 유효성 검증 | Zod                                             |
| 아이콘      | lucide-react                                    |
| 토스트      | sonner                                          |
| 날짜        | date-fns                                        |
| 영속 저장   | electron-store 또는 better-sqlite3              |
| 패키징      | electron-builder                                |
| 테스트      | Vitest, React Testing Library, Playwright (E2E) |

---

## 17. 테스트

### 17.1 테스트 스택

| 도구                      | 용도                              |
| ------------------------- | --------------------------------- |
| Vitest                    | 테스트 러너 (Vite 친화)           |
| React Testing Library     | 컴포넌트 렌더링 & 인터랙션 테스트 |
| @testing-library/jest-dom | DOM assertion 매처                |
| Playwright                | E2E (Electron 앱 자동화)          |

### 17.2 폴더 구조

```
src/
├── shared/
│   └── schemas/
│       └── __tests__/              # Zod 스키마 테스트
│           └── note.schema.test.ts
├── main/
│   └── services/
│       └── __tests__/              # 서비스 단위 테스트
│           └── note.service.test.ts
├── renderer/
│   └── src/
│       ├── __tests__/              # 통합 테스트 유틸
│       │   └── test-utils.tsx
│       ├── features/
│       │   └── notes/
│       │       ├── components/
│       │       │   └── __tests__/
│       │       └── hooks/
│       │           └── __tests__/
│       └── lib/
│           └── __tests__/
└── e2e/                            # Playwright E2E
    └── notes.spec.ts
```

### 17.3 테스트 대상 & 기준

| 대상        | 위치                     | 테스트 기준                          |
| ----------- | ------------------------ | ------------------------------------ |
| Zod 스키마  | `shared/schemas/`        | 유효/무효 데이터, 에러 메시지        |
| Main 서비스 | `main/services/`         | 순수 로직 (store mock)               |
| IPC 핸들러  | `main/ipc/`              | 검증 통과/실패, 서비스 호출 여부     |
| Preload API | `preload/api/`           | `ipcRenderer.invoke` 호출 인자       |
| 커스텀 훅   | `features/*/hooks/`      | 반환값, 상태 변이                    |
| 컴포넌트    | `features/*/components/` | 조건부 렌더링, 이벤트                |
| E2E         | `e2e/`                   | 실제 Electron 앱에서 사용자 시나리오 |

### 17.4 Renderer 테스트 유틸

```typescript
// renderer/src/__tests__/test-utils.tsx
import { render, type RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';

const createTestQueryClient = () =>
  new QueryClient({
    defaultOptions: { queries: { retry: false, gcTime: 0 } },
  });

export const renderWithProviders = (
  ui: React.ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>,
) => {
  const queryClient = createTestQueryClient();
  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>{children}</MemoryRouter>
    </QueryClientProvider>
  );
  return render(ui, { wrapper: Wrapper, ...options });
};
```

### 17.5 `window.api` 모킹

```typescript
// renderer/src/__tests__/test-utils.tsx
import { vi } from "vitest";

export function mockWindowApi(overrides?: Partial<Window["api"]>) {
  const api = {
    note: {
      list: vi.fn().mockResolvedValue([]),
      save: vi.fn().mockResolvedValue(undefined),
      remove: vi.fn().mockResolvedValue(undefined),
      onChanged: vi.fn().mockReturnValue(() => {}),
    },
    file: { read: vi.fn(), write: vi.fn() },
    system: { getVersion: vi.fn() },
    ...overrides,
  };
  (window as any).api = api;
  return api;
}
```

### 17.6 Zod 스키마 테스트

```typescript
// shared/schemas/__tests__/note.schema.test.ts
import { describe, it, expect } from "vitest";
import { NoteSaveSchema } from "../note.schema";

describe("NoteSaveSchema", () => {
  const valid = { title: "할 일", body: "우유 사기", tags: [] };

  it("유효한 데이터를 통과시킨다", () => {
    expect(NoteSaveSchema.safeParse(valid).success).toBe(true);
  });

  it("빈 제목은 실패한다", () => {
    const result = NoteSaveSchema.safeParse({ ...valid, title: "" });
    expect(result.success).toBe(false);
  });

  it("본문 최대 길이를 초과하면 실패한다", () => {
    const result = NoteSaveSchema.safeParse({
      ...valid,
      body: "a".repeat(100_001),
    });
    expect(result.success).toBe(false);
  });
});
```

### 17.7 서비스 테스트

```typescript
// main/services/__tests__/note.service.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../../store", () => ({
  noteStore: {
    set: vi.fn(),
    all: vi.fn().mockResolvedValue([]),
    delete: vi.fn(),
  },
}));

import { noteService } from "../note.service";
import { noteStore } from "../../store";

describe("noteService.save", () => {
  beforeEach(() => vi.clearAllMocks());

  it("id와 updatedAt을 채워 저장한다", async () => {
    const result = await noteService.save({ title: "t", body: "b", tags: [] });
    expect(result.id).toBeDefined();
    expect(result.updatedAt).toBeTypeOf("number");
    expect(noteStore.set).toHaveBeenCalledOnce();
  });
});
```

### 17.8 컴포넌트 테스트

```typescript
// features/notes/components/__tests__/NoteCard.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { renderWithProviders } from '@/__tests__/test-utils';
import { NoteCard } from '../NoteCard';

const note = {
  id: '1',
  title: '회의록',
  body: '',
  tags: [],
  updatedAt: 0,
};

describe('NoteCard', () => {
  it('제목을 렌더링한다', () => {
    renderWithProviders(<NoteCard note={note} onSelect={() => {}} />);
    expect(screen.getByText('회의록')).toBeInTheDocument();
  });

  it('클릭 시 onSelect를 호출한다', async () => {
    const onSelect = vi.fn();
    renderWithProviders(<NoteCard note={note} onSelect={onSelect} />);
    await userEvent.click(screen.getByRole('button', { name: '열기' }));
    expect(onSelect).toHaveBeenCalledWith('1');
  });
});
```

### 17.9 E2E 테스트 (Playwright)

```typescript
// e2e/notes.spec.ts
import { test, expect, _electron as electron } from "@playwright/test";

test("노트를 생성하고 목록에 표시된다", async () => {
  const app = await electron.launch({ args: ["."] });
  const window = await app.firstWindow();

  await window.getByRole("link", { name: "Notes" }).click();
  await window.getByRole("button", { name: "새 노트" }).click();
  await window.getByLabel("제목").fill("새 회의");
  await window.getByRole("button", { name: "저장" }).click();

  await expect(window.getByText("새 회의")).toBeVisible();
  await app.close();
});
```

---

## 18. 프로젝트 설정 파일

### 18.1 `tsconfig.json` (Project References)

```json
{
  "files": [],
  "references": [
    { "path": "./tsconfig.node.json" },
    { "path": "./tsconfig.web.json" },
    { "path": "./tsconfig.shared.json" }
  ]
}
```

### 18.2 `tsconfig.node.json` (main + preload)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "types": ["node", "electron"],
    "strict": true,
    "paths": {
      "@main/*": ["./src/main/*"],
      "@preload/*": ["./src/preload/*"],
      "@shared/*": ["./src/shared/*"]
    }
  },
  "include": ["src/main/**/*", "src/preload/**/*"]
}
```

### 18.3 `tsconfig.web.json` (renderer)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["DOM", "DOM.Iterable", "ESNext"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "paths": {
      "@/*": ["./src/renderer/src/*"],
      "@shared/*": ["./src/shared/*"]
    }
  },
  "include": ["src/renderer/**/*", "src/shared/**/*"]
}
```

### 18.4 ESLint 경계 강제 (예시)

```javascript
// eslint.config.mjs
import boundaries from "eslint-plugin-boundaries";

export default [
  {
    plugins: { boundaries },
    settings: {
      "boundaries/elements": [
        { type: "main", pattern: "src/main/**" },
        { type: "preload", pattern: "src/preload/**" },
        { type: "renderer", pattern: "src/renderer/**" },
        { type: "shared", pattern: "src/shared/**" },
      ],
    },
    rules: {
      "boundaries/element-types": [
        "error",
        {
          default: "disallow",
          rules: [
            { from: "main", allow: ["main", "shared"] },
            { from: "preload", allow: ["preload", "shared"] },
            { from: "renderer", allow: ["renderer", "shared"] },
            { from: "shared", allow: ["shared"] },
          ],
        },
      ],
    },
  },
];
```

---

## 19. 새 기능 추가 체크리스트

새 도메인 기능(예: `tasks`)을 추가할 때 따르는 순서:

- [ ] `shared/types/task.type.ts` — 도메인 타입 정의
- [ ] `shared/schemas/task.schema.ts` — zod 스키마
- [ ] `shared/ipc-channels.ts` — `TASK_*` 채널 상수 추가
- [ ] `main/services/task.service.ts` — 순수 도메인 로직
- [ ] `main/ipc/task.handler.ts` — 핸들러 (검증 + 위임)
- [ ] `main/ipc/index.ts` — `registerTaskIpc()` 등록
- [ ] `preload/api/task.api.ts` — `ipcRenderer.invoke` 래퍼
- [ ] `preload/index.ts` — `api.task` 병합
- [ ] `renderer/src/features/tasks/api.ts` — 클라이언트 래퍼
- [ ] `renderer/src/features/tasks/hooks/useTasks.ts` — React Query 훅
- [ ] `renderer/src/features/tasks/components/` — Container/Presentation
- [ ] `renderer/src/routes/tasks/TasksListRoute.tsx` — 라우트 컴포넌트
- [ ] `renderer/src/routes/index.tsx` — 라우트 등록
- [ ] 각 계층 테스트 작성 (스키마 → 서비스 → 훅 → 컴포넌트)

> 이 순서를 지키면 **IPC 경계의 타입·검증·노출이 누락될 수 없습니다.**

---

## 20. 핵심 원칙 요약

1. **신뢰 경계를 디렉토리로 드러낸다** — 파일 위치가 곧 권한 수준
2. **단방향 의존성** — renderer → preload → main, 역방향 금지
3. **공통 계약은 `shared/`에 한 곳만** — 타입·스키마·채널의 단일 출처
4. **핸들러는 얇게, 서비스는 두껍게** — IPC 핸들러는 검증과 위임만
5. **프리로드는 얇게, 구체적으로** — 범용 API 노출 금지
6. **Route는 얇게, Container에서 조립** — 라우트 컴포넌트는 파라미터 해석만
7. **`window.api` 직접 호출 금지** — feature 래퍼 경유
8. **새 기능은 안쪽부터 바깥쪽으로** — shared → main → preload → renderer
9. **HashRouter 필수** — `file://`/`app://` 환경 호환성
10. **보안 기본값은 하드코딩** — `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`
