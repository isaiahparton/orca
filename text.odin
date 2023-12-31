package orca

import "core:os"
import "core:fmt"

import "core:time"
import "core:runtime"
import "core:strings"
import "core:math"
import "core:math/linalg"

import "core:unicode"
import "core:unicode/utf8"

import ttf "vendor:stb/truetype"

@private
_Font_Data :: ttf.fontinfo

Text_Alignment :: enum {
	Left,
	Center,
	Right,
}

Text_Baseline :: enum {
	Top,
	Center,
	Bottom,
}

Text_Style :: struct {
	underline,
	strikethrough: bool,
	size: Unit,
	align: Text_Alignment,
}

Glyph_Data :: struct {
	image: Image,
	offset: [2]Pixels,
	advance: Px,
}

Glyph_Info :: struct {
	value: rune,
	size: Pixels,
}

Font_Size :: struct {
	// Metrics
	scale: f32,
	line_gap,
	baseline: Px,
	// Glyph data
	glyphs: map[rune]Glyph_Data,
}
destroy_font_size :: proc(size: ^Font_Size) {
	for key, &value in size.glyphs {
		destroy_image(&value.image)
	}
	delete(size.glyphs)
	size^ = {}
}

Font :: struct {
	file_data: []u8,
	// Internal truetype data
	data: _Font_Data,
	// Cache important glyph data
	sizes: map[Pixels]Font_Size,
}

Font_Handle :: int

Text_Wrap :: enum {
	None,
	Normal,
	Word,
}

// Text
Text_Object_Info :: struct {
	font: Font_Handle,
	size: Unit,
	line_limit: Maybe(Unit),
	text: string,
	align: Text_Alignment,
	baseline: Text_Baseline,
	fill_style: Fill_Style,
	stroke_style: Stroke_Style,
	wrap: Text_Wrap,
}
Text_Object_Data :: struct {
	size: [2]Px,
	exact_size: Px,
	info: Text_Object_Info,
}

Text_Iterator :: struct {
	// Font
	font: ^Font,
	size: ^Font_Size,
	// Current line size
	line_limit: Maybe(Px),
	line_size: Px,
	new_line: bool,
	// Glyph offset
	offset: [2]Px,
	// Current codepoint and glyph data
	codepoint: rune,
	glyph: ^Glyph_Data,
	// Current byte index
	next_word,
	index,
	next_index: int,
	// Do offset
	do_offset: bool,
}
make_text_iterator :: proc(doc: ^Document, info: Text_Object_Info) -> (it: Text_Iterator) {
	it.font = &doc.fonts[info.font]
	it.size, _ = get_font_size(it.font, to_exact(doc, info.size))
	if line_limit, ok := info.line_limit.?; ok {
		it.line_limit = to_exact(doc, to_exact(doc, line_limit))
	}
	return
}
iterate_text :: proc(it: ^Text_Iterator, doc: ^Document, info: Text_Object_Info) -> bool {
	
	// Update index
	it.index = it.next_index
	// Decode next codepoint
	codepoint, bytes := utf8.decode_rune(info.text[it.index:])
	// Update next index
	it.next_index += bytes
	// Update horizontal offset with last glyph
	if it.new_line {
		it.line_size = 0
	}
	if it.glyph != nil {
		it.offset.x += it.glyph.advance
		it.line_size += it.glyph.advance
	}
	// Get current glyph data
	if glyph, ok := get_font_glyph(it.font, it.size, codepoint); ok {
		it.glyph = glyph
	}
	space: Px = it.glyph.advance if it.glyph != nil else 0
	if info.wrap == .Word && it.next_index >= it.next_word && codepoint != ' ' {
		j := it.next_word
		for i := it.next_word; ; {
			c, b := utf8.decode_rune(info.text[i:])
			if g, ok := get_font_glyph(it.font, it.size, codepoint); ok {
				space += g.advance
			}
			if c == ' ' || i >= len(info.text) - 1 {
				it.next_word = i + b
				break
			}
			i += b
		}
	}

	it.new_line = false
	new_line := false
	if codepoint == '\n' || (it.line_limit != nil && it.line_size + space >= it.line_limit.?) {
		if info.wrap == .None {
			return false
		} else {
			new_line = true
		}
	}
	// Update vertical offset
	if new_line {
		it.new_line = true
		it.offset.y += it.size.baseline + it.size.line_gap
	}
	// Reset offset if new line
	if it.do_offset && (new_line || it.index == 0) {
		it.offset.x = 0
		#partial switch info.align {
			case .Center: it.offset.x -= measure_next_line(doc, info, it^) / 2
			case .Right: it.offset.x -= measure_next_line(doc, info, it^)
		}
	}
	it.codepoint = codepoint
	
	return it.index < len(info.text)
}

