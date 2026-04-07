# Electron + React + TS 폴더/파일 구조 컨벤션

보안(신뢰 경계)을 디렉토리로 드러내는 Electron + React + TypeScript 프로젝트 구조 가이드.

## 전체 구조

```
my-electron-app/
├── package.json
├── electron.vite.config.ts
├── tsconfig.json                   # project references 루트
├── tsconfig.node.json              # main + preload
├── tsconfig.web.json               # renderer
├── electron-builder.yml            # 패키징/서명/notarize
├── .env.example
│
├── resources/                      # 앱 아이콘, 트레이 이미지
├── build/                          # 패키징용 entitlements, icons
│
├── src/
│   ├── main/                       # [신뢰 영역] Node 전권
│   │   ├── index.ts                # 앱 부트스트랩
│   │   ├── bootstrap/
│   │   │   ├── single-instance.ts  # app.requestSingleInstanceLock
│   │   │   ├── security.ts         # CSP, 권한 핸들러, webContents 가드
│   │   │   └── protocol.ts         # 커스텀 프로토콜 등록
│   │   ├── windows/
│   │   │   ├── main-window.ts      # webPreferences 강제 설정
│   │   │   └── settings-window.ts
│   │   ├── ipc/
│   │   │   ├── index.ts            # 모든 핸들러 등록 엔트리
│   │   │   ├── file.handler.ts     # 경로 화이트리스트 + 스키마 검증
│   │   │   ├── note.handler.ts
│   │   │   └── system.handler.ts
│   │   ├── services/               # 도메인 로직 (IPC와 독립)
│   │   │   ├── note.service.ts
│   │   │   ├── file.service.ts
│   │   │   └── updater.service.ts
│   │   ├── store/                  # electron-store, SQLite 등
│   │   │   └── index.ts
│   │   ├── menu/
│   │   ├── tray/
│   │   └── utils/
│   │       ├── path-guard.ts       # 경로 탈출(../) 차단
│   │       └── logger.ts
│   │
│   ├── preload/                    # [경계] 유일한 통로
│   │   ├── index.ts                # contextBridge.exposeInMainWorld('api', ...)
│   │   ├── api/
│   │   │   ├── note.api.ts
│   │   │   ├── file.api.ts
│   │   │   └── system.api.ts
│   │   └── types.ts                # window.api 타입 선언
│   │
│   ├── renderer/                   # [신뢰 불가 영역] 순수 웹
│   │   ├── index.html              # CSP meta 포함
│   │   ├── src/
│   │   │   ├── main.tsx
│   │   │   ├── App.tsx             # <RouterProvider router={router} />
│   │   │   ├── routes/             # 라우트 정의 (HashRouter 기반)
│   │   │   │   ├── index.tsx       # createHashRouter(...) default export
│   │   │   │   ├── notes/
│   │   │   │   │   ├── NotesListRoute.tsx       #  /notes
│   │   │   │   │   └── NoteDetailRoute.tsx      #  /notes/:id
│   │   │   │   ├── settings/
│   │   │   │   │   └── SettingsRoute.tsx        #  /settings
│   │   │   │   └── home/
│   │   │   │       └── HomeRoute.tsx            #  /
│   │   │   ├── features/           # 도메인별 기능 묶음
│   │   │   │   └── notes/
│   │   │   │       ├── components/
│   │   │   │       ├── hooks/
│   │   │   │       └── api.ts      # window.api.note 호출 래퍼
│   │   │   ├── components/         # 공용 UI
│   │   │   ├── hooks/
│   │   │   ├── stores/             # zustand 등
│   │   │   ├── lib/                # 순수 유틸 (fs/path 금지)
│   │   │   ├── styles/
│   │   │   └── types/
│   │   │       └── window.d.ts     # window.api 타입 주입
│   │   └── public/
│   │
│   └── shared/                     # [공통] main·preload·renderer 모두 참조
│       ├── ipc-channels.ts         # 채널명 상수
│       ├── schemas/                # zod 스키마 (IPC 페이로드)
│       │   ├── note.schema.ts
│       │   └── file.schema.ts
│       ├── types/                  # 도메인 모델 (DTO)
│       └── errors.ts               # 공통 에러 타입
│
└── out/ 또는 dist/                 # 빌드 산출물
```

## 4개 영역의 역할

| 영역        | 신뢰 수준 | 역할                                 | 핵심 제약                      |
| ----------- | --------- | ------------------------------------ | ------------------------------ |
| `main/`     | 신뢰      | Node 전권, OS 자원 접근, 도메인 로직 | 렌더러/프리로드 import 금지    |
| `preload/`  | 경계      | contextBridge로 좁은 API만 노출      | 로직 없음, 얇게 유지           |
| `renderer/` | 신뢰 불가 | React UI, 브라우저 환경 가정         | Node/Electron import 전면 금지 |
| `shared/`   | 공통      | 타입, 스키마, 채널 상수              | DOM·Node 전용 코드 금지        |

