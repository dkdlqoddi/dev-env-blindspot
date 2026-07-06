# dev-env-blindspot

모든 프로젝트가 공통으로 쓰는 Claude Code Agent/Skill 모음 — 사용자 요구사항 이해, Unknown Unknowns 구체화, 문서 작성, 작업사항 보고.

Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다.

## 설치 (소비 프로젝트 루트에서)

```bash
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .claude/shared
bash .claude/shared/install.sh
```

`install.sh`가 하는 일 (멱등 — 재실행 안전):

1. `.claude/skills/`, `.claude/agents/`에 개별 상대 심링크 생성 (프로젝트 자체 skill/agent와 공존)
2. `.claude/settings.json`에 SessionStart hook 병합 — 매 세션 `MANDATE.md`(작업유형→필수 skill 매핑) 주입
3. 프로젝트 `CLAUDE.md`에 `@.claude/shared/MANDATE.md` import 라인 추가 (hook 실패 시 안전망)

## 업데이트

```bash
git submodule update --remote .claude/shared
bash .claude/shared/install.sh
```

## 제공 Skill (라이프사이클 순)

| Skill | 용도 | 산출물 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 (한 번에 한 질문, 아키텍처 영향 순) | `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` |
| `blindspot-pass` | codebase-scanner 병렬 스캔으로 Unknown Unknowns를 결정 가능한 질문으로 구체화 | `...-unknowns.md` |
| `explainer` | 결정사항·대안·범위 제외를 담은 독립 설계 문서 | `...-explainer.md` |
| `work-report` | (노트) 구현 중 결정 즉시 기록 / (보고) diff 분석 + Human/Agent 분리 보고서 + Pre-Merge Quiz | `...-report.md`, `quiz/*.html`, `<slug>-implementation-notes.md` |
| `blindspot-flow` | 위 전체를 순서대로 실행하는 오케스트레이터 (`/blindspot-flow`) | (하위 skill 산출물) |

## 제공 Agent (모두 읽기 전용)

| Agent | 역할 |
|---|---|
| `codebase-scanner` | 렌즈(conventions/similar-features/integration-points/edge-cases)별 코드 탐색, `파일:라인` 근거 반환 |
| `doc-verifier` | 산출 문서의 placeholder·모순·모호성·범위 검사 |
| `change-analyzer` | base 대비 diff 분석: 변경 요약, 위험 지점, 테스트 유무, 퀴즈 후보 |

## 규칙

- 산출물은 전부 한국어, `docs/blindspot/` 아래에 저장
- Pre-Merge Quiz를 전부 맞히기 전에는 머지 금지

## 제약

- 심링크 사용: Linux / WSL / macOS 전용 (네이티브 Windows 미지원)
- settings 병합에 `jq` 또는 `python3` 필요

## 이 저장소 개발

```bash
bash test/check.sh   # mandate hook + frontmatter lint + installer 멱등성
```

설계 문서: `docs/superpowers/specs/`, 구현 계획: `docs/superpowers/plans/`
