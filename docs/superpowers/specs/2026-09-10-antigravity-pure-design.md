# Google Antigravity 순수 단일 하네스 일원화 설계 (antigravity-pure)

- 날짜: 2026-09-10
- 상태: 구현·검증 완료, 사용자 검토 대기
- 브랜치: `antigravity-pure`
- 선행 스펙: `2026-09-07-three-tier-docs-design.md`, `2026-09-08-antigravity-swarm-design.md`

## 1. 목적과 배경

`main` 브랜치는 Claude Code 단일 환경에서 계획부터 직렬 구현·보고까지 수행했고, `antigravity-swarm` 브랜치는 Claude Code(계획·감사)와 Google Antigravity(스웜 병렬 실행)로 역할을 이원화했습니다.

하지만 두 도구를 오가며 작업하는 것은 컨텍스트 전환 비용을 발생시키고, 두 하네스 각각의 설치·설정(`.claude/`와 `.agents/`)을 관리해야 하는 복잡도를 수반했습니다.

`antigravity-pure` 브랜치는 **계획(인터뷰, 사각지대 점검, 스펙 작성, 스웜 계획)부터 실행(스웜 병렬 실행 또는 세션 내 직접 구현), 감사·보고(스웜 감사, 변경 분석, 머지 전 퀴즈 생성)까지 모든 과정을 오직 Google Antigravity 단독으로 완결**하도록 통합합니다.

## 2. 핵심 변경 및 결정사항

| # | 결정 | 선택 | 근거 | 기각한 대안 |
|---|---|---|---|---|
| 1 | 단일 하네스 체제 | 모든 과정을 Google Antigravity에서 단독 실행 | 사용자 요청. Claude Code 의존성 완전 제거 및 단일 환경의 일관된 경험 제공 | Claude Code + Antigravity 이원화 유지 |
| 2 | 디렉터리 구조 일원화 | `skills/` 8종, `agents/` 8종, `rules/` 1종으로 통합 | Antigravity 단일 하네스이므로 `antigravity/` 하위 폴더 분리 불필요 | `antigravity/`와 루트로 이원화 유지 |
| 3 | 서브에이전트 규격 표준화 | 8개 에이전트 모두 Antigravity frontmatter 표준 적용 (`subagent: true`, `mainAgent: false`, `model: flash`, `commandExecutionPolicy: auto`, `tools:` 블록) | Antigravity 런타임에서 안정적인 백그라운드 호출(`invoke_subagent`) 보장 | 도구 이름 미지정(빈 도구) 또는 비표준 frontmatter |
| 4 | 도구 허용목록 준수 | 실측 허용된 9종 도구만 사용 (`view_file`, `find_by_name`, `grep_search`, `list_dir`, `run_command`, `write_to_file`, `replace_file_content`, `read_url_content`, `search_web`) | 비인가 도구 호출로 인한 에이전트 런타임 실패 방지 | 임의의 도구명 방치 |
| 5 | 설치 스크립트 단일화 | `install.sh`가 소비 프로젝트의 `.agents/{skills,agents,rules}`에 심링크하고 `AGENTS.md`/`ANTIGRAVITY.md` 설정. `install-antigravity.sh`는 호환용 포워더 | 소비 프로젝트 온보딩 간소화, 기존 스크립트 호출 호환성 유지 | install.sh와 install-antigravity.sh 별도 유지 |
| 6 | 안내 문서 전환 | `CLAUDE.md` 제거, `ANTIGRAVITY.md` 신설 및 `AGENTS.md -> ANTIGRAVITY.md` 심링크 제공 | Antigravity 표준 프로젝트 안내서 적용 | CLAUDE.md 유지 |
| 7 | 기존 기능 100% 계승 | `main`의 3계층 문서화 및 인터뷰·사각지대·설명·보고 흐름, `antigravity-swarm`의 스웜 계획·실행·감사 기능 모두 온전히 보존 | 기존 기능 누락 없는 완전한 기능 슈퍼셋 달성 | 일부 스킬 간소화 또는 삭제 |

## 3. 구조

