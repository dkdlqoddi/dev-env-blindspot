# Codex 전용 blindspot 개발환경 작업 보고서

- 날짜: 2026-07-29
- 기준: `f2d473d` → `d552ebe` (구현 기준)
- 퀴즈: `docs/blindspot/quiz/2026-07-29-codex-port.html` — 통과 전 머지 금지
- 읽는 법: 코드를 모르는 분은 '요약'과 '스크린샷/데모'까지만 읽으면 됩니다. 그 아래는 개발자와 AI를 위한 상세입니다.

## Human 섹션

### 요약

Codex 전용 환경은 다섯 작업 흐름과 다섯 역할 도우미를 설치합니다.
설치기는 예약된 항목만 갱신하고 기존 프로젝트의 다른 설정을 보존합니다.
설치 결과를 저장할 관리 폴더가 외부를 가리키면 변경 전에 차단됩니다.
도우미를 시작할 수 없는 환경에서도 필수 조사와 검증은 생략되지 않습니다.
사용자가 퀴즈를 모두 맞혔다고 확인하기 전에는 변경을 합치지 않습니다.

### 스크린샷 / 데모

해당 없음

### 리뷰 포인트 (개발자용)

- `install.sh:286` — `lstat()` 기반 관리 디렉터리 경계와 오류 처리를 검토합니다.
- `install.sh:297` — 지원 자산, agent TOML, hook, 안내 문서를 모두 쓰기 전에 검증하는 순서를 검토합니다.
- `test/check_installer.sh:283` — 네 관리 루트 symlink와 허용된 `.codex/shared` mount fixture의 보존 범위를 검토합니다.
- `skills/requirements-interview/SKILL.md:18` — 단일 역할의 보류·대기·재시도·부모 fallback 순서를 검토합니다.
- `MANDATE.md:19` — 필수 위임과 post-retry 부모 수행 예외가 충돌하지 않는지 검토합니다.
- `test/check_skills.sh:53` — 각 단일 단계의 지정 profile·입력과 fallback 계약을 bounded section 안에서 고정하는지 검토합니다.
- `test/check_codex.sh:23` — 인증·네트워크 없이 native Codex loader의 정상·손상 profile 경로를 검사하는 방식을 검토합니다.

## Agent 섹션 (AI 인수인계용)

### 의도 (Intent)

Claude Code 전용 blindspot 개발환경의 사용자 관찰 동작을 Codex 전용 runtime으로 이식한다. 다섯 Skill, 다섯 custom-agent profile, 시작 hook, mandate 안전망, 보고서와 만점 퀴즈 gate를 하나의 설치 계약으로 제공한다.

### 제약 (Constraints)

- 사용자의 지시에 따라 별도 worktree 없이 로컬 `codex` 브랜치에서 작업했다.
- active runtime은 Codex 전용이며, 과거 날짜 문서는 수정하거나 삭제하지 않는다.
- 소비 프로젝트 소유 데이터는 예약 이름 밖에서 보존하고, 잘못된 입력은 managed write 전에 거부한다.
- 공개 검사는 인증과 외부 네트워크에 의존하지 않아야 한다.
- push, merge, 완료 선언은 사용자의 퀴즈 만점 확인 전까지 수행하지 않는다.

### 검토한 엣지케이스

| 엣지케이스 | 처리 |
|---|---|
| 예약 Skill symlink 또는 agent 일반 파일이 이미 존재함 | 교체 가능한 예약 이름만 공유 원본으로 교체하고 비예약 항목은 보존한다. |
| 예약 Skill 또는 agent 목적지가 디렉터리·특수 파일임 | 소비자 데이터를 자동 제거하지 않고 preflight에서 실패한다. |
| 잘못된 hook JSON, agent TOML, mandate marker | 전체 preflight에서 실패하고 managed content를 바꾸지 않는다. |
| hook 또는 안내 문서가 symlink, FIFO, socket, directory임 | 일반 파일이 아닌 managed document를 읽거나 교체하지 않고 실패한다. |
| `.agents`, `.agents/skills`, `.codex`, `.codex/agents`가 symlink임 | `lstat()`으로 실제 디렉터리가 아님을 확인하고 외부 target 변경 전에 실패한다. |
| `.codex/shared`만 source mount symlink임 | 원본 mount는 허용하고 다섯 Skill과 다섯 agent를 정상 설치한다. |
| 지원 template 또는 quiz checker가 누락됨 | 참조 자산을 preflight에서 검사하고 쓰기 전에 실패한다. |
| agent thread가 일시적으로 포화됨 | 거부된 역할을 pending으로 유지하고 slot을 기다려 재시도한다. |
| subagent spawning이 계속 불가능함 | 재시도 뒤 부모가 정확한 profile 전체 지침과 같은 입력으로 모든 pending 역할을 수행한다. |
| SessionStart hook이 신뢰되지 않음 | `AGENTS.md` 또는 기존 `AGENTS.override.md`의 managed mandate block이 시작 안전망으로 남는다. |
| `debug prompt-input`이 `--strict-config`를 거부함 | 정확한 미지원 진단에만 strict flag 없는 격리 재실행을 허용한다. |

### 검증 결과

- `bash -n install.sh hooks/mandate.sh test/*.sh` — 통과
- `bash test/check.sh` — 최종 구현 HEAD에서 통과
- `python3 skills/work-report/scripts/quiz_check.py docs/blindspot/quiz/2026-07-29-codex-port.html docs/blindspot/2026-07-29-codex-port-report.md` — 통과
- `git diff --check f2d473d...d552ebe` — 통과
- 과거 문서 add-only 검사 — 통과
- 최종 scoped review — Critical 0, Important 0, Minor 0, Ready: Yes

### 의도적 범위 제외

- 설치는 파일별 원자 교체와 멱등 재실행을 제공하지만, 모든 산출물을 묶는 전역 rollback transaction은 제공하지 않는다.
- native gate는 profile parsing과 Skill·mandate 발견을 검사하지만, 인증이 필요한 실제 모델 위임 end-to-end 실행은 포함하지 않는다.
- Codex CLI가 없는 환경에서는 native discovery 검사만 명시적으로 skip하며, 나머지 focused test는 실행한다.
- Claude Code용 active runtime 호환 계층은 만들지 않았다.
- 브랜치 push와 merge는 수행하지 않았다.

### 구현 노트 요약

- 사용자가 worktree 생성을 거부해 현재 `codex` 브랜치에서 직접 구현했다.
- Codex CLI 0.146.0의 `debug --strict-config` 비호환은 사용자가 승인한 정확한 오류 전용 fallback으로 제한했다.
- custom-agent native 검사는 네트워크 진단 대신 로컬 `app-server --stdio` loader를 사용한다.
- runtime의 자동 대기열 가정은 실제 thread-limit 동작에 맞춰 보류·대기·재시도·부모 수행으로 보완했다.
- 관리 문서 특수 노드와 관리 루트 symlink는 소비자 데이터 보존을 위해 preflight에서 거부한다.
- 최종 리뷰에서 부모 fallback 예외와 역할·입력 회귀 검사를 강화했다.
- 남은 `사용자 확인 필요: 예` 항목은 없다. 퀴즈 만점 확인만 merge gate로 남아 있다.
