import gleam/list
import gleam/result
import mendcord/forum.{type Post, Ideas, Post}
import mendcord/forum/client
import mendcord/forum/sitemap.{type Entry}
import mendcord/forum/ssr

const sitemap_url = "https://community.mendix.com/sitemaps/sitemap_ideas.xml"

const scan_top_n = 15

pub type Error {
  SitemapFetchFailed(client.Error)
  DetailFetchFailed(url: String, cause: client.Error)
}

pub fn recent(is_seen is_seen: fn(String) -> Bool) -> Result(List(Post), Error) {
  use body <- result.try(
    client.get(sitemap_url) |> result.map_error(SitemapFetchFailed),
  )
  let candidates =
    sitemap.parse(body)
    |> sitemap.top_by_lastmod(scan_top_n)
    |> list.filter(fn(entry) { !is_seen(sitemap.guid_from_url(entry.url)) })

  list.try_map(candidates, fetch_detail)
}

fn fetch_detail(entry: Entry) -> Result(Post, Error) {
  use html <- result.try(
    client.get(entry.url)
    |> result.map_error(fn(e) { DetailFetchFailed(entry.url, e) }),
  )
  let detail = ssr.parse(html)
  Ok(
    Post(
      kind: Ideas,
      guid: sitemap.guid_from_url(entry.url),
      title: detail.title,
      url: entry.url,
      description: detail.description,
      author: detail.author,
      space: sitemap.space_from_url(entry.url),
      tags: "",
      reply_count: detail.reply_count,
      date: case detail.date {
        "" -> entry.lastmod
        d -> d
      },
    ),
  )
}
