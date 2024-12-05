extends SubViewportContainer
class_name DrawingCanvas

const BRUSH_STROKE = preload("res://BrushStroke/BrushStroke.tscn")

var _background_color: Color
var info = Types.CanvasInfo.new()
var _is_enabled := false
var _brush_size = DefaultSettings.DEFAULT_BRUSH_SIZE: set = set_brush_size
var _brush_color = DefaultSettings.DEFAULT_BRUSH_COLOR
var _current_stroke: BrushStroke
var _optimizer: BrushStrokeOptimizer
var _target_optimizer: BrushStrokeOptimizer
var _strokes: Array[BrushStroke] = []
var _targetStrokes: Array[BrushStroke] = []
# change based on tool
var _use_optmizer := false

@onready var _grid: DrawingCanvasGrid = $SubViewport/Grid
@onready var _strokes_parent: Node2D = $SubViewport/Strokes
@onready var _target_strokes_parent: Node2D = $SubViewport/TargetStrokes
@onready var _default_pressure_curve := load("res://DrawingCanvas/default_pressure_curve.tres")
@onready var _constant_pressure_curve := load("res://DrawingCanvas/constant_pressure_curve.tres")
@onready var _viewport: SubViewport = $SubViewport
@onready var _strokes_randomizer: StrokeRandomizer = $StrokeRandomizer
@onready var _brush_tool: BrushTool = $BrushTool
@onready var _active_tool: CanvasTool = _brush_tool

func set_background_color(color: Color) -> void:
	_background_color = color
	RenderingServer.set_default_clear_color(_background_color)
	_grid.set_canvas_color(_background_color)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#TODO get from settings file
	set_background_color(DefaultSettings.DEFAULT_CANVAS_COLOR)
	_optimizer = BrushStrokeOptimizer.new()
	_target_optimizer = BrushStrokeOptimizer.new()
	
	_brush_size = DefaultSettings.DEFAULT_BRUSH_SIZE
	_active_tool._on_brush_size_changed(_brush_size)
	_active_tool.enabled = false
	
	var constant_pressure: bool = DefaultSettings.DEFAULT_CONSTANT_PRESSURE
		
	if constant_pressure:
		_brush_tool.pressure_curve = _constant_pressure_curve
	else:
		_brush_tool.pressure_curve = _default_pressure_curve

# -------------------------------------------------------------------------------------------------
func _unhandled_key_input(event: InputEvent) -> void:
	_process_event(event)

# -------------------------------------------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	_process_event(event)

func _process_event(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		info.current_pressure = event.pressure
	
	if !get_tree().root.get_viewport().is_input_handled():
		if _active_tool.enabled:
			if Input.is_action_just_pressed("clear_strokes"):
				_active_tool.clear_prev_strokes()
			if Input.is_action_just_pressed("generate_rand_stroke"):
				_strokes_randomizer.generate_strokes()
				get_tree().root.get_viewport().set_input_as_handled()
			_active_tool.tool_event(event)


func center_to_mouse() -> void:
	if _active_tool != null:
		var screen_space_cursor_pos := _viewport.get_mouse_position()


func use_tool(tool_type: int) -> void:
	var prev_tool := _active_tool
	var prev_status := prev_tool.enabled


func enable_grid(e: bool) -> void:
	_grid.enable(e)

func enable() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_active_tool.get_cursor().update_position()
	_active_tool.enabled = true
	_is_enabled = true

func disable() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_active_tool.enabled = false
	_is_enabled = false

func add_stroke(stroke: BrushStroke) -> void:
	_strokes.append(stroke)
	_strokes_parent.add_child(stroke)
	info.point_count += stroke.points.size()
	info.stroke_count += 1

func add_stroke_point(point: Vector2, pressure := 1.0) -> void:
	_current_stroke.add_point(point, pressure)
	if _use_optmizer:
		_optimizer.optimize(_current_stroke)
	_current_stroke.refresh()

# -------------------------------------------------------------------------------------------------
func remove_last_stroke_point() -> void:
	_current_stroke.remove_last_point()

# -------------------------------------------------------------------------------------------------
func remove_all_stroke_points() -> void:
	_current_stroke.remove_all_points()

func is_drawing() -> bool:
	return _current_stroke != null 

func start_stroke() -> void:
	_current_stroke = BRUSH_STROKE.instantiate()
	_current_stroke.size = _brush_size
	_current_stroke.color = _brush_color
	
	_strokes_parent.add_child(_current_stroke)
	_optimizer.reset()

func end_stroke() -> void:
	if _current_stroke != null:
		var points: Array = _current_stroke.points
		if points.size() <= 1 || (points.size() == 2 && points.front().is_equal_approx(points.back())):
			_strokes_parent.remove_child(_current_stroke)
			_current_stroke.queue_free()
		_strokes.append(_current_stroke)
	_current_stroke = null

func set_brush_size(s: int) -> void:
	_brush_size = s
	if _active_tool != null:
		_active_tool._on_brush_size_changed(_brush_size)

func set_brush_color(color: Color) -> void:
	_brush_color = color
	if _active_tool != null:
		_active_tool._on_brush_color_changed(_brush_color)

func enable_constant_pressure(e: bool) -> void:
	if e:
		_brush_tool.pressure_curve = _constant_pressure_curve
	else:
		_brush_tool.pressure_curve = _default_pressure_curve

func clear_strokes() -> void:
	_strokes.clear()
	for child in _strokes_parent.get_children():
		child.queue_free()
