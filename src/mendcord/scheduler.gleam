import discord_gleam/types/bot.{type Bot}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result
import logging
import mendcord/discord/post as discord_post
import mendcord/forum.{type FeedKind, type Post, Exchanges, Ideas, Questions}
import mendcord/forum/exchanges
import mendcord/forum/ideas
import mendcord/forum/questions
import mendcord/state.{type Seen}

const first_tick_delay_ms = 500

pub type Message {
  Tick
}

type Loop {
  Loop(
    kind: FeedKind,
    bot: Bot,
    channel_id: String,
    interval_ms: Int,
    self: Subject(Message),
    seen: Seen,
    bootstrapped: Bool,
  )
}

pub fn start(
  kind kind: FeedKind,
  bot bot: Bot,
  channel_id channel_id: String,
  interval_ms interval_ms: Int,
) -> Result(Subject(Message), actor.StartError) {
  actor.new_with_initialiser(2000, fn(self) {
    process.send_after(self, first_tick_delay_ms, Tick)
    let loop =
      Loop(
        kind:,
        bot:,
        channel_id:,
        interval_ms:,
        self:,
        seen: state.empty(),
        bootstrapped: False,
      )
    actor.initialised(loop)
    |> actor.returning(self)
    |> Ok
  })
  |> actor.on_message(handle)
  |> actor.start()
  |> result.map(fn(started) { started.data })
}

fn handle(loop: Loop, message: Message) -> actor.Next(Loop, Message) {
  case message {
    Tick -> {
      let next_loop = tick(loop)
      process.send_after(loop.self, loop.interval_ms, Tick)
      actor.continue(next_loop)
    }
  }
}

fn tick(loop: Loop) -> Loop {
  let is_seen = fn(guid) { state.has(loop.seen, guid) }

  let result = case loop.kind {
    Questions ->
      questions.recent(is_seen:)
      |> result.map_error(fn(_) { "questions fetch failed" })
    Ideas ->
      ideas.recent(is_seen:)
      |> result.map_error(fn(_) { "ideas fetch failed" })
    Exchanges ->
      exchanges.recent(is_seen:)
      |> result.map_error(fn(_) { "exchanges fetch failed" })
  }

  case result {
    Error(msg) -> {
      logging.log(
        logging.Warning,
        label(loop.kind) <> ": " <> msg <> "; skipping tick",
      )
      loop
    }
    Ok(posts) ->
      case loop.bootstrapped {
        False -> bootstrap(loop, posts)
        True -> announce(loop, posts)
      }
  }
}

fn bootstrap(loop: Loop, posts: List(Post)) -> Loop {
  let guids = list.map(posts, fn(p) { p.guid })
  logging.log(
    logging.Info,
    label(loop.kind)
      <> ": bootstrapped with "
      <> int.to_string(list.length(guids))
      <> " existing guid(s)",
  )
  Loop(..loop, seen: state.insert_many(loop.seen, guids), bootstrapped: True)
}

fn announce(loop: Loop, posts: List(Post)) -> Loop {
  case posts {
    [] -> loop
    _ -> {
      logging.log(
        logging.Info,
        label(loop.kind)
          <> ": found "
          <> int.to_string(list.length(posts))
          <> " new post(s)",
      )
      let posted_guids =
        list.filter_map(posts, fn(post) { announce_one(loop, post) })
      Loop(..loop, seen: state.insert_many(loop.seen, posted_guids))
    }
  }
}

fn announce_one(loop: Loop, post: Post) -> Result(String, Nil) {
  case discord_post.announce(loop.bot, loop.channel_id, post) {
    Ok(_) -> Ok(post.guid)
    Error(msg) -> {
      logging.log(
        logging.Warning,
        label(loop.kind) <> ": " <> msg <> " (guid=" <> post.guid <> ")",
      )
      Error(Nil)
    }
  }
}

fn label(kind: FeedKind) -> String {
  forum.kind_label(kind)
}
