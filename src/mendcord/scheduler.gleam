import discord_gleam/types/bot.{type Bot}
import gleam/int
import gleam/list
import gleam/result
import logging
import mendcord/discord/post as discord_post
import mendcord/forum.{type FeedKind, type Post, Exchanges, Ideas, Questions}
import mendcord/forum/exchanges
import mendcord/forum/ideas
import mendcord/forum/questions
import mendcord/state.{type Seen}

pub fn run_once(
  kind kind: FeedKind,
  bot bot: Bot,
  channel_id channel_id: String,
  seen seen: Seen,
  bootstrap bootstrap: Bool,
) -> Seen {
  let is_seen = fn(guid) { state.has(seen, guid) }

  let result = case kind {
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
        label(kind) <> ": " <> msg <> "; skipping this feed",
      )
      seen
    }
    Ok(posts) ->
      case bootstrap {
        True -> seed(kind, seen, posts)
        False -> announce(kind, bot, channel_id, seen, posts)
      }
  }
}

fn seed(kind: FeedKind, seen: Seen, posts: List(Post)) -> Seen {
  let guids = list.map(posts, fn(p) { p.guid })
  logging.log(
    logging.Info,
    label(kind)
      <> ": seeded "
      <> int.to_string(list.length(guids))
      <> " existing guid(s)",
  )
  state.insert_many(seen, guids)
}

fn announce(
  kind: FeedKind,
  bot: Bot,
  channel_id: String,
  seen: Seen,
  posts: List(Post),
) -> Seen {
  case posts {
    [] -> seen
    _ -> {
      logging.log(
        logging.Info,
        label(kind)
          <> ": found "
          <> int.to_string(list.length(posts))
          <> " new post(s)",
      )
      let posted_guids =
        list.filter_map(posts, fn(post) {
          announce_one(kind, bot, channel_id, post)
        })
      state.insert_many(seen, posted_guids)
    }
  }
}

fn announce_one(
  kind: FeedKind,
  bot: Bot,
  channel_id: String,
  post: Post,
) -> Result(String, Nil) {
  case discord_post.announce(bot, channel_id, post) {
    Ok(_) -> Ok(post.guid)
    Error(msg) -> {
      logging.log(
        logging.Warning,
        label(kind) <> ": " <> msg <> " (guid=" <> post.guid <> ")",
      )
      Error(Nil)
    }
  }
}

fn label(kind: FeedKind) -> String {
  forum.kind_label(kind)
}
