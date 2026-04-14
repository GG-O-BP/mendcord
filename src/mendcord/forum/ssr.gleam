import gleam/option.{Some}
import gleam/regexp
import gleam/string

pub type Detail {
  Detail(
    title: String,
    description: String,
    author: String,
    date: String,
    reply_count: String,
  )
}

pub fn parse(html: String) -> Detail {
  Detail(
    title: extract_title(html),
    description: extract_meta_description(html),
    author: extract_author(html),
    date: extract_date(html),
    reply_count: extract_reply_count(html),
  )
}

fn extract_title(html: String) -> String {
  case
    first_submatch(
      html,
      "<h[12]\\s+itemprop=['\"]name['\"][^>]*>([^<]+)</h[12]>",
    )
  {
    Ok(value) -> string.trim(value)
    Error(_) ->
      case first_submatch(html, "<title>([^<]+)</title>") {
        Ok(raw) ->
          raw
          |> string.replace(" | Mendix Forum", "")
          |> string.trim
        Error(_) -> ""
      }
  }
}

fn extract_meta_description(html: String) -> String {
  case
    first_submatch(
      html,
      "<meta\\s+name=\"Description\"\\s+content=\"([^\"]*)\"",
    )
  {
    Ok(value) -> string.trim(value)
    Error(_) -> ""
  }
}

fn extract_author(html: String) -> String {
  case
    first_submatch(
      html,
      "itemprop=['\"]author['\"][\\s\\S]*?<span\\s+itemprop=['\"]name['\"][^>]*>([^<]+)</span>",
    )
  {
    Ok(value) -> string.trim(value)
    Error(_) -> ""
  }
}

fn extract_date(html: String) -> String {
  case
    first_submatch(
      html,
      "itemprop=['\"]dateCreated['\"]\\s+datetime=['\"]([^'\"]+)['\"]",
    )
  {
    Ok(value) -> string.trim(value)
    Error(_) -> ""
  }
}

fn extract_reply_count(html: String) -> String {
  case
    first_submatch(
      html,
      "itemprop=['\"](?:answerCount|commentCount)['\"][^>]*>([^<]*)</span>",
    )
  {
    Ok(value) -> string.trim(value)
    Error(_) -> ""
  }
}

fn first_submatch(content: String, pattern: String) -> Result(String, Nil) {
  case regexp.from_string(pattern) {
    Error(_) -> Error(Nil)
    Ok(re) ->
      case regexp.scan(re, content) {
        [match, ..] ->
          case match.submatches {
            [Some(value), ..] -> Ok(value)
            _ -> Error(Nil)
          }
        [] -> Error(Nil)
      }
  }
}
