import discord_gleam
import discord_gleam/discord/intents
import discord_gleam/types/bot.{type Bot}
import gleam/erlang/process
import logging
import mendcord/config
import mendcord/forum.{Exchanges, Ideas, Questions}
import mendcord/scheduler

pub fn main() -> Nil {
  logging.configure()

  case config.load() {
    Error(err) -> logging.log(logging.Error, "config: " <> config.describe(err))
    Ok(cfg) -> run(cfg)
  }
}

fn run(cfg: config.Config) -> Nil {
  let bot =
    discord_gleam.bot(
      cfg.discord_token,
      cfg.discord_client_id,
      intents.default(),
    )

  case discord_gleam.simple(bot, []) |> discord_gleam.start() {
    Error(_) -> logging.log(logging.Error, "discord bot failed to start")
    Ok(_) -> {
      start_worker("Questions", Questions, bot, cfg.channels.questions, cfg)
      start_worker("Ideas", Ideas, bot, cfg.channels.ideas, cfg)
      start_worker("Exchanges", Exchanges, bot, cfg.channels.exchanges, cfg)
      logging.log(logging.Info, "mendcord running; awaiting ticks")
      process.sleep_forever()
    }
  }
}

fn start_worker(
  label: String,
  kind: forum.FeedKind,
  bot: Bot,
  channel_id: String,
  cfg: config.Config,
) -> Nil {
  case
    scheduler.start(kind:, bot:, channel_id:, interval_ms: cfg.poll_interval_ms)
  {
    Ok(_) -> Nil
    Error(_) -> logging.log(logging.Error, label <> " worker failed to start")
  }
}
