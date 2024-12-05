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
var points: Array[Vector2]
var pressures: Array[float]

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
	return "Color: %s, Size: %d, Points: %s" % [color, size, points]

# -------------------------------------------------------------------------------------------------
func add_point(point: Vector2, pressure: float) -> void:
	# Smooth out pressure values (on Linux i sometimes get really high pressure spikes)
	if !pressures.is_empty():
		var last_pressure: float = pressures.back()
		var pressure_diff := pressure - last_pressure
		if abs(pressure_diff) > MAX_PRESSURE_DIFF:
			pressure = last_pressure + sign(pressure_diff) * MAX_PRESSURE_DIFF
	pressure = clamp(pressure, MIN_PRESSURE_VALUE, MAX_PRESSURE_VALUE)
	
	points.append(point)
	pressures.append(pressure)

# ------------------------------------------------------------------------------------------------
func remove_last_point() -> void:
	if !points.is_empty():
		points.pop_back()
		pressures.pop_back()
		_line2d.points.remove_at(_line2d.points.size() - 1)
		_line2d.width_curve.remove_point(_line2d.width_curve.get_point_count() - 1)

# ------------------------------------------------------------------------------------------------
func remove_all_points() -> void:
	if !points.is_empty():
		points.clear()
		pressures.clear()
		_line2d.points = PackedVector2Array()
		_line2d.width_curve.clear_points()

# ------------------------------------------------------------------------------------------------
func refresh() -> void:
	_line2d.clear_points()
	_line2d.width_curve.clear_points()
	
	if points.is_empty():
		return
	
	_line2d.default_color = color
	_line2d.width = size
	
	var p_idx := 0
	var curve_step: float = 1.0 / pressures.size()
	for point: Vector2 in points:
		# Add the point
		_line2d.add_point(point)
		var pressure: float = pressures[p_idx]
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
	points.clear()
	pressures.clear()
	_line2d.clear_points()
	_line2d.width_curve.clear_points()
