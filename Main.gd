extends Control

@onready var _canvas = $DrawingCanvas
var gamemode = Types.Gamemode.RNG_LINES

func _ready() -> void:
	get_window().title = "Ōsami"
	
	seed(1)
	#randomize()
	
	# Set tablet driver
	#var driver: String = Settings.get_value(Settings.GENERAL_TABLET_DRIVER, DisplayServer.tablet_get_current_driver())
	#DisplayServer.tablet_set_current_driver(driver)
	get_window().files_dropped.connect(_on_files_dropped)
	_canvas.mouse_entered.connect(_on_DrawingCanvas_mouse_entered)
	_canvas.mouse_exited.connect(_on_DrawingCanvas_mouse_exited)

func _process(delta: float) -> void:
	match gamemode:
		Types.Gamemode.RNG_LINES:
			gamemode_RNG_process(delta)

func _on_DrawingCanvas_mouse_entered() -> void:
	_canvas.enable()

func _on_DrawingCanvas_mouse_exited() -> void:
	_canvas._active_tool.end_stroke()
	_canvas.disable()

func _on_files_dropped(files: PackedStringArray) -> void:
	#TODO handle dropped .osu files
	for file: String in files:
		print(file)


func gamemode_RNG_process(delta: float) -> void:
	if _canvas._targetStrokes.size() < 1:
		_canvas._strokes_randomizer.generate_strokes()
	if _canvas._targetStrokes.size() > 0 && _canvas._strokes.size() >= _canvas._targetStrokes.size():
		var line_diff := score_rounding(_canvas._strokes[0], _canvas._targetStrokes[0])
		$Panel/ScoreLabel.text = str(line_diff)
		if !has_line_completed(_canvas._strokes[0], _canvas._targetStrokes[0], 0.20):
			_canvas._active_tool.clear_prev_strokes()
			$Panel/ScoreLabel.modulate = Color.DARK_RED
			return
		$Panel/ScoreLabel.modulate = Color.WHITE
		_canvas._active_tool.clear_prev_strokes()
		_canvas._strokes_randomizer.clear()

func score_rounding(stroke: BrushStroke, target: BrushStroke) -> String:
	return "Precision: %.2f" % [100 - clampf(calculate_score_straight_line(stroke, target) * 8, 0, 100)]

func log_strokes(s: Array[BrushStroke]) -> void:
	for stroke in s:
		for i in range(stroke.data.size() - 1):
			print("Pos: %s, pressure: %.2f, timestamp: %d, timedelta: %d, distance: %.2f " % [stroke.data[i].pos, stroke.data[i].pressure, stroke.data[i].timestamp, stroke.data[i + 1].timestamp - stroke.data[i].timestamp, distance(stroke.data[i].pos, stroke.data[i + 1].pos)])

# calculate the distance between two points
func distance(point1: Vector2, point2: Vector2) -> float:
	return sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2))

# calculate the score for an strait line
func calculate_score_straight_line(line_data: BrushStroke, target_line: BrushStroke) -> float:
	
	# check if the line is completed before calculating anything
	var points = line_data.data
	# calculate sum of all points to target distances multiplicated by the weight
	var sum = 0.0
	var weight_sum = 0.0
	for i in range(points.size() - 1):
		#var point_data = line_data[i]
		#var point_data_next = line_data[i + 1]
		var point_time_delta = points[i + 1].timestamp - points[i].timestamp
		if(point_time_delta == 0): point_time_delta = 1
		var weight = distance(points[i + 1].pos, points[i].pos) / point_time_delta
		sum += line_min_distance(points[i].pos, target_line) * weight
		weight_sum += weight
		#print("min_dist: %.f, distance: %.f, sum: %d, weighted_sum: %d " % [line_min_distance(points[i].pos, target_line),distance(points[i + 1].pos, points[i].pos), sum, weight_sum])

	# Last point edge case
	#sum += line_min_distance(points[-1].pos, target_line) * (points[-1].pos - points[-2].pos).length() * 
	if(weight_sum == 0): return -1
	return (sum / weight_sum)

# calculate the min distance of the point to the target line considering bounds
func line_min_distance(point: Vector2, line: BrushStroke) -> float:
	# calculate the angle of the target line and the point to the start and end
	var target_line_angle = calculate_angle(line.start, line.end) + PI / 2
	
	var pos1 = point_location(point, line.start, target_line_angle)
	var pos2 = point_location(point, line.end, target_line_angle)
	
	if pos1 != pos2:
		return point_to_line_distance(point, line.start, line.end)
	
	return min(distance(point, line.start), distance(point, line.end))

func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	# Line segment direction
	var dx = line_end.x - line_start.x
	var dy = line_end.y - line_start.y

	# Numerator of the distance formula
	var numerator = abs(dy * point.x - dx * point.y + line_end.x * line_start.y - line_end.y * line_start.x)
	
	# Denominator of the distance formula (line segment length)
	var denominator = sqrt(dy * dy + dx * dx)
	
	# Avoid division by zero
	if denominator == 0:
		return 0
	
	# Return the perpendicular distance
	return numerator / denominator


# Determines if the point is on one side of the line defined by target_point and target_angle
func point_location(point: Vector2, target_point: Vector2, target_angle: float) -> bool:
	# Line equation components: ax + by + c = 0
	var a = sin(target_angle)
	var b = -cos(target_angle)
	var c = -(a * target_point.x + b * target_point.y)
	
	# Calculate the localization value for the point
	var localization = a * point.x + b * point.y + c
	
	# Debugging print statements to understand the localization value
	#print("Point: ", point)
	#print("Line Equation: ", "a * point.x + b * point.y + c =", localization)
	
	# If localization is positive, the point lies on one side of the line
	if localization > 0:
		return true
	
	# Otherwise, the point lies on the other side
	return false

# calculate the angle between two points
func calculate_angle(point1: Vector2, point2: Vector2) -> float:
	return atan2(point2.y - point1.y, point2.x - point1.x)

func to_degrees(angle: float) -> float:
	return angle * 180 / PI

# function to check if the line is completed sucefully 
# for osu calculations i have no idea how to make this
func has_line_completed(line_data: BrushStroke, target_line: BrushStroke, tolerance: float = 0.20) -> bool:
	var distance_start_min = INF
	var distance_end_min = INF
	var target_dist = distance(target_line.start, target_line.end) * tolerance
	# calculate the distance of all points distances to the start and end of target line
	for point in line_data.data:
		distance_start_min = min(distance_start_min, distance(point.pos, target_line.start))
		distance_end_min = min(distance_end_min, distance(point.pos, target_line.end))

	return distance_start_min < target_dist && distance_end_min < target_dist


# 1 approach if the target curve is an Array[Types.StrokeData]
func curve_min_distance(point: Vector2, curve_target: BrushStroke) -> float:
	# its more simple because you dont have to check for bounds but its more expensive because you have to calculate the distance for every point

	var min_distance = 9223372036854775807
	for i in range(curve_target.data.size() - 1):
		min_distance = min(min_distance, distance(point, curve_target.data[i].pos))
	return min_distance

# 2 approach aka osu way if the target curve is an formula
func curve_min_distance_2(point: Types.StrokePoint, curve_target: BrushStroke) -> float:
	#TODO
	# calculate de derivative of the distance of the curve to the point 
	# skull
	return 0.0
