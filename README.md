# dev-env-blindspot

여러 프로젝트에서 공통으로 쓰는 Codex Skill과 custom agent 모음이다. 사용자 요구사항을 구체화하고, 미처 생각하지 못한 조건(Unknown Unknowns)을 찾고, 설계 문서와 작업 보고서를 만든다.

Thariq의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386) 라이프사이클과 ["How We Use Skills"](https://x.com/trq212/status/2033949937936085378)의 skill 설계 원칙을 따른다.

**핵심 아이디어**: 처음 받은 요청은 실제 요구사항의 불완전한 지도일 뿐이다. 이 도구는 코딩을 시작하기 전에 모르는 것을 결정 가능한 질문으로 바꾼다. 작업이 끝나면 리뷰어가 반드시 알아야 할 내용을 퀴즈로 확인한다.

## 1. 설치

Linux, WSL, macOS를 지원한다. 소비 프로젝트의 루트에서 다음 두 명령을 실행한다.

```bash
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .codex/shared
bash .codex/shared/install.sh
```

`install.sh`는 여러 번 실행해도 같은 결과를 만드는 멱등 설치기다. 다음 항목만 관리하고, 그 밖의 기존 설정과 같은 디렉터리의 다른 이름은 보존한다.

- `.agents/skills/<name>`: 공유 저장소의 다섯 skill을 가리키는 개별 상대 심볼릭 링크
- `.codex/agents/<name>.toml`: 다섯 custom agent 원본의 실제 복사본
- `.codex/hooks.json`: 기존 최상위 필드와 다른 hook을 보존하면서 하나의 `SessionStart` hook 병합
- `AGENTS.md`: 두 관리 마커 사이에 `MANDATE.md` 전체를 복사한 시작 시점 안전망
- `AGENTS.override.md`: 설치 전에 이미 존재할 때만 같은 관리 블록을 추가하거나 갱신

설치기가 예약하고 갱신하는 agent 파일은 다음 다섯 개다. 소비 프로젝트가 같은 이름의 파일을 갖고 있으면 설치 시 공유 원본으로 교체된다. 자체 profile은 다른 이름으로 옮긴 뒤 설치한다.

```text
.codex/agents/change_analyzer.toml
.codex/agents/check_runner.toml
.codex/agents/codebase_scanner.toml
.codex/agents/doc_verifier.toml
.codex/agents/domain_researcher.toml
```

설치 결과는 다음 명령으로 확인할 수 있다.

```bash
ls .agents/skills
ls .codex/agents
bash .codex/shared/hooks/mandate.sh | head -3
```

생성되거나 변경된 `.gitmodules`, `.agents/`, `.codex/agents/`, `.codex/hooks.json`, `AGENTS.md`, 그리고 기존에 있던 경우 `AGENTS.override.md`를 소비 프로젝트에 커밋한다.

### 프로젝트 신뢰와 hook 활성화

프로젝트의 `.codex` 설정과 설치된 정확한 hook 정의는 Codex의 신뢰 승인이 필요하다. 승인 전에도 `AGENTS.md`의 관리 블록이 시작 시점 안전망으로 mandate를 제공한다. Codex에서 `/hooks`를 열어 아래 명령의 hook을 검토하고 활성화하면 startup, resume, clear, compact 때마다 mandate가 다시 주입된다.

```text
bash "$(git rev-parse --show-toplevel)/.codex/shared/hooks/mandate.sh"
```

hook이 꺼져 있어도 skill 규칙을 생략해도 된다는 뜻은 아니다. 안전망을 유지하고, 신뢰할 수 있는 프로젝트에서는 `/hooks`로 재주입까지 활성화한다.

## 2. 사용법

설치 후 새 Codex 세션을 시작한다. 작업 유형을 인식하면 각 skill의 설명과 mandate에 따라 자동으로 workflow가 시작된다.

### 방법 A — 평소처럼 요청하기

| 이렇게 말하면 | 발동하는 skill | 무슨 일이 일어나나 |
|---|---|---|
| "로그인 기능을 추가하고 싶어" | `requirements-interview` | 코드를 먼저 조사한 뒤, 설계를 바꾸는 질문을 영향이 큰 순서로 한 번에 하나씩 묻고 요구사항 문서를 만든다 |
| "이 코드베이스에서 내가 놓친 게 뭐지?" | `blindspot-pass` | 관례, 유사 기능, 통합 지점, 경계 사례의 네 관점으로 조사하고, 필요한 도메인 지식까지 보강해 결정 가능한 질문을 만든다 |
| "지금까지 결정한 내용을 문서로 정리해줘" | `explainer` | 결정사항, 기각한 대안, 의도적으로 제외한 범위를 담은 독립 설계 문서를 만든다 |
| 구현을 시작하면 | `work-report` notes mode | 중요 결정과 계획 이탈을 발생 시점에 구현 노트로 기록한다 |
| "작업 보고서 만들어줘" 또는 머지 직전 | `work-report` report mode | 변경을 분석해 보고서와 Pre-Merge Quiz HTML을 만든다 |

### 방법 B — 전체 라이프사이클 실행하기

skill을 확실하게 지정하려면 `$blindspot-flow`를 명시한다.

```text
$blindspot-flow 카테고리별 월 예산 한도 기능을 처음부터 끝까지 진행해줘.
```

다음 순서로 진행하며, 각 단계 사이에 계속할지 확인한다. 이미 산출물이 있는 단계는 재사용을 제안한다.

```text
① requirements-interview  코드 조사 → 한 번에 한 질문 → 요구사항 문서
② blindspot-pass          네 관점 조사 → 놓친 결정 확인 → unknowns 문서
③ explainer               결정, 대안, 범위 제외를 담은 설계 문서
④ 구현                    결정할 때마다 구현 노트 기록
⑤ work-report             보고서 + Pre-Merge Quiz 생성
```

`requirements-interview`는 한 번에 한 질문씩 제시한다. `blindspot-pass`는 구조 영향이 큰 순서로 최대 일곱 개의 결정을 묶어 제시할 수 있다. 두 skill 모두 코드를 몰라도 답할 수 있는 한국어를 사용한다. 근거로 결정할 수 있는 내용은 스스로 해소하고 기록한다. 한 번의 조사에서 질문 후보가 일곱 개를 넘으면 먼저 추가 조사로 줄인다. 구현 중 되돌릴 수 있는 선택은 보수적인 기본값으로 진행하고 다음 확인 지점에 모아서 묻는다.

### 실행 환경의 제한이 있을 때

skill은 `.codex/agents/<name>.toml`의 `name`에 해당하는 custom agent profile을 선택한다. 현재 Codex 표면에서 profile 선택을 지원하지 않으면, 그 TOML의 전체 `developer_instructions`와 작업 입력을 일반 subagent에 함께 전달한다. 이름만 같은 일반 작업으로 바꾸지 않는다.

스레드 상한으로 일부 spawn이 거부되면 가능한 역할은 최대한 병렬로 시작하고, 거부된 역할은 대기 상태로 유지한다. 자리가 나면 재시도한다. 모든 역할이 끝날 때까지 일찍 종합하거나 역할을 빠뜨리지 않는다. subagent 생성이 계속 불가능하면 남은 모든 역할을 해당 profile의 전체 `developer_instructions`와 같은 작업 입력으로 부모가 직접 수행한다. 어떤 경우에도 조사 관점, 검증 단계, 산출물 계약을 줄이지 않는다.

웹 접근이 제한된 환경에서도 도메인 조사를 건너뛰지 않는다. 확인 가능한 모델 지식으로 계속하되 출처를 `출처: 모델 지식 (웹 접근 불가)`로 표시하고 URL을 만들어내지 않는다.

### 산출물 위치

모든 사용자용 산출물은 한국어로 프로젝트의 `docs/blindspot/` 아래에 생긴다.

```text
docs/blindspot/
├── 2026-07-29-budget-limit-requirements.md   ① 요구사항과 4분면 표
├── 2026-07-29-budget-limit-unknowns.md       ② 해소되거나 남은 unknowns
├── 2026-07-29-budget-limit-explainer.md      ③ 독립 설계 문서
├── budget-limit-implementation-notes.md      ④ 구현 노트, 날짜 접두사 없음
├── 2026-07-29-budget-limit-report.md         ⑤ Human/Agent 섹션 작업 보고서
└── quiz/2026-07-29-budget-limit.html         ⑤ Pre-Merge Quiz
```

### Pre-Merge Quiz

작업 완료 시 생성되는 퀴즈는 리뷰어가 반드시 이해해야 할 동작 변화, 위험 지점, 계획 이탈을 묻는 객관식 4~6문항이다. 코드를 보지 않은 사람도 읽을 수 있는 짧은 문장으로 작성된다. 답에 필요한 정보는 퀴즈 페이지의 `변경 요약`에 모두 들어 있으므로 보고서를 외울 필요가 없다.

1. 브라우저로 퀴즈를 연다. WSL에서는 `explorer.exe docs/blindspot/quiz/<파일명>.html`을 사용할 수 있다.
2. 모든 문항에 답하고 **정답 확인**을 누른다. 각 문항의 해설과 정답 보기가 표시된다.
3. 틀린 문항은 변경 요약과 보고서를 다시 읽고 재시도한다.
4. **100점이 되기 전에는 머지하거나 완료를 선언하지 않는다.** 사용자가 전부 맞았다고 확인해야 gate를 통과한다.

## 3. 업데이트와 복구

공유 저장소의 최신 변경을 적용할 때는 소비 프로젝트에서 다음 명령을 실행한다.

```bash
git submodule update --remote .codex/shared
bash .codex/shared/install.sh
```

이미 submodule이 등록된 프로젝트를 새로 clone했다면 먼저 초기화한다.

```bash
git submodule update --init --recursive
bash .codex/shared/install.sh
```

## 4. 제공 Skill

| Skill | 용도 | 산출물 |
|---|---|---|
| `requirements-interview` | 구조화된 인터뷰로 요구사항 확정 | `docs/blindspot/YYYY-MM-DD-<slug>-requirements.md` |
| `blindspot-pass` | 네 관점 조사로 Unknown Unknowns 구체화 | `docs/blindspot/YYYY-MM-DD-<slug>-unknowns.md` |
| `explainer` | 결정, 대안, 범위 제외를 담은 독립 설계 문서 | `docs/blindspot/YYYY-MM-DD-<slug>-explainer.md` |
| `work-report` | 구현 노트 기록, 변경 보고서와 quiz 생성 | `docs/blindspot/YYYY-MM-DD-<slug>-report.md`, `docs/blindspot/quiz/*.html`, `docs/blindspot/<slug>-implementation-notes.md` |
| `blindspot-flow` | 전체 라이프사이클을 순서대로 실행 | 하위 skill의 산출물 |

## 5. 제공 Agent

| Agent 파일 | 역할 | 권한과 model 정책 |
|---|---|---|
| `codebase_scanner.toml` | 한 조사 관점의 코드 근거와 결정 질문 반환 | read-only, Terra medium |
| `domain_researcher.toml` | 외부 도메인 지식과 출처 조사 | read-only, Terra medium |
| `doc_verifier.toml` | placeholder, 모순, 모호성, 범위 검사 | read-only, Terra low |
| `change_analyzer.toml` | diff, 위험, 계획 이탈, quiz 후보 분석 | read-only, 부모 model 상속 |
| `check_runner.toml` | 프로젝트의 표준 검사를 한 번씩 실행하고 실패만 요약 | workspace-write, Terra low |

`check_runner`의 쓰기 권한은 테스트 cache나 build artifact를 위한 예외다. 소스, 설정, 문서를 수정하거나 외부 동작을 수행할 수 있다는 뜻은 아니다.

## 6. 문제 해결

| 증상 | 원인과 해결 |
|---|---|
| `install.sh`가 `.codex/hooks.json is not valid JSON`으로 실패 | 기존 `.codex/hooks.json`을 올바른 JSON object로 고친 뒤 다시 실행한다. 설치기는 검증 실패 전에 관리 파일을 바꾸지 않는다. |
| Python 3가 없다는 오류 | Python 3를 설치한 뒤 다시 실행한다. Linux에서는 배포판 package manager를 사용할 수 있다. |
| clone 직후 skill link나 공유 파일이 없음 | submodule이 초기화되지 않았다. `git submodule update --init --recursive` 다음 `bash .codex/shared/install.sh`을 실행한다. |
| hook이 startup, resume, clear, compact에서 실행되지 않음 | 프로젝트 또는 정확한 hook 정의가 신뢰되지 않았거나 hook이 꺼져 있다. `AGENTS.md` 안전망을 유지한 채 `/hooks`에서 설치된 정의를 검토하고 활성화한다. |
| 설치 뒤 새 `AGENTS.override.md`를 추가하자 mandate가 보이지 않음 | 같은 디렉터리의 override가 `AGENTS.md`를 가릴 수 있다. 설치기를 다시 실행해 기존 override에도 관리 블록을 넣는다. |
| runtime이 예약 custom agent profile을 선택할 수 없음 | 해당 `.codex/agents/<name>.toml`을 읽고 전체 `developer_instructions`와 입력을 일반 subagent에 전달한다. 멀티 에이전트가 비활성화되어 있으면 부모가 같은 지침을 직접 수행한다. |
| 웹 검색이 차단되어 domain 조사에 URL이 없음 | 조사를 생략하지 않고 모델 지식으로 진행한다. `출처: 모델 지식 (웹 접근 불가)`를 표시하고 URL을 만들지 않는다. |
| 자체 agent 파일이 업데이트 뒤 바뀜 | 위의 다섯 filename은 설치기가 소유하는 예약 이름이라 매번 원본으로 교체된다. 자체 profile을 다른 이름으로 바꾸고 다시 설치한다. |
| 네이티브 Windows에서 심볼릭 링크 생성 오류 | 지원 범위는 Linux, WSL, macOS다. WSL 또는 지원 운영체제를 사용한다. |
| skill 자동 시작이 기대와 다름 | 새 세션인지 확인하고, 필요한 skill을 `$blindspot-pass`처럼 명시한다. hook 상태도 `/hooks`에서 확인한다. |

## 7. 이 저장소 개발

유지보수자는 저장소 루트에서 표준 검사를 실행한다.

```bash
bash test/check.sh
```

skill이나 agent를 추가, 삭제, 이름 변경하면 검사 목록, `MANDATE.md` 매핑, 설치기 예약 이름, 이 README를 함께 갱신한다. 날짜가 붙은 `docs/superpowers/` 설계·계획 문서와 `docs/blindspot/` 보고서는 당시 결정을 보존하는 역사 기록이므로 runtime 용어를 바꾸기 위해 다시 쓰지 않는다.
