package orca

import "core:fmt"

// Do not change order
Side :: enum {
	Left,
	Right,
	Top,
	Bottom,
}

Layout :: struct {
	box: Box,
	side: Side,
	growing: bool,
}

current_layout :: proc(doc: ^Document, loc := #caller_location) -> ^Layout {
	assert(doc.layout.height > 0, "There is no current layout", loc)
	return &doc.layout.items[doc.layout.height - 1]
}
shrink_layout :: proc(doc: ^Document, size: Unit) {
	pixel_size := get_exact_value(doc, size)
	layout := current_layout(doc)
	layout.box.x += pixel_size
	layout.box.y += pixel_size
	layout.box.w -= pixel_size * 2
	layout.box.h -= pixel_size * 2
}
push_layout :: proc(doc: ^Document, layout: Layout) {
	push_stack(&doc.layout, layout)
}
push_fixed_layout :: proc(doc: ^Document, side: Side, amount: Unit) {
	assert(doc.layout.height > 0)
	last_layout := current_layout(doc)
	layout: Layout = {
		box = cut_box(&last_layout.box, side, get_exact_value(doc, amount)),
		side = side,
	}
	push_stack(&doc.layout, layout)
}
push_adaptive_layout :: proc(doc: ^Document, side: Side, amount: Unit) {
	assert(doc.layout.height > 0)
	layout: Layout = {
		box = cut_box(&current_layout(doc).box, side, 0),
		side = side,
		growing = true,
	}
	push_stack(&doc.layout, layout)
}
add_text_offset :: proc(doc: ^Document, side: Side, time: f32, info: Text_Object_Info) {
	layout := current_layout(doc)
	// Calculate origin
	origin: [2]Px
	size := measure_text_object(doc, info)
	box := cut_box(&layout.box, side, size[int(side) / 2])
	switch side {
		case .Bottom: origin = {box.x + Px(f32(box.w) * time), box.y + box.h}
		case .Left: origin = {box.x, box.y + Px(f32(box.h) * time)}
		case .Right: origin = {box.x + box.w, box.y + Px(f32(box.h) * time)}
		case .Top: origin = {box.x + Px(f32(box.w) * time), box.y}
	}
	// Add the objcet
	add_object(doc, Object({
		origin = {origin.x, origin.y},
		info = info,
		data = Text_Object_Data{
			size = size,
		},
	}))
}
add_text :: proc(doc: ^Document, side: Side, info: Text_Object_Info, loc := #caller_location) {
	assert(doc.font_exists[info.font], "That font doesn't exist!", loc)
	layout := current_layout(doc)
	// Calculate origin
	origin: [2]Px
	size := measure_text_object(doc, info)
	box := cut_box(&layout.box, side, size[int(side) / 2])
	switch info.align {
		case .Left: origin.x = box.x
		case .Center: origin.x = box.x + box.w / 2
		case .Right: origin.x = box.x + box.w
	}
	switch info.baseline {
		case .Top: origin.y = box.y
		case .Center: origin.y = box.y + box.h / 2
		case .Bottom: origin.y = box.y + box.h
	}
	// Add the objcet
	add_object(doc, Object({
		origin = {origin.x, origin.y},
		info = info,
		data = Text_Object_Data{
			size = size,
		},
	}))
}
add_space :: proc(doc: ^Document, side: Side, space: Unit) {
	layout := current_layout(doc)
	pixel_space := get_exact_value(doc, space)
	cut_box(&layout.box, side, pixel_space)
}
add_divider :: proc(doc: ^Document, side: Side, size: Unit) {
	layout := current_layout(doc)
	pixel_size := get_exact_value(doc, size)
	box := cut_box(&layout.box, side, pixel_size)
	add_object(doc, Object({
		origin = {box.x, box.y},
		info = Box_Object_Info{
			size = {box.w, box.h},
			fill_style = {0, 0, 0, 255},
		},
	}))
}
pop_layout :: proc(doc: ^Document) {
	pop_stack(&doc.layout)
}