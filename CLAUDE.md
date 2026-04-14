# mendcord

Mendix 커뮤니티 포럼(`community.mendix.com`)의 Questions·Ideas·Exchanges 세 종류 포스트를 주기적으로 수집해 Discord의 **세 채널에 각각 따로** 공지하는 봇. 언어는 Gleam, 런타임은 Erlang/BEAM. **인증 불필요** — 공개 피드(RSS)·사이트맵·Schema.org SSR만 사용. **실행 모델: GitHub Actions cron이 5분마다 `gleam run`을 호출 → 1회 폴링 후 종료**(상주 프로세스 아님).

## Tech stack

- **Gleam 1.15+** · Erlang target · stdlib `gleam_stdlib`
- **Discord**: `discord_gleam` (cyteon, v2.x) — REST `send_message`만 사용 (gateway `start()` 호출하지 않음)
- **HTTP**: `gleam_httpc` — 익명 GET (Discordbot UA)
- **XML/HTML 파싱**: `gleam_regexp` — RSS / sitemap / Schema.org 마이크로데이터
- **상태 영속화**: `simplifile` + `gleam_json` — `seen.json` 읽기/쓰기
- **Env**: `glenvy` (`.env` 로더 + 타입 getter)
- **Log**: `logging` (lpil) — OTP logger 래퍼
- **스케줄링**: 외부 cron(GitHub Actions `*/5 * * * *`). 프로세스 내부 타이머·액터 없음.

새 의존성을 추가할 때는 hex.pm 최신 버전을 확인하고 `gleam add <pkg>`로만 설치. `gleam.toml`·`manifest.toml`을 직접 손으로 편집하지 않는다.

## Commands

| | |
| --- | --- |
| `gleam run` | 봇 실행 |
| `gleam test` | gleeunit 테스트 실행 |
| `gleam format` | 포매터 (PostToolUse 훅이 자동 실행) |
| `gleam check` | 타입체크 (Stop 훅이 자동 실행) |
| `gleam add <pkg>` | 의존성 추가 |
| `gleam deps update` | 의존성 갱신 |

## Architecture

```
src/
  mendcord.gleam               — 엔트리포인트. seen 로드 → 3 feed 순차 실행 → seen 저장 → 종료
  mendcord/config.gleam        — env 로딩
  mendcord/forum.gleam         — FeedKind·Post 공통 타입
  mendcord/forum/
    client.gleam               — Discordbot UA 기반 GET 헬퍼
    rss.gleam                  — /feed.xml 파서
    sitemap.gleam              — XML 사이트맵 파서 + lastmod 정렬
    ssr.gleam                  — Schema.org QAPage HTML 파서
    questions.gleam            — RSS → List(Post)
    ideas.gleam                — sitemap top N + SSR 상세 → List(Post)
    exchanges.gleam            — (ideas와 동일 패턴)
  mendcord/discord/post.gleam  — Post → Embed → send_message
  mendcord/scheduler.gleam     — `run_once(kind, bot, channel, seen, bootstrap) -> Seen` 단일 함수
  mendcord/state.gleam         — Seen 집합(+ JSON encode/decode)
  mendcord/state/store.gleam   — simplifile로 seen.json 읽기/쓰기

.github/workflows/poll.yml     — cron `*/5 * * * *` + actions/cache (seen.json)
seen.json                      — 실행 간 상태. gitignore. Actions 캐시가 영속화 담당
```

한 번의 실행에서 3 FeedKind를 순차 처리한다. `Seen` 상태는 kind 구분 없이 guid 전체를 담는 Set이며, 첫 실행/캐시 미스 시(`seen.json` 부재·빈 상태) **bootstrap 모드**로 전환되어 현재 피드 글을 전부 seen에만 기록하고 전송은 건너뛴다 — 이 규칙이 재시작/캐시 유실 시 대량 중복 공지를 차단한다.

### 소스별 경로

