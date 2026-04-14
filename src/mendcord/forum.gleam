pub type FeedKind {
  Questions
  Ideas
  Exchanges
}

pub type Post {
  Post(
    kind: FeedKind,
    guid: String,
    title: String,
    url: String,
    description: String,
    author: String,
    space: String,
    tags: String,
    reply_count: String,
    date: String,
  )
}

pub fn kind_label(kind: FeedKind) -> String {
  case kind {
    Questions -> "Question"
    Ideas -> "Idea"
    Exchanges -> "Exchange"
  }
}
