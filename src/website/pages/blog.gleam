import gleam/list

import lustre/attribute
import lustre/element
import lustre/element/html

import website/post

pub fn view(posts: List(post.Post)) -> element.Element(Nil) {
	html.main([attribute.class("container")],
		list.map(posts, fn(p: post.Post) -> element.Element(Nil) {
			html.a([attribute.href("./" <> p.slug <> ".html")], [
				html.article([], [
					html.header([], [element.text(p.title)])
				])
			])
		})
	)
}
