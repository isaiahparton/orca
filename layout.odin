package orca

Side :: enum {
	Top,
	Bottom,
	Left,
	Right,
}

Layout :: struct {
	box: Box,
}

Text_Layout :: struct {
	point: [2]Px,
	side: Side,
}

begin_text_layout :: proc(doc: ^Document, point: [2]Unit, side: Side) {
	layout: Text_Layout = {
		point = get_exact_values(doc, point),
		side = side,
	}
	push_stack(&doc.text_layout, layout)
}
add_text :: proc(doc: ^Document, info: Text_Object_Info) {
	font := &doc.fonts[info.font]
	font_size, _ := get_font_size(font, get_exact_value(doc, info.size))
	layout := &doc.text_layout.items[doc.text_layout.height - 1]
	add_object(doc, Object({
		origin = {Px(layout.point.x), Px(layout.point.y)},
		info = info,
	}))
	size := measure_text_object(doc, info, font, font_size)
	switch layout.side {
		case .Top: layout.point.y -= size.y
		case .Bottom: layout.point.y += size.y
		case .Left: layout.point.x -= size.x
		case .Right: layout.point.x += size.x
	}
}
add_space :: proc(doc: ^Document, space: Unit) {
	layout := &doc.text_layout.items[doc.text_layout.height - 1]
	pixel_space := get_exact_value(doc, space)
	switch layout.side {
		case .Top: layout.point.y -= pixel_space
		case .Bottom: layout.point.y += pixel_space
		case .Left: layout.point.x -= pixel_space
		case .Right: layout.point.x += pixel_space
	}
}
end_text_layout :: proc(doc: ^Document) {
	pop_stack(&doc.text_layout)
}