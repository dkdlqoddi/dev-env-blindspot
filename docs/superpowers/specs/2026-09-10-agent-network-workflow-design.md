# Google Antigravity 에이전트 협업 네트워크(Collaborative Squad) 워크플로우 및 중간 산출물 수명주기 설계

- 날짜: 2026-09-10
- 상태: 구현·검증 완료, 사용자 검토 대기
- 브랜치: `antigravity-pure`
- 선행 스펙: `2026-09-10-antigravity-pure-design.md`, `2026-09-08-antigravity-swarm-design.md`, `2026-09-07-three-tier-docs-design.md`

## 1. 목적과 배경

Antigravity 단일 환경에서 스웜 작업을 실행할 때, 기존의 고립형 단일 워커(`swarm-worker`) 방식은 개별 작업 완료 후 웨이브 단위 전체 검사(`swarm-checker`) 시점에야 에러를 발견하는 한계가 있었습니다. 특히 미묘한 컨벤션 위반, 테스트 누락, 엣지케이스 처리 미흡 등은 단일 에이전트의 자기 검토만으로는 포착하기 어려웠습니다.

또한, 복잡한 워크플로우 진행 중에 생성되는 계획 패키지(`docs/swarm/plan.md`, `tasks/`), 실행 상태 및 결과 기록(`docs/swarm/status.md`, `results/`), 임시 작업 노트(`docs/notes/`) 등의 중간 문서들이 워크플로우 종료 후에도 저장소에 영구 잔존할 경우, 문서의 최신성 관리가 무너지고 저장소가 오염되는 문제가 발생합니다.

본 설계는 다음 두 가지 핵심 요구사항을 완벽히 해결합니다:
1. **에이전트 협업 네트워크(Collaborative Triad Squad)**: 작업 단위마다 구현(`swarm-worker`), 검증(`swarm-verifier`), 리뷰(`swarm-reviewer`)가 유기적인 상호 소통(`send_message`)을 통해 코드와 작업의 완성도를 극대화.
2. **중간 문서 100% 삭제 및 3계층 영구 보존**: 워크플로우 진행 중에는 중간 문서를 자유롭게 활용하되, 워크플로우가 종료되면 모든 중간 문서를 완전히 삭제하여 최종 산출물을 **3계층(3-layer) 살아있는 문서(`rules.md`, `map.md`, `specs/`)**로만 엄격히 고정.

## 2. 핵심 결정사항

| # | 결정 | 선택 | 근거 | 기각한 대안 |
|---|---|---|---|---|
| 1 | 3자 협업 스쿼드 체제 | 작업(Task)마다 worker(구현) ↔ verifier(검증) ↔ reviewer(리뷰) 스쿼드 구성 | 전문화된 에이전트 간 크로스 체크로 무결성 확보 및 완성도 극대화 | 단일 워커의 고립 구현 |
| 2 | 스쿼드 내 상호 통신 프로토콜 | `send_message` 기반 구조화된 메시지 교환 (`[PHASE: ..._REQUEST / RESULT]`) | Antigravity 에이전트 간 직접 대화로 기계적·반복적 오류 조기 치유 | 오케스트레이터 경유 릴레이 |
| 3 | 턴 버짓(Turn Budget) 제한 | 스쿼드 내 티키타카 상호 피드백 최대 3회로 제한 | 무한 핑퐁 루프 방지 및 수렴 보장, 할당량 및 토큰 최적화 | 무제한 피드백 루프 |
| 4 | 중간 문서 완전 삭제 보장 | 워크플로우 종료(`work-report` 5단계) 시 `docs/swarm/` 및 `docs/notes/` 100% 삭제 | 최종 산출물을 3계층 문서로 고정하고 저장소 오염 방지 | 중간 문서 영구 보존 |
| 5 | 살아있는 3계층 문서 영구화 | `docs/<area>/rules.md`, `map.md`, `specs/<unit>.md`에만 최종 지식 누적 | 단일 진실 공급원(Single Source of Truth) 유지 | 일회성 작업 보고서 축적 |
| 6 | 스쿼드 간 격리 원칙 | 스쿼드 통신은 작업 스쿼드 내부로 한정, 소유 파일 분리 유지 | 병렬 실행 중 충돌 방지 및 안전한 트리 공유 | 타 작업 스쿼드와의 직접 통신 |

