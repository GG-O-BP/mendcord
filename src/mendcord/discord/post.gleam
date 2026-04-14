import discord_gleam
import discord_gleam/types/bot.{type Bot}
import discord_gleam/types/message.{Embed}
import gleam/list
import gleam/result
import gleam/string
import mendcord/forum.{type FeedKind, type Post, Exchanges, Ideas, Questions}

const description_limit = 3800

const title_limit = 240

const color_question = 0x58a6ff

const color_idea = 0xf1c40f

const color_exchange = 0x2ecc71

pub fn announce(bot: Bot, channel_id: String, post: Post) -> Result(Nil, String) {
  let embed =
    Embed(
      title: truncate(post.title, title_limit),
      description: build_description(post),
      color: color_for(post.kind),
    )

  discord_gleam.send_message(bot, channel_id, "", [embed])
  |> result.replace(Nil)
  |> result.replace_error("failed to send Discord message")
}

fn build_description(post: Post) -> String {
  let header = "**" <> post.space <> "** · " <> forum.kind_label(post.kind)
  let body = truncate(post.description, description_limit)
  let meta = meta_line(post)
  let parts = [header, post.url, "", body, meta, tags_line(post)]
  parts
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> string.join("\n")
}

fn meta_line(post: Post) -> String {
  [
    wrap("By: ", post.author, ""),
    wrap("", post.reply_count, " replies"),
    post.date,
  ]
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> string.join("  ·  ")
}

fn tags_line(post: Post) -> String {
  case string.is_empty(post.tags) {
    True -> ""
    False -> "Tags: " <> post.tags
  }
}

fn wrap(pre: String, value: String, suffix: String) -> String {
  case string.is_empty(value) {
    True -> ""
    False -> pre <> value <> suffix
  }
}

fn color_for(kind: FeedKind) -> Int {
  case kind {
    Questions -> color_question
    Ideas -> color_idea
    Exchanges -> color_exchange
  }
}

fn truncate(value: String, limit: Int) -> String {
  case string.length(value) > limit {
    True -> string.slice(value, 0, limit - 1) <> "…"
    False -> value
  }
}
