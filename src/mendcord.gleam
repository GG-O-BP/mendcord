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

  let before = state.size(seen)
  let seen =
    seen
    |> feed(Questions, bot, cfg.channels.questions, _)
    |> feed(Ideas, bot, cfg.channels.ideas, _)
    |> feed(Exchanges, bot, cfg.channels.exchanges, _)
  let after = state.size(seen)

  case store.save(seen_path, seen) {
    Ok(_) -> logging.log(logging.Info, "state: saved seen.json")
    Error(err) -> logging.log(logging.Error, "state: " <> store.describe(err))
  }

  logging.log(logging.Info, summary(before, after))
}

fn feed(kind: FeedKind, bot: Bot, channel_id: String, seen: Seen) -> Seen {
  scheduler.run_once(kind:, bot:, channel_id:, seen:)
}

fn summary(before: Int, after: Int) -> String {
  let delta = after - before
  "tick complete: announced "
  <> int.to_string(delta)
  <> " new post(s); tracking "
  <> int.to_string(after)
  <> " guid(s)"
}
