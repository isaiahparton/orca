package example

import "core:fmt"
import "core:mem"
import "core:time"
import "core:runtime"

import rl "vendor:raylib"

import ".."

_main :: proc() {
	using orca

	doc: Document
	doc.ppi = 141

	title_font, _ := load_font(&doc, "Edwardian Script ITC.ttf")
	header_font, _ := load_font(&doc, "calibri-bold.ttf")
	content_font, _ := load_font(&doc, "calibri-regular.ttf")

	page := begin_page(&doc, {In(8.5), In(11)}, 255)
		shrink_layout(&doc, In(0.25))
		push_fixed_layout(&doc, .Bottom, In(1.25))
			shrink_layout(&doc, In(0.15))
			push_fixed_layout(&doc, .Right, In(2))
				add_text_offset(&doc, .Top, 0.5, {
					font = header_font,
					text = "PURCHASE NUMBER: ",
					fill_style = {0, 0, 0, 255},
					size = Pt(13),
					align = .Right,
				})
				add_space(&doc, .Top, Pt(4))
				add_text_offset(&doc, .Top, 0.5, {
					font = header_font,
					text = "0955124474",
					fill_style = {0, 0, 0, 255},
					size = Pt(13),
					align = .Left,
				})
			pop_layout(&doc)
			push_fixed_layout(&doc, .Left, Pc(100))
				add_text(&doc, .Top, {
					font = header_font,
					text = "CENTRO ESCOLAR EVANGELICO",
					fill_style = {0, 0, 0, 255},
					size = Pt(13),
				})
				add_space(&doc, .Top, Pt(10))
				add_text(&doc, .Top, {
					font = content_font,
					text = "Calle El Berrendo 5-511",
					fill_style = {0, 0, 0, 255},
					size = Pt(13),
				})
				add_text(&doc, .Top, {
					font = content_font,
					text = "Los Jagueyes, Namiquipa",
					fill_style = {0, 0, 0, 255},
					size = Pt(13),
				})
				add_text(&doc, .Top, {
					font = content_font,
					text = "Chihuahua, Mexico",
					fill_style = {0, 0, 0, 255},
					size = Pt(13),
				})
			pop_layout(&doc)
		pop_layout(&doc)
		add_divider(&doc, .Bottom, Mm(0.25))

		add_space(&doc, .Top, In(0.25))
		add_text(&doc, .Top, {
			font = title_font,
			text = "Invoice",
			fill_style = {0, 0, 0, 255},
			size = In(1.5),
			align = .Center,
		})
		add_space(&doc, .Top, In(0.5))
		add_divider(&doc, .Top, Mm(0.25))
		add_space(&doc, .Top, In(0.5))
		push_fixed_layout(&doc, .Left, In(1.2))
			add_text(&doc, .Top, {
				font = header_font,
				text = "QUANTITY",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Right,
			})
			add_space(&doc, .Top, Pt(5))
			add_text(&doc, .Top, {
				font = content_font,
				text = "1",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Right,
			})
			add_text(&doc, .Top, {
				font = content_font,
				text = "1",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Right,
			})
		pop_layout(&doc)
		add_space(&doc, .Left, Pt(10))
		push_fixed_layout(&doc, .Right, In(1))
			add_text(&doc, .Top, {
				font = header_font,
				text = "TOTAL",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
			add_space(&doc, .Top, Pt(5))
			add_text(&doc, .Top, {
				font = content_font,
				text = "95.45",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
			add_text(&doc, .Top, {
				font = content_font,
				text = "7.77",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
		pop_layout(&doc)
		push_fixed_layout(&doc, .Right, In(1))
			add_text(&doc, .Top, {
				font = header_font,
				text = "UNIT PRICE",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
			add_space(&doc, .Top, Pt(5))
			add_text(&doc, .Top, {
				font = content_font,
				text = "95.45",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
			add_text(&doc, .Top, {
				font = content_font,
				text = "7.77",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
		pop_layout(&doc)
		push_fixed_layout(&doc, .Left, In(1))
			add_text(&doc, .Top, {
				font = header_font,
				text = "DESCRIPTION",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
			add_space(&doc, .Top, Pt(5))
			add_text(&doc, .Top, {
				font = content_font,
				text = "Amogus Bean Bag",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
			add_text(&doc, .Top, {
				font = content_font,
				text = "Bag of frozen corn of something",
				fill_style = {0, 0, 0, 255},
				size = Pt(12),
				align = .Left,
			})
		pop_layout(&doc)
	end_page(&doc)

	s := time.now()
	render_page(&doc, page)
	fmt.printf("Rendered page (%ix%i) in %fms\n", page.size.x, page.size.y, time.duration_milliseconds(time.since(s)))

	rl.SetTraceLogLevel(.NONE)
	rl.InitWindow(title = "a window", width = i32(f32(page.size.x) * 0.6), height = i32(f32(page.size.y) * 0.6))
	rl.SetTargetFPS(60)

	img := rl.Image({
		data = (transmute(runtime.Raw_Slice)page.image.data).data,
		width = i32(page.image.width),
		height = i32(page.image.height),
		format = .UNCOMPRESSED_R8G8B8A8,
		mipmaps = 1,
	})
	tex := rl.LoadTextureFromImage(img)
	rl.SetTextureFilter(tex, .BILINEAR)

	for {
		if rl.WindowShouldClose() {
			break
		}
		rl.BeginDrawing()
			rl.ClearBackground({})
			rl.DrawTexturePro(tex, {0, 0, f32(tex.width), f32(tex.height)}, {0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}, {}, 0, rl.WHITE)
		rl.EndDrawing()
	}
	rl.UnloadTexture(tex)
	rl.CloseWindow()

	destroy_document(&doc)
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	_main()

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}