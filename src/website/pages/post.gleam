import gleam/int
import gleam/list
import gleam/string

import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/ssg/djot

import website/post

pub fn view(p: post.Post) -> element.Element(Nil) {
	html.main([attribute.class("container")], [
		html.h1([], [element.text(p.title)]),
		// todo: add date of publishing
		//html.time([], [])
		html.small([], [element.text({{p.contents |> string.split(" ") |> list.length} / 200} |> int.to_string <> " min read")]),
		..djot.render(p.contents, djot.default_renderer())
	])
}
