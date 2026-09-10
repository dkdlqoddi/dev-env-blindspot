# dev-env-blindspot — `opencode` 브랜치

모든 프로젝트가 공통으로 쓰는 OpenCode (`opencode`) Agent/Skill/Command 모음. Thariq의 Unknown Unknowns 탐색과 3계층 문서화 라이프사이클부터 에이전트 협업 네트워크(Collaborative Squad) 스웜 병렬 실행까지, **오픈소스 LLM API(Ollama, vLLM, 로컬 OpenAI 호환 엔드포인트)를 활용하여 OpenCode 환경에서 완벽히 구동**된다.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다. `antigravity-pure` 브랜치의 3자 협업 스쿼드(Triad Squad) 및 중간 산출물 100% 삭제 수명주기를 **OpenCode 네이티브 서브에이전트(`task` 위임) 및 오픈소스 LLM 최적화 아키텍처**로 완벽히 포팅했다.

---

## 0. 이 브랜치의 의도

로컬 머신이나 사내 GPU 클러스터에서 구동되는 오픈소스 LLM(Qwen 2.5 Coder, DeepSeek R1/V3, Llama 3.3 등)을 활용할 때, 독점적 상용 API나 특정 단일 IDE에 종속되지 않고 글로벌 오픈소스 CLI인 **OpenCode (`opencode`)**에서 강력한 에이전트 협업 네트워크를 운용할 수 있도록 지원합니다.

| 성격 | 실행 주체 | 권장 모델 (오픈소스 LLM) | 담당 단계 |
|---|---|---|---|
| **판단 & 오케스트레이션** | OpenCode 메인 세션 / primary | 고성능 Coder / 추론 모델 (Qwen 2.5 Coder 32B, Llama 3.3 70B 등) | 인터뷰, 사각지대 점검, 스펙 작성, 스웜 **계획**, 결과 **감사**, 보고·퀴즈 |
| **협업 구현 (Builder)** | `swarm-worker` subagent | 코딩 특화 모델 (Qwen 2.5 Coder 32B 등) | 브리프 기반 소유 파일 구현, 검증자·리뷰어와 `task` 도구로 협업 |
| **검증 & 테스트 (Verifier)** | `swarm-verifier`, `swarm-checker` | 고속 모델 (Qwen 2.5 Coder 7B 등) | 테스트·린트 실행 및 에러 분석 전달, 웨이브 통합 검증 |
| **심층 리뷰 (Reviewer)** | `swarm-reviewer`, `swarm-auditor` | 추론/규칙 대조 모델 (DeepSeek-R1 32B, Qwen 2.5 Coder 32B 등) | rules.md 불변규칙 및 diff 정밀 리뷰, 스웜 결과 감사 |

```
OpenCode 메인 세션 (강한 모델)                      OpenCode 서브에이전트 스쿼드 (task 도구 협업)
─────────────────────────────────────             ─────────────────────────────────────────
① requirements-interview ─┐
② blindspot-pass          ├─ 3계층 문서에 기록 (Tier 1 rules.md / Tier 2 map.md / Tier 3 specs/*.md)
③ explainer               ─┘
④ swarm-plan  ──── docs/swarm/plan.md ──────────▶ /swarm-run
                   docs/swarm/tasks/T01.md          ├─ 웨이브 1: [worker T01 ↔ verifier ↔ reviewer] ‖ [worker T02 ↔ verifier ↔ reviewer]
                   docs/swarm/tasks/T02.md          │            └ checker: 전체 검증 → git commit
                   …                                ├─ 웨이브 2: [worker T03 ↔ verifier ↔ reviewer]
                                                    │            └ checker → git commit
   swarm-review ◀── docs/swarm/status.md ───────────┘
   (swarm-auditor)  docs/swarm/results/*.md
        │ 실패·이탈 → ④ 재계획 회차
        ▼
⑤ work-report 보고 모드 → docs/quiz.html 통과 → 머지 & 중간 문서 완전 삭제

최종 영구 산출물: docs/<area>/rules.md (Tier 1), map.md (Tier 2), specs/*.md (Tier 3), docs/quiz.html
```

설계 원칙 네 가지:

1. **판단은 위로, 지시는 아래로.** 빠른 모델이 결정을 내리는 순간이 없어야 한다. 브리프는 "필요하면 …"이 없는 자기완결 문서고, 스펙 없이는 계획을 쓰지 않는다.
2. **인터페이스는 파일, 최종 산출물은 3계층.** 계획·브리프·상태·결과가 전부 `docs/swarm/` 아래 마크다운이라 투명하게 검토할 수 있다. 한 번의 워크플로우가 끝나면 모든 중간 문서(`docs/swarm/`, `docs/notes/`)는 완전히 삭제되어 3계층 살아있는 문서만 영구 보존된다.
3. **충돌은 구조로 막고 완성도는 협업으로 올린다.** 작업마다 소유 파일이 겹치지 않아 안전하게 트리를 공유하며, 스쿼드 내부에서 worker-verifier-reviewer가 상호 소통(`task` 도구 위임 및 단계별 프로토콜, 최대 3턴)하여 완성도를 극대화한다. `swarm_check.py`가 실행 전에 기계적으로 검사한다.
4. **게이트는 하나.** 사람의 확인과 이해는 타협하지 않는다. 스웜 결과도 감사를 거쳐 기존 머지 전 퀴즈를 통과해야 머지한다.

---

## 1. 설치 및 설정 (처음 한 번)

### 1.1 저장소 연결 및 심링크 설치

소비하려는 프로젝트의 루트에서:

```bash
git submodule add -b opencode https://github.com/dkdlqoddi/dev-env-blindspot.git .agents/shared
bash .agents/shared/install.sh
```

