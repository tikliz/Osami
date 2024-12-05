class_name BaseCursor
extends Sprite2D

# -------------------------------------------------------------------------------------------------
var _brush_size: int
var _pressure := 1.0

# -------------------------------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_position()

# -------------------------------------------------------------------------------------------------
func update_position() -> void:
	global_position = get_global_mouse_position()

# -------------------------------------------------------------------------------------------------
func set_pressure(pressure: float) -> void:
	_pressure = pressure

# -------------------------------------------------------------------------------------------------
func change_size(value: int) -> void:
	_brush_size = value

# -------------------------------------------------------------------------------------------------
func _on_canvas_position_changed(pos: Vector2) -> void:
	update_position()

# -------------------------------------------------------------------------------------------------
func _on_zoom_changed(value: float) -> void:
	pass
