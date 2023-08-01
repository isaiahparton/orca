package orca

import "core:fmt"

Box :: struct {
	x, y, w, h: Px,
}

clip_box :: proc(box, clip: Box) -> (Box, bool) {
	if box.x > clip.x + clip.w || box.x + box.w < clip.x || box.y > clip.y + clip.h || box.y + box.h < clip.y {
		return box, false
	}
	box := box
	if clip.x > box.x {
		d := clip.x - box.x
		box.x += d
		box.w -= d
	}
	if clip.y > box.y {
		d := clip.y - box.y
		box.y += d
		box.h -= d
	}
	box.w = min(box.w, clip.w - (box.x - clip.x))
	box.h = min(box.h, clip.h - (box.y - clip.y))
	return box, true
}

// cut a box and return the cut piece
cut_box_left :: proc(box: ^Box, amount: Px) -> (result: Box) {
	amount := min(box.w, amount)
	result = {box.x, box.y, amount, box.h}
	box.x += amount
	box.w -= amount
	return
}
cut_box_top :: proc(box: ^Box, amount: Px) -> (result: Box) {
	amount := min(box.h, amount)
	result = {box.x, box.y, box.w, amount}
	box.y += amount
	box.h -= amount
	return
}
cut_box_right :: proc(box: ^Box, amount: Px) -> (result: Box) {
	amount := min(box.w, amount)
	box.w -= amount
	result = {box.x + box.w, box.y, amount, box.h}
	return
}
cut_box_bottom :: proc(box: ^Box, amount: Px) -> (result: Box) {
	amount := min(box.h, amount)
	box.h -= amount
	result = {box.x, box.y + box.h, box.w, amount}
	return
}
cut_box :: proc(box: ^Box, side: Side, amount: Px) -> Box {
	switch side {
		case .Bottom: 	return cut_box_bottom(box, amount)
		case .Top: 			return cut_box_top(box, amount)
		case .Left: 		return cut_box_left(box, amount)
		case .Right: 		return cut_box_right(box, amount)
	}
	return {}
}

// get a cut piece of a box
get_box_left :: proc(b: Box, a: Px) -> Box {
	return {b.x, b.y, a, b.h}
}
get_box_top :: proc(b: Box, a: Px) -> Box {
	return {b.x, b.y, b.w, a}
}
get_box_right :: proc(b: Box, a: Px) -> Box {
	return {b.x + b.w - a, b.y, a, b.h}
}
get_box_bottom :: proc(b: Box, a: Px) -> Box {
	return {b.x, b.y + b.h - a, b.w, a}
}
get_box :: proc(box: Box, side: Side, amount: Px) -> Box {
	switch side {
		case .Bottom: 	return get_box_bottom(box, amount)
		case .Top: 		return get_box_top(box, amount)
		case .Left: 	return get_box_left(box, amount)
		case .Right: 	return get_box_right(box, amount)
	}
	return {}
}

// attach a box
attach_box_left :: proc(box: Box, amount: Px) -> Box {
	return {box.x - amount, box.y, amount, box.h}
}
attach_box_top :: proc(box: Box, amount: Px) -> Box {
	return {box.x, box.y - amount, box.w, amount}
}
attach_box_right :: proc(box: Box, amount: Px) -> Box {
	return {box.x + box.w, box.y, amount, box.h}
}
attach_box_bottom :: proc(box: Box, amount: Px) -> Box {
	return {box.x, box.y + box.h, box.w, amount}
}
attach_box :: proc(box: Box, side: Side, size: Px) -> Box {
	switch side {
		case .Bottom: 	return attach_box_bottom(box, size)
		case .Top: 		return attach_box_top(box, size)
		case .Left: 	return attach_box_left(box, size)
		case .Right: 	return attach_box_right(box, size)
	}
	return {}
}