| FeedKind | 목록 소스 | 상세 소스 |
| --- | --- | --- |
| Questions | `GET /feed.xml` (RSS, 20건) | 상세는 RSS `<description>`에 이미 포함 |
| Ideas | `GET /sitemaps/sitemap_ideas.xml` → lastmod desc top N | 각 URL을 Discordbot UA로 GET → Schema.org QAPage |
| Exchanges | `GET /sitemaps/sitemap_exchanges.xml` → lastmod desc top N | 각 URL을 Discordbot UA로 GET → Schema.org QAPage |

## References (NOT auto-imported)

- `references/xas_list.md`·`references/xas_detail.md` — **역사적 참고용**. 현재 구현은 XAS를 사용하지 않음. 혹시 XAS 경로를 되살려야 할 때 구조 참고.
- `references/gleam_language_tour.md` — Gleam 문법 가이드.

**중요: 이 파일들을 세션마다 자동 로드하지 않는다.** 필요할 때만 Read/Grep으로 부분 조회.

## Conventions

- 모듈 임포트는 **qualified** 기본. 언큐얼리파이드는 `gleam/result.{try}` 같이 널리 쓰이는 함수에만.
- 주석은 타입·함수 바로 **위 줄**, 뒤 줄 금지.
- 예외·`null` 없음. 실패는 `Result(a, Error)`로. 모듈별로 자체 Error 타입 정의.
- 파일은 포매터가 책임지므로 수동 정렬 금지.

## Anti-patterns (하지 말 것)

- **Discord를 모킹**하지 말 것. 계약 테스트는 실제 응답 픽스처(`test/fixtures/*.xml`·`*.html`)로 파서만 검증.
- **시크릿 하드코딩 금지**. `DISCORD_TOKEN`은 env. `.env`는 gitignore.
- `gleam_fetch`를 쓰지 않는다 (JS 타겟 전용). Erlang 타겟이므로 `gleam_httpc`.
- `shimmer`, `glyph` 라이브러리는 유지보수 중단 상태 — 사용 금지.
- `gleam.toml`·`manifest.toml` 수동 편집 금지.
- 커밋 전 `gleam check` / `gleam test` 모두 통과해야 함 (Stop 훅이 체크).

## Environment

- OS: Windows 11, shell: Git Bash. 경로 구분자는 `/`, 디바이스 경로는 `/c/Users/...`.
- Gleam 바이너리: `gleam 1.15.2` (`AppData/Local/Microsoft/WinGet/Links/gleam`).
- 빌드 아티팩트 `/build`는 gitignore.

### 필요한 env 변수 (`.env`는 로컬용·gitignore, CI는 GitHub Actions secrets)

```
DISCORD_TOKEN=
DISCORD_CLIENT_ID=
QUESTIONS_CHANNEL_ID=
IDEAS_CHANNEL_ID=
EXCHANGES_CHANNEL_ID=
```

폴링 간격은 `.github/workflows/poll.yml`의 cron(`*/5 * * * *`)으로 고정. 코드 안에는 스케줄 관련 설정이 없음.

봇은 Discord Developer Portal에서 앱 1개만 만들면 됨. `Send Messages` + `Embed Links` 권한으로 초대. 세 채널 ID는 각각 다른 채널을 가리켜야 함.

### GitHub Actions 호스팅 운영 메모

- 리포는 public 전제(무제한 무료 분). private로 바꾸려면 월 2000분 한도 고려.
- `seen.json`은 `actions/cache`로 run_id 키 저장, 다음 실행은 `mendcord-seen-` prefix로 최신 엔트리 복원. 캐시 미스 시 bootstrap 로직이 안전장치.
- GitHub는 **리포에 커밋이 60일 없으면 schedule 워크플로우를 자동 disable**. 주기적 커밋 또는 수동 재활성화 필요.
- 봇 Discord 온라인 표시(초록 점)는 **오프라인으로 보임** — gateway 접속을 하지 않기 때문. 포스팅엔 영향 없음.
