class_name BoardLayout
extends RefCounted

var columns: int = 0
var cell_size: Vector2 = Vector2.ZERO
var bottom_row_y: float = 0.0
var design_width: float = 0.0
var danger_line_y: float = 0.0

func configure(config: GameConfig) -> void:
	columns = config.board_columns
	cell_size = config.board_cell_size
	bottom_row_y = config.board_bottom_row_y
	design_width = config.design_size.x
	danger_line_y = config.board_danger_line_y

func get_cell_center(cell: Vector2i) -> Vector2:
	var board_width: float = float(columns) * cell_size.x
	var left_x: float = (design_width - board_width) * 0.5
	return Vector2(left_x + (float(cell.x) + 0.5) * cell_size.x, bottom_row_y - float(cell.y) * cell_size.y)

func get_cell_top_y(cell: Vector2i) -> float:
	return get_cell_center(cell).y - cell_size.y * 0.5

func is_valid_column(column: int) -> bool:
	return column >= 0 and column < columns
