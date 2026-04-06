# Backend Convention Rules

> TypeScript + Express 기반 백엔드 API 서버 코드 컨벤션

---

## 1. 폴더 구조

```
src/
├── app.ts                        # Express 앱 설정 & 미들웨어 스택
│
├── routes/                       # Express 라우트 정의
│   ├── index.ts                  # 라우터 통합 (app.use 등록)
│   ├── oauth.ts                  # 인증 관련 라우트
│   ├── members.ts
│   ├── tasks.ts
│   ├── schedule.ts
│   └── dashboard.ts
│
├── controllers/                  # 요청 핸들러 (입력 검증 → 서비스 호출 → 응답)
│   ├── members.ts
│   ├── tasks.ts
│   ├── profile.ts
│   └── dashboard.ts
│
├── services/                     # 비즈니스 로직 (DB 접근, 데이터 가공)
│   ├── members.ts
│   ├── tasks.ts
│   ├── profile.ts
│   └── dashboard.ts
│
├── validators/                   # Zod 스키마 (요청 유효성 검증)
│   ├── members.ts
│   ├── tasks.ts
│   └── profile.ts
│
├── middlewares/                   # Express 미들웨어
│   ├── auth.ts                   # JWT 인증 & 자동 갱신
│   ├── errorHandler.ts           # 글로벌 에러 핸들러
│   └── logger.ts                 # 요청 로깅
│
├── scripts/                      # 유틸리티 스크립트
│   └── seed.ts                   # DB 시딩
│
└── __tests__/                    # 통합 테스트
    ├── setup.ts                  # 테스트 환경 설정
    ├── helpers.ts                # 테스트 유틸 (토큰 생성 등)
    ├── auth.test.ts
    ├── members.test.ts
    └── tasks.test.ts
```

### 모노레포 공유 패키지 (선택)

```
packages/
├── consts/                       # 환경 변수 & 설정 상수
├── db/                           # MongoDB 스키마 & 연결
├── libs/                         # JWT & 유틸리티 함수
├── types/                        # 공유 TypeScript 타입
├── utils/                        # 에러 핸들링 유틸
├── eslint-config/                # 공유 ESLint 설정
└── typescript-config/            # 공유 TypeScript 설정
```

---

## 2. 아키텍처 패턴 (MVC-like)

### Route → Controller → Service → DB

```
클라이언트 요청
  ↓
Route (라우트 정의, 미들웨어 체이닝)
  ↓
Controller (입력 검증, 응답 포맷)
  ↓
Service (비즈니스 로직, DB 쿼리)
  ↓
Model (Mongoose 모델)
```

### 2.1 Route

- **역할**: HTTP 메서드 & 경로 매핑, 미들웨어 체이닝
- **규칙**: 로직 없이 라우팅만 담당

```typescript
// routes/members.ts
import { Router } from "express";
import { authMiddleware } from "../middlewares/auth";
import * as membersController from "../controllers/members";

const router = Router();

router.use(authMiddleware);

router.get("/", membersController.getMembers);
router.get("/search", membersController.searchMembers);
router.get("/:id", membersController.getMemberDetail);
router.patch("/:id", membersController.updateMember);
router.post("/:id/register", membersController.registerMember);

export default router;
```

### 2.2 Controller

- **역할**: 요청 파싱, Zod 검증, 서비스 호출, 응답 반환
- **규칙**: 비즈니스 로직 없음. 검증 + 서비스 호출 + 응답만.

```typescript
// controllers/members.ts
import { AppController } from "@repo/types";
import { getMembersQuerySchema } from "../validators/members";
import * as membersService from "../services/members";
import { AppError } from "@repo/utils";

export const getMembers: AppController = async (req, res) => {
  const parsed = getMembersQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    throw new AppError(parsed.error.message, "VALIDATOR_ERROR");
  }

  const members = await membersService.getMembers({
    trainerId: req.id,
    ...parsed.data,
  });

  res.json({ success: true, data: members });
};
```

### 2.3 Service

- **역할**: 비즈니스 로직, DB 쿼리, 데이터 가공
- **규칙**: Express 의존성 없음 (req, res 접근 금지). 순수 비즈니스 로직만.

