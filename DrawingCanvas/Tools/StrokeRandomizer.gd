class_name StrokeRandomizer
extends Node


@export var pressure_curve: Curve

var _canvas: DrawingCanvas
var _current_stroke: BrushStroke

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_canvas = get_parent()

func generate_strokes(point_count: int = 2, line_type: Types.LineType = Types.LineType.STRAIGHT):
	if point_count < 2:
		point_count = 2
	start_stroke(_canvas._brush_size, DefaultSettings.DEFAULT_TARGET_COLOR)
	var center := Vector2i(_canvas.size / 2)
	#TODO get from settings or ratio from screen size
	var area_size := Vector2(512, 384)
	var prev_point := Vector2(
		int(center.x + randf() * area_size.x - area_size.x / 2),
		int(center.y + randf() * area_size.y - area_size.y / 2))
	_current_stroke.add_point(prev_point, randf_range(0, 1.0))
	for i in range(point_count - 1):
		var new_point: Vector2
		match line_type:
			Types.LineType.STRAIGHT:
				new_point = prev_point + Vector2(randi_range(-200, 200), randi_range(-200, 200))
		
		new_point = new_point.clamp(Vector2.ZERO, _canvas.size)
		_current_stroke.add_point(new_point, randf_range(0, 1.0))
		prev_point = new_point
	end_stroke()

func start_stroke(s: int = _canvas._brush_size, c: Color = _canvas._brush_color) -> void:
	_current_stroke = _canvas.BRUSH_STROKE.instantiate()
	_current_stroke.size = s
	_current_stroke.color = c
	_canvas._target_optimizer.reset()

func end_stroke() -> void:
	if _current_stroke != null:
		var points: Array = _current_stroke.points
		if points.size() <= 1 || (points.size() == 2 && points.front().is_equal_approx(points.back())):
			_canvas._target_strokes_parent.add_child(_current_stroke)
			_current_stroke.queue_free()
			_current_stroke = null
			return
	_canvas._target_strokes_parent.add_child(_current_stroke)
	_canvas._targetStrokes.append(_current_stroke)
	for stroke in _canvas._targetStrokes:
		print(stroke.to_string())
	print("---------")
	_current_stroke = null

func clear() -> void:
	_canvas._targetStrokes.clear()
	for child in _canvas._target_strokes_parent.get_children():
		child.queue_free()
