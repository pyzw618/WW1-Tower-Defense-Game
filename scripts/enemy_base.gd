extends CharacterBody2D
class_name EnemyBase

@export var enemy_name: String = "Enemy"
@export var max_hp: float = 100.0
@export var speed: float = 100.0
@export var armor: float = 0.0
@export var kill_reward: int = 20
@export var lives_lost_on_leak: int = 1
@export var scale_factor: Vector2 = Vector2(0.12, 0.12)
@export var animation_frames: Array[Texture2D] = []
@export var animation_fps: float = 6.0

var current_hp: float
var path_follow: PathFollow2D
var path_length: float = 1.0
var is_dead: bool = false
var _anim_timer: Timer = null
var _anim_idx: int = 0
var _ref_frame_size: Vector2 = Vector2.ZERO

const BAR_W: float = 40.0
const BAR_H: float = 6.0
const BAR_Y: float = -54.0

signal died(enemy: EnemyBase)
signal reached_end(enemy: EnemyBase)

@onready var sprite: Node2D = $Sprite
@onready var health_bar: ProgressBar = $HealthBar


func _ready() -> void:
	current_hp = max_hp
	sprite.scale = scale_factor
	health_bar.visible = false

	if animation_frames.size() > 1:
		_ref_frame_size = animation_frames[0].get_size()
		sprite.set("texture", animation_frames[0])
		_anim_timer = Timer.new()
		add_child(_anim_timer)
		_anim_timer.wait_time = 1.0 / animation_fps
		_anim_timer.timeout.connect(_on_anim_tick)
		_anim_timer.start()


func _draw() -> void:
	if is_dead:
		return
	var x = -BAR_W / 2.0
	var ratio = current_hp / max_hp
	var fill_color: Color
	if ratio > 0.5:
		fill_color = Color(0.2, 0.8, 0.2, 0.9)
	elif ratio > 0.25:
		fill_color = Color(0.9, 0.6, 0.1, 0.9)
	else:
		fill_color = Color(0.9, 0.2, 0.2, 0.9)
	draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color(0.1, 0.1, 0.1, 0.85))
	draw_rect(Rect2(x, BAR_Y, BAR_W * ratio, BAR_H), fill_color)


func setup(path: Path2D) -> void:
	path_follow = PathFollow2D.new()
	path_follow.rotates = false
	path_follow.loop = false
	path.add_child(path_follow)
	path_length = path.curve.get_baked_length()
	if path_length <= 0:
		path_length = 1.0


func _physics_process(delta: float) -> void:
	if is_dead or not path_follow:
		return

	path_follow.progress_ratio += (speed * delta) / path_length

	if path_follow.progress_ratio < 1.0:
		global_position = path_follow.global_position
	else:
		reached_end.emit(self)
		_die()


func _on_anim_tick() -> void:
	if is_dead or animation_frames.size() <= 1:
		return
	_anim_idx = (_anim_idx + 1) % animation_frames.size()
	sprite.set("texture", animation_frames[_anim_idx])
	var frame_size = animation_frames[_anim_idx].get_size()
	var rx = _ref_frame_size.x / frame_size.x if frame_size.x > 0 else 1.0
	var ry = _ref_frame_size.y / frame_size.y if frame_size.y > 0 else 1.0
	sprite.scale = Vector2(scale_factor.x * rx, scale_factor.y * ry)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	var effective = max(amount - armor, 1.0)
	current_hp -= effective
	current_hp = max(current_hp, 0.0)
	queue_redraw()
	if current_hp <= 0:
		died.emit(self)
		EconomyManager.add_gold(kill_reward)
		_die()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	if path_follow:
		path_follow.queue_free()
	queue_free()