```typescript
// services/members.ts
import { User } from "@repo/db";

interface GetMembersOptions {
  trainerId: string;
  active?: boolean;
  name?: string;
}

export const getMembers = async ({ trainerId, active, name }: GetMembersOptions) => {
  const filter: Record<string, any> = { trainerId, role: "member" };
  if (active !== undefined) filter.active = active;
  if (name) filter.name = { $regex: name, $options: "i" };

  return User.find(filter).select("name email profileImage active").lean();
};
```

### 2.4 Validator

- **역할**: 요청 데이터 스키마 정의 (Zod)
- **규칙**: 스키마만 export. 추론 타입도 함께 export.

```typescript
// validators/members.ts
import { z } from "zod";

export const getMembersQuerySchema = z.object({
  active: z.enum(["true", "false"]).optional(),
  name: z.string().optional(),
});

export const updateMemberBodySchema = z.object({
  category: z.enum(["diet", "weight"]).optional(),
  goal: z.string().optional(),
  active: z.boolean().optional(),
});

export type UpdateMemberData = z.infer<typeof updateMemberBodySchema>;
```

---

## 3. 네이밍 컨벤션

### 3.1 파일 & 폴더

| 대상 | 규칙 | 예시 |
|------|------|------|
| 모든 파일 | kebab-case 또는 camelCase | `error-handler.ts`, `members.ts` |
| 라우트 파일 | 도메인 단수/복수 | `members.ts`, `profile.ts` |
| 테스트 파일 | `.test.ts` 접미사 | `members.test.ts` |
| 스키마 파일 | 도메인명 | `members.ts` (validators/) |

### 3.2 함수 & 변수

| 대상 | 규칙 | 예시 |
|------|------|------|
| 서비스 함수 | 동사 + 명사 | `getMembers`, `createTasks`, `updateTaskStatus` |
| 컨트롤러 핸들러 | 동사 + 명사 | `getMembers`, `searchMembers` |
| 스키마 | camelCase + Schema | `getMembersQuerySchema`, `updateMemberBodySchema` |
| 상수 | SCREAMING_SNAKE_CASE | `TOKEN_RENEWAL_THRESHOLD`, `ACCESS_TOKEN_KEY` |
| 환경 변수 | SCREAMING_SNAKE_CASE | `API_BASE_URL`, `MONGODB_URI` |
| Boolean | is/has/can 접두사 | `isExpired`, `hasPermission` |

### 3.3 타입

| 대상 | 규칙 | 예시 |
|------|------|------|
| 모델 타입 | PascalCase | `User`, `Task`, `Meal` |
| 상태 유니온 | PascalCase | `TaskStatus`, `TaskCategory` |
| 옵션/파라미터 | PascalCase + Options/Params | `GetMembersOptions` |
| 추론 타입 | z.infer 사용 | `type UpdateMemberData = z.infer<typeof schema>` |
| 제네릭 응답 | PascalCase | `ApiResponse<T>` |

---

## 4. 미들웨어 스택

### 4.1 등록 순서 (app.ts)

```typescript
// 1. 보안
app.use(helmet());

// 2. 쿠키 파싱
app.use(cookieParser());

// 3. Rate Limiting
app.use(rateLimit({ windowMs: 60_000, max: 120 }));

// 4. Body 파싱
app.use(express.json());

// 5. 압축
app.use(compression());

// 6. 로깅 (개발 환경)
if (!isProd) app.use(logMiddleware);

// 7. 라우트
app.use("/api/oauth", oauthRoutes);
app.use("/api/members", membersRoutes);
app.use("/api/tasks", tasksRoutes);
// ...

// 8. 404 핸들러
app.use(notFoundHandler);

// 9. 글로벌 에러 핸들러
app.use(errorHandler);
```

### 4.2 인증 미들웨어

```typescript
export const authMiddleware: AppMiddleware = async (req, res, next) => {
  // 1. X-API-Key 헤더 체크 (서버 간 통신)
  // 2. JWT 쿠키 검증
  // 3. 만료 임박 시 자동 갱신 (24시간 이내)
  // 4. req.id = decoded.sub (사용자 ID 설정)
  next();
};
```

### 4.3 에러 핸들러

