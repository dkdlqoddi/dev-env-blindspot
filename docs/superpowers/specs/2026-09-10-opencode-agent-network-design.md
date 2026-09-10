# OpenCode 오픈소스 LLM 기반 에이전트 협업 네트워크(Collaborative Squad) 및 Blindspot Flow 설계

- 날짜: 2026-09-10
- 상태: 구현 및 검증 완료
- 브랜치: `opencode`
- 선행 스펙: `2026-09-10-agent-network-workflow-design.md`, `2026-09-10-antigravity-pure-design.md`, `2026-09-07-three-tier-docs-design.md`

## 1. 목적과 배경

`antigravity-pure` 브랜치에서는 Google Antigravity 런타임 환경에 특화된 도구 세트(`invoke_subagent`, `send_message`, `schedule` 등)를 기반으로 3자 협업 스쿼드(Triad Squad: `swarm-worker` ↔ `swarm-verifier` ↔ `swarm-reviewer`)와 3계층 살아있는 문서 체계를 구현하였습니다.

그러나 로컬 및 사내 인프라(Ollama, vLLM, LM Studio, OpenAI 호환 엔드포인트 등)에서 구동되는 오픈소스 LLM(Qwen 2.5 Coder, DeepSeek R1/V3, Llama 3.3 등)을 활용하여 개발을 수행하는 환경에서는 Antigravity 전용 API에 의존할 수 없습니다. 대신 글로벌 표준 CLI 개발 도구인 **OpenCode (`opencode`)**를 기반으로 동일한 수준의 에이전트 협업 네트워크와 Thariq의 Blindspot 수명주기를 완벽히 재현할 필요가 있습니다.

본 설계는 오픈소스 LLM API를 사용하는 OpenCode 환경에서:
1. **에이전트 네트워크 협업(Triad Squad)**: OpenCode의 `task` (서브에이전트 위임) 도구와 명확한 위상 프로토콜(`[PHASE: ...]`)을 통해 워커·검증자·리뷰어 간 실시간 피드백 루프 구축
2. **오픈소스 LLM 최적화**: 제한된 컨텍스트 및 도구 호출 정밀도를 고려한 역할별 모델 티어링(Coder / Fast / Reasoning) 및 명시적 권한(Permissions) 가드
3. **단일 진실 공급원(SSOT) 3계층 문서 보존 및 중간 문서 100% 삭제**: 워크플로우 진행 중 생성된 `docs/swarm/`, `docs/notes/`를 완료 시 완전히 삭제하고 영구 3계층 문서(`rules.md`, `map.md`, `specs/`)만 보존
을 제공합니다.

---

## 2. 핵심 결정사항

| # | 결정 | 선택 | 근거 | 기각한 대안 |
|---|---|---|---|---|
| 1 | OpenCode 에이전트 인터페이스 표준화 | `.opencode/agents/*.md` 규격 및 YAML frontmatter (`mode: subagent`, `permission: ...`) 채택 | OpenCode 네이티브 서브에이전트 검색 및 도구 권한 세분화 지원 | 범용 단일 프롬프트 에이전트 |
| 2 | 협업 통신 메커니즘 | OpenCode `task` 도구 위임 및 단계별 프로토콜 마커 (`[PHASE: VERIFY_REQUEST / RESULT]`) 교환 | `send_message`가 없는 OpenCode에서 서브에이전트 호출 결과를 부모/워커 컨텍스트로 전달 가능 | 파일 폴링 기반 통신 |
| 3 | 서브에이전트 중첩 깊이 (`subagent_depth`) | `subagent_depth: 3` 설정 및 오케스트레이터 릴레이 이중 지원 | 워커가 직접 verifier/reviewer를 호출하거나, 디스패처가 스쿼드 루프를 중재하여 오픈소스 모델 한계 극복 | 깊이 1 강제 (협업 불가) |
| 4 | 오픈소스 LLM 프로바이더 구성 | Ollama (`http://127.0.0.1:11434/v1`) 및 vLLM / OpenAI 호환 (`http://127.0.0.1:8000/v1`) 듀얼 템플릿 제공 (`opencode.jsonc`) | 사용자가 로컬 오픈소스 인프라에 즉시 연결 가능하도록 표준 엔드포인트 내장 | 단일 클라우드 상용 API 하드코딩 |
| 5 | 역할별 모델 티어링 | Worker/Primary: Coder 모델 (32B), Verifier/Checker: 고속 모델 (7B), Reviewer/Auditor: 추론/심층 모델 (DeepSeek-R1 / 32B) | 오픈소스 LLM 특성에 맞추어 비용/속도 최적화 및 정밀 코드 리뷰 달성 | 모든 작업에 동일 소형 모델 사용 |
| 6 | 중간 산출물 엄격한 정리 | `work-report` 5단계 완료 시 `docs/swarm/` 및 `docs/notes/` 완전 삭제 강제 | 3계층 문서 외 쓰레기 파일 누적 방지 | 스웜 작업 내역 영구 보존 |

