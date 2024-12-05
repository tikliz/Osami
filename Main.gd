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
		var line_diff := calculate_line_similarity(_canvas._strokes[0].points, _canvas._targetStrokes[0].points[0], _canvas._targetStrokes[0].points[1])
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