```typescript
export const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
  if (err instanceof AppError) {
    const { statusCode } = getErrorInfo(err.code);
    return res.status(statusCode).json({
      success: false,
      errorCode: err.code,
      message: err.message,
      timestamp: new Date().toISOString(),
    });
  }

  res.status(500).json({
    success: false,
    errorCode: "INTERNAL_SERVER_ERROR",
    message: "서버 내부 오류가 발생했습니다.",
  });
};
```

---

## 5. 에러 핸들링

### 5.1 AppError 클래스

```typescript
export class AppError extends Error {
  code: ErrorCode;

  constructor(message: string, code: ErrorCode) {
    super(message);
    this.code = code;
  }
}
```

### 5.2 에러 코드 정의

```typescript
export const ERROR_CODES = {
  VALIDATOR_ERROR: { statusCode: 400 },
  MISSING_TOKEN: { statusCode: 401 },
  JWT_EXPIRED: { statusCode: 401 },
  JWT_INVALID: { statusCode: 401 },
  INVALID_API_KEY: { statusCode: 403 },
  USER_NOT_FOUND: { statusCode: 404 },
  INTERNAL_SERVER_ERROR: { statusCode: 500 },
} as const;

export type ErrorCode = keyof typeof ERROR_CODES;
```

### 5.3 에러 사용 패턴

```typescript
// Controller/Service에서 throw
throw new AppError("회원을 찾을 수 없습니다.", "USER_NOT_FOUND");
throw new AppError(parsed.error.message, "VALIDATOR_ERROR");

// 글로벌 에러 핸들러가 자동으로 응답 포맷팅
```

---

## 6. 인증 패턴

### 6.1 JWT (RS256)

- **알고리즘**: RS256 (RSA 비대칭 키)
- **저장**: httpOnly 쿠키 (`__fitvely_token`)
- **수명**: 7일 (24시간 이내 만료 시 자동 갱신)
- **라이브러리**: `jose`

```typescript
// 토큰 발급
import { getSignedToken } from "@repo/libs";

const token = await getSignedToken(
  { sub: user._id.toString(), role: user.role },
  "7d",
);

res.cookie(ACCESS_TOKEN_KEY, token, {
  httpOnly: true,
  secure: isProd,
  sameSite: "lax",
  maxAge: 7 * 24 * 60 * 60 * 1000,
});
```

### 6.2 API Key (서버 간 통신)

```typescript
// X-API-Key 헤더로 서버 간 인증
const apiKey = req.headers["x-api-key"];
if (apiKey && apiKey === process.env.INTERNAL_API_KEY) {
  // 서버 간 통신 허용
  next();
}
```

---

## 7. 데이터베이스 (MongoDB + Mongoose)

### 7.1 모델 정의

```typescript
// packages/db/src/models/user.ts
const userSchema = new Schema<IUser>(
  {
    email: { type: String, required: true },
    provider: { type: String, enum: ["google", "apple"], required: true },
    name: { type: String, required: true },
    role: { type: String, enum: ["trainer", "member", "admin"], required: true },
    trainerId: { type: Schema.Types.ObjectId, ref: "User" },
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

// 인덱스 정의
userSchema.index({ email: 1, provider: 1 }, { unique: true });
userSchema.index({ trainerId: 1 });

export const User = model<IUser>("User", userSchema);
```

### 7.2 쿼리 패턴

```typescript
// .lean() 으로 Plain Object 반환 (성능 최적화)
const members = await User.find({ trainerId }).lean();

// .select() 로 필요한 필드만 조회
const profile = await User.findById(id).select("name email profileImage").lean();

// populate 사용
const tasks = await Task.find({ trainerId })
  .populate("memberId", "name profileImage")
  .lean();
```

---

## 8. 유효성 검증 (Zod)

### 8.1 요청 검증 패턴

```typescript
// validators/tasks.ts
export const createTasksBodySchema = z.object({
  memberId: z.string().min(1),
  sessions: z.array(
    z.object({
      scheduledAt: z.string().datetime(),
      duration: z.number().min(30).max(180),
      category: z.enum(["diet", "weight"]),
      content: z.string().optional(),
    }),
  ).min(1),
});

// controllers/tasks.ts
const parsed = createTasksBodySchema.safeParse(req.body);
if (!parsed.success) {
  throw new AppError(parsed.error.message, "VALIDATOR_ERROR");
}
```

