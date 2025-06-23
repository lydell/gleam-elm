import gleam/option.{type Option, None, Some}

pub type Url {
  Url(
    protocol: Protocol,
    host: String,
    port_: Option(Int),
    path: String,
    query: Option(String),
    fragment: Option(String),
  )
}

pub type Protocol {
  Http
  Https
}

pub fn from_string(str: String) -> Option(Url) {
  Some(Url(
    protocol: Http,
    host: "example.com",
    port_: None,
    path: str,
    query: None,
    fragment: None,
  ))
}