## 각 영역 네이밍 컨벤션

### `main/`

- **`bootstrap/`** — 앱 시작 시 1회 실행되는 초기화 코드 (보안 가드, 프로토콜 등록)
- **`windows/`** — `BrowserWindow` 생성 팩토리. 창마다 파일 하나
- **`ipc/*.handler.ts`** — `ipcMain.handle` 등록만. 비즈니스 로직 금지
- **`services/*.service.ts`** — 순수 도메인 로직. Electron 객체 import 금지 (테스트 용이성)
- **`store/`** — 영속 저장소 래퍼 (electron-store, SQLite)
- **`utils/`** — main 전용 유틸 (경로 가드, 로거)

### `preload/`

- **`index.ts`** — `contextBridge.exposeInMainWorld('api', api)` 한 줄 중심
- **`api/*.api.ts`** — 도메인별 노출 API. 각 함수는 `ipcRenderer.invoke` 한 번만 래핑
- 이벤트 리스너를 노출할 때는 반드시 **해제 함수 반환**

### `renderer/src/`

- **`routes/`** — 라우터 정의 및 라우트 단위 화면 컴포넌트
  - `index.tsx` — `createHashRouter([...])`로 만든 router를 **default export**. `App.tsx`가 이걸 import해 `<RouterProvider />`에 전달
  - `<domain>/<Feature>Route.tsx` — 도메인별 라우트 화면 컴포넌트. 파일명은 항상 `...Route.tsx` 접미사
  - `routes/index.tsx`는 각 도메인의 Route 컴포넌트를 import해 경로와 매핑만 담당 (라우트 트리의 단일 출처)
- **`features/<domain>/`** — 도메인 단위 기능 묶음 (components + hooks + api)
  - `api.ts` — `window.api.<domain>` 호출을 감싸는 얇은 클라이언트
  - `hooks/` — 해당 도메인 전용 훅
  - `components/` — 해당 도메인 전용 컴포넌트
- **`components/`** — 여러 feature에서 쓰는 공용 UI
- **`hooks/`** — 공용 훅
- **`stores/`** — 전역 상태 (zustand/redux)
- **`lib/`** — 순수 유틸 (DOM 또는 순수 JS만)
- **`types/window.d.ts`** — `window.api` 타입 전역 주입

#### 라우팅 규칙 (Electron 특화)

- **반드시 `HashRouter` 사용** — Electron은 프로덕션에서 `file://` 또는 `app://` 프로토콜로 렌더러를 로드하므로, `BrowserRouter`는 새로고침·딥링크·경로 해석 문제가 발생. `createHashRouter`(또는 `createMemoryRouter`)가 안전
- **라우트 정의는 `routes/index.tsx`에만** — 라우트 트리의 단일 출처. 다른 파일에서 `createHashRouter`를 또 만들지 않음
- **Route 컴포넌트는 얇게** — 데이터 로딩 트리거, 레이아웃, `features/`의 컴포넌트 조립만. 실제 UI/로직은 `features/<domain>/`에서 가져옴
- **도메인-라우트-피처 1:1 대응** — `routes/notes/` ↔ `features/notes/`가 짝을 이루면 탐색이 쉬움

#### `routes/` 예시

```
routes/
├── index.tsx                       # createHashRouter([...]) default export
├── home/
│   └── HomeRoute.tsx               #  /
├── notes/
│   ├── NotesListRoute.tsx          #  /notes
│   └── NoteDetailRoute.tsx         #  /notes/:id
└── settings/
    └── SettingsRoute.tsx           #  /settings
```

```tsx
// routes/index.tsx
import { createHashRouter } from "react-router-dom";
import { HomeRoute } from "./home/HomeRoute";
import { NotesListRoute } from "./notes/NotesListRoute";
import { NoteDetailRoute } from "./notes/NoteDetailRoute";
import { SettingsRoute } from "./settings/SettingsRoute";

const router = createHashRouter([
  { path: "/", element: <HomeRoute /> },
  { path: "/notes", element: <NotesListRoute /> },
  { path: "/notes/:id", element: <NoteDetailRoute /> },
  { path: "/settings", element: <SettingsRoute /> },
]);

export default router;
```

```tsx
// App.tsx
import { RouterProvider } from "react-router-dom";
import router from "./routes";

export function App() {
  return <RouterProvider router={router} />;
}
```

### `shared/`

- **`ipc-channels.ts`** — 채널명 상수. 문자열 리터럴 직접 사용 금지
- **`schemas/*.schema.ts`** — zod 스키마 (IPC 페이로드 런타임 검증)
- **`types/`** — 도메인 DTO 인터페이스
- **`errors.ts`** — 공통 에러 클래스/타입

## 파일 네이밍 규칙

