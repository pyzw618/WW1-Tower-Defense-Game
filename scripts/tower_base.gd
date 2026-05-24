extends StaticBody2D
class_name TowerBase

@export var tower_name: String = "Machine Gun Nest"
@export var damage_levels: Array[float] = [15.0, 30.0, 50.0]
@export var fire_rate_levels: Array[float] = [0.5, 0.4, 0.3]
@export var range_levels: Array[float] = [250.0, 280.0, 320.0]
@export var upgrade_costs: Array[int] = [100, 150, 250]
@export var scale_factor: Vector2 = Vector2(0.15, 0.15)
@export var level_textures: Array[Texture2D] = []

var current_level: int = 1
var total_invested: int = 0
var current_target: EnemyBase = null
var can_fire: bool = true

@onready var sprite: Sprite2D = $Sprite
@onready var range_area: Area2D = $RangeArea
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var fire_timer: Timer = $FireTimer
@onready var range_indicator: Node2D = $RangeIndicator

signal tower_clicked(tower: TowerBase)

func _ready() -> void:
	sprite.scale = scale_factor
	total_invested = upgrade_costs[0]
	input_pickable = true
	_apply_level_stats()
	range_area.body_entered.connect(_on_body_entered_range)
	range_area.body_exited.connect(_on_body_exited_range)
	fire_timer.timeout.connect(_on_fire_timer_timeout)

func _process(_delta: float) -> void:
	if not current_target or not is_instance_valid(current_target) or current_target.is_dead:
		_acquire_target()
	if current_target and can_fire:
		_fire()

func upgrade() -> bool:
	if current_level >= 3:
		return false
	var cost = upgrade_costs[current_level]
	if not EconomyManager.can_afford(cost):
		return false
	EconomyManager.spend_gold(cost)
	total_invested += cost
	current_level += 1
	_apply_level_stats()
	return true

func sell() -> int:
	var refund = EconomyManager.get_refund(total_invested)
	EconomyManager.add_gold(refund)
	queue_free()
	return refund

func _apply_level_stats() -> void:
	var idx = current_level - 1
	var radius = range_levels[idx]
	if range_collision and range_collision.shape is CircleShape2D:
		range_collision.shape.radius = radius
	_update_range_indicator()
	if fire_timer:
		fire_timer.wait_time = fire_rate_levels[idx]
	if sprite:
		var textures = level_textures if level_textures.size() >= 3 else [
			preload("res://assets/towers/mg_nest_lv1.png"),
			preload("res://assets/towers/mg_nest_lv2.png"),
			preload("res://assets/towers/mg_nest_lv3.png"),
		]
		if idx < textures.size():
			sprite.texture = textures[idx]

func _update_range_indicator() -> void:
	if range_indicator:
		range_indicator.visible = false
		range_indicator.queue_redraw()

func _on_body_entered_range(body: Node2D) -> void:
	if body is EnemyBase:
		_acquire_target()

func _on_body_exited_range(body: Node2D) -> void:
	if body == current_target:
		current_target = null
		_acquire_target()

func _acquire_target() -> void:
	var best: EnemyBase = null
	var best_progress: float = -1.0
	var bodies = range_area.get_overlapping_bodies()
	for body in bodies:
		if body is EnemyBase and not body.is_dead:
			var prog = body.path_follow.progress_ratio if body.path_follow else 0.0
			if prog > best_progress:
				best_progress = prog
				best = body
	current_target = best

func _fire() -> void:
	if not current_target or not is_instance_valid(current_target) or current_target.is_dead:
		_acquire_target()
		return
	can_fire = false
	fire_timer.start()
	var bullet = preload("res://scenes/bullet.tscn").instantiate()
	get_tree().root.get_node("Main/Projectiles").add_child(bullet)
	bullet.setup(current_target, damage_levels[current_level - 1], global_position)

func _on_fire_timer_timeout() -> void:
	can_fire = true

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tower_clicked.emit(self)
