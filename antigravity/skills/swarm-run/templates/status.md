# 스웜 실행 상태

- 계획: docs/swarm/plan.md
- 회차: 1
- 시작: YYYY-MM-DD HH:MM
- 진행: 실행 중 | 끝남
- 전체 검증 최종 결과: 미실행 | 통과 | 실패 | 실행 불가

<!-- Written only by scripts/swarm_next.py of the swarm-run skill, from this template — never by hand. 상태: 대기 / 실행 중 / 완료 / 부분 완료 / 실패 / 보류. 시도 counts dispatches across rounds, and a result file counts only when its 시도 matches. 회차 = the round the task last ran in. 커밋 = the 웨이브 commit that holds the task's last run (- while uncommitted, 없음 when the 웨이브 changed nothing). 웨이브 검증 is append-only; 결과: 통과 / 건너뜀 / 실행 불가 / 실패 — 일부 재시도 / 실패 — 전체 재시도 / 실패 — 중단; 웨이브 최종 = the closing 전체 검증. Rerunning /swarm-run resumes from this file. -->

## 작업

| id | 웨이브 | 상태 | 시도 | 회차 | 커밋 | 비고 |
|---|---|---|---|---|---|---|

## 웨이브 검증

| 웨이브 | 회차 | 결과 | 핵심 메시지 |
|---|---|---|---|
