extends Node2D

var _dash_offset: float = 0.0
const DASH_LEN: float = 20.0
const GAP_LEN: float = 5.0
const LINE_WIDTH: float = 5.0
const COLOR_WHITE := Color(1, 1, 1, 0.7)
const COLOR_BLACK := Color(0.05, 0.05, 0.05, 0.6)
const FLOW_SPEED: float = 80.0


func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	set_process(false)


func _process(delta: float) -> void:
	_dash_offset += FLOW_SPEED * delta
	var cycle = (DASH_LEN + GAP_LEN) * 2.0
	if _dash_offset >= cycle:
		_dash_offset -= cycle
	queue_redraw()


func _on_game_state_changed(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.PREPARING:
			show()
			set_process(true)
			queue_redraw()
		GameManager.GameState.IN_WAVE:
			hide()
			set_process(false)


func _draw() -> void:
	var paths_node = $".."
	for child in paths_node.get_children():
		if child is Path2D:
			_draw_flowing_curve(child.curve)


func _draw_flowing_curve(curve: Curve2D) -> void:
	var points := curve.get_baked_points()
	if points.size() < 2:
		return

	var pair = DASH_LEN + GAP_LEN
	var cycle = pair * 2.0

	for i in range(points.size() - 1):
		var from := points[i]
		var to := points[i + 1]
		var seg_dir := to - from
		var seg_length := seg_dir.length()
		if seg_length < 1.0:
			continue
		seg_dir = seg_dir / seg_length

		var pos := -_dash_offset
		while pos < seg_length:
			# Determine which part of the cycle we're in
			var local = fmod(pos + _dash_offset + cycle, cycle)

			if local < DASH_LEN:
				# White dash
				var dash_start = maxf(pos, 0.0)
				var dash_end = minf(pos + (DASH_LEN - local), seg_length)
				if dash_end > dash_start:
					draw_line(from + seg_dir * dash_start, from + seg_dir * dash_end, COLOR_WHITE, LINE_WIDTH)
				pos += DASH_LEN - local
			elif local < pair:
				# Gap after white
				pos += pair - local
			elif local < pair + DASH_LEN:
				# Black dash
				var dash_start = maxf(pos, 0.0)
				var dash_end = minf(pos + (pair + DASH_LEN - local), seg_length)
				if dash_end > dash_start:
					draw_line(from + seg_dir * dash_start, from + seg_dir * dash_end, COLOR_BLACK, LINE_WIDTH)
				pos += pair + DASH_LEN - local
			else:
				# Gap after black
				pos += cycle - local
