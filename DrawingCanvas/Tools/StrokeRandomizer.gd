class_name StrokeRandomizer
extends Node


@export var pressure_curve: Curve
const stroke_types := preload("res://BrushStroke/StrokeTypes.gd")

var _canvas: DrawingCanvas
var _current_stroke: BrushStroke

const CANVAS_X_OFFSET := Vector2(90, 90)
const CANVAS_Y_OFFSET := Vector2i(-90, 0)
const LINE_DEGREE_RANGE := 5
const BEZIER_STEPS := 50

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_canvas = get_parent()

func generate_strokes(point_count: int = 2, line_type: Types.LineType = Types.LineType.RANDOM):
	if point_count < 2:
		point_count = 2
	if line_type == Types.LineType.RANDOM:
		var valid_types = [Types.LineType.STRAIGHT, Types.LineType.BEZIER, Types.LineType.CIRCLE]
		line_type = valid_types[randi() % valid_types.size()]
	start_stroke(_canvas._brush_size, DefaultSettings.DEFAULT_TARGET_COLOR)
	var center := Vector2i(_canvas.size / 2)
	#TODO get from settings or ratio from screen size
	var area_size := Vector2(512, 384)
	var prev_point := Vector2(
		int(center.x + randf() * area_size.x - area_size.x / 2),
		int(center.y + randf() * area_size.y - area_size.y / 2))
	_current_stroke.add_point(prev_point, randf_range(.15, 1.0))
	weighted_gen(point_count, line_type, prev_point)
	
	end_stroke()

func weighted_gen(point_count: int, line_type: Types.LineType, prev_point: Vector2) -> void:
	if point_count < 2:
		return
	
	var total_weights := 0
	for weight in stroke_types.LINE_DIRECTION_WEIGHTS.values():
		total_weights += weight
		
	var rand_value := randi_range(0, total_weights)
	
	var cumulative := 0
	var direction_type := stroke_types.LineDirection.HORIZONTAL
	for direction in stroke_types.LINE_DIRECTION_WEIGHTS.keys():
		cumulative += stroke_types.LINE_DIRECTION_WEIGHTS[direction]
		if rand_value < cumulative:
			direction_type = direction
			break
	
	var new_point := Vector2.ZERO
	match line_type:
		Types.LineType.STRAIGHT:
			_current_stroke._line_form = Types.LineType.STRAIGHT
			generate_constrained_point(prev_point, direction_type)
		Types.LineType.BEZIER:
			_current_stroke._line_form = Types.LineType.BEZIER
			generate_bezier_points(prev_point, direction_type)
		Types.LineType.CIRCLE:
			#TODO
			_current_stroke._line_form = Types.LineType.CIRCLE
			pass
	
	prev_point = new_point
	point_count -= 1
	weighted_gen(point_count, line_type, prev_point)

func calculate_direction(direction: StrokeTypes.LineDirection) -> Vector2:
	var base_angle := 0.0
	match direction:
		stroke_types.LineDirection.HORIZONTAL:
			base_angle = 0 if randf() < 0.5 else PI
		stroke_types.LineDirection.VERTICAL:
			base_angle = PI / 2 if randf() < 0.5 else -PI / 2
		stroke_types.LineDirection.FREEFORM:
			base_angle = randf_range(0, 2 * PI)
	
	var angle_offset := deg_to_rad(randf_range(-LINE_DEGREE_RANGE, LINE_DEGREE_RANGE))
	var final_angle := base_angle + angle_offset
	var direction_vector := Vector2(cos(final_angle), sin(final_angle))
	return direction_vector

func generate_constrained_point(prev_point: Vector2, direction: StrokeTypes.LineDirection) -> void:
	var direction_vector := calculate_direction(direction)
	
	var distance := randf_range(100, _canvas.size.x) 
	var new_point: Vector2 = prev_point + direction_vector * distance
	new_point = new_point.clamp(Vector2.ZERO + CANVAS_X_OFFSET, _canvas._viewport.size + CANVAS_Y_OFFSET)
	
	_current_stroke.add_point(new_point, randf_range(0.15, 1.0))

func generate_bezier_points(prev_point: Vector2, direction: StrokeTypes.LineDirection) -> void:
	var direction_vector := calculate_direction(direction)
	var distance := randf_range(100, _canvas.size.x) 
	var new_point: Vector2 = prev_point + direction_vector * distance
	new_point = new_point.clamp(Vector2.ZERO + CANVAS_X_OFFSET, _canvas._viewport.size + CANVAS_Y_OFFSET)
	
	var control_offset := Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var control_point := (prev_point + new_point) / 2 + control_offset
	control_point = control_point.clamp(Vector2.ZERO + CANVAS_X_OFFSET, _canvas._viewport.size + CANVAS_Y_OFFSET)
	
	var curve_points := calculate_quadratic_bezier_points(prev_point, new_point, control_point, BEZIER_STEPS)
	for point in curve_points:
		_current_stroke.add_point(point, randf_range(.15, 1.0))
	

func calculate_quadratic_bezier_points(start: Vector2, end: Vector2, control_point: Vector2, steps: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(steps + 1):
		points.append(Utils.quadratic_bezier(start, end, control_point, i / float(steps)))
	return points

func start_stroke(s: int = _canvas._brush_size, c: Color = _canvas._brush_color) -> void:
	_current_stroke = _canvas.BRUSH_STROKE.instantiate()
	_current_stroke.size = s
	_current_stroke.color = c
	_canvas._target_optimizer.reset()

func end_stroke() -> void:
	if _current_stroke != null:
		var points: Array = _current_stroke.data
		if points.size() <= 1 || (points.size() == 2 && points.front().pos.is_equal_approx(points.back().pos)):
			_canvas._target_strokes_parent.add_child(_current_stroke)
			_current_stroke.queue_free()
			_current_stroke = null
			return
	_canvas._target_strokes_parent.add_child(_current_stroke)
	_canvas._targetStrokes.append(_current_stroke)
	_current_stroke = null

func clear() -> void:
	_canvas._targetStrokes.clear()
	for child in _canvas._target_strokes_parent.get_children():
		child.queue_free()
