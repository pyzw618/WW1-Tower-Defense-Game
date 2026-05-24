extends Node2D

@export var mg_nest_scene: PackedScene
@export var artillery_scene: PackedScene
@export var path_nodes: Array[Path2D] = []
@export var towers_parent: Node2D
@export var min_distance_from_path: float = 80.0
@export var tower_tower_min_distance: float = 60.0

var _placing: bool = false
var _preview: Sprite2D = null
var _valid_position: bool = false
var _tower_scene: PackedScene = null
var _tower_cost: int = 0

signal tower_placed(tower: TowerBase)
signal placement_cancelled()

func _ready() -> void:
	_preview = Sprite2D.new()
	_preview.visible = false
	_preview.z_index = 100
	add_child(_preview)

func start_placement(tower_scene: PackedScene, preview_texture: Texture2D, cost: int) -> void:
	if not EconomyManager.can_afford(cost):
		return
	_tower_scene = tower_scene
	_tower_cost = cost
	_preview.texture = preview_texture
	_preview.scale = Vector2(0.15, 0.15)
	_placing = true
	_preview.visible = true

func cancel_placement() -> void:
	_placing = false
	_preview.visible = false
	placement_cancelled.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not _placing:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _valid_position:
			_place_tower()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		cancel_placement()
		get_viewport().set_input_as_handled()

	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		cancel_placement()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _placing:
		return
	_preview.global_position = get_global_mouse_position()
	_valid_position = _is_valid_placement(_preview.global_position)
	_preview.modulate = Color.GREEN if _valid_position else Color.RED

func _is_valid_placement(pos: Vector2) -> bool:
	if not EconomyManager.can_afford(_tower_cost):
		return false
	for path in path_nodes:
		if _distance_to_path(pos, path) < min_distance_from_path:
			return false
	if not towers_parent:
		return true
	for child in towers_parent.get_children():
		if child is Node2D:
			if pos.distance_to(child.global_position) < tower_tower_min_distance:
				return false
	return true

func _distance_to_path(pos: Vector2, path: Path2D) -> float:
	if not path or not path.curve:
		return 9999.0
	var baked = path.curve.get_baked_points()
	if baked.size() < 2:
		return 9999.0
	var min_dist: float = INF
	for point in baked:
		var world_point = path.global_position + point
		var dist = pos.distance_to(world_point)
		if dist < min_dist:
			min_dist = dist
	return min_dist

func _place_tower() -> void:
	if not EconomyManager.spend_gold(_tower_cost):
		return
	var tower = _tower_scene.instantiate()
	towers_parent.add_child(tower)
	tower.global_position = _preview.global_position
	tower.total_invested = _tower_cost
	tower.tower_clicked.connect(_on_tower_clicked)
	tower_placed.emit(tower)
	_placing = false
	_preview.visible = false

func _on_tower_clicked(_tower: TowerBase) -> void:
	pass
