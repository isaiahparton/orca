package orca

import "core:fmt"
import "core:slice"
import "core:math"
import "core:math/linalg"

Page :: struct {
	doc: ^Document,
	size: [2]Pixels,
	image: Image,
}

create_page :: proc(doc: ^Document, size: [2]Unit, background: Color) -> (page: Page) {
	page.size = get_exact_values(doc, size)
	page.image = create_image(page.size.x, page.size.y, 4, background)
	return
}

get_exact_value :: proc(doc: ^Document, value: Unit) -> Px {
	pixels: Px
	#partial switch type in value {
		case Px: pixels = type
		case Pt: pixels = Px((type / 72.0) * Pt(doc.ppi))
		case In: pixels = Px(type * In(doc.ppi))
	}
	return pixels
}
get_exact_values :: proc(doc: ^Document, values: [$N]Unit) -> [N]Pixels {
	pixels: [N]Pixels
	for i in 0..<N {
		pixels[i] = get_exact_value(doc, values[i])
	}
	return pixels
}

boxes_overlap :: proc(a, b: Box) -> bool {
	return (a.origin.x + a.size.x >= b.origin.x && a.origin.x <= b.origin.x + b.size.x && a.origin.y + a.size.y >= b.origin.y && a.origin.y <= b.origin.y + b.size.y)
}

resize_document :: proc(doc: ^Document, size: [2]Unit) {
	pixel_size := get_exact_values(doc, size)
}

render_page :: proc(doc: ^Document, page: ^Page) {
	render_page_region(doc, page, {size = page.size})
}
render_page_region :: proc(doc: ^Document, page: ^Page, region: Box) {

	region_objects: [dynamic]^Object
	// Append items whos bounding boxes overlap the region
	for &object in doc.objects {
		if boxes_overlap(object.box, region) {
			append(&region_objects, &object)
		}
	}
	// Sort by draw order
	slice.sort_by(region_objects[:], proc(a, b: ^Object) -> bool {
		return a.order < b.order
	})
	// Render the items
	for object in region_objects {
		#partial switch info in object.info {
			case Text_Object_Info:
			render_text_object(doc, page.image, get_exact_values(doc, object.origin), info)

			case Box_Object_Info:
			origin := get_exact_values(doc, object.origin)
			size := get_exact_values(doc, info.size)
			for x in 0..<size.x {
				for y in 0..<size.y {
					i := ((x + origin.x) + (y + origin.y) * page.image.width) * 4
					color: Color = {
						page.image.data[i],
						page.image.data[i+1],
						page.image.data[i+2],
						page.image.data[i+3],
					}
					color = blend_colors(color, info.fill_style, 255)
					page.image.data[i] = color.r
					page.image.data[i+1] = color.g
					page.image.data[i+2] = color.b
					page.image.data[i+3] = color.a
				}
			}

			case Ellipse_Object_Info:
			origin := get_exact_values(doc, object.origin)
			size := get_exact_values(doc, info.size)
			radius := max(size.x, size.y) / 2
			top_left := origin - radius
			bottom_right := origin + radius
			ratio := f32(size.x) / f32(size.y)
			for x in top_left.x..<bottom_right.x {
				for y in top_left.y..<bottom_right.y {
					nx := f32(x - origin.x)
					ny := f32(y - origin.y) * f32(size.x / size.y)
					dist := linalg.length(([2]f32){nx, ny})
					if dist > f32(radius) {
						continue
					}
					value := u8((1.0 - max(0.0, dist - f32(radius - 1))) * 255) 
					i := (x + y * page.image.width) * 4

					color: Color = {
						page.image.data[i],
						page.image.data[i+1],
						page.image.data[i+2],
						page.image.data[i+3],
					}
					color = blend_colors(color, info.fill_style, {255, 255, 255, value})
					page.image.data[i] = color.r
					page.image.data[i+1] = color.g
					page.image.data[i+2] = color.b
					page.image.data[i+3] = color.a
				}
			}
		}
	}
}