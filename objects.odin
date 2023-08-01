package orca

Fill_Style :: Color
Stroke_Style :: struct {
	color: Color,
	thickness: Unit,
}

Object :: struct {
	order: int,
	origin: [2]Unit,
	box: Box,
	info: Object_Info,
	state: Object_Data,
}

Image_Object_Info :: struct {
	size: [2]Unit,
	image: Image,
}

// A basic box
Box_Object_Info :: struct {
	size: [2]Unit,
	roundness: Unit,
	fill_style: Fill_Style,
	stroke_style: Stroke_Style,
}

// A basic ellipse
Ellipse_Object_Info :: struct {
	size: [2]Unit,
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
}