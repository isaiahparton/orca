package orca

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:slice"
import "core:runtime"
import img "vendor:stb/image"
import "core:image/png"

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

save_image :: proc(image: Image, file: string) {
	file_cstr := strings.clone_to_cstring(file)
	img.write_png(file_cstr, i32(image.width), i32(image.height), i32(image.channels), (transmute(runtime.Raw_Slice)image.data).data, 0)
}
clone_image :: proc(img: Image) -> Image {
		return Image{
			data = slice.clone(img.data),
			width = img.width,
			height = img.height,
			channels = img.channels,
		}
}
load_image :: proc(file: string) -> (img: Image, ok: bool) {
	if _img, err := png.load_from_file(file); err == nil {
		img = Image{
			data = _img.pixels.buf[:],
			width = Px(_img.width),
			height = Px(_img.height),
			channels = _img.channels,
		}
		ok = true
	} else {
		fmt.printf("[ERROR] %v\n", err)
	}
	return
}
create_image :: proc(width, height: Px, channels: int, color: Color) -> Image {
	image: Image

	image.data = make([]u8, int(width * height) * channels)
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
destroy_image :: proc(image: ^Image) {
	delete(image.data)
	image^ = {}
}

get_image_pixel :: proc(img: Image, x, y: Px) -> (res: Color) {
	assert(img.channels < 5)
	res = 255
	i := int(x + y * img.width) * img.channels
	for j in 0..<img.channels {
		res[j] = img.data[i + j]
	}
	return
}
set_image_pixel :: proc(img: Image, x, y: Px, color: Color) {
	assert(img.channels < 5)
	i := int(x + y * img.width) * img.channels
	for j in 0..<img.channels {
		img.data[i + j] = color[j]
	}
}
paint_image_on_image :: proc(src, dst: Image, src_box, dst_box: Box, tint: Color) {
	assert(dst.data != nil && src.data != nil)
	for y in dst_box.y..<min(Px(dst.height), dst_box.y + dst_box.h) {
		y_norm := f32(y - dst_box.y) / f32(dst_box.h)
		for x in dst_box.x..<min(Px(dst.width), dst_box.x + dst_box.w) {
			x_norm := f32(x - dst_box.x) / f32(dst_box.w)

			src_x := Px(f32(src_box.x) + x_norm * f32(src_box.w))
			src_y := Px(f32(src_box.y) + y_norm * f32(src_box.h))

			color := blend_colors(get_image_pixel(dst, x, y), get_image_pixel(src, src_x, src_y), 255)
			set_image_pixel(dst, x, y, color)
		}
	}
}
paint_box_on_image :: proc(target: Image, box: Box, color: Color) {
	for y in box.y..<box.y + box.h {
		for x in box.x..<box.x + box.w {
			color := blend_colors(get_image_pixel(target, x, y), color, 255)
			set_image_pixel(target, x, y, color)
		}
	}
}