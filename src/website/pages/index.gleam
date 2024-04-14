import lustre/attribute
import lustre/element
import lustre/element/html

pub fn view() -> element.Element(Nil) {
	html.main([attribute.class("container")], [
		html.div([attribute.class("grid home-display")], [
			html.img([
				attribute.src("https://avatars1.githubusercontent.com/u/38820196?s=460&u=b9f4efb2375bae6cb30656d790c6e0a2939327c0&v=4"),
				attribute.style([
					#("border-radius", "50%"),
					#("max-width", "180px"),
				])
			]),
			html.div([attribute.style([
				#("display", "flex"),
				#("flex-direction", "column"),
				#("justify-content", "center"),
			])], [
				html.h1([], [element.text("sammyette")])
			])
		])
	])
}