---

## 3. 에이전트 협업 네트워크 아키텍처 (OpenCode 런타임)

### 3.1 10종 서브에이전트 및 권한 매핑

OpenCode에서는 `permission` 블록을 통해 에이전트별 도구 접근을 선언적으로 통제합니다:

| 에이전트 | 모드 | 주 역할 | 허용 도구 (Permissions) | 거부 도구 (Deny) | 모델 티어 (권장) |
|---|---|---|---|---|---|
| `codebase-scanner` | subagent | 코드베이스 렌즈 탐색 | `read`, `glob`, `grep`, `list`, `bash` | `edit`, `task` | Fast / Coder (7B-32B) |
| `domain-researcher`| subagent | 외부 기술 문서 및 웹 조사 | `read`, `websearch`, `webfetch`, `bash` | `edit`, `task` | General / Coder |
| `doc-verifier` | subagent | 3계층 문서 가독성·규격 점검 | `read`, `glob`, `grep`, `list`, `bash` | `edit`, `task` | Fast (7B) |
| `change-analyzer` | subagent | Git diff 및 변경 단위 분석 | `read`, `glob`, `grep`, `list`, `bash` | `edit`, `task` | Fast / Coder (7B-32B) |
| `check-runner` | subagent | 프로젝트 표준 테스트·린트 실행 | `read`, `bash` | `edit`, `task` | Fast (7B) |
| `swarm-worker` | subagent | 소유 파일 내 코드 구현 & 협업 조율 | `read`, `edit`, `glob`, `grep`, `list`, `bash`, `task` | 없음 (단, git commit 금지) | Coder (32B) |
| `swarm-verifier` | subagent | 작업 단위 테스트 실행 및 에러 진단 | `read`, `glob`, `grep`, `list`, `bash` | `edit` (앱 코드 수정 불가), `task` | Fast / Coder (7B-32B) |
| `swarm-reviewer` | subagent | rules.md 불변규칙 및 diff 정밀 리뷰 | `read`, `glob`, `grep`, `list`, `bash` | `edit` (읽기 전용), `task` | Reasoning (DeepSeek-R1 / 32B) |
| `swarm-checker` | subagent | 웨이브 전체 통합 검증 및 커밋 판정 | `read`, `bash` | `edit`, `task` | Fast (7B) |
| `swarm-auditor` | subagent | 스웜 전체 diff 및 결과 파일 무결성 감사 | `read`, `glob`, `grep`, `list`, `bash` | `edit`, `task` | Reasoning / Coder (32B) |

### 3.2 협업 라이프사이클 (Triad Squad Collaboration Flow)

OpenCode 환경에서 서브에이전트 간의 상호작용은 다음 흐름으로 안전하게 진행됩니다:

```
[OpenCode Session / swarm-run]
       │
       ├── 1. 작업 브리프(docs/swarm/tasks/<id>.md) 배정 및 스쿼드 기동
       │
       ▼
┌─────────────────────── 작업 스쿼드 (Task Squad) ───────────────────────┐
│                                                                        │
│   [swarm-worker]                                                       │
│        │ (1. 소유 파일에 한정하여 구현 완료)                           │
│        ▼                                                               │
│   task(agent: "swarm-verifier", prompt: "[PHASE: VERIFY_REQUEST] ...") │
│        │                                                               │
│        ▼                                                               │
│   [swarm-verifier] ──(테스트 & 린트 명령 실행)                         │
│        │                                                               │
│        ├── [실패] ── 반환: [PHASE: VERIFY_RESULT] FAIL + 에러 요약 ──┐ │
│        │                                                             │ │
│        │             [swarm-worker] ──(소유 파일 재수정) ────────────┘ │
│        │                                                               │
│        └── [통과] ── 반환: [PHASE: VERIFY_RESULT] PASS ────────────────┼┐
│                                                                        ││
│   [swarm-worker]                                                       ││
│        │ (2. 검증 통과 후 리뷰어 호출)                                 ││
│        ▼                                                               ││
│   task(agent: "swarm-reviewer", prompt: "[PHASE: REVIEW_REQUEST] ...") ││
│        │                                                               ││
│        ▼                                                               ││
│   [swarm-reviewer] ──(git diff & rules.md 대조 검토)                   ││
│        │                                                               ││
│        ├── [지적] ── 반환: [PHASE: REVIEW_FEEDBACK] + 수정 지점 ─────┐ ││
│        │                                                             │ ││
│        │             [swarm-worker] ──(코드 개선 및 재검증) ─────────┘ ││
│        │                                                               ││
│        └── [승인] ── 반환: [PHASE: REVIEW_RESULT] APPROVAL (LGTM) ─────┼┤
│                                                                        ││
│   [swarm-worker]                                                       ││
│        │ (3. 작업 결과 파일 기록)                                      ││
│        ▼                                                               ││
│   docs/swarm/results/<id>.md 작성 (상태, 검증, 결정, 막힌 것 기록)     ││
└────────────────────────────────────────────────────────────────────────┘│
       │                                                                  │
       ├── 2. 웨이브 내 스쿼드 작업 완료 수렴 (최대 3회 턴 버짓)          │
       │                                                                  │
       ▼                                                                  │
[swarm-checker] ──(웨이브 전체 검증 실행 & 통과 시 웨이브 단위 커밋)      ▼
```

