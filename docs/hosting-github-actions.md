# GitHub Actions를 호스팅 서버로 사용하기

**결론 먼저:** 가능. 봇을 **"5분마다 한 번 실행 후 종료"** 모델로 바꾸는 소규모 리팩터가 필요합니다.

## 변경 핵심

| 현재 | Actions 용 |
| --- | --- |
| `sleep_forever()`로 프로세스 상주 | **1 tick 돌고 exit** |
| 3개 scheduler 액터가 영구 폴링 | main에서 3 feed 순차 실행 후 종료 |
| `Seen` 상태가 메모리 안에 지속 | 외부 저장 필요 (아래 선택) |
| cron은 OTP `send_after`가 담당 | **GitHub cron** (`*/5 * * * *`, 최소 간격 5분) |

## Seen 상태 저장 옵션

1. **GitHub Actions 캐시** (추천) — `actions/cache@v3` + 고정 키. 설정 간단, 커밋 쌓이지 않음. 드물게 cache miss 시 봇의 bootstrap 로직이 자동으로 "현재 것 전부 seen 처리"로 안전 처리.
2. **리포 파일 커밋** — state 전용 브랜치에 `seen.json` push. 명시적이지만 노이지.
3. **gist 읽기/쓰기** — 깔끔하지만 `gh auth` 추가.

## 알아둘 제약

- **Discord 초록 점(온라인 표시) 꺼짐** — 게이트웨이가 실행 시에만 붙으므로 봇이 "오프라인"으로 보임. REST 전송은 정상이라 포스팅엔 영향 없음.
- **cron 최소 간격 5분.** 더 짧게는 못 함.
- **60일 비활성화** — 리포에 커밋이 60일 없으면 Actions가 자동 disable. 관리 필요.
- **실행당 ~10초 BEAM 부팅 오버헤드.** 현재 무료 한도(public 무제한 · private 2000분/월) 안에서 여유.

## 언제 적합한가

공개 리포면 무료, 서버 관리 0, 로그도 GitHub UI에서 바로 볼 수 있어 지금 이 봇 성격(5분 폴링·상태만 보존)에 잘 맞음. 상주 봇과 달리 "온라인" 상태 표시가 안 되는 점만 허용되면 최적의 선택.

## 진행 시 필요한 결정

1. 상태 저장 옵션 — **캐시 / 커밋 / gist** 중 하나
2. 리포 공개 여부 — **public / private** (비용·노출 차이)

결정되면 리팩터 범위:

- `src/mendcord.gleam` · `src/mendcord/scheduler.gleam`에서 영구 루프 제거, 순차 실행으로 전환
- 선택한 저장 옵션용 직렬화/역직렬화 1세트 추가 (가장 단순한 건 `simplifile`로 `seen.json` 읽고 쓰기)
- `.github/workflows/poll.yml` 작성 (cron + 캐시 step + `gleam run`)

하루 이내 작업량입니다.
