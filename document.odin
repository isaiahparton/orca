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
	place_side: Side,
	place_size: Unit,
	place_offset: Unit,
	// Layout
	layout: Stack(Layout, MAX_LAYOUTS),
}

destroy_document :: proc(doc: ^Document) {
	delete(doc.objects)
	for &obj in doc.objects {
		destroy_object(&obj)
	}
	for &page in doc.pages {
		destroy_page(&page)
	}
	for i in 0..<MAX_FONTS {
		if doc.font_exists[i] {
			destroy_font(&doc.fonts[i])
		}
	}
	delete(doc.pages)
	doc^ = {}
}

add_object :: proc(doc: ^Document, obj: Object) {
	append(&doc.objects, obj)
}

begin_page :: proc(doc: ^Document, size: [2]Unit, background: Color) -> (page: ^Page) {
	append(&doc.pages, create_page(doc, size, background))
	page = &doc.pages[len(doc.pages) - 1]
	push_layout(doc, {box = {0, 0, page.size.x, page.size.y}})
	return
}
end_page :: proc(doc: ^Document) {
	pop_layout(doc)
}