오픈소스 모델의 깊은 서브에이전트 호출이 불완전한 런타임의 경우, `swarm-run` 디스패처가 워커 ↔ 검증자 ↔ 리뷰어를 번갈아 `task`로 호출하는 **스쿼드 코디네이터(Coordinator) 릴레이** 모드로 완벽히 폴백(Fallback)할 수 있도록 이중 보장합니다.

---

## 4. 오픈소스 LLM API 설정 및 실행 환경 (`opencode.jsonc`)

### 4.1 기본 프로바이더 및 모델 매핑

OpenCode는 `@ai-sdk/openai-compatible`을 통해 표준 OpenAI 호환 API를 지원합니다:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "subagent_depth": 3,
  "default_agent": "build",
  "provider": {
    "ollama": {
      "name": "Ollama (Local)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:11434/v1"
      }
    },
    "vllm": {
      "name": "vLLM (Local / OpenAI-Compatible)",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://127.0.0.1:8000/v1"
      }
    }
  },
  "model": "ollama/qwen2.5-coder:32b",
  "small_model": "ollama/qwen2.5-coder:7b",
  "skills": {
    "paths": [
      ".opencode/skills",
      ".agents/skills",
      "skills"
    ]
  }
}
```

### 4.2 슬래시 커맨드 바인딩 (`.opencode/commands/`)

OpenCode의 빠른 실행을 위해 다음 슬래시 명령을 `.opencode/commands/`에 등록합니다:
- `/blindspot-flow`: 전체 라이프사이클 5단계 순차 오케스트레이션
- `/requirements-interview`: 사전 인터뷰 및 요구사항/결정 도출
- `/blindspot-pass`: 코드베이스 렌즈 탐색 및 도메인 조사
- `/explainer`: 3계층 단위 스펙 제자리 갱신
- `/swarm-plan`: 웨이브 기반 스웜 작업 브리프 패키징
- `/swarm-run`: 협업 스쿼드 병렬 실행 및 웨이브 검증
- `/swarm-review`: 스웜 변경 감사 및 델타 수렴 판정
- `/work-report`: 노트 기록 또는 최종 퀴즈 게이트 및 중간 파일 삭제

---

## 5. 산출물 수명주기 및 3계층 문서 계약

1. **영구 보존 (Living 3-tier Docs)**:
   - Tier 1 (`docs/<area>/rules.md`): 영역당 1개, 상한 60줄
   - Tier 2 (`docs/<area>/map.md`): 영역당 1개, 상한 150줄
   - Tier 3 (`docs/<area>/specs/<unit>.md`): 단위당 1개, 상한 200줄
2. **단일 게이트 (Single Pre-merge Quiz)**:
   - `docs/quiz.html`: 매 사이클 덮어쓰며, 퀴즈 통과 시에만 커밋/머지 허용
3. **중간 문서 100% 삭제 (Intermediate Cleanup Contract)**:
   - `docs/swarm/` (plan, tasks, status, results) 및 `docs/notes/`는 워크플로우 진행 중에만 사용되며, `work-report` 최종 승인 시 무조건 완전 삭제 (`rm -rf docs/swarm docs/notes`).

---

## 6. 결론 및 기대 효과

1. **오픈소스 LLM 자립성**: 폐쇄형 상용 API에 종속되지 않고 사내/로컬 Ollama 및 vLLM 인프라에서 최신 코딩 LLM(Qwen 2.5 Coder 등)으로 동일한 협업 네트워크를 가동.
2. **다층 품질 보증**: 단일 워커의 착각(Hallucination)이나 컨벤션 누락을 검증자(verifier)의 즉각적 테스트와 리뷰어(reviewer)의 규칙 대조를 통해 커밋 전 사전 차단.
3. **완전한 저장소 청결성**: 중간 스웜 산출물이 잔존하여 지식이 분산되는 문제를 원천 방지하고 3계층 문서만 최신 상태로 유지.
