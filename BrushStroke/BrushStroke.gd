extends Node2D
class_name BrushStroke

# ------------------------------------------------------------------------------------------------
const MAX_POINTS 			:= 1000
const MAX_PRESSURE_DIFF 	:= 0.05
const MIN_PRESSURE_VALUE 	:= 0.1
const MAX_PRESSURE_VALUE 	:= 1.0
const COLLIDER_NODE_NAME 	:= "StrokeCollider"
const GROUP_ONSCREEN 		:= "onscreen_stroke"

const MAX_VECTOR2 := Vector2(2147483647, 2147483647)
const MIN_VECTOR2 := -MAX_VECTOR2

# ------------------------------------------------------------------------------------------------
@onready var _line2d: Line2D = $Line2D

var color: Color: get = get_color, set = set_color
var size: int
var data: Array[Types.StrokePoint] = []
var last: 
	get: return data.front().pos
var first: 
	get: return data.back().pos

# ------------------------------------------------------------------------------------------------
func _ready() -> void:
	_line2d.width_curve = Curve.new()
	_line2d.texture = BrushStrokeTexture.texture
	
	var rounding_mode: int = DefaultSettings.DEFAULT_BRUSH_ROUNDING_MODE
	
	match rounding_mode:
		Types.BrushRoundingType.FLAT:
			_line2d.end_cap_mode = Line2D.LINE_CAP_NONE
			_line2d.begin_cap_mode = Line2D.LINE_CAP_NONE
		Types.BrushRoundingType.ROUNDED:
			_line2d.end_cap_mode = Line2D.LINE_CAP_ROUND
			_line2d.begin_cap_mode = Line2D.LINE_CAP_ROUND
	
	refresh()

# -------------------------------------------------------------------------------------------------
func _to_string() -> String:
	return "Color: %s, Size: %d, Points: %s" % [color, size, data.size()]

# -------------------------------------------------------------------------------------------------
func add_point(point: Vector2, pressure: float, timestamp: int = Time.get_ticks_msec()) -> void:
	# Smooth out pressure values (on Linux i sometimes get really high pressure spikes)
	if !data.is_empty():
		var last_pressure: float = data.back().pressure
		var pressure_diff := pressure - last_pressure
		if abs(pressure_diff) > MAX_PRESSURE_DIFF:
			pressure = last_pressure + sign(pressure_diff) * MAX_PRESSURE_DIFF
	pressure = clamp(pressure, MIN_PRESSURE_VALUE, MAX_PRESSURE_VALUE)
	
	var stroke_point := Types.StrokePoint.new()
	stroke_point.pos = point
	stroke_point.pressure = pressure
	stroke_point.timestamp = timestamp
	data.append(stroke_point)

# ------------------------------------------------------------------------------------------------
func remove_last_point() -> void:
	if !data.is_empty():
		data.pop_back()
		_line2d.points.remove_at(_line2d.points.size() - 1)
		_line2d.width_curve.remove_point(_line2d.width_curve.get_point_count() - 1)

# ------------------------------------------------------------------------------------------------
func remove_all_points() -> void:
	if !data.is_empty():
		data.clear()
		_line2d.points = PackedVector2Array()
		_line2d.width_curve.clear_points()

# ------------------------------------------------------------------------------------------------
func refresh() -> void:
	_line2d.clear_points()
	_line2d.width_curve.clear_points()
	
	if data.is_empty():
		return
	
	_line2d.default_color = color
	_line2d.width = size
	
	var p_idx := 0
	var curve_step: float = 1.0 / data.size()
	for point in data:
		# Add the point
		_line2d.add_point(point.pos)
		var pressure: float = point.pressure
		_line2d.width_curve.add_point(Vector2(curve_step * p_idx, pressure / MAX_PRESSURE_VALUE))
		p_idx += 1
		

# -------------------------------------------------------------------------------------------------
func set_color(c: Color) -> void:
	color = c
	if _line2d != null:
		_line2d.default_color = color

# -------------------------------------------------------------------------------------------------
func get_color() -> Color:
	return color

# -------------------------------------------------------------------------------------------------
func clear() -> void:
	data.clear()
	_line2d.clear_points()
	_line2d.width_curve.clear_points()
