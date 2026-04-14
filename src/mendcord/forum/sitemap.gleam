import gleam/list
import gleam/option.{Some}
import gleam/regexp
import gleam/string

pub type Entry {
  Entry(url: String, lastmod: String)
}

pub fn parse(xml: String) -> List(Entry) {
  let assert Ok(url_re) =
    regexp.from_string(
      "<ns1:url>\\s*<ns1:loc>([^<]+)</ns1:loc>\\s*<ns1:lastmod>([^<]+)</ns1:lastmod>",
    )
  regexp.scan(url_re, xml)
  |> list.filter_map(fn(m) {
    case m.submatches {
      [Some(url), Some(lastmod)] ->
        Ok(Entry(url: string.trim(url), lastmod: string.trim(lastmod)))
      _ -> Error(Nil)
    }
  })
}

pub fn top_by_lastmod(entries: List(Entry), count: Int) -> List(Entry) {
  entries
  |> list.sort(fn(a, b) { string.compare(b.lastmod, a.lastmod) })
  |> list.take(count)
}

pub fn guid_from_url(url: String) -> String {
  url |> string.split("/") |> list.last |> unwrap_string
}

pub fn space_from_url(url: String) -> String {
  case url |> string.split("/") |> list.reverse {
    [_id, _kind, space, "spaces", ..] -> space
    _ -> ""
  }
}

fn unwrap_string(r: Result(String, Nil)) -> String {
  case r {
    Ok(v) -> v
    Error(_) -> ""
  }
}
