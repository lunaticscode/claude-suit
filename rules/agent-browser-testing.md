# Agent-Browser 공통 검증 기준

> Claude Code agent-browser를 활용한 브라우저 레벨 검증 항목
> 앱 종류/도메인/프레임워크와 무관하게 적용 가능한 공통 기준만 정의

---

## 0. 기준의 출처 (Best Practice References)

본 문서의 검증 기준은 아래의 공개 베스트 프랙티스를 교집합 방식으로 통합한 것이다.
즉, 복수 표준이 공통으로 권장하는 항목만 "공통 기준"으로 채택한다.

| 출처 | 주요 커버 영역 | 채택 이유 |
|------|----------------|-----------|
| **Google Lighthouse** (Performance / Accessibility / Best Practices / SEO) | 페이지 품질 종합 점수 | 앱 종류 불문, 업계 사실상 표준 |
| **Core Web Vitals** (web.dev) | LCP / CLS / INP / TTFB | 사용자 체감 성능 지표, 프레임워크 중립 |
| **WCAG 2.2 (Level AA)** | 접근성 | 법적/윤리적 최소선, 플랫폼 중립 |
| **Playwright / Cypress Testing Guides** | E2E 인터랙션 패턴 | 툴 무관하게 재사용 가능한 검증 흐름 |
| **OWASP Secure Headers Project** | 기본 보안 헤더 | 앱 로직과 무관한 선언적 검증 |
| **HTML Living Standard** | DOM/메타 정합성 | 모든 웹 앱이 따르는 기반 규격 |

> 앱/환경 종속성이 있는 항목(예: 결제 플로우, 로그인 세션, 특정 SaaS 연동)은
> 본 문서에서 다루지 않는다. 각 앱의 별도 테스트 스위트에서 정의할 것.

---

## 1. 공통 검증 카테고리

6개 카테고리, 모두 앱 비종속.

### 1.1 Availability (가용성)

| 항목 | 판단 기준 | Severity |
|------|-----------|----------|
| HTTP 상태 | 2xx 응답 (리다이렉트 체인은 최종 상태 기준) | critical |
| DOM 렌더 | `<body>`가 비어있지 않음, 최소 1개 이상의 텍스트 노드 | critical |
| 에러 페이지 아님 | 4xx/5xx 페이지, "Something went wrong" 류 폴백 UI 아님 | critical |
| 페이지 타이틀 존재 | `<title>`이 비어있지 않고, 의미 있는 문자열 | major |

### 1.2 Console & Network Health

| 항목 | 판단 기준 | Severity |
|------|-----------|----------|
| JS Runtime Error | `console.error` / `pageerror` 0건 | critical |
| Unhandled Rejection | `unhandledrejection` 이벤트 0건 | critical |
| 네트워크 실패 | 페이지 로드 중 4xx/5xx 리소스 요청 0건 | major |
| CORS / Mixed Content | CORS 에러, mixed content 경고 0건 | major |
| 콘솔 경고 | `console.warn` 수집 (차단 기준 아님, 리포트에만 기록) | info |

### 1.3 Accessibility (WCAG 2.2 AA 기반, 자동 검사 가능 항목만)

| 항목 | 판단 기준 | Severity |
|------|-----------|----------|
| `<html lang>` | lang 속성 존재 및 유효 언어 코드 | major |
| 이미지 대체 텍스트 | 모든 `<img>`에 `alt` 속성 존재 (장식 이미지는 `alt=""` 허용) | major |
| 제목 계층 | `<h1>` 정확히 1개, heading skip 없음 | minor |
| 폼 레이블 | 모든 input에 연결된 label 또는 aria-label | major |
| 키보드 포커스 | Tab 순회로 모든 인터랙티브 요소 접근 가능, 포커스 링 visible | major |
| 색 대비 | 본문 텍스트 4.5:1, 큰 텍스트 3:1 이상 | major |
| ARIA 위반 없음 | 잘못된 role, 필수 속성 누락 0건 | major |

> 자동화 도구(axe-core 등) 또는 agent-browser의 DOM 스냅샷으로 검사 가능한 항목만 포함.
> 수동 판단이 필요한 WCAG 항목(의미 검토 등)은 제외.

### 1.4 Performance (Core Web Vitals)

