# dev-env-blindspot: 공통 Agent/Skill 저장소 설계

- 날짜: 2026-07-06
- 상태: 승인됨 (사용자 인터뷰 및 설계 리뷰 완료)
- 참조: Thariq(Anthropic), ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386), ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)

## 1. 목적

모든 프로젝트가 공통으로 사용하는 Claude Code Agent/Skill 모음. 네 가지 기능을 제공한다:

1. **사용자 요구사항 이해** — 구조화된 인터뷰
2. **Unknown Unknowns 구체화** — 코드베이스 blindspot 탐색
3. **문서 작성** — 스펙/설명서(explainer)
4. **작업사항 보고** — 구현 노트 + 보고서 + Pre-Merge Quiz

아티클의 라이프사이클(구현 전 → 중 → 후)과 Unknowns 4분면(Known Knowns / Known Unknowns / Unknown Knowns / Unknown Unknowns) 프레임워크를 충실히 따른다.

## 2. 확정된 결정사항

| 결정 | 선택 | 근거 |
|---|---|---|
| 배포 방식 | 프로젝트별 git submodule (`.claude/shared/`) | 사용자 선택. 프로젝트마다 명시적 버전 고정 |
| 강제 메커니즘 | SessionStart hook + CLAUDE.md `@import` 이중화 | hook이 매 세션 규칙 주입, import는 안전망 |
| 언어 | 지침서(SKILL.md, agent, MANDATE) 영어 / 산출물(질문·문서·보고서·퀴즈) 한국어 | 모델 지침 안정성 + 사용자 가독성 |
| 산출물 형식 | Markdown 일원화, Pre-Merge Quiz만 자체완결형 HTML | git diff/리뷰 용이 + 아티클의 퀴즈 기법 유지 |
| 구조 | 4 Skills(라이프사이클) + 3 Agents(격리 실행자) | skill=워크플로우 지식, agent=컨텍스트 격리 |

## 3. 저장소 구조

```
dev-env-blindspot/
├── README.md                  # 사람용 소비 가이드 (한국어)
├── CLAUDE.md                  # 이 repo 자체 개발 지침 (구현 시 갱신)
├── MANDATE.md                 # 소비 프로젝트에 주입되는 강제 규칙 (영어)
├── install.sh                 # 소비 프로젝트 온보딩 스크립트 (멱등)
├── hooks/
│   └── mandate.sh             # SessionStart hook: MANDATE.md를 stdout으로 출력
├── skills/
│   ├── requirements-interview/
│   │   ├── SKILL.md
│   │   └── templates/requirements.md
│   ├── blindspot-pass/
│   │   ├── SKILL.md
│   │   └── templates/unknowns.md
│   ├── explainer/
│   │   ├── SKILL.md
│   │   └── templates/explainer.md
│   └── work-report/
│       ├── SKILL.md
│       └── templates/
│           ├── implementation-notes.md
│           ├── report.md
│           └── quiz.html
├── agents/
│   ├── codebase-scanner.md
│   ├── doc-verifier.md
│   └── change-analyzer.md
├── docs/superpowers/specs/    # 이 저장소의 설계 문서
└── test/
    └── check.sh               # 멱등성 테스트 + frontmatter 린트
```

## 4. Skill 설계

공통 원칙 (아티클 "How We Use Skills" 준수):

- frontmatter `description`은 **트리거 조건** 서술 ("Use when ...")
- 템플릿은 폴더에 분리, 필요 시점에 로드 (점진적 공개)
- 목표와 제약을 제시하되 경직된 단계 강제 최소화 (railroading 회피)
- 각 SKILL.md에 **Gotchas** 섹션 — 반복 실패 지점을 축적하는 자리
- 산출물은 소비 프로젝트의 `docs/blindspot/` 아래 한국어로 작성
- 파일명: `YYYY-MM-DD-<slug>-<종류>.md` (slug는 기능/주제의 kebab-case). 예외: `<slug>-implementation-notes.md`는 여러 날에 걸치는 작업 파일이므로 날짜 접두사 없음
- 각 skill 종료 시 라이프사이클상 다음 skill을 안내 (composition)

### 4.1 requirements-interview

