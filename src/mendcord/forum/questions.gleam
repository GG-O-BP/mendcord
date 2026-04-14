import gleam/list
import gleam/result
import mendcord/forum.{type Post, Post, Questions}
import mendcord/forum/client
import mendcord/forum/rss

const feed_url = "https://community.mendix.com/feed.xml"

pub type Error {
  FetchFailed(client.Error)
}

pub fn recent(is_seen is_seen: fn(String) -> Bool) -> Result(List(Post), Error) {
  use body <- result.try(client.get(feed_url) |> result.map_error(FetchFailed))
  let items =
    rss.parse(body)
    |> list.filter(fn(item) { !is_seen(item.guid) })
    |> list.map(to_post)
  Ok(items)
}

fn to_post(item: rss.Item) -> Post {
  Post(
    kind: Questions,
    guid: item.guid,
    title: item.title,
    url: item.link,
    description: item.description,
    author: item.creator,
    space: item.category,
    tags: item.tags,
    reply_count: item.answers,
    date: item.pub_date,
  )
}