| 항목 | 기준 (Good) | 기준 (Poor) | Severity |
|------|-------------|-------------|----------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | > 4.0s | major |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | > 0.25 | major |
| **INP** (Interaction to Next Paint) | ≤ 200ms | > 500ms | major |
| **TTFB** (Time to First Byte) | ≤ 800ms | > 1.8s | minor |
| 총 JS 번들 크기 | 페이지별 추적 (차단 기준 아님, 추이 모니터링) | — | info |

### 1.5 SEO / Meta 정합성

| 항목 | 판단 기준 | Severity |
|------|-----------|----------|
| `<meta name="viewport">` | 존재 및 `width=device-width` 포함 | major |
| `<meta name="description">` | 존재, 50~160자 권장 | minor |
| Canonical URL | `<link rel="canonical">` 존재 (SPA는 선택) | minor |
| Open Graph 기본 태그 | `og:title`, `og:description` 존재 | info |

### 1.6 Responsive & Interaction 기본

| 항목 | 판단 기준 | Severity |
|------|-----------|----------|
| 뷰포트 렌더링 | 모바일(375), 태블릿(768), 데스크탑(1280)에서 렌더 확인 | major |
| 가로 스크롤 없음 | 각 뷰포트에서 `document.scrollingElement.scrollWidth ≤ clientWidth` | major |
| 주요 네비게이션 | 메인 링크 클릭 → URL 변경 + 신규 페이지 렌더 | critical |
| 폼 입력 | input/textarea에 문자 입력 반영 | major |
| 버튼 반응 | 주요 CTA 클릭 시 DOM 변화(모달/라우팅/상태 변경) 감지 | major |
| 로딩 → 완료 상태 전이 | 스피너/스켈레톤 → 실제 콘텐츠 전환 관찰 | minor |
| 빈 상태 UI | 데이터 0건일 때 empty state 렌더 (해당 시) | info |

---

## 2. Severity 정의

| Severity | 의미 | 대응 |
|----------|------|------|
| **critical** | 사용자가 앱을 전혀 사용할 수 없음 | 배포 차단 |
| **major** | 주요 기능/품질 저하, 일부 사용자 차단 | 수정 필요, 리뷰에서 블로킹 권장 |
| **minor** | 품질 개선 사항 | 백로그 등록 |
| **info** | 참고용 지표, 추이 관찰 | 리포트에만 기록 |

---

## 3. Report 산출물

### 3.1 설계 원칙

1. **Machine-readable + Human-readable 동시 산출**
   JSON으로 구조화하여 CI/후속 스크립트가 파싱 가능하게, Markdown으로 사람이 즉시 읽을 수 있게.
2. **증거(Evidence) 포함**
   각 실패 항목은 스크린샷, 콘솔 로그 스니펫, DOM 셀렉터 등 재현 가능한 근거를 포함.
3. **비교 가능성**
   타임스탬프 + 커밋 해시 기록으로 이전 리포트와 비교 가능.
4. **범주별 요약**
   카테고리별 pass/fail 카운트와 총점을 최상단에 배치해 한눈에 판단 가능.

### 3.2 산출물 디렉토리 구조

```
reports/agent-browser/<timestamp>-<commit>/
├── report.json           # 머신 리더블 전체 결과
├── report.md             # 사람용 요약 + 상세
├── summary.json          # CI 게이트용 경량 요약 (pass/fail 카운트만)
├── screenshots/
│   ├── <testId>-before.png
│   ├── <testId>-after.png
│   └── <viewport>-<route>.png
├── traces/               # (선택) Playwright trace, HAR 등
│   └── <testId>.zip
└── console-logs/
    └── <route>.log
```

### 3.3 `report.json` 스키마

