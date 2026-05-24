extends Node

@export var path_nodes: Array[Path2D] = []
@export var enemy_parent: Node2D
@export var towers_parent: Node2D

var total_waves: int = 10
var current_wave: int = 0
var enemies_alive: int = 0
var wave_active: bool = false
var _spawning: bool = false

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

var wave_data: Array = []

func _ready() -> void:
	_build_wave_data()

func reset() -> void:
	current_wave = 0
	enemies_alive = 0
	wave_active = false
	_spawning = false

func start_next_wave() -> void:
	current_wave += 1
	if current_wave > total_waves:
		return
	wave_active = true
	wave_started.emit(current_wave)
	_spawn_wave(current_wave)

func _spawn_wave(wave_num: int) -> void:
	_spawning = true
	var groups: Array = wave_data[wave_num - 1]
	for group in groups:
		await get_tree().create_timer(group["start_delay"]).timeout
		if not wave_active:
			_spawning = false
			return
		var scene = load(group["scene_path"])
		for i in range(group["count"]):
			if not wave_active:
				_spawning = false
				return
			_spawn_enemy(scene, group["path_index"], group.get("hp", -1.0))
			await get_tree().create_timer(group["interval"]).timeout
	_spawning = false
	_check_wave_end()

func _spawn_enemy(scene: PackedScene, path_index: int, hp_override: float = -1.0) -> void:
	var enemy = scene.instantiate()
	if hp_override > 0:
		enemy.max_hp = hp_override
	enemy_parent.add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	if path_index < path_nodes.size():
		enemy.setup(path_nodes[path_index])
	enemies_alive += 1

func _on_enemy_died(_enemy: EnemyBase) -> void:
	enemies_alive -= 1
	_check_wave_end()

func _on_enemy_reached_end(enemy: EnemyBase) -> void:
	GameManager.lose_life(enemy.lives_lost_on_leak)
	enemies_alive -= 1
	_check_wave_end()

func _check_wave_end() -> void:
	if enemies_alive <= 0 and wave_active and not _spawning:
		wave_active = false
		wave_completed.emit(current_wave)
		GameManager._on_wave_completed(current_wave)

