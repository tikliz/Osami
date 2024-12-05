extends Node2D
class_name DrawingCanvasGrid

var _pattern := DefaultSettings.DEFAULT_GRID_PATTERN
var _grid_size := DefaultSettings.DEFAULT_GRID_SIZE
var _grid_color: Color


func set_canvas_color(c: Color) -> void:
	_grid_color = c * 1.25
	queue_redraw()

func _on_viewport_size_changed() -> void: queue_redraw()

func _draw() -> void:
	var size := Vector2(get_viewport().size.x, get_viewport().size.y) * 1
	var grid_size := int(ceil((_grid_size * pow(1, 0.75))))
	var offset := Vector2(0, 0)
	
	match _pattern:
		Types.GridPattern.DOTS:
			var dot_size := int(ceil(grid_size * 0.12))
			var x_start := int(offset.x / grid_size) - 1
			var x_end := int((size.x + offset.x) / grid_size) + 1
			var y_start := int(offset.y / grid_size) - 1
			var y_end := int((size.y + offset.y) / grid_size) + 1
			
			for x in range(x_start, x_end):
				for y in range(y_start, y_end):
					var pos := Vector2(x, y) * grid_size
					draw_rect(Rect2(pos.x, pos.y, dot_size, dot_size), _grid_color)
