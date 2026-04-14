# mendcord

A Discord bot that watches the [Mendix Community Forum](https://community.mendix.com/) and announces new posts across three dedicated Discord channels: Questions, Ideas, and Exchanges.

Written in [Gleam](https://gleam.run/) on the Erlang/BEAM runtime. No Mendix account is required — the bot only reads public RSS feeds, XML sitemaps, and Schema.org server-rendered HTML.

## How it works

Three independent workers poll the forum at a configurable interval. Each keeps its own set of seen post IDs and announces to its own Discord channel, while sharing a single bot token.

| Feed | Listing source | Detail source |
| --- | --- | --- |
| Questions | `/feed.xml` (RSS, 20 most recent) | Already present in the RSS `<description>` |
| Ideas | `/sitemaps/sitemap_ideas.xml` — top N by `lastmod` | Each URL fetched and parsed as a Schema.org `QAPage` |
| Exchanges | `/sitemaps/sitemap_exchanges.xml` — top N by `lastmod` | Same pattern as Ideas |

## Prerequisites

- [Gleam 1.15 or newer](https://gleam.run/getting-started/installing/) with an Erlang installation
- A Discord bot application with the `Send Messages` and `Embed Links` permissions
- Three Discord channels the bot has been invited to, one per feed kind

## Configuration

Settings are loaded from a `.env` file in the project root via [glenvy](https://hex.pm/packages/glenvy). The file is gitignored — never commit tokens.

| Variable | Description |
| --- | --- |
| `DISCORD_TOKEN` | Bot token from the Discord Developer Portal |
| `DISCORD_CLIENT_ID` | Application (client) ID |
| `QUESTIONS_CHANNEL_ID` | Channel that receives Questions announcements |
| `IDEAS_CHANNEL_ID` | Channel that receives Ideas announcements |
| `EXCHANGES_CHANNEL_ID` | Channel that receives Exchanges announcements |
| `POLL_INTERVAL_SECONDS` | Polling cadence shared by all workers (default `300`) |

## Running

```sh
gleam run     # start the bot and all three workers
gleam test    # run the test suite
gleam format  # format the codebase
gleam check   # type-check without building
```

## Hosting

See [docs/hosting-github-actions.md](docs/hosting-github-actions.md) for a worked example of deploying the bot on GitHub Actions.

## Licence

Released under the Mozilla Public License, v. 2.0. See [LICENCE](LICENCE) for the full text.
