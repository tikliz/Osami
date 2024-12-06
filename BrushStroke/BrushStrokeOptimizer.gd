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
	if s.data.size() < 8:
		return

	var filtered_points: Array[Types.StrokePoint] = []

	filtered_points.append(s.front())

	var previous_angle := 0.0

	for i: int in range(1, s.data.size()):
		var prev_point := s.data[i - 1]
		var point := s.data[i]

		var distance := prev_point.pos.distance_to(point.pos)
		var angle_diff: float = abs(prev_point.pos.angle_to(point.pos) - previous_angle)

		if distance > MIN_DISTANCE or angle_diff >= ANGLE_THRESHOLD:
			filtered_points.append(point)
			previous_angle = prev_point.pos.angle_to(point.pos)  # Update only when a point is added
		else:
			points_removed += 1

	# Add back the last point if it's not already included
	if filtered_points.size() > 0 and !filtered_points.back().is_equal_approx(s.points.back()):
		filtered_points.append(s.back())

	s.data = filtered_points
