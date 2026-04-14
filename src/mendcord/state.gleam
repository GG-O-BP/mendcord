import gleam/list
import gleam/set.{type Set}

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
