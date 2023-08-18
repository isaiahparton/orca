package orca

Fill_Style :: Color
Stroke_Style :: struct {
	color: Color,
	thickness: Unit,
}

Object :: struct {
	order: int,
	origin: [2]Px,
	box: Box,
	info: Object_Info,
	data: Object_Data,
}

destroy_object :: proc(obj: ^Object) {
	#partial switch v in &obj.info {
		case Image_Object_Info: 
		destroy_image(&v.image)
	}
}

Image_Object_Info :: struct {
	size: [2]Px,
	image: Image,
	tint: Color,
}

// A basic box
Box_Object_Info :: struct {
	size: [2]Px,
	roundness: Unit,
	fill_style: Fill_Style,
	stroke_style: Stroke_Style,
}

// A basic ellipse
Ellipse_Object_Info :: struct {
	size: [2]Px,
	fill_style: Fill_Style,
	stroke_style: Stroke_Style,
}

Object_Data :: union {
	Text_Object_Data,
}
Object_Info :: union {
	Text_Object_Info,
	Box_Object_Info,
	Ellipse_Object_Info,
	Image_Object_Info,
}