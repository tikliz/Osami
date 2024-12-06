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
		var line_diff := calculate_score_straight_line(_canvas._strokes[0], _canvas._targetStrokes[0])
		print(line_diff)
		_canvas._active_tool.clear_prev_strokes()
		_canvas._strokes_randomizer.clear() 
	

func calculate_line_similarity(hand_drawn: Array[Vector2], line_start: Vector2, line_end: Vector2) -> float:
	var total_distance = 0.0
	var count = hand_drawn.size()
	if hand_drawn[0] - line_start < hand_drawn[0] - line_end:
		var temp_line_start = line_start
		line_start = line_end
		line_end = temp_line_start
	
	for point in hand_drawn:
		var distance = abs(
			(line_end.y - line_start.y) * point.x 
			- (line_end.x - line_start.x) * point.y 
			+ line_end.x * line_start.y 
			- line_end.y * line_start.x
		) / sqrt(pow(line_end.y - line_start.y, 2) + pow(line_end.x - line_start.x, 2))
		total_distance += distance
	
	return total_distance / count  # Return the average distance


# calculate the distance between two points
func distance(point1: Vector2, point2: Vector2) -> float:
	return sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2))

# calculate the score for an strait line
func calculate_score_straight_line(line_data: BrushStroke, target_line: BrushStroke) -> float:
	
	# check if the line is completed before calculating anything
	if !has_line_completed(line_data, target_line): return 0
	var points = line_data.data
	# calculate sum of all points to target distances multiplicated by the weight
	var sum = 0.0
	for i in range(points.size() - 1):
		#var point_data = line_data[i]
		#var point_data_next = line_data[i + 1]
		var weight = points[i + 1].timestamp - points[i].timestamp
		sum += line_min_distance(points[i].pos, target_line) * weight

	# Last point edge case
	sum += line_min_distance(points[-1].pos, target_line) * (points[-1].pos - points[-2].pos).length()

	# calculate total weigth for the the line average, in order to normalize the score 
	var time_delta = (points[-1].timestamp - points[0].timestamp);
	
	return sum / time_delta

# calculate the min distance of the point to the target line considering bounds
func line_min_distance(point: Vector2, line: BrushStroke) -> float:
	# calculate the angle of the target line and the point to the start and end
	var target_line_angle = calculate_angle(line.start, line.end)
	var end_angle = calculate_angle(point, line.end)
	var start_angle = calculate_angle(point, line.start)
	
	# calculate the angle to check if the point is out of bonds of the target line
	var angle_barrier = 2 * target_line_angle + PI / 2
	
	# this is relative to the end and start position on the canvas some times the comparison must be reversed 
	# needs testing to determine the correct approach and order of comparison
	# if its outof the bounds do a sinple distance calculation
	if(angle_barrier < end_angle): return distance(point, line.start)
	if(angle_barrier < start_angle): return distance(point, line.end)


	# if the point is within the bounds calculate the distance with default formula
	return abs((line.end.y - line.start.y) * point.x - (line.end.x - line.start.x) * point.y + line.end.x * line.start.y - line.end.y * line.start.x)

# calculate the angle between two points
func calculate_angle(point1: Vector2, point2: Vector2) -> float:
	return atan2(point2.y - point1.y, point2.x - point1.x)


# function to check if the line is completed sucefully 
# for osu calculations i have no idea how to make this
func has_line_completed(line_data: BrushStroke, target_line: BrushStroke, tolerance: int = 25) -> bool:
	var distance_start_min = 9223372036854775807
	var distance_end_min = 9223372036854775807
	
	# calculate the distance of all points distances to the start and end of target line
	for point in line_data.data:
		distance_start_min = min(distance_start_min, line_min_distance(point.pos, target_line))
		distance_end_min = min(distance_end_min, line_min_distance(point.pos, target_line))
	
	return distance_start_min < tolerance && distance_end_min < tolerance


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
