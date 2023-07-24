package orca

import "core:fmt"
import "core:mem"

Color :: [4]u8

blend_colors :: proc(dst, src, tint: Color) -> (out: Color) {
	out = 255

	src := src
	src.r = u8((u32(src.r) * (u32(tint.r) + 1)) >> 8)
	src.g = u8((u32(src.g) * (u32(tint.g) + 1)) >> 8)
	src.b = u8((u32(src.b) * (u32(tint.b) + 1)) >> 8)
	src.a = u8((u32(src.a) * (u32(tint.a) + 1)) >> 8)

	if (src.a == 0) {
		out = dst
	} else if src.a == 255 {
		out = src
	} else {
		alpha := u32(src.a) + 1
		out.a = u8((u32(alpha) * 256 + u32(dst.a) * (256 - alpha)) >> 8)

		if out.a > 0 {
			out.r = u8(((u32(src.r) * alpha * 256 + u32(dst.r) * u32(dst.a) * (256 - alpha)) / u32(out.a)) >> 8)
			out.g = u8(((u32(src.g) * alpha * 256 + u32(dst.g) * u32(dst.a) * (256 - alpha)) / u32(out.a)) >> 8)
			out.b = u8(((u32(src.b) * alpha * 256 + u32(dst.b) * u32(dst.a) * (256 - alpha)) / u32(out.a)) >> 8)
		}
	}
	return
}

Image :: struct {
	data: []u8,
	width, 
	height: Px,
	channels: int,
}

create_image :: proc(width, height, channels: int, color: Color) -> Image {
	image: Image

	image.data = make([]u8, width * height * channels)
	if color != {} {
		for i in 0..<len(image.data) {
			image.data[i] = color[i % 4]
		}
	}
	image.width = width
	image.height = height
	image.channels = channels

	return image
}

get_image_pixel :: proc(img: Image, x, y: Px) -> (res: Color) {
	assert(img.channels < 5)
	res = 255
	i := x + y * img.width
	for j in 0..<img.channels {
		res[j] = img.data[i + j]
	}
	return
}
set_image_pixel :: proc(img: Image, x, y: Px, color: Color) {
	assert(img.channels < 5)
	i := x + y * img.width
	for j in 0..<img.channels {
		img.data[i + j] = color[j]
	}
}
paint_image_on_image :: proc(src, dst: Image, src_box, dst_box: Box, tint: Color) {
	assert(dst.data != nil && src.data != nil)
	for y in dst_box.origin.y..<min(Px(dst.height), dst_box.origin.y + dst_box.size.y) {
		y_norm := f32(y - dst_box.origin.y) / f32(dst_box.size.y)
		for x in dst_box.origin.x..<min(Px(dst.width), dst_box.origin.x + dst_box.size.x) {
			x_norm := f32(x - dst_box.origin.x) / f32(dst_box.size.x)

			src_x := Px(f32(src_box.origin.x) + x_norm * f32(src_box.size.x))
			src_y := Px(f32(src_box.origin.y) + y_norm * f32(src_box.size.y))

			color := blend_colors(get_image_pixel(dst, x, y), get_image_pixel(src, src_x, src_y), 255)
			set_image_pixel(dst, x, y, color)
		}
	}
}