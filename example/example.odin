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

	font_title, _ := load_font(&doc, "Edwardian Script ITC.ttf")
	font_content, _ := load_font(&doc, "calibri-regular.ttf")

	page, _ := add_page(&doc, {In(5), In(5)}, 255)
	
	add_object(&doc, {
		origin = {In(2.5), 0},
		info = Box_Object_Info({
			size = {Px(1), In(5)},
			fill_style = {80, 80, 80, 255},
		}),
	})

	begin_text_layout(&doc, {In(2.5), 0}, .Bottom)
		add_text(&doc, {
			text = "Hellope!",
			font = font_title,
			size = Pt(72),
			align = .Center,
			fill_style = {0, 0, 0, 255},
		})
		add_space(&doc, In(0.5))
		add_text(&doc, {
			text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas sed quam nisi. Nulla facilisi. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Fusce consequat purus vel congue euismod.",
			font = font_content,
			line_limit = Unit(In(2)),
			size = Pt(11),
			align = .Left,
			fill_style = {0, 0, 0, 255},
		})
		add_text(&doc, {
			text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas sed quam nisi. Nulla facilisi. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Fusce consequat purus vel congue euismod.",
			font = font_content,
			line_limit = Unit(In(2)),
			size = Pt(11),
			align = .Center,
			fill_style = {0, 0, 0, 255},
		})
		add_text(&doc, {
			text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas sed quam nisi. Nulla facilisi. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Fusce consequat purus vel congue euismod.",
			font = font_content,
			line_limit = Unit(In(2)),
			size = Pt(11),
			align = .Right,
			fill_style = {0, 0, 0, 255},
		})
	end_text_layout(&doc)

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