```
(이 저장소)
skills/
├── blindspot-flow/SKILL.md          # 라이프사이클 오케스트레이터
├── requirements-interview/SKILL.md  # 요구사항 인터뷰 (ask_question, doc-verifier)
├── blindspot-pass/                  # 사각지대 점검 및 부트스트랩
│   ├── SKILL.md
│   └── templates/{rules.md, map.md}
├── explainer/                       # 3계층 스펙 작성
│   ├── SKILL.md
│   └── templates/spec.md
├── swarm-plan/                      # 스웜 계획 패키지 생성
│   ├── SKILL.md
│   ├── templates/{plan.md, task.md}
│   └── scripts/swarm_check.py       # 계획 패키지 검증 스크립트
├── swarm-run/                       # Antigravity 스웜 병렬 디스패처
│   ├── SKILL.md
│   └── templates/{status.md, result.md}
├── swarm-review/SKILL.md            # 스웜 결과 감사 및 라우팅
└── work-report/                     # 작업 노트 및 머지 전 퀴즈 생성
    ├── SKILL.md
    ├── templates/{notes.md, quiz.html}
    └── scripts/docs_check.py        # 계층 문서 및 퀴즈 검사 스크립트

agents/                              # Antigravity 전용 서브에이전트 8종
├── codebase-scanner.md              # 코드베이스 관점 탐색
├── domain-researcher.md             # 웹 도메인 조사
├── doc-verifier.md                  # 문서 품질 검증
├── change-analyzer.md               # git diff 분석
├── check-runner.md                  # 프로젝트 표준 검사 실행
├── swarm-auditor.md                 # 스웜 브리프-결과-diff 감사
├── swarm-worker.md                  # 단일 브리프 전담 구현 워커 (소유 파일 한정)
└── swarm-checker.md                 # 웨이브 검증 명령 단독 실행 체커

rules/
└── mandate.md                       # trigger: always_on 규칙

MANDATE.md                           # 프로젝트 주입용 지침 (48줄, ≤60줄 상한)
ANTIGRAVITY.md / AGENTS.md           # Antigravity 가이드 및 계약
install.sh / install-antigravity.sh  # 소비 프로젝트 설치 스크립트
test/check.sh                        # 전체 계약 자동 검증 (12개 검증 통과)

(소비 프로젝트)
.agents/shared/                      # git submodule 마운트 위치
.agents/skills/*                     # 8개 스킬 심링크
.agents/agents/*                     # 8개 서브에이전트 심링크
.agents/rules/mandate.md             # 항상 주입되는 규칙 심링크
AGENTS.md / ANTIGRAVITY.md           # @.agents/shared/MANDATE.md 포함
```

## 4. 라이프사이클 흐름 비교

### main 브랜치
`인터뷰(Claude)` → `사각지대 점검(Claude)` → `스펙 작성(Claude)` → `세션 내 직렬 구현(Claude)` → `보고 및 퀴즈(Claude)`

### antigravity-swarm 브랜치
`인터뷰(Claude)` → `사각지대 점검(Claude)` → `스펙 작성(Claude)` → `스웜 계획(Claude)` → **`스웜 병렬 실행(Antigravity)`** → `스웜 감사(Claude)` → `보고 및 퀴즈(Claude)`

### antigravity-pure 브랜치 (현 브랜치)
모든 과정이 **Google Antigravity 메인 세션과 서브에이전트** 내에서 완결:
1. **계획 단계**: Antigravity 메인 세션이 `requirements-interview`, `blindspot-pass`, `explainer`를 통해 3계층 문서를 구축하고, 복잡한 구현은 `swarm-plan`으로 세분화.
2. **실행 단계**: Antigravity 내에서 `/swarm-run`을 호출하여 `swarm-worker`와 `swarm-checker` 서브에이전트들이 웨이브 단위로 파일 소유권을 엄격히 분리하여 병렬 구현. (또는 직렬 세션 구현 선택 가능)
3. **감사 및 보고 단계**: `swarm-review`와 `swarm-auditor`로 diff와 결과를 대조·검증하고, `work-report`와 `change-analyzer`로 변경 사항을 3계층 문서에 반영하며, `docs/quiz.html`을 생성하여 사용자가 퀴즈를 통과한 후 머지 게이트를 통과.

## 5. 검증 결과

`bash test/check.sh`를 통해 아래 항목들이 100% 통과함을 확인:
1. `hooks/mandate.sh`의 8개 스킬 및 계층 경로 출력 확인
2. 8개 스킬, 8개 서브에이전트, 1개 규칙의 frontmatter 규격 및 도구 허용목록 검증
3. `TypeName: <name>`과 `MANDATE.md` 간의 서브에이전트 상호 참조 무결성 확인
4. 가독성 표준(`25 어절`) 4개 스킬 정확한 위치 검증
5. 임시 소비 프로젝트 대상 `install.sh` 및 `install-antigravity.sh`의 멱등성 및 심링크 동작 검증
6. `docs_check.py` 템플릿 검사 통과 및 잘못된 계층 파일에 대한 오류 포착 검증
7. 레거시/퇴역 경로 잔존 여부 0건 검증
8. 스웜 및 계층 템플릿의 헤딩 및 불릿 계약 검증
9. 스킬 내 템플릿 참조 무결성 검증
10. `MANDATE.md` 60줄 이하 상한(48줄) 준수 검증
11. `swarm_check.py`의 유효 패키지 승인 및 비정상 패키지(소유권 겹침, 누락, 플레이스홀더 등) 감지 검증
