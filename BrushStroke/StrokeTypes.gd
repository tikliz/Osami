extends Node
class_name StrokeTypes


enum LineDirection {
	VERTICAL,
	HORIZONTAL,
	FREEFORM
}

const LINE_DIRECTION_WEIGHTS = {
	LineDirection.VERTICAL: 40,
	LineDirection.HORIZONTAL: 40,
	LineDirection.FREEFORM: 20
}