```json
{
  "schemaVersion": "1.0",
  "meta": {
    "timestamp": "2026-04-08T10:15:00Z",
    "commit": "abc1234",
    "branch": "main",
    "baseUrl": "http://localhost:3000",
    "viewports": ["375x667", "768x1024", "1280x800"],
    "agent": "claude-code agent-browser",
    "durationMs": 48231
  },
  "summary": {
    "total": 42,
    "pass": 38,
    "fail": 3,
    "warn": 1,
    "bySeverity": {
      "critical": { "pass": 6, "fail": 0 },
      "major":    { "pass": 22, "fail": 2 },
      "minor":    { "pass": 8, "fail": 1 },
      "info":     { "pass": 2, "fail": 0 }
    },
    "byCategory": {
      "availability":   { "pass": 4, "fail": 0 },
      "consoleNetwork": { "pass": 5, "fail": 0 },
      "accessibility":  { "pass": 10, "fail": 2 },
      "performance":    { "pass": 3, "fail": 1 },
      "seo":            { "pass": 4, "fail": 0 },
      "interaction":    { "pass": 12, "fail": 0 }
    },
    "gate": "fail"
  },
  "results": [
    {
      "id": "a11y-img-alt-001",
      "category": "accessibility",
      "check": "이미지 대체 텍스트",
      "severity": "major",
      "status": "fail",
      "route": "/products",
      "viewport": "1280x800",
      "expected": "모든 <img>에 alt 속성",
      "actual": "3개 요소에서 alt 누락",
      "evidence": {
        "selectors": [
          "main > section:nth-child(2) > img",
          "ul.product-list > li:nth-child(5) img"
        ],
        "screenshot": "screenshots/a11y-img-alt-001.png",
        "logExcerpt": null
      },
      "metric": null,
      "threshold": null
    },
    {
      "id": "perf-lcp-001",
      "category": "performance",
      "check": "LCP",
      "severity": "major",
      "status": "fail",
      "route": "/",
      "viewport": "1280x800",
      "expected": "≤ 2500ms",
      "actual": "3820ms",
      "metric": { "name": "LCP", "value": 3820, "unit": "ms" },
      "threshold": { "good": 2500, "poor": 4000 },
      "evidence": {
        "screenshot": "screenshots/perf-lcp-001.png",
        "trace": "traces/perf-lcp-001.zip"
      }
    }
  ]
}
```

### 3.4 `report.md` 템플릿

```markdown
# Agent-Browser Report — <timestamp>

**Commit:** `abc1234` · **Branch:** `main` · **Base URL:** `http://localhost:3000`
**Gate:** ❌ FAIL (critical 0, major 2, minor 1)

## Summary

| Category        | Pass | Fail | Warn |
|-----------------|-----:|-----:|-----:|
| Availability    |    4 |    0 |    0 |
| Console/Network |    5 |    0 |    0 |
| Accessibility   |   10 |    2 |    0 |
| Performance     |    3 |    1 |    0 |
| SEO             |    4 |    0 |    0 |
| Interaction     |   12 |    0 |    1 |
| **Total**       | **38** | **3** | **1** |

## ❌ Failures

### [major] Accessibility — 이미지 대체 텍스트 (`/products`)
- Expected: 모든 `<img>`에 alt 속성
- Actual: 3개 요소에서 alt 누락
- Selectors:
  - `main > section:nth-child(2) > img`
  - `ul.product-list > li:nth-child(5) img`
- Screenshot: `screenshots/a11y-img-alt-001.png`

### [major] Performance — LCP (`/`)
- Expected: ≤ 2500ms   Actual: **3820ms**   Poor threshold: 4000ms
- Trace: `traces/perf-lcp-001.zip`

## ⚠ Warnings

### [info] Interaction — Empty state (`/search?q=zzz`)
- empty state UI 미검출 (앱에 해당 기능이 없을 수 있음)

## ✅ Passed (38) — [펼치기]
...
```

### 3.5 `summary.json` (CI 게이트용)

```json
{
  "gate": "fail",
  "critical": 0,
  "major": 2,
  "minor": 1,
  "info": 0,
  "reportPath": "reports/agent-browser/2026-04-08T10-15-00Z-abc1234/report.md"
}
```

### 3.6 Gate 규칙 (권장)

- `critical > 0` → **차단 (fail)**
- `major > 0` → **차단 (fail)** — 프로젝트에 따라 경고로 완화 가능
- `minor > 0` → **경고 (warn)**
- `info` → 차단/경고 없음

프로젝트 별로 `gate.config.json` 등을 두고 임계값을 override 할 수 있도록 한다.

---

## 4. 체크리스트 (에이전트 실행 시)

- [ ] 테스트 대상 URL 목록 확인
- [ ] 3개 뷰포트(375/768/1280)로 순회
- [ ] 카테고리 6개 전체 수행
- [ ] 실패 항목마다 스크린샷 + 셀렉터 수집
- [ ] Core Web Vitals는 실제 측정값 수집 (추정 금지)
- [ ] `report.json` / `report.md` / `summary.json` 생성
- [ ] `summary.json` 기준으로 gate 판정 반환