- **트리거**: 새 기능·변경 요청 논의 시작, 요구사항이 불명확할 때
- **워크플로우**:
  1. 요청을 4분면으로 초기 분류 (명시된 것 / 답 필요한 질문 / 암묵적 선호 후보 / 미지 영역)
  2. 질문 생성 **전에** `codebase-scanner` agent를 스폰해 관련 코드 현실 파악 — 질문이 코드 사실에 근거하도록
  3. 인터뷰: 한 번에 한 질문, 아키텍처를 바꾸는 질문 우선, 객관식 우선 (AskUserQuestion 활용)
  4. `templates/requirements.md` 기반으로 요구사항 문서 작성 — 4분면 표, 확정 요구사항, 미해결 질문 포함
  5. `doc-verifier` agent로 검증 후 저장
- **산출물**: `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md`
- **다음 단계 안내**: blindspot-pass

### 4.2 blindspot-pass

- **트리거**: 낯선 코드베이스·도메인 작업 전, 구현 계획 수립 전, 사용자가 "모르는 게 뭔지" 물을 때
- **워크플로우**:
  1. 과제 및 (있으면) requirements 문서를 입력으로
  2. `codebase-scanner` agent를 **3~4개 병렬 스폰**, 렌즈 분담:
     - 관례·패턴 (conventions)
     - 유사 기능 선례 (similar features)
     - 통합 지점·의존성 (integration points)
     - 엣지케이스·외부 제약 (edge cases)
  3. 결과 종합: Unknown Unknown을 "결정 가능한 구체적 질문"으로 변환, 4분면 재배치
  4. 아키텍처 영향 큰 순으로 사용자에게 확인 (AskUserQuestion)
  5. 해소 결과 포함해 문서화, `doc-verifier` 검증
- **산출물**: `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md`
- **다음 단계 안내**: explainer 또는 구현 시작 시 work-report(노트 모드)

### 4.3 explainer

- **트리거**: 스펙·설계 문서·설명서 필요 시, "문서로 정리해줘"
- **워크플로우**:
  1. 입력 수집: requirements, unknowns 문서, 관련 코드, 프로토타입
  2. `templates/explainer.md` 기반 작성: 목적/배경, 결정사항, 검토한 대안과 트레이드오프, **의도적 범위 제외**, 열린 질문
  3. `doc-verifier` agent 검증 (placeholder·모순·모호성) 후 수정·저장
- **산출물**: `docs/blindspot/YYYY-MM-DD-<slug>-explainer.md`
- **다음 단계 안내**: 구현 시작 시 work-report(노트 모드)

### 4.4 work-report

이중 모드 skill.

- **모드 (a) 노트 — 트리거**: 구현 시작 시, 구현 중 비자명한 결정·계획 이탈 발생 시
  - `docs/blindspot/<slug>-implementation-notes.md` 생성/append
  - 항목 형식: 결정, 이유, 검토한 대안, 보수적 선택 여부, 계획과의 이탈
- **모드 (b) 보고 — 트리거**: 작업 완료, 머지 전, "보고서 작성해줘"
  1. `change-analyzer` agent 스폰 (base ref 대비 diff 분석)
  2. implementation-notes와 병합
  3. 보고서 작성 — **Human 섹션**(요약, 스크린샷 자리) / **Agent 섹션**(의도, 제약, 검토한 엣지케이스, 의도적 범위 제외) 분리 (아티클의 PR split 기법)
  4. **Pre-Merge Quiz** HTML 생성: 변경 요약 + 객관식 5문항 내외 + 정답 확인. 자체완결형(외부 리소스 없음, 인라인 CSS/JS)
  5. 사용자에게 "퀴즈 통과 전 머지 금지" 안내
- **산출물**: `docs/blindspot/YYYY-MM-DD-<slug>-report.md`, `docs/blindspot/quiz/YYYY-MM-DD-<slug>.html`

## 5. Agent 설계

형식: `.claude/agents/*.md` 규격 — frontmatter `name`, `description`, `tools` + 본문 시스템 프롬프트(영어). 모두 **읽기 전용** 지향.

| Agent | 입력 | 출력 | tools |
|---|---|---|---|
| `codebase-scanner` | 렌즈(관점) + 과제 설명 | `파일:라인` 근거가 달린 구조화된 발견 목록 (마크다운) | Read, Grep, Glob, Bash(읽기 전용 git 명령) |
| `doc-verifier` | 문서 경로 | placeholder/모순/모호성/범위 이슈 목록, 없으면 PASS | Read, Grep, Glob |
| `change-analyzer` | base ref (기본 main) | 변경 요약, 파일별 핵심 변경, 위험 지점, 테스트 존재 여부 | Read, Grep, Glob, Bash(git diff/log) |

