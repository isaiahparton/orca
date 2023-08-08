package orca

Px :: i64
In :: distinct f64
Pt :: distinct f64 
Pc :: distinct f64
Mm :: distinct f64

Pixels :: Px
Inches :: In
Points :: Pt
Percent :: Pc
Millimeters :: Mm

Unit :: union #no_nil {
	Pixels,
	Inches,
	Points,
	Percent,
	Millimeters,
}

Stack :: struct($T: typeid, $N: int) {
	items: [N]T,
	height: int,
}
push_stack :: proc(stack: ^Stack($T, $N), item: T) {
	assert(stack.height < N)
	stack.items[stack.height] = item
	stack.height += 1
}
pop_stack :: proc(stack: ^Stack($T, $N)) {
	assert(stack.height > 0)
	stack.height -= 1
}