import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/result

pub type Error {
  BuildFailed
  Transport(httpc.HttpError)
  BadStatus(status: Int, body: String)
}

const user_agent = "Discordbot/2.0 (+mendcord)"

pub fn get(url: String) -> Result(String, Error) {
  use base <- result.try(request.to(url) |> result.replace_error(BuildFailed))
  let req =
    base
    |> request.set_header("accept", "*/*")
    |> request.set_header("user-agent", user_agent)

  use resp <- result.try(httpc.send(req) |> result.map_error(Transport))

  case resp.status {
    200 -> Ok(resp.body)
    code -> Error(BadStatus(code, resp.body))
  }
}

pub fn describe(error: Error) -> String {
  case error {
    BuildFailed -> "URL build failed"
    Transport(_) -> "HTTP transport error"
    BadStatus(code, _) -> "HTTP " <> int.to_string(code)
  }
}
