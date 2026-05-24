extends Node2D

var radius: float = 250.0
var visible_circle: bool = false

func _draw() -> void:
	if visible_circle:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.1))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(1, 1, 1, 0.25), 1.5)

func show_range(r: float) -> void:
	radius = r
	visible_circle = true
	queue_redraw()

func hide_range() -> void:
	visible_circle = false
	queue_redraw()