/*
	String processing procedures
*/
measure_next_line :: proc(doc: ^Document, info: Text_Object_Info, it: Text_Iterator) -> Px {
	it := it
	it.do_offset = false
	for iterate_text(&it, doc, info) {
		if it.new_line {
			break
		}
	}
	return it.line_size
}
measure_next_word :: proc(doc: ^Document, info: Text_Object_Info, it: Text_Iterator) -> (size: Px, end: int) {
	it := it
	it.do_offset = false
	it.line_size = 0
	for iterate_text(&it, doc, info) {
		if it.codepoint == ' ' {
			break
		}
	}
	return it.line_size, it.next_index
}
// Load a font and store it in the given document
load_font :: proc(doc: ^Document, file: string) -> (handle: Font_Handle, success: bool) {
	font: Font
	if font.file_data, success = os.read_entire_file(file); success {
		if ttf.InitFont(&font.data, transmute([^]u8)(transmute(runtime.Raw_Slice)font.file_data).data, 0) {
			for i in 0..<MAX_FONTS {
				if !doc.font_exists[i] {
					doc.font_exists[i] = true
					doc.fonts[i] = font
					// Add the font to the atlas
					default_runes: []rune = {32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 0x2022}
					for r in default_runes {
						
					}

					handle = Font_Handle(i)
					success = true
					break
				}
			}
		}
	}
	return
}
destroy_font :: proc(font: ^Font) {
	for _, &size in font.sizes {
		destroy_font_size(&size)
	}
	delete(font.sizes)
	delete(font.file_data)
	font^ = {}
}
// Get the data for a given pixel size of the font
get_font_size :: proc(font: ^Font, size: Px) -> (data: ^Font_Size, ok: bool) {
	data, ok = &font.sizes[size]
	if !ok {
		data = map_insert(&font.sizes, size, Font_Size{})
		// Compute glyph scale
		data.scale = ttf.ScaleForPixelHeight(&font.data, f32(size))
		// Compute vertical metrics
		ascent, descent, line_gap: i32
		ttf.GetFontVMetrics(&font.data, &ascent, &descent, &line_gap)
		data.baseline = Px(f32(ascent) * data.scale)
		data.line_gap = Px(f32(line_gap) * data.scale)
		// Yup
		ok = true
	}
	return
}
// First creates the glyph if it doesn't exist, then returns its data
get_font_glyph :: proc(font: ^Font, size: ^Font_Size, codepoint: rune) -> (data: ^Glyph_Data, success: bool) {
	// Try fetching from map
	glyph_data, found_glyph := &size.glyphs[codepoint]
	// If the glyph doesn't exist, we create and render it
	if !found_glyph {
		// Get codepoint index
		index := ttf.FindGlyphIndex(&font.data, codepoint)
		// Get metrics
		advance, left_side_bearing: i32
		ttf.GetGlyphHMetrics(&font.data, index, &advance, &left_side_bearing)
		// Generate bitmap
		image_width, image_height, glyph_offset_x, glyph_offset_y: i32
		image_data := ttf.GetGlyphBitmap(
			&font.data, 
			size.scale, 
			size.scale, 
			index,
			&image_width,
			&image_height,
			&glyph_offset_x,
			&glyph_offset_y,
			)
		image: Image 
		if image_data != nil {
			image = {
				data = transmute([]u8)runtime.Raw_Slice({data = image_data, len = int(image_width * image_height)}),
				channels = 1,
				width = Px(image_width),
				height = Px(image_height),
			}
		}
		// Set glyph data
		glyph_data = map_insert(&size.glyphs, codepoint, Glyph_Data({
			image = image,
			offset = {Px(glyph_offset_x), Px(glyph_offset_y) + size.baseline},
			advance = Px(f32(advance) * size.scale),
		}))
		success = true
	} else {
		success = true
	}
	data = glyph_data
	return
}
// Measure text
measure_text_object :: proc(doc: ^Document, info: Text_Object_Info) -> [2]Px {
	size: [2]Px
	it := make_text_iterator(doc, info)
	for iterate_text(&it, doc, info) {
		if it.new_line {
			size.x = max(size.x, it.line_size)
			size.y += it.size.baseline + it.size.line_gap
		}
	}
	size.y += it.size.baseline + it.size.line_gap
	return size
}
// Render text to a given image
render_text_object :: proc(doc: ^Document, target: Image, origin: [2]Px, clip: Box, info: Text_Object_Info, data: Text_Object_Data) {
	origin := origin
	// Measure the text
	if info.baseline != .Top {
		#partial switch info.baseline {
			case .Center: origin.y -= data.size.y / 2
			case .Bottom: origin.y -= data.size.y
		}
	}
	// Render text
	point := origin
	it := make_text_iterator(doc, info)
	it.do_offset = true
	for iterate_text(&it, doc, info) {
		if it.codepoint != '\n' && it.codepoint != ' ' {
			dst_box: Box = {
				point.x + it.offset.x + it.glyph.offset.x,
				point.y + it.offset.y + it.glyph.offset.y,
				it.glyph.image.width,
				it.glyph.image.height,
			}
			if box, ok := clip_box(dst_box, clip); ok {
				for x in box.x..<box.x + box.w {
					for y in box.y..<box.y + box.h {
						src_x := x - dst_box.x
						src_y := y - dst_box.y
						i := int(x + y * target.width) * 4
						if i < 0 || i >= len(target.data) {
							continue
						}
						color: Color = {
							target.data[i],
							target.data[i+1],
							target.data[i+2],
							target.data[i+3],
						}
						value := it.glyph.image.data[src_x + src_y * it.glyph.image.width]
						color = blend_colors(color, info.fill_style, {255, 255, 255, value})
						target.data[i] = color.r
						target.data[i+1] = color.g
						target.data[i+2] = color.b
						target.data[i+3] = color.a
					}
				}
			}
		}
	}
}