### 8.2 스키마 네이밍 규칙

| 대상 | 패턴 | 예시 |
|------|------|------|
| Query 파라미터 | `get[Domain]QuerySchema` | `getMembersQuerySchema` |
| Path 파라미터 | `[domain]ParamsSchema` | `memberParamsSchema` |
| Request Body | `[action][Domain]BodySchema` | `createTasksBodySchema`, `updateMemberBodySchema` |

---

## 9. 응답 포맷

### 9.1 성공 응답

```typescript
// 단일 조회
res.json({ success: true, data: member });

// 목록 조회
res.json({ success: true, data: members });

// 목록 + 페이지네이션
res.json({ success: true, data: members, pagination: { total, page, limit } });

// 생성/수정 (데이터 반환)
res.status(201).json({ success: true, data: createdTask });

// 삭제 (데이터 없음)
res.json({ success: true });
```

### 9.2 에러 응답

```typescript
{
  success: false,
  errorCode: "USER_NOT_FOUND",
  message: "회원을 찾을 수 없습니다.",
  timestamp: "2026-01-15T10:30:00.000Z"
}
```

---

## 10. 환경 변수 관리

### 10.1 환경 변수 구조

```env
# 서버
APP_PORT=8081
NODE_ENV=development

# 데이터베이스
MONGODB_URI=mongodb://localhost:27017/myapp

# JWT
JWT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\n..."

# 클라이언트
CLIENT_BASE_URL=http://localhost:3000

# OAuth
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_CALLBACK_URL=http://localhost:8081/api/oauth/google-callback

# 서버 간 통신
INTERNAL_API_KEY=...
```

### 10.2 환경 변수 검증

```typescript
// packages/consts/src/env.ts
export const validateEnvConfigs = (scope: "trainer" | "member") => {
  const required = ["MONGODB_URI", "JWT_PRIVATE_KEY", "JWT_PUBLIC_KEY", "APP_PORT"];
  if (scope === "trainer") {
    required.push("GOOGLE_CLIENT_ID", "GOOGLE_CLIENT_SECRET");
  }

  for (const key of required) {
    if (!process.env[key]) {
      throw new Error(`Missing required env: ${key}`);
    }
  }
};
```

---

## 11. 테스트

### 11.1 테스트 스택

| 도구 | 용도 |
|------|------|
| Vitest | 테스트 러너 |
| Supertest | HTTP 요청 테스트 |
| mongodb-memory-server | 인메모리 MongoDB |

### 11.2 테스트 구조

```typescript
// __tests__/setup.ts
beforeAll(async () => {
  // 인메모리 MongoDB 시작
  // DB 연결
});

afterAll(async () => {
  // DB 연결 종료
  // 인메모리 MongoDB 종료
});

beforeEach(async () => {
  // 컬렉션 초기화
});
```

### 11.3 Mock 데이터 생성 규칙

> DB 스키마(Mongoose 모델)를 기준으로 mock 데이터를 생성하여 테스트를 진행한다.
> 스키마와 mock이 항상 동기화되도록 헬퍼 함수를 통해 관리한다.

```typescript
// __tests__/helpers.ts
import { Types } from "mongoose";
import type { IUser, ITask } from "@repo/types";

// 스키마 필수 필드를 모두 포함하는 기본 mock 팩토리
export const createMockUser = (overrides?: Partial<IUser>): IUser => ({
  _id: new Types.ObjectId(),
  email: "test@example.com",
  provider: "google",
  name: "테스트유저",
  role: "trainer",
  active: true,
  createdAt: new Date(),
  updatedAt: new Date(),
  ...overrides,
});

export const createMockTask = (overrides?: Partial<ITask>): ITask => ({
  _id: new Types.ObjectId(),
  trainerId: new Types.ObjectId(),
  memberId: new Types.ObjectId(),
  scheduledAt: new Date(),
  duration: 60,
  category: "weight",
  content: "스쿼트 3세트",
  status: "scheduled",
  createdAt: new Date(),
  updatedAt: new Date(),
  ...overrides,
});

// DB에 시딩하는 헬퍼
export const seedUsers = async (users: Partial<IUser>[]) => {
  return User.insertMany(users.map(createMockUser));
};

export const seedTasks = async (tasks: Partial<ITask>[]) => {
  return Task.insertMany(tasks.map(createMockTask));
};

// 인증 토큰 생성 헬퍼
export const createTestToken = async (userId: string) => {
  return getSignedToken({ sub: userId, role: "trainer" }, "1h");
};
```