*(참고: `install-opencode.sh`를 실행해도 동일하게 `install.sh`로 연결되어 정상 작동합니다)*

`install.sh`가 하는 일 (멱등):
- `.opencode/skills/` 및 `.agents/skills/`에 8개 스킬 개별 상대 심링크
- `.opencode/agents/` 및 `.agents/agents/`에 10개 서브에이전트 개별 상대 심링크
- `.opencode/commands/`에 8개 슬래시 커맨드 개별 상대 심링크
- `.agents/rules/`에 상시 주입 규칙(`mandate.md`) 개별 상대 심링크
- `opencode.jsonc` 템플릿 배포 (Ollama, vLLM 프로바이더 구성 내장)
- `AGENTS.md` 및 `OPENCODE.md`에 `@.agents/shared/MANDATE.md` import 추가

확인:

```bash
ls .opencode/skills/    # blindspot-flow blindspot-pass explainer requirements-interview swarm-plan swarm-review swarm-run work-report (8개)
ls .opencode/agents/    # 10개 에이전트 (.md)
ls .opencode/commands/  # 8개 슬래시 커맨드 (.md)
```

### 1.2 오픈소스 LLM API 연결 (`opencode.jsonc`)

프로젝트 루트의 `opencode.jsonc`에서 로컬 Ollama 또는 vLLM 서버의 엔드포인트를 지정합니다:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "build",
  "instructions": [
    "AGENTS.md",
    "MANDATE.md"
  ],
  "provider": {
    "ollama": {
      "name": "Ollama (Local Open Source LLM)",
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
  "skills": {
    "paths": [
      "skills",
      ".agents/skills",
      ".opencode/skills"
    ]
  },
  "permission": {
    "read": "allow",
    "glob": "allow",
    "grep": "allow",
    "list": "allow",
    "bash": "allow",
    "edit": "allow",
    "task": "allow",
    "skill": "allow",
    "websearch": "allow",
    "webfetch": "allow"
  }
}
```

---

## 2. 사용법

### 문서 3계층

| 계층 | 경로 | 담는 것 | 상한 |
|---|---|---|---|
| Tier 1 Global Rules | `docs/<영역>/rules.md` | 불변 규칙, 관례, 표준 명령, 용어 | 60줄 이하 |
| Tier 2 System Map | `docs/<영역>/map.md` | 단위 목록과 위치, 주요 흐름, 통합 지점, 위험 | 150줄 이하 |
| Tier 3 Detail Spec | `docs/<영역>/specs/<단위>.md` | 단위 하나의 목적, 요구사항, 동작, 결정 기록, 엣지케이스, 범위 제외, 열린 질문, 변경 이력 | 200줄 이하 |

영역은 `docs/` 아래 `map.md`를 가진 폴더(`frontend`, `backend`, 둘 다 아니면 `core`). 첫 실행 때 `blindspot-pass`가 부트스트랩합니다.

### 슬래시 커맨드 및 자동 트리거

OpenCode 대화창에서 명령어를 입력하거나 자연어로 요청하면 즉시 매핑된 단계가 실행됩니다:

| 슬래시 명령어 | 자연어 입력 예시 | 실행되는 Skill |
|---|---|---|
| `/blindspot-flow` | "전체 라이프사이클로 기능 구현해줘" | `blindspot-flow` |
| `/requirements-interview` | "로그인 기능 추가하고 싶어" | `requirements-interview` |
| `/blindspot-pass` | "내가 모르는 게 뭐지?" / 맵 없음 / "맵 갱신해줘" | `blindspot-pass` |
| `/explainer` | "지금까지 결정한 거 문서로 정리해줘" | `explainer` |
| `/swarm-plan` | "스웜으로 나눠줘" / "병렬로 구현하게 계획 짜줘" | `swarm-plan` |
| `/swarm-run` | "스웜 실행해줘" / "이어서 실행" | `swarm-run` |
| `/swarm-review` | "스웜 결과 검토해줘" (status.md가 끝남) | `swarm-review` |
| `/work-report` | "작업 끝났어, 보고서 만들어줘" / 머지 직전 | `work-report` 보고 모드 |

### CLI 단독 실행 예시

OpenCode CLI를 통해 헤드리스로 스웜 실행 및 라이프사이클을 구동할 수 있습니다:

```bash
opencode run --command swarm-run
```

---

## 3. 검증 체계 (`test/check.sh`)

저장소의 무결성과 계약 준수 여부는 다음 명령으로 100% 자동 검증됩니다:

```bash
bash test/check.sh
```

검증 항목:
1. Mandate hook 출력 및 필수 8개 스킬/3계층 경로 포함 여부
2. Frontmatter 린트 (8개 스킬, 10개 OpenCode 서브에이전트 권한/모드, 슬래시 커맨드, 규칙)
3. 스킬 ↔ 에이전트 간 상호 참조 무결성 (`TypeName: <name>` 및 `MANDATE.md` 규칙 2)
4. 가독성 표준(문장당 25 어절 이하) 정확히 4개 스킬 유지
5. `install.sh` 및 `install-opencode.sh` 가상 프로젝트 설치 멱등성
6. `docs_check.py` 템플릿 검사 통과 및 비정상 파일 거부 테스트
7. 구버전 잔재 경로(`docs/blindspot` 등) 부재 검사
8. 템플릿 필수 헤딩 및 불릿 규격 검사
9. `swarm_check.py` 정상 패키지 통과 및 오염 패키지 차단 검사
10. OpenCode 런타임 에이전트 목록(`opencode agent list`) 10종 서브에이전트 검색 검증
