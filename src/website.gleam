import gleam/dict
import gleam/io
import gleam/list
import gleam/string

import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/ssg
import lustre/ssg/djot
import simplifile
import tom

import website/post

import website/pages/index
import website/pages/blog
import website/pages/post as blogpost

pub fn main() {
	let assert Ok(files) = simplifile.get_files("./content/blog")
	let posts = list.map(files, fn(path: String) -> #(String, post.Post) {
		let assert Ok(content) = simplifile.read(path)
		let assert Ok(metadata) = djot.metadata(content)
		let assert Ok(title) = tom.get_string(metadata, ["title"])
		let assert Ok(filename) = path |> string.split("/") |> list.last
		let assert Ok(slug) = filename |> string.split(".") |> list.first

		#(slug, post.Post(title: title, slug: slug, contents: djot.content(content)))
	})

	let build = ssg.new("./public")
		|> ssg.add_static_dir("static")
		|> ssg.add_static_route("/", assemble_page(index.view()))
		|> ssg.add_static_route("/blog", assemble_page(blog.view(list.map(posts, fn(slug_post: #(String, post.Post)) -> post.Post {
			slug_post.1
		}))))
		|> ssg.add_dynamic_route("/blog", dict.from_list(posts), fn(p: post.Post) {
			assemble_page(blogpost.view(p))
		})
		|> ssg.use_index_routes
		|> ssg.build

	case build {
		Ok(_) -> io.println("Website successfully built!")
		Error(e) -> {
			io.debug(e)
			io.println("Website could not be built.")
		}
	}
}

fn assemble_page(view: element.Element(a)) -> element.Element(a) {
	html.html([attribute.attribute("data-theme", "dark")], [
		html.head([], [
			html.meta([
				attribute.name("viewport"),
				attribute.attribute("content", "width=device-width, initial-scale=1.0")
			]),
			html.link([
				attribute.rel("stylesheet"),
				attribute.href("https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css")
			]),
			html.link([
				attribute.rel("stylesheet"),
				attribute.href("/main.css")
			]),
		]),
		html.body([], [
			html.header([attribute.class("fixed-top")], [
				html.div([attribute.class("container")], [
					html.nav([], [
						html.ul([], [
							html.li([], [
								html.a([attribute.href("/")], [
									html.span([attribute.class("m-0")], [element.text("sammyette's place")])
								])
							]),
							html.li([], [
								html.a([attribute.href("/blog")], [element.text("☁ community")]),
							]),
							html.li([], [
								html.a([attribute.href("/blog")], [element.text("blog")]),
							]),
							html.li([], [
								html.a([attribute.href("/projects")], [element.text("projects")]),
							])
						]),
						html.ul([], [
							html.li([], [
								html.button([], [element.text("Contact")])
							])
						])
					])
				])
			]),
			view,
			//html.footer([], [
			//	html.div([attribute.class("container")], [
			//		html.h1([], [element.text("hi")])
			//	])
			//])
		])
	])
}
