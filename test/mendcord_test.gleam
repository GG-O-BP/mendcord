import gleam/list
import gleam/string
import gleeunit
import mendcord/forum/rss
import mendcord/forum/sitemap
import mendcord/forum/ssr
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn rss_parses_all_items_test() {
  let assert Ok(xml) = simplifile.read("test/fixtures/feed.xml")
  let items = rss.parse(xml)

  assert list.length(items) == 20
  let assert Ok(first) = list.first(items)
  assert first.guid == "145569"
  assert first.title == "JVM Heap Tuning in Mendix Operator"
  assert first.creator == "Rakesh"
  assert first.category == "Deployment"
  assert first.tags == "Deployment"
  assert first.answers == "1"
  assert string.contains(first.link, "/questions/145569")
  assert string.contains(first.description, "OutOfMemoryError")
}

pub fn sitemap_parses_and_sorts_test() {
  let assert Ok(xml) = simplifile.read("test/fixtures/sitemap_ideas.xml")
  let entries = sitemap.parse(xml)

  assert list.length(entries) == 5086

  let top5 = sitemap.top_by_lastmod(entries, 5)
  let assert Ok(newest) = list.first(top5)
  assert string.contains(newest.url, "/ideas/5493")
  assert string.contains(newest.lastmod, "2026-04-14")
}

pub fn sitemap_url_helpers_test() {
  assert sitemap.guid_from_url(
      "https://community.mendix.com/link/spaces/app-development/ideas/5493",
    )
    == "5493"
  assert sitemap.space_from_url(
      "https://community.mendix.com/link/spaces/app-development/ideas/5493",
    )
    == "app-development"
}

pub fn ssr_parses_question_test() {
  let assert Ok(html) = simplifile.read("test/fixtures/ssr_question.html")
  let detail = ssr.parse(html)

  assert string.contains(detail.title, "White screen after login")
  assert string.contains(detail.description, "synchronization")
}

pub fn ssr_parses_idea_test() {
  let assert Ok(html) = simplifile.read("test/fixtures/ssr_idea.html")
  let detail = ssr.parse(html)

  assert detail.title == "The definition of this widget has changed"
  assert detail.author == "Jord ten Bulte - Toll"
  assert detail.date == "2026-04-14"
  assert detail.reply_count == "0"
}

pub fn ssr_parses_exchange_test() {
  let assert Ok(html) = simplifile.read("test/fixtures/ssr_exchange.html")
  let detail = ssr.parse(html)

  assert detail.title == "Desafio Low Hack!"
  assert detail.author == "Lucas Faccio"
  assert detail.date == "2024-10-29"
  assert detail.reply_count == "0"
}
