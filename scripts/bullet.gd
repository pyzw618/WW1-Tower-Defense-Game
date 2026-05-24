extends Area2D

var target: EnemyBase = null
var damage: float = 0.0
var speed: float = 600.0
var direction: Vector2 = Vector2.ZERO
var _lifetime: float = 3.0
var _age: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func setup(_target: EnemyBase, _damage: float, start_pos: Vector2) -> void:
	target = _target
	damage = _damage
	global_position = start_pos
	if target and is_instance_valid(target):
		direction = (target.global_position - start_pos).normalized()

func _physics_process(delta: float) -> void:
	_age += delta
	if _age > _lifetime:
		queue_free()
		return

	if target and is_instance_valid(target) and not target.is_dead:
		direction = (target.global_position - global_position).normalized()

	global_position += direction * speed * delta

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color(1, 0.9, 0.2))
	draw_circle(Vector2.ZERO, 5.0, Color(1, 0.7, 0, 0.3))

func _on_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not body.is_dead:
		body.take_damage(damage)
		queue_free()
