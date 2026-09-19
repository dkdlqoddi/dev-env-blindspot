# dev-env-blindspot

코드를 쓰기 전에 모르는 것을 질문으로 바꿔 묻고, 그 답을 git에 남겨 팀 전원의 세션이 공유하게 하는 Claude Code 스킬 하나(`blindspot-pass`)와 에이전트 하나(`codebase-scanner`)다. 이전 full 버전은 요구사항 인터뷰, 설계 문서, 작업 노트, 보고서, 머지 전 퀴즈, 문서 검증, 영역별 3계층 문서까지 갖췄다. 그 대가로 사이클마다 스캐너가 6번 넘게, 검증 에이전트가 최대 8번 돌았고, 강한 모델이 산문을 2번 썼으며, 사용자 턴이 15번을 넘었다. 토큰과 시간이 과했다. lite는 vanilla Claude Code가 못 하는 두 가지만 남긴다. 계획을 쓰기 전에 unknown unknowns를 결정 가능한 질문으로 바꿔 묻는 것, 그리고 결정을 `docs/decisions.md`에 남겨 다시 묻지 않는 것이다. 사이클당 스캐너는 2번, 사용자 턴은 1~2번이다. 출발점은 Thariq(Anthropic)의 ["A Field Guide to Fable: Finding Your Unknowns"](https://x.com/trq212/article/2073100352921215386)다.

## 1. 설치

소비할 프로젝트의 루트에서 두 명령을 실행한다.

```bash
git submodule add https://github.com/dkdlqoddi/dev-env-blindspot.git .claude/shared
bash .claude/shared/install.sh
```

`install.sh`가 하는 일 (몇 번 다시 실행해도 안전하다):

1. `.claude/skills/blindspot-pass`와 `.claude/agents/codebase-scanner.md` 심링크를 만든다. 프로젝트 자체의 스킬·에이전트와 함께 쓸 수 있다.
2. `.claude/shared`를 가리키지만 대상이 사라진 옛 심링크를 지운다. 프로젝트 자체의 파일과 다른 곳을 가리키는 링크는 건드리지 않는다.
3. `.claude/settings.json`에 SessionStart hook을 병합한다. 매 세션 시작 때 `MANDATE.md`(규칙 5개)가 주입된다.
4. 프로젝트 `CLAUDE.md`에 `@.claude/shared/MANDATE.md` import 줄을 추가한다. hook이 실패할 때의 안전망이다.

`docs/` 아래에는 아무것도 만들지 않는다. `docs/decisions.md`는 스킬이 첫 결정을 기록할 때 만든다.

설치 확인:

```bash
ls .claude/skills/     # 공유 스킬은 blindspot-pass 하나만 보여야 한다 (프로젝트 자체 스킬은 함께 보일 수 있음)
ls .claude/agents/     # codebase-scanner.md
bash .claude/shared/hooks/mandate.sh | head -1   # "# Blindspot Mandate"가 출력되어야 한다
```

생성·변경된 파일(`.gitmodules`, `.claude/`, `CLAUDE.md`)을 커밋하면 팀원도 같은 환경을 받는다.

## 2. 사용법

설치 후 새로 시작한 세션부터 적용된다. 새 기능, 요구사항이 애매한 변경, 낯선 코드를 건드리는 작업을 시작하면 Claude가 계획을 쓰기 전에 `blindspot-pass`를 실행한다. 파일 몇 개로 끝나는 명확한 작업은 건너뛴다. 직접 부르려면 "내가 모르는 게 뭐지?"라고 물으면 된다.

진행 순서:

1. `docs/decisions.md`를 읽는다. 이미 기록된 결정은 묻지 않고 그 행을 인용한다.
2. `codebase-scanner` 두 개가 동시에 코드를 훑는다. 하나는 통합 지점(API, 스키마, 설정, 빌드)을, 하나는 엣지케이스(실패, 동시성, 권한)를 본다.
3. 근거로 정할 수 있는 것은 Claude가 스스로 정한다. 남은 질문은 영향이 큰 순서로 최대 4개를 한 번에 묻는다. 넘치는 질문은 보류 행으로 남긴다.
4. 답과 스스로 정한 결정을 `docs/decisions.md`에 한 줄씩 추가한다. 계획 모드에서는 행을 계획에 싣고, 승인 직후 코드보다 먼저 추가한다.
5. 결정 행과 `파일:라인` 근거를 단 계획을 쓴다.

**사용자가 할 일은 질문 4개 이하에 답하는 것뿐이다.**

결정 기록은 표 하나다. 한 행이 결정 하나이고, 행은 고치지 않고 아래에 덧붙인다. 결정을 바꾸려면 옛 행의 날짜를 근거에 적은 새 행을 추가한다.

```markdown
| 날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체 |
|---|---|---|---|---|---|
| 2026-09-14 | backend | 결제 재시도는 최대 3회로 하고 멱등 키로 중복 청구를 막는다 | src/pay/retry.ts:42 재시도 횟수 제한 없음 | 재시도 없음 / 무제한 재시도 | 사용자 |
```

영역은 frontend, backend, core 또는 모듈 이름이다. 결정 주체는 사용자 또는 자체(Claude가 근거로 정함)다. 이 파일이 git으로 공유되므로 다음 사람의 세션이 읽고 같은 질문을 다시 하지 않는다. 구현 중 계획에서 벗어나는 결정도 그때 한 줄 추가한다. 과거 결정은 `grep -h '^| 20' docs/decisions.md`로 모아 볼 수 있다.

표준 명령(테스트·린트·빌드)과 불변 규칙은 결정 기록이 아니라 프로젝트 `CLAUDE.md`에 둔다.

## 3. 마무리: main에 직접 푸시

퀴즈도 PR 머지 게이트도 없다. 작업을 끝내고 검증했으면 PR 없이 기본 브랜치(main)에 직접 커밋하고 푸시한다. 변경 요약과 리뷰 포인트는 커밋 메시지 본문에 쓴다. 이번 작업이 추가한 결정 행은 같은 커밋의 diff에 그대로 보인다. 브랜치나 PR은 사용자가 요청할 때만 만들고, force-push는 하지 않는다.

## 4. 업데이트

이 저장소가 갱신되면 소비 프로젝트에서 실행한다.

```bash
git submodule update --remote .claude/shared && bash .claude/shared/install.sh
```

submodule이 등록된 프로젝트를 새로 clone했다면 먼저 `git submodule update --init --recursive`를 실행한다.

`--remote`는 `.gitmodules`에 브랜치 지정이 없으면 이 저장소의 기본 브랜치(main)를 따라간다. main이 아닌 브랜치를 쓰는 프로젝트는 먼저 `git config -f .gitmodules submodule..claude/shared.branch <브랜치>`로 고정하고 커밋한다.

### full 버전에서 올라오는 경우

위 명령 한 줄이면 된다. `install.sh`가 사라진 스킬·에이전트의 옛 심링크를 지우고, hook과 import 줄은 그대로 둔다. 옛 `docs/<영역>/` 문서와 작업 노트, 퀴즈 파일은 어떤 스킬도 읽지 않으므로 그대로 둬도 된다. 필요한 결정만 옮기려면 그 파일을 지목해 "이 스펙의 결정 기록을 docs/decisions.md로 옮겨줘"라고 요청한다.

## 5. 의도적으로 없는 것

| 없는 것 | 대신 쓰는 것 |
|---|---|
| 설계 문서 | 필요할 때 "이 단위 설명 문서 만들어줘"라고 요청 |
| 작업 노트 | 결정 행 한 줄 |
| 보고서·퀴즈·PR 머지 게이트 | 커밋 메시지 본문의 요약과 리뷰 포인트 |
| 문서 검증 | 없음 |

## 6. 문제 해결

| 증상 | 원인과 해결 |
|---|---|
| `install.sh`가 "not valid JSON"으로 실패 | 기존 `.claude/settings.json`이 깨져 있다. 고치거나 지운 뒤 다시 실행 |
| `install.sh`가 python3가 없다고 실패 | python3를 설치하거나, 에러 메시지에 나온 hook JSON을 settings.json에 직접 추가 |
| clone 직후 `.claude/skills/` 심링크가 깨져 있음 | submodule이 초기화되지 않았다. `git submodule update --init --recursive` 후 `install.sh` 다시 실행 |
| 스킬이 자동으로 실행되지 않음 | 설치 후 새로 시작한 세션인지 확인. 그래도 안 되면 "blindspot-pass 실행해줘"라고 직접 요청 |
| 병렬 브랜치가 `docs/decisions.md` 끝에서 충돌 | 양쪽 행을 모두 남긴다. 결정은 날짜로 검색하므로 행 순서가 조금 섞여도 된다 |
| 네이티브 Windows에서 심링크 오류 | 지원 범위 밖. Linux, WSL, macOS에서 사용 |

## 7. 이 저장소 개발

```bash
bash test/check.sh
```

스킬이나 에이전트를 추가·제거하면 `test/check.sh`의 파일 수 검사, `MANDATE.md`, `CLAUDE.md`의 Consumer contract를 함께 갱신한다. 이 저장소 자체의 결정 기록은 `docs/decisions.md`다. `docs/superpowers/`와 `docs/blindspot/`는 full 버전 시절의 설계·검증 이력이며 어떤 스킬도 읽지 않는다.