## 3. 에이전트 협업 네트워크 아키텍처

### 3.1 10종 서브에이전트 역할 구성
- **탐색 및 조사 (2종)**: `codebase-scanner` (코드 렌즈 탐색), `domain-researcher` (외부 웹 기술 조사)
- **문서 및 변경 검증 (2종)**: `doc-verifier` (3계층 문서 검증), `change-analyzer` (git diff 분석)
- **일반 점검 (1종)**: `check-runner` (프로젝트 표준 테스트/린트 실행)
- **협업 실행 스쿼드 (3종)**:
  - `swarm-worker`: 소유 파일 내 코드 구현 및 피드백 반영, verifier/reviewer와 `send_message` 소통.
  - `swarm-verifier`: 워커의 변경분에 대한 테스트·린트·타입검사 직접 실행 및 실패 진단 전달.
  - `swarm-reviewer`: `rules.md` 컨벤션 및 브리프 완료 조건 대비 diff 검토 및 승인(LGTM)/수정 요청.
- **웨이브 및 릴리스 감사 (2종)**: `swarm-checker` (웨이브 전체 통합 검사 및 커밋), `swarm-auditor` (스웜 실행 결과 감사)

### 3.2 스쿼드 상호작용 흐름 (Triad Collaboration Lifecycle)

```
[swarm-run 오케스트레이터]
      │
      ├── 1. 작업 브리프 전달 및 스쿼드 기동 (worker, verifier, reviewer)
      │
      ▼
┌────────────────── 작업 스쿼드 (Task Squad) ──────────────────┐
│                                                               │
│   [swarm-worker]                                              │
│        │ (1. 소유 파일 구현 완료)                                 │
│        ▼                                                      │
│   send_message([PHASE: VERIFY_REQUEST])                       │
│        │                                                      │
│        ▼                                                      │
│   [swarm-verifier] ──(테스트/린트 실행)                         │
│        │                                                      │
│        ├── [실패 시] ── send_message([PHASE: VERIFY_RESULT]) ──┐│
│        │                 (에러 로그 및 재수정 요청)           ││
│        │                                                      ▼│
│        │                 [swarm-worker] ──(코드 재수정) ──────┘│
│        │                                                      │
│        └── [통과 시: PASS] ────────────────────────────────────┼┤
│                                                               ││
│   [swarm-worker]                                              ││
│        │ (2. 검증 통과 후 리뷰 요청)                            ││
│        ▼                                                      ││
│   send_message([PHASE: REVIEW_REQUEST])                       ││
│        │                                                      ││
│        ▼                                                      ││
│   [swarm-reviewer] ──(rules.md 및 diff 검토)                  ││
│        │                                                      ││
│        ├── [지적 시] ── send_message([PHASE: REVIEW_RESULT]) ──┐│
│        │                 (컨벤션/품질 수정 요청)              ││
│        │                                                      ▼│
│        │                 [swarm-worker] ──(코드 재수정) ──────┘│
│        │                                                      │
│        └── [승인 시: APPROVED] ────────────────────────────────┼┤
│                                                               ││
│   [swarm-worker]                                              ││
│        │ (3. 작업 결과 파일 작성)                             ││
│        ▼                                                      ││
│   docs/swarm/results/<id>.md 기록                             ││
│   (협업 기록: 검증 n회, 리뷰 승인 완료)                      ││
└───────────────────────────────────────────────────────────────┘
      │
      ├── 2. 웨이브 내 모든 스쿼드 완료 수렴 (최대 3회 턴 버짓)
      │
      ▼
[swarm-checker] ──(웨이브 전체 검증 명령 실행 & 성공 시 자동 커밋)
```

