# Backend Project Structure

> Express + TypeScript 기반 백엔드 API 서버 폴더 구조 및 데이터 흐름

---

## 1. 폴더 구조

```
├── src/
│   ├── app.ts                    # Express 앱 & 미들웨어 스택
│   │
│   ├── routes/                   # 라우트 정의
│   │   ├── index.ts              # 라우터 통합
│   │   └── [feature].ts
│   │
│   ├── controllers/              # 요청 핸들러
│   │   └── [feature].ts
│   │
│   ├── services/                 # 비즈니스 로직
│   │   └── [feature].ts
│   │
│   ├── validators/               # Zod 스키마
│   │   └── [feature].ts
│   │
│   ├── middlewares/               # 미들웨어
│   │   ├── auth.ts
│   │   ├── errorHandler.ts
│   │   └── logger.ts
│   │
│   ├── scripts/                  # 시딩 등 스크립트
│   │
│   └── __tests__/                # 통합 테스트
│       ├── setup.ts
│       ├── helpers.ts
│       └── [feature].test.ts
│
├── keys/                         # RSA 키 (JWT 서명용)
├── tsconfig.json
├── tsup.config.ts
├── vitest.config.ts
└── package.json
```

---

## 2. 데이터 흐름

```
클라이언트 요청
  → Middleware (auth, rate-limit)
    → Route → Controller (검증)
      → Service (비즈니스 로직)
        → Model (DB 쿼리)
          → 응답 반환
```

---

## 3. Import 규칙

```typescript
// 상대 경로 사용
import * as membersService from "../services/members";
import { getMembersQuerySchema } from "../validators/members";
```

---

## 4. 기술 스택

| 레이어 | 기술 |
|--------|------|
| **프레임워크** | Express 5, TypeScript 5 |
| **DB** | MongoDB + Mongoose 9 |
| **인증** | JWT (RS256, jose) + httpOnly Cookie |
| **유효성 검증** | Zod |
| **빌드** | tsup + @vercel/ncc |
| **테스트** | Vitest + Supertest + mongodb-memory-server |
