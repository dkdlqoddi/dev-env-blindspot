# dev-env-blindspot — Codex lite

코드를 쓰기 전에 모르는 것을 결정 가능한 질문으로 바꾸고, 답을 git에
남겨 팀의 다음 Codex 세션이 같은 질문을 반복하지 않게 하는 스킬 하나
(`blindspot-pass`)와 읽기 전용 에이전트 하나(`codebase_scanner`)다.

이전 full 버전은 요구사항 인터뷰, 설계 문서, 작업 노트, 보고서, 머지 전
퀴즈, 문서 검증까지 제공했다. 그만큼 스캔·검증 호출과 사용자 턴이
늘어났다. lite는 계획 전 unknown unknowns 탐색과
`docs/decisions.md` 결정 기록만 유지한다. 한 사이클에서 스캐너는 두 번
동시에 실행되고 질문은 한 번에 최대 세 개다.

## 1. 설치

소비할 프로젝트 루트에서 실행한다.

```bash
git submodule add -b codex https://github.com/dkdlqoddi/dev-env-blindspot.git .codex/shared
bash .codex/shared/install.sh
```

`install.sh`는 여러 번 실행해도 같은 결과를 만든다.

1. `.agents/skills/blindspot-pass` 심링크를 만든다.
2. `.codex/agents/codebase_scanner.toml`을 실제 파일로 복사한다.
3. `.codex/shared`를 가리키지만 대상이 사라진 옛 스킬 링크를 지운다.
4. 과거 full 배포의 에이전트 파일은 배포 당시 내용과 정확히 같을 때만
   지운다. 사용자가 수정한 파일과 다른 에이전트는 보존한다.
5. `.codex/hooks.json`에 SessionStart hook 하나를 병합한다.
6. 루트 `AGENTS.md`와 이미 존재하는 `AGENTS.override.md`에 짧은 mandate
   블록을 추가한다. 블록 밖의 프로젝트 지침은 그대로 둔다.

설치기는 `docs/`를 만들지 않는다. `docs/decisions.md`는 첫 결정을 기록할
때 스킬이 템플릿에서 만든다.

설치 확인:

```bash
ls .agents/skills/
ls .codex/agents/
bash .codex/shared/hooks/mandate.sh | head -1
```

Codex는 프로젝트 hook을 실행하기 전에 검토와 신뢰를 요구할 수 있다.
CLI에서 `/hooks`를 열어 blindspot SessionStart hook을 확인한다. hook을
아직 신뢰하지 않아도 같은 규칙이 `AGENTS.md`에 들어 있으므로 워크플로는
유지된다.

생성·변경된 `.gitmodules`, `.agents/`, `.codex/`, `AGENTS.md`를 커밋하면
팀원이 같은 환경을 받는다.

## 2. 사용법

설치 후 새 Codex 세션부터 적용된다. 새 기능, 요구사항이 애매한 변경,
낯선 코드 작업은 구현 계획을 쓰기 전에 `$blindspot-pass`를 사용한다.
파일 몇 개로 끝나는 명확한 작업은 건너뛴다. 직접 실행하려면
`$blindspot-pass`라고 부르거나 “내가 모르는 게 뭐지?”라고 묻는다.

진행 순서:

1. `docs/decisions.md`를 읽고 이미 기록된 결정은 다시 묻지 않는다.
2. `codebase_scanner` 두 개를 동시에 실행한다. 하나는 통합 지점(API,
   스키마, 설정, 빌드)을, 하나는 엣지케이스(실패, 동시성, 권한)를 본다.
3. 저장소 근거가 답하는 항목은 Codex가 스스로 정한다.
4. 남은 질문은 영향이 큰 순서로 최대 세 개를 한 번에 묻는다. 초과분은
   재방문 시점을 적은 `보류:` 결정 행으로 남긴다.
5. 답변, 자체 결정, 보류 항목을 `docs/decisions.md`에 한 줄씩 추가한다.
6. 결정 행과 `파일:라인` 근거를 인용한 구현 계획을 제시한다.

결정 기록은 표 하나다. 한 행은 결정 하나이며 기존 행을 고치거나 지우지
않는다. 결정을 바꾸려면 이전 행의 날짜를 근거에 적은 새 행을 추가한다.

