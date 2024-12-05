extends Panel

const TARGET_ASPECT_RATIO = Vector2(512, 384)

# Parse the slider data
func parse_slider(data: String) -> Dictionary:
	var parts = data.split(",")
	var x = int(parts[0])
	var y = int(parts[1])
	var start_point = Vector2(x, y)
	var time = int(parts[2])
	var curve_data = parts[5].split("|")
	var curve_type = curve_data[0]
	var control_points = []
	curve_data.remove_at(0)
	for point in curve_data:
		var coords = point.split(":")
		control_points.append(Vector2(int(coords[0]), int(coords[1])))
	var slides = int(parts[6])
	var length = float(parts[7])
	return {
		"start_point": start_point,
		"curve_type": curve_type,
		"control_points": control_points,
		"slides": slides,
		"length": length,
		"time": time,
	}

# Process segments with repeated anchors
func process_segments(points: Array, resolution: int = 50) -> Array:
	var final_points = []
	var segment = [points[0]]

	for i in range(1, points.size()):
		if points[i] == points[i - 1]:
			# Process the current Bézier segment if it exists
			if segment.size() > 1:
				final_points += generate_bezier_points(segment, resolution)
			# Add a straight line segment
			final_points += [points[i - 1], points[i]]
			segment = [points[i]]
		else:
			segment.append(points[i])
	
	# Handle the last segment
	if segment.size() > 1:
		final_points += generate_bezier_points(segment, resolution)
	
	return final_points

# Generate Bézier curve points (Cubic Bézier in this case)
func generate_bezier_points(control_points: Array, resolution: int) -> Array:
	var points = []
	for t in range(resolution):
		var t_norm = float(t) / float(resolution)
		# Cubic Bézier formula: B(t) = (1-t)^3 * P0 + 3(1-t)^2 * t * P1 + 3(1-t) * t^2 * P2 + t^3 * P3
		if control_points.size() == 4:  # Cubic Bézier curve
			var p0 = control_points[0]
			var p1 = control_points[1]
			var p2 = control_points[2]
			var p3 = control_points[3]
			var x = (1 - t_norm) * (1 - t_norm) * (1 - t_norm) * p0.x + 3 * (1 - t_norm) * (1 - t_norm) * t_norm * p1.x + 3 * (1 - t_norm) * t_norm * t_norm * p2.x + t_norm * t_norm * t_norm * p3.x
			var y = (1 - t_norm) * (1 - t_norm) * (1 - t_norm) * p0.y + 3 * (1 - t_norm) * (1 - t_norm) * t_norm * p1.y + 3 * (1 - t_norm) * t_norm * t_norm * p2.y + t_norm * t_norm * t_norm * p3.y
			points.append(Vector2(x, y))
		elif control_points.size() == 3:  # Quadratic Bézier curve
			var p0 = control_points[0]
			var p1 = control_points[1]
			var p2 = control_points[2]
			var x = (1 - t_norm) * (1 - t_norm) * p0.x + 2 * (1 - t_norm) * t_norm * p1.x + t_norm * t_norm * p2.x
			var y = (1 - t_norm) * (1 - t_norm) * p0.y + 2 * (1 - t_norm) * t_norm * p1.y + t_norm * t_norm * p2.y
			points.append(Vector2(x, y))
	return points
	
func center_and_resize_panel():
	# Get the viewport size (program resolution)
	var viewport_size = get_viewport().size

	# Calculate the target aspect ratio
	var aspect_ratio = TARGET_ASPECT_RATIO.x / TARGET_ASPECT_RATIO.y

	# Determine scaling factors for width and height
	var scale_width = viewport_size.x / TARGET_ASPECT_RATIO.x
	var scale_height = viewport_size.y / TARGET_ASPECT_RATIO.y

	# Choose the smaller scaling factor to maintain aspect ratio
	var scale_factor = min(scale_width, scale_height)

	# Calculate the new panel size
	var panel_width = TARGET_ASPECT_RATIO.x * scale_factor
	var panel_height = TARGET_ASPECT_RATIO.y * scale_factor
	size = Vector2(panel_width, panel_height)
	
	# Center the panel
	position = Vector2((viewport_size.x - size.x) / 2, (viewport_size.y - size.y) / 2)

# Draw the slider inside the panel
func _draw():
	var slider_data = "423,190,14124,6,0,B|320:69|207:101|130:179|130:179|284:175|266:295|408:281,1,630"
	var slider = parse_slider(slider_data)

	# Combine start point and control points
	var points = [slider["start_point"]] + slider["control_points"]

	# Generate points for drawing
	var final_points = process_segments(points)

	# Find bounds of the curve
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for point in final_points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	# Calculate curve bounds
	var curve_width = max_x - min_x
	var curve_height = max_y - min_y

	# Get panel size
	var panel_size = size  # rect_size is the Panel's size
	var panel_width = panel_size.x
	var panel_height = panel_size.y

	# Calculate scale factors
	var scale_x = (panel_width - 40) / curve_width  # Subtract margin
	var scale_y = (panel_height - 40) / curve_height
	var scale = min(scale_x, scale_y)  # Maintain aspect ratio

	# Apply scaling and centering
	var margin = 20
	var offset = Vector2(min_x, min_y)  # Offset to normalize points
	var center_offset = Vector2(
		(panel_width - curve_width * scale) / 2,
		(panel_height - curve_height * scale) / 2
	)

	# Draw the curve
	for i in range(final_points.size() - 1):
		var start = final_points[i]
		var end = final_points[i + 1]

		# Normalize and scale points
		start = ((start - offset) * scale) + center_offset + Vector2(margin, margin)
		end = ((end - offset) * scale) + center_offset + Vector2(margin, margin)

		# Draw the line inside the panel
		draw_line(start, end, Color(0, 0, 1), 2)

	# Draw control points inside the panel
	for point in points:
		var normalized_point = ((point - offset) * scale) + center_offset + Vector2(margin, margin)
		draw_circle(normalized_point, 5, Color(1, 0, 0))

func _ready():
	get_tree().get_root().size_changed.connect(resize)
	resize()

func resize():
	center_and_resize_panel()
	queue_redraw()
