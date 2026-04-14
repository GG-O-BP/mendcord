import gleam/list
import gleam/option.{type Option, Some}
import gleam/regexp.{type Regexp}
import gleam/string

pub type Item {
  Item(
    guid: String,
    title: String,
    link: String,
    description: String,
    creator: String,
    category: String,
    tags: String,
    answers: String,
    pub_date: String,
  )
}

pub fn parse(xml: String) -> List(Item) {
  let assert Ok(item_re) = regexp.from_string("<item>([\\s\\S]*?)</item>")
  regexp.scan(item_re, xml)
  |> list.map(fn(m) {
    let inner = case m.submatches {
      [Some(body)] -> body
      _ -> ""
    }
    Item(
      guid: extract(inner, "guid"),
      title: extract(inner, "title"),
      link: extract(inner, "link"),
      description: extract(inner, "description"),
      creator: extract(inner, "dc:creator"),
      category: extract(inner, "category"),
      tags: extract(inner, "media:tags"),
      answers: extract(inner, "mx:answers"),
      pub_date: extract(inner, "pubDate"),
    )
  })
}

fn extract(body: String, tag: String) -> String {
  case compile_tag_re(tag) {
    Ok(re) ->
      case regexp.scan(re, body) {
        [match, ..] -> first_submatch(match.submatches) |> strip_cdata
        [] -> ""
      }
    Error(_) -> ""
  }
}

fn compile_tag_re(tag: String) -> Result(Regexp, regexp.CompileError) {
  regexp.from_string("<" <> tag <> "[^>]*>([\\s\\S]*?)</" <> tag <> ">")
}

fn first_submatch(subs: List(Option(String))) -> String {
  case subs {
    [Some(value), ..] -> value
    _ -> ""
  }
}

fn strip_cdata(value: String) -> String {
  let trimmed = string.trim(value)
  case string.starts_with(trimmed, "<![CDATA[") {
    True ->
      trimmed
      |> string.drop_start(9)
      |> string.replace("]]>", "")
      |> string.trim
    False -> trimmed
  }
}
