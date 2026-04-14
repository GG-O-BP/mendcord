import gleam/result
import gleam/string
import mendcord/state.{type Seen}
import simplifile

pub type Error {
  ReadError(simplifile.FileError)
  WriteError(simplifile.FileError)
  ParseError
}

pub fn load(path: String) -> Result(Seen, Error) {
  case simplifile.read(path) {
    Error(simplifile.Enoent) -> Ok(state.empty())
    Error(err) -> Error(ReadError(err))
    Ok(raw) ->
      case string.trim(raw) {
        "" -> Ok(state.empty())
        trimmed ->
          state.from_json(trimmed)
          |> result.replace_error(ParseError)
      }
  }
}

pub fn save(path: String, seen: Seen) -> Result(Nil, Error) {
  state.to_json(seen)
  |> simplifile.write(to: path)
  |> result.map_error(WriteError)
}

pub fn describe(err: Error) -> String {
  case err {
    ReadError(e) -> "read failed: " <> simplifile.describe_error(e)
    WriteError(e) -> "write failed: " <> simplifile.describe_error(e)
    ParseError -> "malformed seen.json"
  }
}
