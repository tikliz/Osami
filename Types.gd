extends Node
class_name Types

enum GridPattern {
	DOTS,
	LINES,
	NONE
}

enum BrushRoundingType {
	FLAT,
	ROUNDED
}

class CanvasInfo:
	var point_count: int
	var stroke_count: int
	var current_pressure: float

enum LineType {
	STRAIGHT,
	BEZIER,
	CIRCLE
}

enum Gamemode {
	RNG_LINES,
}

class StrokePoint:
	var pos: Vector2
	var pressure: float
	var timestamp: int
