import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string

pub opaque type Seen {
  Seen(guids: Set(String))
}

pub fn empty() -> Seen {
  Seen(guids: set.new())
}

pub fn has(seen: Seen, guid: String) -> Bool {
  set.contains(seen.guids, guid)
}

pub fn insert(seen: Seen, guid: String) -> Seen {
  Seen(guids: set.insert(seen.guids, guid))
}

pub fn insert_many(seen: Seen, guids: List(String)) -> Seen {
  Seen(guids: list.fold(guids, seen.guids, set.insert))
}

pub fn size(seen: Seen) -> Int {
  set.size(seen.guids)
}

pub fn to_json(seen: Seen) -> String {
  seen.guids
  |> set.to_list
  |> list.sort(string.compare)
  |> json.array(of: json.string)
  |> json.to_string
}

pub fn from_json(raw: String) -> Result(Seen, Nil) {
  json.parse(from: raw, using: decode.list(decode.string))
  |> result.replace_error(Nil)
  |> result.map(fn(guids) { insert_many(empty(), guids) })
}
