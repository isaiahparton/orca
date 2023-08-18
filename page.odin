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
	page.size = to_exact(doc, size)
	page.image = create_image(page.size.x, page.size.y, 4, background)
	return
}
destroy_page :: proc(page: ^Page) {
	destroy_image(&page.image)
	page^ = {}
}

Axis :: enum {
	H,
	V,
}
to_exact_single :: proc(doc: ^Document, value: Unit) -> Px {
	pixels: Px
	switch type in value {
		case Pc:
		pixels = Px(type)
		case Px: 
		pixels = type
		case Pt: 
		pixels = Px((type / 72.0) * Pt(doc.ppi))
		case In: 
		pixels = Px(type * In(doc.ppi))
		case Mm:
		pixels = Px(In(type / 25.4) * In(doc.ppi))
	}
	return pixels
}
to_exact_double :: proc(doc: ^Document, values: [2]Unit) -> [2]Pixels {
	pixels: [2]Pixels
	for i in 0..<2 {
		pixels[i] = to_exact(doc, values[i])
	}
	return pixels
}
to_exact :: proc {
	to_exact_single, 
	to_exact_double,
}

boxes_overlap :: proc(a, b: Box) -> bool {
	return (a.x + a.w >= b.x && a.x <= b.x + b.w && a.y + a.y >= b.y && a.y <= b.y + b.y)
}

render_page :: proc(doc: ^Document, page: ^Page) {
	render_page_region(doc, page, {w = page.size.x, h = page.size.y})
}
render_page_region :: proc(doc: ^Document, page: ^Page, region: Box) {

	region_objects: [dynamic]^Object
	defer delete(region_objects)
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
			render_text_object(doc, page.image, object.origin, region, info, object.data.(Text_Object_Data))

			case Image_Object_Info: 
			for x in 0..<info.size.x {
				for y in 0..<info.size.y {
					i := ((x + object.origin.x) + (y + object.origin.y) * page.image.width) * 4
					color: Color = {
						page.image.data[i],
						page.image.data[i+1],
						page.image.data[i+2],
						page.image.data[i+3],
					}
					color = blend_colors(color, get_image_pixel(info.image, x, y), info.tint)
					page.image.data[i] = color.r
					page.image.data[i+1] = color.g
					page.image.data[i+2] = color.b
					page.image.data[i+3] = color.a
				}
			}

			case Box_Object_Info:
			for x in 0..<info.size.x {
				for y in 0..<info.size.y {
					i := ((x + object.origin.x) + (y + object.origin.y) * page.image.width) * 4
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
			radius := max(info.size.x, info.size.y) / 2
			top_left := object.origin - radius
			bottom_right := object.origin + radius
			ratio := f32(info.size.x) / f32(info.size.y)
			for x in top_left.x..<bottom_right.x {
				for y in top_left.y..<bottom_right.y {
					nx := f32(x - object.origin.x)
					ny := f32(y - object.origin.y) * f32(info.size.x / info.size.y)
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