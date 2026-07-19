class_name BoardState
extends RefCounted

var _cells: Dictionary = {}
var _cell_by_obstacle_id: Dictionary = {}

func register_obstacle(obstacle_id: int, cell: Vector2i) -> bool:
	if _cells.has(cell):
		return false
	_cells[cell] = obstacle_id
	_cell_by_obstacle_id[obstacle_id] = cell
	return true

func release_obstacle(obstacle_id: int) -> void:
	if not _cell_by_obstacle_id.has(obstacle_id):
		return
	var cell: Vector2i = _cell_by_obstacle_id[obstacle_id] as Vector2i
	_cells.erase(cell)
	_cell_by_obstacle_id.erase(obstacle_id)

func advance_rows() -> Dictionary:
	var advanced_cells: Dictionary = {}
	for cell: Vector2i in _cells.keys():
		var obstacle_id: int = _cells[cell] as int
		# 棋盘行号向上增长；屏幕坐标的 y 则由 BoardLayout 在映射时反向换算。
		var advanced_cell: Vector2i = cell + Vector2i(0, 1)
		advanced_cells[advanced_cell] = obstacle_id
		_cell_by_obstacle_id[obstacle_id] = advanced_cell
	_cells = advanced_cells
	return _cell_by_obstacle_id.duplicate()

func get_cell_for_obstacle(obstacle_id: int) -> Vector2i:
	return _cell_by_obstacle_id.get(obstacle_id, Vector2i(-1, -1)) as Vector2i

func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _cells.keys():
		cells.append(cell)
	return cells

func get_obstacle_count() -> int:
	return _cells.size()
