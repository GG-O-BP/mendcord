import gleam/int
import gleam/result
import glenvy/dotenv
import glenvy/env
import logging

pub type Config {
  Config(
    discord_token: String,
    discord_client_id: String,
    channels: Channels,
    poll_interval_ms: Int,
  )
}

pub type Channels {
  Channels(questions: String, ideas: String, exchanges: String)
}

pub type Error {
  MissingVar(name: String)
  InvalidInt(name: String)
}

pub fn load() -> Result(Config, Error) {
  case dotenv.load() {
    Ok(_) -> Nil
    Error(_) ->
      logging.log(logging.Info, "no .env file; using process env only")
  }

  use discord_token <- result.try(required("DISCORD_TOKEN"))
  use discord_client_id <- result.try(required("DISCORD_CLIENT_ID"))
  use questions_channel <- result.try(required("QUESTIONS_CHANNEL_ID"))
  use ideas_channel <- result.try(required("IDEAS_CHANNEL_ID"))
  use exchanges_channel <- result.try(required("EXCHANGES_CHANNEL_ID"))
  use poll_seconds <- result.try(int_with_default("POLL_INTERVAL_SECONDS", 300))

  Ok(Config(
    discord_token:,
    discord_client_id:,
    channels: Channels(
      questions: questions_channel,
      ideas: ideas_channel,
      exchanges: exchanges_channel,
    ),
    poll_interval_ms: poll_seconds * 1000,
  ))
}

pub fn describe(err: Error) -> String {
  case err {
    MissingVar(name) -> "missing env var " <> name
    InvalidInt(name) -> "invalid int in env var " <> name
  }
}

fn required(name: String) -> Result(String, Error) {
  env.string(name) |> result.map_error(fn(_) { MissingVar(name) })
}

fn int_with_default(name: String, default: Int) -> Result(Int, Error) {
  case env.string(name) {
    Error(_) -> Ok(default)
    Ok(raw) -> int.parse(raw) |> result.map_error(fn(_) { InvalidInt(name) })
  }
}
