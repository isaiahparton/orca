package orca


Px :: int
In :: distinct f32
Pt :: distinct f32 
Pc :: distinct f32

Pixels :: Px
Inches :: In
Points :: Pt
Percent :: Pc

Stack :: struct($T: typeid, $N: int) {
	items: [N]T,
	height: int,
}
push_stack :: proc(stack: ^Stack($T, $N), item: T) {
	assert(stack.height < N)
	stack.items[stack.height] = item
	stack.height += 1
}
pop_stack :: proc(stack: ^Stack($T, $N)) {
	assert(stack.height > 0)
	stack.height -= 1
}

Unit :: union #no_nil {
	Pixels,
	Inches,
	Points,
	Percent,
}

Box :: struct {
	origin,
	size: [2]Pixels,
}

/*
	Esto es que será
*/

/*
	doc := create_document()
	
	header_font := load_font("Edwardian Script ITC") or_return
	default_font := load_font("Calibri") or_return
	
	set_text_style(font = header_font, size = Points(54), align = .Center)
	add_text("Header")

	add_space(Inches(0.25))
	add_divider()
	add_space(Inches(0.25))

	set_text_style(font = default_font, size = Points(11))
	add_text("Content")

	destroy_document(&doc)
*/