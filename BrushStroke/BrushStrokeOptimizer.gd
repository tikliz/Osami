class_name BrushStrokeOptimizer

# -------------------------------------------------------------------------------------------------
const ANGLE_THRESHOLD := 0.5  # Adjust to radians if using radians
const MIN_DISTANCE := 4.0

# -------------------------------------------------------------------------------------------------
var points_removed := 0

# -------------------------------------------------------------------------------------------------
func reset() -> void:
	points_removed = 0

# -------------------------------------------------------------------------------------------------
func optimize(s: BrushStroke) -> void:
	if s.points.size() < 8:
		return

	var filtered_points: Array[Vector2] = []
	var filtered_pressures: Array[float] = []

	filtered_points.append(s.points.front())
	filtered_pressures.append(s.pressures.front())

	var previous_angle := 0.0

	for i: int in range(1, s.points.size()):
		var prev_point := s.points[i - 1]
		var point := s.points[i]
		var pressure := s.pressures[i]

		var distance := prev_point.distance_to(point)
		var angle_diff: float = abs(prev_point.angle_to(point) - previous_angle)

		if distance > MIN_DISTANCE or angle_diff >= ANGLE_THRESHOLD:
			filtered_points.append(point)
			filtered_pressures.append(pressure)
			previous_angle = prev_point.angle_to(point)  # Update only when a point is added
		else:
			points_removed += 1

	# Add back the last point if it's not already included
	if filtered_points.size() > 0 and !filtered_points.back().is_equal_approx(s.points.back()):
		filtered_points.append(s.points.back())
		filtered_pressures.append(s.pressures.back())

	s.points = filtered_points
	s.pressures = filtered_pressures
