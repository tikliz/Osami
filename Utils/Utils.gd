extends Node

func cubic_bezier(start: Vector2, end: Vector2, control_point1: Vector2, control_point2: Vector2, t: float) -> Vector2:
	return (
			(1 - t) * (1 - t) * (1 - t) * start +
			3 * (1 - t) * (1 - t) * t * control_point1 +
			3 * (1 - t) * t * t * control_point2 +
			t * t * t * end
		)

func quadratic_bezier(start: Vector2, end: Vector2, control_point: Vector2, t: float) -> Vector2:
	return (
		(1 - t) * (1 - t) * start + 2 * (1 - t) * t * control_point + t * t * end
	)
