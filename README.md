# mendcord

A Discord bot that watches the [Mendix Community Forum](https://community.mendix.com/) and announces new posts across three dedicated Discord channels: Questions, Ideas, and Exchanges.

Written in [Gleam](https://gleam.run/) on the Erlang/BEAM runtime. No Mendix account is required — the bot only reads public RSS feeds, XML sitemaps, and Schema.org server-rendered HTML.

## How it works

`mendcord` runs as a **one-shot process**: each invocation loads persisted state, polls the three feeds once, posts anything new to Discord, saves state, and exits. Scheduling is external — a GitHub Actions cron triggers `gleam run` every five minutes. There is no in-process timer and no long-lived actor.

| Feed | Listing source | Detail source |
| --- | --- | --- |
| Questions | `/feed.xml` (RSS, 20 most recent) | Already present in the RSS `<description>` |
| Ideas | `/sitemaps/sitemap_ideas.xml` — top N by `lastmod` | Each URL fetched and parsed as a Schema.org `QAPage` |
| Exchanges | `/sitemaps/sitemap_exchanges.xml` — top N by `lastmod` | Same pattern as Ideas |

State across runs is a single JSON file, `seen.json`, holding the set of announced GUIDs. On first run (or any run where the file is missing/empty) the bot enters **seed mode** — it records the current posts as "seen" without announcing them, so that a fresh deployment or a cache miss never floods a channel with backlog.

## Prerequisites

- [Gleam 1.15 or newer](https://gleam.run/getting-started/installing/) with an Erlang installation
- A Discord bot application with the `Send Messages` and `Embed Links` permissions
- Three Discord channels the bot has been invited to, one per feed kind

## Configuration

Settings come from environment variables. For local runs, a `.env` file in the project root is loaded via [glenvy](https://hex.pm/packages/glenvy); the file is gitignored. In CI they come from GitHub Actions secrets.

| Variable | Description |
| --- | --- |
| `DISCORD_TOKEN` | Bot token from the Discord Developer Portal |
| `DISCORD_CLIENT_ID` | Application (client) ID |
| `QUESTIONS_CHANNEL_ID` | Channel that receives Questions announcements |
| `IDEAS_CHANNEL_ID` | Channel that receives Ideas announcements |
| `EXCHANGES_CHANNEL_ID` | Channel that receives Exchanges announcements |

The polling interval is defined by the GitHub Actions workflow's cron expression, not by the bot itself.

## Running

```sh
gleam run     # one tick: poll, announce, save, exit
gleam test    # run the test suite
gleam format  # format the codebase
gleam check   # type-check without building
```

Local iteration is easiest by running `gleam run` repeatedly; `seen.json` is created on the first run and reused thereafter.

## Deployment

The supported deployment target is GitHub Actions — `.github/workflows/poll.yml` drives the whole pipeline:

- A `schedule: cron` fires every five minutes
- `actions/cache` persists `seen.json` across runs so the bot remembers what it already announced
- Each run is capped at five minutes via `timeout-minutes` and serialised via `concurrency`
- `workflow_dispatch` is enabled for manual triggers

Notes for operators:

- Keep the repository **public**; that avoids Actions minute limits and matches the shape of similar open-source community bots
- GitHub disables scheduled workflows after 60 days of repository inactivity — an occasional commit (or a manual re-enable) keeps the cron alive
- The bot does not connect to Discord's gateway, so it will appear offline in the member list; posting works fine because it is done over the REST API

See [docs/hosting-github-actions.md](docs/hosting-github-actions.md) for the rationale and the cache-design notes behind these choices.

## Licence

Released under the Mozilla Public License, v. 2.0. See [LICENCE](LICENCE) for the full text.