**Mock 데이터 규칙:**
- mock 팩토리 함수는 스키마의 **모든 필수 필드**를 기본값으로 포함
- `overrides` 파라미터로 테스트 케이스별 값만 덮어쓰기
- 스키마 변경 시 mock 팩토리도 반드시 업데이트
- 관계 필드(`trainerId`, `memberId`)는 `new Types.ObjectId()`로 생성
- 날짜 필드는 `new Date()`로 현재 시점 기본값

### 11.4 테스트 패턴

```typescript
// __tests__/members.test.ts
describe("GET /api/members", () => {
  let trainerId: string;
  let token: string;

  beforeEach(async () => {
    // DB 스키마 기반 mock 데이터 시딩
    const trainer = await User.create(createMockUser({ role: "trainer" }));
    trainerId = trainer._id.toString();
    token = await createTestToken(trainerId);

    await seedUsers([
      { name: "회원A", role: "member", trainerId: trainer._id },
      { name: "회원B", role: "member", trainerId: trainer._id },
    ]);
  });

  it("인증 없이 요청 시 401 반환", async () => {
    const res = await request(app).get("/api/members");
    expect(res.status).toBe(401);
  });

  it("트레이너의 회원 목록 조회", async () => {
    const res = await request(app)
      .get("/api/members")
      .set("Cookie", `__fitvely_token=${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveLength(2);
  });
});
```

---

## 12. 빌드 & 배포

### 12.1 빌드 파이프라인

```
TypeScript → tsup (ESM, ES2022) → @vercel/ncc (단일 번들)
```

### 12.2 스크립트

```json
{
  "scripts": {
    "dev": "tsx watch src/app.ts",
    "build": "tsup && ncc build build/app.js -o dist-ncc",
    "prod": "node dist-ncc/index.js",
    "test": "vitest run",
    "test:watch": "vitest",
    "seed": "tsx src/scripts/seed.ts"
  }
}
```

### 12.3 tsup 설정

```typescript
// tsup.config.ts
import { defineConfig } from "tsup";

export default defineConfig({
  entry: ["src/app.ts"],
  format: ["esm"],
  target: "es2022",
  outDir: "build",
  clean: true,
  sourcemap: true,
});
```

---

## 13. TypeScript 설정

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "build",
    "rootDir": "src",
    "paths": {
      "@repo/*": ["../../packages/*/src"]
    }
  },
  "include": ["src/**/*"]
}
```

---

## 14. 주요 의존성 스택

| 카테고리 | 라이브러리 |
|----------|-----------|
| 프레임워크 | Express v5 |
| ORM | Mongoose v9 |
| 유효성 검증 | Zod |
| JWT | jose |
| 보안 | helmet, express-rate-limit |
| 압축 | compression |
| 쿠키 | cookie-parser |
| 빌드 | tsup, @vercel/ncc |
| 런타임 (개발) | tsx |
| 테스트 | Vitest, Supertest, mongodb-memory-server |

---

## 15. API 설계 규칙

### 15.1 URL 구조

```
GET    /api/[resource]                    # 목록 조회
GET    /api/[resource]/search             # 검색
GET    /api/[resource]/:id                # 단건 조회
POST   /api/[resource]                    # 생성
PATCH  /api/[resource]/:id                # 부분 수정
DELETE /api/[resource]/:id                # 삭제
PATCH  /api/[resource]/:id/[sub-action]   # 상태 변경 등 하위 액션
GET    /api/[resource]/:id/[sub-resource] # 하위 리소스 조회
```

### 15.2 HTTP 메서드 규칙

| 메서드 | 용도 | 응답 코드 |
|--------|------|-----------|
| GET | 조회 | 200 |
| POST | 생성 | 201 |
| PATCH | 부분 수정 | 200 |
| DELETE | 삭제 | 200 (또는 204) |

### 15.3 쿼리 파라미터 규칙

```
GET /api/tasks?startDate=2026-01-01&endDate=2026-01-31&memberId=abc123
GET /api/members?active=true&name=김
```