func _build_wave_data() -> void:
	var s = "res://scenes/elite_soldier.tscn"
	var t = "res://scenes/tank.tscn"
	var a = "res://scenes/airplane.tscn"
	var z = "res://scenes/zeppelin.tscn"
	var f = "res://scenes/flamethrower.tscn"

	wave_data = [
		# Wave 1 - soldiers on two paths
		[
			{"scene_path": s, "count": 5, "path_index": 0, "interval": 0.9, "start_delay": 0.0},
			{"scene_path": s, "count": 5, "path_index": 1, "interval": 0.9, "start_delay": 2.0},
		],
		# Wave 2 - soldiers on all paths + a tank
		[
			{"scene_path": s, "count": 4, "path_index": 0, "interval": 0.8, "start_delay": 0.0},
			{"scene_path": s, "count": 4, "path_index": 1, "interval": 0.8, "start_delay": 1.5},
			{"scene_path": s, "count": 3, "path_index": 2, "interval": 0.8, "start_delay": 3.0},
			{"scene_path": t, "count": 1, "path_index": 0, "interval": 0.0, "start_delay": 6.0},
		],
		# Wave 3 - soldiers, tanks, and an airplane
		[
			{"scene_path": s, "count": 4, "path_index": 0, "interval": 0.7, "start_delay": 0.0},
			{"scene_path": s, "count": 4, "path_index": 1, "interval": 0.7, "start_delay": 1.5},
			{"scene_path": t, "count": 1, "path_index": 0, "interval": 0.0, "start_delay": 3.0},
			{"scene_path": t, "count": 1, "path_index": 2, "interval": 0.0, "start_delay": 5.0},
			{"scene_path": a, "count": 1, "path_index": 1, "interval": 0.0, "start_delay": 7.0},
		],
		# Wave 4 - Phase 2 (Tank=700, Airplane=200)
		[
			{"scene_path": s, "count": 5, "path_index": 0, "interval": 0.5, "start_delay": 0.0},
			{"scene_path": s, "count": 4, "path_index": 1, "interval": 0.5, "start_delay": 1.0},
			{"scene_path": s, "count": 4, "path_index": 2, "interval": 0.5, "start_delay": 2.0},
			{"scene_path": t, "count": 2, "path_index": 0, "interval": 2.0, "start_delay": 3.0, "hp": 700.0},
			{"scene_path": t, "count": 2, "path_index": 1, "interval": 2.0, "start_delay": 5.0, "hp": 700.0},
			{"scene_path": a, "count": 2, "path_index": 2, "interval": 1.5, "start_delay": 7.0, "hp": 200.0},
		],
		# Wave 5 - Phase 2 (Airplane=200)
		[
			{"scene_path": s, "count": 5, "path_index": 0, "interval": 0.5, "start_delay": 0.0},
			{"scene_path": s, "count": 5, "path_index": 1, "interval": 0.5, "start_delay": 2.0},
			{"scene_path": a, "count": 5, "path_index": 0, "interval": 0.8, "start_delay": 3.0, "hp": 200.0},
			{"scene_path": a, "count": 4, "path_index": 2, "interval": 0.8, "start_delay": 6.0, "hp": 200.0},
		],
		# Wave 6 - Phase 2 (Tank=700, Flamethrower=400, Airplane=200)
		[
			{"scene_path": s, "count": 5, "path_index": 0, "interval": 0.5, "start_delay": 0.0},
			{"scene_path": s, "count": 4, "path_index": 1, "interval": 0.5, "start_delay": 1.5},
			{"scene_path": s, "count": 4, "path_index": 2, "interval": 0.5, "start_delay": 3.0},
			{"scene_path": t, "count": 2, "path_index": 0, "interval": 1.5, "start_delay": 4.0, "hp": 700.0},
			{"scene_path": f, "count": 5, "path_index": 1, "interval": 0.7, "start_delay": 5.0, "hp": 400.0},
			{"scene_path": a, "count": 5, "path_index": 2, "interval": 0.7, "start_delay": 3.0, "hp": 200.0},
		],
		# Wave 7 - Phase 3 (Tank=1100, Flamethrower=600, Zeppelin=2500)
		[
			{"scene_path": s, "count": 4, "path_index": 0, "interval": 0.5, "start_delay": 0.0},
			{"scene_path": s, "count": 3, "path_index": 1, "interval": 0.5, "start_delay": 1.0},
			{"scene_path": t, "count": 2, "path_index": 0, "interval": 1.5, "start_delay": 2.0, "hp": 1100.0},
			{"scene_path": t, "count": 2, "path_index": 2, "interval": 1.5, "start_delay": 4.0, "hp": 1100.0},
			{"scene_path": f, "count": 4, "path_index": 1, "interval": 0.7, "start_delay": 3.0, "hp": 600.0},
			{"scene_path": z, "count": 2, "path_index": 0, "interval": 3.0, "start_delay": 7.0, "hp": 2500.0},
		],
		# Wave 8 - Phase 3 (Tank=1100, Flamethrower=600, Airplane=280)
		[
			{"scene_path": s, "count": 4, "path_index": 0, "interval": 0.4, "start_delay": 0.0},
			{"scene_path": s, "count": 4, "path_index": 1, "interval": 0.4, "start_delay": 1.0},
			{"scene_path": s, "count": 3, "path_index": 2, "interval": 0.4, "start_delay": 2.0},
			{"scene_path": t, "count": 2, "path_index": 0, "interval": 1.5, "start_delay": 2.0, "hp": 1100.0},
			{"scene_path": t, "count": 2, "path_index": 2, "interval": 1.5, "start_delay": 4.0, "hp": 1100.0},
			{"scene_path": f, "count": 4, "path_index": 1, "interval": 0.6, "start_delay": 3.0, "hp": 600.0},
			{"scene_path": a, "count": 3, "path_index": 0, "interval": 0.7, "start_delay": 6.0, "hp": 280.0},
			{"scene_path": a, "count": 3, "path_index": 2, "interval": 0.7, "start_delay": 7.0, "hp": 280.0},
		],
		# Wave 9 - Phase 3 (Tank=1100, Flamethrower=600, Airplane=280, Zeppelin=2500)
		[
			{"scene_path": t, "count": 3, "path_index": 0, "interval": 1.5, "start_delay": 0.0, "hp": 1100.0},
			{"scene_path": t, "count": 3, "path_index": 1, "interval": 1.5, "start_delay": 2.0, "hp": 1100.0},
			{"scene_path": f, "count": 5, "path_index": 0, "interval": 0.6, "start_delay": 1.0, "hp": 600.0},
			{"scene_path": a, "count": 4, "path_index": 2, "interval": 0.6, "start_delay": 3.0, "hp": 280.0},
			{"scene_path": z, "count": 2, "path_index": 0, "interval": 2.5, "start_delay": 6.0, "hp": 2500.0},
			{"scene_path": z, "count": 2, "path_index": 1, "interval": 2.5, "start_delay": 9.0, "hp": 2500.0},
		],
		# Wave 10 - Phase 3 (Tank=1100, Flamethrower=600, Airplane=280, Zeppelin=2500)
		[
			{"scene_path": s, "count": 5, "path_index": 0, "interval": 0.3, "start_delay": 0.0},
			{"scene_path": s, "count": 4, "path_index": 1, "interval": 0.3, "start_delay": 1.0},
			{"scene_path": s, "count": 4, "path_index": 2, "interval": 0.3, "start_delay": 2.0},
			{"scene_path": t, "count": 2, "path_index": 0, "interval": 1.0, "start_delay": 1.5, "hp": 1100.0},
			{"scene_path": t, "count": 2, "path_index": 2, "interval": 1.0, "start_delay": 3.5, "hp": 1100.0},
			{"scene_path": f, "count": 6, "path_index": 1, "interval": 0.5, "start_delay": 2.5, "hp": 600.0},
			{"scene_path": a, "count": 3, "path_index": 0, "interval": 0.6, "start_delay": 6.0, "hp": 280.0},
			{"scene_path": a, "count": 4, "path_index": 1, "interval": 0.6, "start_delay": 7.0, "hp": 280.0},
			{"scene_path": z, "count": 2, "path_index": 0, "interval": 2.0, "start_delay": 8.0, "hp": 2500.0},
			{"scene_path": z, "count": 2, "path_index": 1, "interval": 2.0, "start_delay": 10.0, "hp": 2500.0},
		],
	]
