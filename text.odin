package orca

import "core:os"
import "core:fmt"

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

Font :: struct {
	name: string,
	// Internal truetype data
	data: _Font_Data,
	// Cache important glyph data
	sizes: map[Pixels]Font_Size,
}

Font_Handle :: int

Text_Iterator :: struct {
	// Current line size
	line_size: Px,
	// Glyph offset
	offset: [2]Px,
	// Current codepoint and glyph data
	codepoint: rune,
	glyph: ^Glyph_Data,
	// Current byte index
	index: int,
}
iterate_text :: proc(it: ^Text_Iterator, doc: ^Document, info: Text_Object_Info) -> bool {
	font := &doc.fonts[info.font]
	font_size, _ := get_font_size(font, get_exact_value(doc, info.size))
	codepoint, bytes := utf8.decode_rune(info.text[it.index:])
	
	if it.glyph != nil {
		it.offset.x += it.glyph.advance
		it.line_size += it.glyph.advance
	}

	line_limit_reached: bool
	if line_limit, ok := info.line_limit.?; ok {
		if it.line_size > get_exact_value(doc, line_limit) {
			line_limit_reached = true
		}
	}

	if codepoint == '\n' || line_limit_reached || it.index == 0 {
		it.offset.x = 0
		#partial switch info.align {
			case .Center: it.offset.x -= measure_next_line(doc, info, it.index, font, font_size) / 2
			case .Right: it.offset.x -= measure_next_line(doc, info, it.index, font, font_size)
		}
	}
	if codepoint == '\n' || line_limit_reached  {
		it.offset.y += font_size.baseline + font_size.line_gap
		it.line_size = 0
	} else {
		it.glyph, _ = get_font_glyph(font, font_size, codepoint)
		it.index += bytes
		it.codepoint = codepoint
	}

	return bytes != 0
}

/*
	String processing procedures
*/
measure_next_line :: proc(doc: ^Document, info: Text_Object_Info, offset: int, font: ^Font, font_size: ^Font_Size) -> Px {
	line_limit: Maybe(Px)
	if info.line_limit != nil {
		line_limit = get_exact_value(doc, info.line_limit.?)
	}
	s := info.text[offset:]
	size: Px
	for c, i in s {
		if c == '\n' {
			if i == 0 {
				continue
			} else {
				break
			}
		} else if c != ' ' && line_limit != nil && size > line_limit.? {
			break
		}
		if glyph, ok := get_font_glyph(font, font_size, c); ok {
			size += glyph.advance
		}
	}
	return size
}
// Load a font and store it in the given document
load_font :: proc(doc: ^Document, file: string) -> (handle: Font_Handle, success: bool) {
	font: Font
	if file_data, ok := os.read_entire_file(file); ok {
		if ttf.InitFont(&font.data, transmute([^]u8)(transmute(runtime.Raw_Slice)file_data).data, 0) {
			for i in 0..<MAX_FONTS {
				if !doc.font_exists[i] {
					doc.font_exists[i] = true
					doc.fonts[i] = font
					handle = Font_Handle(i)
					success = true
					break
				}
			}
		}
	}
	return
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
			advance = Px(f32(advance) * size.scale)
		}))
		success = true
	} else {
		success = true
	}
	data = glyph_data
	return
}
// Measure text
measure_text_object :: proc(doc: ^Document, info: Text_Object_Info, font: ^Font, font_size: ^Font_Size) -> [2]Px {
	size: [2]Px
	line_size: Px
	line_limit: Maybe(Px)
	if info.line_limit != nil {
		line_limit = get_exact_value(doc, info.line_limit.?)
	}
	for codepoint in info.text {
		line_limit_reached := (line_limit != nil && line_size > line_limit.?)
		if codepoint == '\n' || line_limit_reached {
			size.x = max(size.x, line_size)
			size.y += font_size.baseline + font_size.line_gap
			line_size = 0
		} else {
			if glyph, ok := get_font_glyph(font, font_size, codepoint); ok {
				line_size += glyph.advance
			}
		}
	}
	size.y += font_size.baseline + font_size.line_gap
	return size
}
// Render text to a given image
render_text_object :: proc(doc: ^Document, target: Image, origin: [2]Px, info: Text_Object_Info) {
	origin := origin
	// Get font
	font := &doc.fonts[info.font]
	// Get font size data
	font_size, _ := get_font_size(font, get_exact_value(doc, info.size))
	// Measure the text
	size: [2]Px
	if info.baseline != .Top {
		size = measure_text_object(doc, info, font, font_size)
		#partial switch info.baseline {
			case .Center: origin.y -= size.y / 2
			case .Bottom: origin.y -= size.y
		}
	}
	// Render text
	point := origin
	it: Text_Iterator
	for iterate_text(&it, doc, info) {
		if it.codepoint != '\n' && it.codepoint != ' ' {
			for x in 0..<it.glyph.image.width {
				for y in 0..<it.glyph.image.height {
					value := it.glyph.image.data[x + y * it.glyph.image.width]
					dst_x := x + point.x + it.offset.x + it.glyph.offset.x
					dst_y := y + point.y + it.offset.y + it.glyph.offset.y
					if dst_y < 0 {
						continue
					}
					i := (dst_x + dst_y * target.width) * 4
					color: Color = {
						target.data[i],
						target.data[i+1],
						target.data[i+2],
						target.data[i+3],
					}
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