Agent 반환 형식은 각 agent 정의에 명시해 skill이 파싱 없이 그대로 활용 가능하게 한다.

## 6. 강제 메커니즘

### 6.1 hooks/mandate.sh (SessionStart)

`MANDATE.md`를 stdout으로 출력 → 매 세션 컨텍스트에 주입. 등록 형태(소비 프로젝트 `.claude/settings.json`):

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/shared/hooks/mandate.sh\""
      }]
    }]
  }
}
```

### 6.2 MANDATE.md 내용 (영어)

- 작업유형 → 필수 skill 매핑 표:
  - 새 기능/변경 요청 논의 → `requirements-interview` 필수
  - 낯선 코드/도메인 작업 착수 → `blindspot-pass` 필수
  - 스펙/설명 문서 요청 → `explainer` 필수
  - 구현 시작·주요 결정 → `work-report` 노트 모드 필수
  - 작업 완료·머지 전 → `work-report` 보고 모드 필수
- "해당 작업 인지 즉시, 다른 응답 전에 skill 호출" 규칙
- skill은 지정된 agent에 탐색·검증을 **반드시 위임** (메인 컨텍스트 오염 금지)
- 산출물 언어는 한국어

### 6.3 CLAUDE.md import (안전망)

소비 프로젝트 CLAUDE.md에 `@.claude/shared/MANDATE.md` 한 줄. hook 미등록/실패 시에도 규칙 유지.

## 7. 소비 프로젝트 온보딩

```bash
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .claude/shared
bash .claude/shared/install.sh
```

`install.sh` 동작 (모두 멱등):

1. `.claude/skills/`, `.claude/agents/` 디렉토리 보장
2. **상대 경로 개별 심링크**: `.claude/skills/<name>` → `../shared/skills/<name>`, `.claude/agents/<file>` → `../shared/agents/<file>` — 프로젝트 고유 skill/agent와 공존
3. `.claude/settings.json`에 SessionStart hook 병합 — jq 우선, 없으면 python3 fallback, 둘 다 없으면 수동 안내 후 실패
4. 프로젝트 CLAUDE.md에 `@.claude/shared/MANDATE.md` 라인 없으면 추가 (파일 없으면 생성)
5. 재실행 시 기존 상태 감지하고 건너뜀

업데이트: `git submodule update --remote .claude/shared` 후 `install.sh` 재실행.

설계 근거: submodule을 `.claude/` 전체가 아닌 `.claude/shared/` 하위에 두는 이유 — 프로젝트 고유 설정(settings.json, 로컬 skill)이 공유 repo에 커밋되는 사고 방지.

제약: 심링크 사용 — Linux/WSL/macOS 대상. 네이티브 Windows(git `core.symlinks` 미설정)는 지원 범위 밖(README에 명시).

## 8. 검증

`test/check.sh` 단일 스크립트:

1. 임시 디렉토리에 가짜 소비 프로젝트 생성(git init) → install.sh **2회 실행** → 심링크 대상, settings.json hook 항목, CLAUDE.md import 라인 assert (2회째 중복 생성 없음 확인)
2. 모든 `skills/*/SKILL.md`와 `agents/*.md`의 frontmatter에 `name`·`description` 존재 린트
3. `hooks/mandate.sh` 실행 시 MANDATE.md 내용이 stdout에 나오는지 확인

## 9. 의도적 범위 제외

- Plugin marketplace 배포 (submodule 선택으로 대체 — 추후 필요 시 `.claude-plugin/` 추가로 전환 가능)
- UserPromptSubmit 등 매 프롬프트 hook (토큰 오버헤드 대비 이득 불충분, SessionStart로 충분)
- 산출물 다국어 지원 (한국어 고정)
- skill 사용 텔레메트리(PreToolUse 로깅) — 아티클이 언급하나 초기 버전에서는 제외, 필요해지면 추가
- CI 파이프라인 (test/check.sh 로컬 실행으로 시작)

## 10. 열린 질문

없음 — 인터뷰에서 모두 해소됨.