```markdown
| 날짜 | 영역 | 결정 | 근거 | 기각한 대안 | 결정 주체 |
|---|---|---|---|---|---|
| 2026-09-15 | backend | 결제 재시도는 최대 3회로 하고 멱등 키로 중복 청구를 막는다 | src/pay/retry.ts:42 재시도 횟수 제한 없음 | 재시도 없음 / 무제한 재시도 | 사용자 |
```

영역은 frontend, backend, core 또는 모듈 이름이다. 결정 주체는 `사용자`
또는 `자체`다. 구현 중 계획 밖의 선택이 생겨도 같은 형식으로 즉시
기록한다. 과거 결정은 다음 명령으로 모아 볼 수 있다.

```bash
grep -h '^| 20' docs/decisions.md
```

표준 테스트·린트·빌드 명령과 불변 규칙은 결정 표가 아니라 프로젝트
`AGENTS.md`에 둔다.

## 3. 마무리: main에 직접 푸시

퀴즈도 PR 머지 게이트도 없다. 작업을 끝내고 검증했으면 PR 없이 기본
브랜치(main)에 직접 커밋하고 푸시한다. 변경 요약과 리뷰 포인트는 커밋
메시지 본문에 쓴다. 이번 작업이 추가한 결정 행은 같은 커밋의 diff에
그대로 보인다. 브랜치나 PR은 사용자가 요청할 때만 만들고, force-push는
하지 않는다.

## 4. 업데이트

```bash
git submodule update --remote .codex/shared
bash .codex/shared/install.sh
```

새 clone에서는 먼저 `git submodule update --init --recursive`를 실행한다.
`.gitmodules`의 submodule branch가 `codex`인지도 확인한다.

### full 버전에서 업데이트

같은 두 명령을 실행하면 대상이 사라진 공유 스킬 링크를 정리한다. 과거
배포가 복사한 에이전트 파일은 내용이 배포 당시와 같을 때만 제거한다.
직접 수정한 옛 파일은 데이터 보호를 위해 남기므로 내용을 확인한 뒤
수동으로 정리한다. 과거 산출물은 어떤 lite 스킬도 읽지 않는다. 필요한
결정만 `docs/decisions.md`로 옮기려면 대상 파일을 지목해 요청한다.

## 5. 의도적으로 없는 것

| 없는 것 | 대신 쓰는 것 |
|---|---|
| 요구사항 인터뷰 | 필요한 질문을 현재 대화에서 직접 처리 |
| 설계 설명 문서 | 필요할 때 명시적으로 요청 |
| 작업 노트 | 결정 행 한 줄 |
| 보고서·퀴즈·PR 머지 게이트 | 커밋 메시지 본문의 요약과 리뷰 포인트 |
| 문서 검증 에이전트 | 없음 |

## 6. 문제 해결

| 증상 | 원인과 해결 |
|---|---|
| `hooks.json is not valid JSON`으로 설치 실패 | 기존 `.codex/hooks.json`을 고친 뒤 다시 실행 |
| Python 오류로 설치 실패 | Python 3을 설치한 뒤 다시 실행 |
| clone 직후 스킬 링크가 깨져 있음 | `git submodule update --init --recursive` 후 설치기를 다시 실행 |
| hook이 실행되지 않음 | `/hooks`에서 프로젝트 hook을 검토하고 신뢰 |
| custom agent가 보이지 않음 | 설치 후 새 세션을 시작하고 `.codex/agents/codebase_scanner.toml` 확인 |
| 병렬 브랜치의 결정 표가 충돌 | 양쪽 행을 모두 남긴다. 행 순서는 동작에 영향을 주지 않음 |
| 네이티브 Windows에서 심링크 오류 | Linux, WSL 또는 macOS 사용 |

## 7. 이 저장소 개발

```bash
bash test/check.sh
```

스킬·에이전트 이름이나 설치 경로를 바꾸면 `AGENTS.md`, `MANDATE.md`,
`install.sh`, `test/check.sh`를 함께 갱신한다. 현재 동작의 결정 근거는
`docs/decisions.md`에 있으며 `docs/blindspot/`은 변환된 과거 기록이다.
