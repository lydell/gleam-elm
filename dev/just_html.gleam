import elm/html
import elm/html/attributes
import elm/virtual_dom

pub fn main(args) {
  virtual_dom.init(
    html.a([attributes.href("https://elm-lang.org/")], [html.text("Elm!")]),
  )(args)
}
