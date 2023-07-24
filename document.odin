package orca

MAX_FONTS :: 128
MAX_LAYOUTS :: 128

Document :: struct {
	// Pixels per inch
	ppi: Pixels,
	// Owned objects
	objects: [dynamic]Object,
	pages: [dynamic]Page,
	// Font data
	font_exists: [MAX_FONTS]bool,
	fonts: [MAX_FONTS]Font,
	// Current options
	stroke_style: Stroke_Style,
	fill_style: Fill_Style,
	text_style: Text_Style,
	// Layout
	layout: Stack(Layout, MAX_LAYOUTS),
	text_layout: Stack(Text_Layout, MAX_LAYOUTS),
}

add_page :: proc(doc: ^Document, size: [2]Unit, background: Color) -> (page: ^Page, ok: bool) {
	append(&doc.pages, create_page(doc, size, background))
	page = &doc.pages[len(doc.pages) - 1]
	ok = true
	return
}

add_object :: proc(doc: ^Document, obj: Object) {
	append(&doc.objects, obj)
}

current_layout :: proc(doc: ^Document) -> ^Layout {
	return &doc.layout.items[doc.layout.height - 1]
}
push_layout :: proc(doc: ^Document, origin, size: [2]Unit) {
	layout: Layout = {
		box = {
			origin = get_exact_values(doc, origin),
			size = get_exact_values(doc, size),
		},
	}
	push_stack(&doc.layout, layout)
}
pop_layout :: proc(doc: ^Document) {
	pop_stack(&doc.layout)
}