## 4. 산출물 수명주기: 중간 문서 100% 삭제 및 3계층 영구화

### 4.1 수명주기 단계별 파일 상태

| 단계 | 생성/수정되는 파일 | 성격 | 수명 주기 |
|---|---|---|---|
| 1. 인터뷰 & 사각지대 | `docs/<area>/rules.md`, `map.md` | 영구 (Tier 1, Tier 2) | 영구 보존 및 갱신 |
| 2. 스펙 작성 | `docs/<area>/specs/<unit>.md` | 영구 (Tier 3) | 영구 보존 및 갱신 |
| 3. 스웜 계획 | `docs/swarm/plan.md`, `docs/swarm/tasks/T*.md` | **중간 작업 문서** | **종료 시 삭제** |
| 4. 스웜 협업 실행 | `docs/swarm/status.md`, `docs/swarm/results/T*.md` | **중간 실행 기록** | **종료 시 삭제** |
| 5. 스웜 결과 감사 | `docs/notes/<slug>.md` | **중간 검토 노트** | **종료 시 삭제** |
| 6. 보고 & 퀴즈 인수 | `docs/quiz.html` | 일회성 게이트 | 매 사이클 덮어씀 |
| **7. 워크플로우 완료** | **`rm -rf docs/swarm docs/notes` 실행** | **완전 정리** | **3계층 문서만 생존** |

### 4.2 영구 산출물 (3계층 문서) 규격 및 역할
- **Tier 1 (`rules.md`)**: 영역당 1개, 상한 60줄. 절대 규칙, 핵심 컨벤션, 핵심 용어 정의.
- **Tier 2 (`map.md`)**: 영역당 1개, 상한 150줄. 영역 전체 구조, 단위 목록, 소유권 맵, 협업 위험 가드.
- **Tier 3 (`specs/<unit>.md`)**: 단위당 1개, 상한 200줄. 목적과 배경, 요구사항, 동작 방식, 결정 기록, 엣지케이스, 의도적 제외, 변경 이력.

### 4.3 삭제 보장 메커니즘
- `skills/work-report/SKILL.md`의 5단계(정리 및 완료)에서 다음 삭제를 강제합니다:
  ```bash
  rm -f "docs/notes/${NOTE_SLUG}.md"
  rm -rf docs/swarm
  ```
- `MANDATE.md` 및 `rules/mandate.md`의 Hard Rule 4에 명문화:
  > "한 번의 워크플로우가 종료되면 작업 중 생성된 중간 문서(`docs/swarm/`, `docs/notes/`)는 완전히 삭제하며, 최종 산출물은 3계층 살아있는 문서로 고정한다."

## 5. 정량적·정성적 검증 체계

1. **하네스 무결성 검증 (`test/check.sh`)**:
   - 10종 서브에이전트의 도구 허용목록 및 규격 검사 (검사 2b).
   - 스킬 ↔ 에이전트 간 상호 참조 완전성 (검사 3).
   - 가독성 표준(25 어절 규칙) 유지 (검사 4).
   - 브리프 형식 및 필수 섹션(`협업 프로토콜` 포함) 유효성 (검사 8).
2. **3계층 문서 품질 검증 (`docs_check.py`)**:
   - 줄 수 상한(60/150/200줄) 준수 여부.
   - 비개발자 섹션 가독성 규칙(문장당 25 어절 이하, plain Korean 우선 등) 자동 검사.
3. **스웜 분해 및 소유권 검증 (`swarm_check.py`)**:
   - 웨이브 내 소유 파일의 엄격한 상호 배타성(Disjointness) 검증.
   - 선행 의존성 위반 및 금지어 검증.
