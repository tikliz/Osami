class_name CanvasTool
extends Node

# -------------------------------------------------------------------------------------------------
const SUBDIVISION_PERCENT := 0.16
const SUBDIVISION_THRESHHOLD := 50.0 # min length in pixels for when subdivision is required 

# -------------------------------------------------------------------------------------------------
@export var cursor_path: NodePath

var _cursor: BaseCursor
var _canvas: DrawingCanvas
var enabled := false: get = get_enabled, set = set_enabled
var performing_stroke := false
var disable_stroke := false

func _ready() -> void:
	_cursor = get_node(cursor_path)
	_canvas = get_parent()
	set_enabled(false)

func set_enabled(e: bool) -> void:
	enabled = e
	set_process(enabled)
	set_process_input(enabled)
	_cursor.set_visible(enabled)

# -------------------------------------------------------------------------------------------------
func get_enabled() -> bool:
	return enabled
	
func tool_event(event: InputEvent) -> void:
	pass
	
func get_cursor() -> BaseCursor:
	return _cursor

# -------------------------------------------------------------------------------------------------
func _on_brush_color_changed(color: Color) -> void:
	pass

# -------------------------------------------------------------------------------------------------
func _on_brush_size_changed(size: int) -> void:
	_cursor.change_size(size)

# -------------------------------------------------------------------------------------------------
func remove_all_stroke_points() -> void:
	_canvas.remove_all_stroke_points()

# -------------------------------------------------------------------------------------------------
func get_current_brush_stroke() -> BrushStroke:
	return _canvas._current_stroke

# -------------------------------------------------------------------------------------------------
func start_stroke() -> void:
	print("STROKE START")
	_canvas.start_stroke()
	performing_stroke = true

# -------------------------------------------------------------------------------------------------
func add_stroke_point(point: Vector2, pressure: float = 1.0) -> void:
	_canvas.add_stroke_point(point, pressure)

# -------------------------------------------------------------------------------------------------
func end_stroke() -> void:
	print("STROKE END")
	_canvas.end_stroke()
	performing_stroke = false

func clear_prev_strokes() -> void:
	var was_perfoming_stroke := performing_stroke
	if was_perfoming_stroke:
		end_stroke()
	_canvas.clear_strokes()
	if was_perfoming_stroke:
		start_stroke()

func reset() -> void:
	end_stroke()
