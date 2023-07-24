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
	state: Object_State,
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
}
Text_Object_State :: struct {
	size: [2]Px,
	info: Text_Object_Info,
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

Object_State :: union {
	Text_Object_State,
}
Object_Info :: union {
	Text_Object_Info,
	Box_Object_Info,
	Ellipse_Object_Info,
}