| 종류            | 패턴                  | 예시                  |
| --------------- | --------------------- | --------------------- |
| IPC 핸들러      | `<domain>.handler.ts` | `note.handler.ts`     |
| 서비스          | `<domain>.service.ts` | `note.service.ts`     |
| 프리로드 API    | `<domain>.api.ts`     | `note.api.ts`         |
| zod 스키마      | `<domain>.schema.ts`  | `note.schema.ts`      |
| React 컴포넌트  | `PascalCase.tsx`      | `NoteList.tsx`        |
| 라우트 컴포넌트 | `<Feature>Route.tsx`  | `NoteDetailRoute.tsx` |
| 훅              | `use<Name>.ts`        | `useNotes.ts`         |
| 유틸            | `kebab-case.ts`       | `path-guard.ts`       |
| 창 팩토리       | `<name>-window.ts`    | `main-window.ts`      |

## 의존성 방향 규칙

```
shared  ←  main
shared  ←  preload  →  (ipcRenderer만)
shared  ←  renderer →  (window.api만)

main     ✗  renderer  (import 금지)
main     ✗  preload   (import 금지)
renderer ✗  main      (import 금지)
renderer ✗  preload   (타입 외 import 금지)
preload  ✗  main      (import 금지)
preload  ✗  renderer  (import 금지)
```

- 모든 영역은 `shared/`만 양방향으로 참조 가능
- `main ↔ renderer`는 **오직 IPC 경계를 통해서만** 통신
- renderer가 preload에서 import하는 것은 **타입 뿐** (`import type { AppApi } from '../../preload'`)

## 계층별 금지 import (ESLint `no-restricted-imports`로 강제)

| 계층        | 금지 import                                                                              |
| ----------- | ---------------------------------------------------------------------------------------- |
| `renderer/` | `electron`, `fs`, `path`, `child_process`, `os`, `../main/*`, `../preload/*` (타입 제외) |
| `preload/`  | `../main/*`, `../renderer/*`, `fs`, `child_process`                                      |
| `main/`     | `../renderer/*`, `../preload/*`                                                          |
| `shared/`   | `electron`, `fs`, `react`, DOM 전역 API                                                  |

권장 플러그인: `eslint-plugin-boundaries` 또는 `eslint-plugin-import` + `no-restricted-paths`.

## tsconfig 분리 전략

```
tsconfig.json              # 루트. project references로 아래 3개를 묶음
├── tsconfig.node.json     # main + preload (target: ES2022, types: ["node"])
├── tsconfig.web.json      # renderer (target: ES2022, lib: ["DOM"], jsx: "react-jsx")
└── tsconfig.shared.json   # shared (target: ES2022, lib 없음)
```

- main/preload는 Node 타입만 사용 (DOM 타입 유입 차단)
- renderer는 DOM 타입만 사용 (Node 타입 유입 차단)
- shared는 둘 다 없이 순수 TS만

이렇게 하면 실수로 renderer에서 `fs`를 import하거나 main에서 `document`를 쓰는 것이 **타입 레벨에서 차단**됩니다.

## 새 기능 추가 시 작업 순서

보안 검증 지점을 자연스럽게 거치도록 강제하는 순서:

1. **`shared/types/`** — 도메인 모델 정의
2. **`shared/schemas/`** — zod 스키마로 입출력 검증 규칙 정의
3. **`shared/ipc-channels.ts`** — 채널명 상수 추가
4. **`main/services/`** — 순수 도메인 로직 구현
5. **`main/ipc/*.handler.ts`** — 스키마 검증 + 서비스 호출
6. **`main/ipc/index.ts`** — 핸들러 등록
7. **`preload/api/*.api.ts`** — `ipcRenderer.invoke` 래퍼 추가
8. **`preload/index.ts`** — `api` 객체에 병합
9. **`renderer/features/<domain>/api.ts`** — 얇은 클라이언트
10. **`renderer/features/<domain>/hooks/`** — 훅/컴포넌트에서 소비

이 순서를 지키면 IPC 경계의 타입·검증·노출이 누락될 수 없습니다.

## 산출물/아티팩트 폴더

- **`resources/`** — 소스 리포에 포함되는 정적 자산 (앱 아이콘, 트레이 이미지)
- **`build/`** — 패키징 관련 파일 (entitlements.plist, 설치 스크립트)
- **`out/` 또는 `dist/`** — 빌드 산출물. `.gitignore` 대상

## 핵심 원칙 요약

1. **신뢰 경계를 디렉토리로 드러낸다** — 파일 위치가 곧 권한 수준
2. **단방향 의존성** — renderer는 preload를 지나서만 main에 도달
3. **공통 계약은 `shared/`에 한 곳만** — 타입·스키마·채널 상수의 단일 출처
4. **핸들러는 얇게, 서비스는 두껍게** — IPC 핸들러는 검증과 위임만
5. **프리로드는 얇게, 구체적으로** — 범용 API 노출 금지, 동작 단위로만
6. **새 기능은 안쪽부터 바깥쪽으로** — shared → main → preload → renderer
