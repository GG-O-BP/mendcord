import discord_gleam
import discord_gleam/discord/intents
import discord_gleam/types/bot.{type Bot}
import gleam/int
import logging
import mendcord/config
import mendcord/forum.{type FeedKind, Exchanges, Ideas, Questions}
import mendcord/scheduler
import mendcord/state.{type Seen}
import mendcord/state/store

const seen_path = "seen.json"

pub fn main() -> Nil {
  logging.configure()

  case config.load() {
    Error(err) -> logging.log(logging.Error, "config: " <> config.describe(err))
    Ok(cfg) -> run(cfg)
  }
}

fn run(cfg: config.Config) -> Nil {
  case store.load(seen_path) {
    Error(err) -> logging.log(logging.Error, "state: " <> store.describe(err))
    Ok(seen) -> tick(cfg, seen)
  }
}

fn tick(cfg: config.Config, seen: Seen) -> Nil {
  let bot =
    discord_gleam.bot(
      cfg.discord_token,
      cfg.discord_client_id,
      intents.default(),
    )

  let bootstrap = state.is_empty(seen)
  case bootstrap {
    True -> logging.log(logging.Info, "state: empty seen.json; seeding")
    False -> Nil
  }

  let before = state.size(seen)
  let seen =
    seen
    |> feed(Questions, bot, cfg.channels.questions, _, bootstrap)
    |> feed(Ideas, bot, cfg.channels.ideas, _, bootstrap)
    |> feed(Exchanges, bot, cfg.channels.exchanges, _, bootstrap)
  let after = state.size(seen)

  case store.save(seen_path, seen) {
    Ok(_) -> logging.log(logging.Info, "state: saved seen.json")
    Error(err) -> logging.log(logging.Error, "state: " <> store.describe(err))
  }

  logging.log(logging.Info, summary(bootstrap, before, after))
}

fn feed(
  kind: FeedKind,
  bot: Bot,
  channel_id: String,
  seen: Seen,
  bootstrap: Bool,
) -> Seen {
  scheduler.run_once(kind:, bot:, channel_id:, seen:, bootstrap:)
}

fn summary(bootstrap: Bool, before: Int, after: Int) -> String {
  let delta = after - before
  let tracked = "tracking " <> int.to_string(after) <> " guid(s)"
  case bootstrap {
    True -> "tick complete: seeded " <> int.to_string(delta) <> "; " <> tracked
    False ->
      "tick complete: announced "
      <> int.to_string(delta)
      <> " new post(s); "
      <> tracked
  }
}
