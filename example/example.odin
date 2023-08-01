package example

import "core:fmt"
import "core:time"
import "core:runtime"

import rl "vendor:raylib"

import ".."

main :: proc() {
	using orca

	doc: Document
	doc.ppi = 140

	title_font, _ := load_font(&doc, "Edwardian Script ITC.ttf")
	content_font, _ := load_font(&doc, "calibri-regular.ttf")

	page := begin_page(&doc, {In(5), In(5)}, 255)
		add_text(&doc, .Top, {
			font = title_font,
			text = "Lorem Ipsum",
			fill_style = {0, 0, 0, 255},
			size = In(1),
			align = .Center,
		})
		add_space(&doc, .Top, In(0.4))
		add_text(&doc, .Top, {
			font = content_font,
			text = "Vivamus elementum arcu quis nibh tincidunt posuere vel a neque. In hac habitasse platea dictumst. Mauris mattis ullamcorper dignissim. Aliquam nec tortor vulputate, malesuada lacus non, placerat enim. Morbi auctor velit sed pellentesque lacinia. Morbi luctus ex velit, in fringilla eros vulputate quis. Praesent congue sed ante maximus euismod. Ut vel turpis nisl. Sed viverra dolor sed mauris porttitor volutpat. Nulla eu cursus est. Curabitur non magna id elit malesuada vehicula ut id odio. Aliquam malesuada ut nisl vel gravida. Phasellus maximus erat et malesuada vestibulum. Nunc eu odio at nulla ornare rutrum. Vestibulum dignissim sit amet justo non mollis. Nam in velit egestas, placerat quam scelerisque, varius urna.",
			fill_style = {0, 0, 0, 255},
			size = Pt(11),
			line_limit = Unit(In(2)),
			align = .Center,
		})
	end_page(&doc)

	s := time.now()
	render_page(&doc, page)
	fmt.printf("Rendered page (%ix%i) in %fms\n", page.size.x, page.size.y, time.duration_milliseconds(time.since(s)))

	rl.SetTraceLogLevel(.NONE)
	rl.InitWindow(title = "a window", width = i32(page.size.x), height = i32(page.size.y))
	rl.SetTargetFPS(60)

	img := rl.Image({
		data = (transmute(runtime.Raw_Slice)page.image.data).data,
		width = i32(page.image.width),
		height = i32(page.image.height),
		format = .UNCOMPRESSED_R8G8B8A8,
		mipmaps = 1,
	})
	tex := rl.LoadTextureFromImage(img)

	for {
		if rl.WindowShouldClose() {
			break
		}
		rl.BeginDrawing()
			rl.ClearBackground({})
			rl.DrawTexture(tex, 0, 0, rl.WHITE)
		rl.EndDrawing()
	}
	rl.CloseWindow()
}