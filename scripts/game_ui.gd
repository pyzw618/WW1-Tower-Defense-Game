extends CanvasLayer

var _selected_tower: TowerBase = null

@onready var tower_placement: Node2D = $"../TowerPlacement"

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var start_wave_btn: Button = $TopBar/StartWaveButton
@onready var tower_btn: Button = $BottomBar/TowerButton
@onready var artillery_btn: Button = $BottomBar/ArtilleryButton
@onready var cancel_btn: Button = $BottomBar/CancelButton
@onready var upgrade_btn: Button = $TowerPanel/UpgradeButton
@onready var sell_btn: Button = $TowerPanel/SellButton
@onready var tower_panel: Control = $TowerPanel
@onready var wave_announce: Label = $WaveAnnounce
@onready var victory_popup: Control = $VictoryPopup
@onready var defeat_popup: Control = $DefeatPopup
@onready var speed_1x_btn: Button = $TopBar/SpeedControl/Speed1x
@onready var speed_2x_btn: Button = $TopBar/SpeedControl/Speed2x

func _ready() -> void:
	EconomyManager.gold_changed.connect(_on_gold_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_completed.connect(_on_wave_completed)

	start_wave_btn.pressed.connect(_on_start_wave_pressed)
	tower_btn.pressed.connect(_on_tower_button_pressed)
	artillery_btn.pressed.connect(_on_artillery_button_pressed)
	cancel_btn.pressed.connect(_on_cancel_button_pressed)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	sell_btn.pressed.connect(_on_sell_pressed)
	speed_1x_btn.pressed.connect(func(): Engine.time_scale = 1.0)
	speed_2x_btn.pressed.connect(func(): Engine.time_scale = 2.0)

	victory_popup.get_node("Button").pressed.connect(_on_restart_pressed)
	victory_popup.get_node("Button").text = "返回大厅"
	defeat_popup.get_node("Button").pressed.connect(_on_restart_pressed)
	defeat_popup.get_node("Button").text = "返回大厅"

	if tower_placement:
		tower_placement.tower_placed.connect(_on_tower_placed)

	_update_gold(EconomyManager.gold)
	_update_lives(GameManager.starting_lives)
	wave_label.text = "Wave: 0/%d" % WaveManager.total_waves
	cancel_btn.visible = false
	tower_panel.visible = false
	victory_popup.visible = false
	defeat_popup.visible = false
	_apply_button_style()

func _apply_button_style() -> void:
	var btn_bg = StyleBoxTexture.new()
	btn_bg.texture = preload("res://assets/ui/button_bg.png")
	btn_bg.content_margin_left = 8
	btn_bg.content_margin_right = 8
	btn_bg.content_margin_top = 4
	btn_bg.content_margin_bottom = 4
	var buttons = [start_wave_btn, tower_btn, artillery_btn, cancel_btn, upgrade_btn, sell_btn]
	for btn in buttons:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_bg)
			btn.add_theme_stylebox_override("hover", btn_bg)
			btn.add_theme_stylebox_override("pressed", btn_bg)

func _on_gold_changed(amount: int) -> void:
	_update_gold(amount)

func _update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount

func _on_lives_changed(lives: int) -> void:
	lives_label.text = "Lives: %d" % lives

func _update_lives(lives: int) -> void:
	lives_label.text = "Lives: %d" % lives

func _on_start_wave_pressed() -> void:
	if GameManager.current_state == GameManager.GameState.PREPARING or GameManager.current_state == GameManager.GameState.WAVE_COMPLETE:
		GameManager.start_wave()

func _on_tower_button_pressed() -> void:
	if tower_placement:
		tower_placement.start_placement(
			tower_placement.mg_nest_scene,
			preload("res://assets/towers/mg_nest_lv1.png"),
			100
		)
		cancel_btn.visible = true

func _on_artillery_button_pressed() -> void:
	if tower_placement:
		tower_placement.start_placement(
			tower_placement.artillery_scene,
			preload("res://assets/towers/artillery_lv1.png"),
			150
		)
		cancel_btn.visible = true

func _on_cancel_button_pressed() -> void:
	if tower_placement:
		tower_placement.cancel_placement()
	cancel_btn.visible = false

func _on_tower_placed(tower: TowerBase) -> void:
	cancel_btn.visible = false
	tower.tower_clicked.connect(select_tower)

func _on_game_state_changed(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.PREPARING:
			start_wave_btn.visible = true
			start_wave_btn.text = "Start Wave"
		GameManager.GameState.IN_WAVE:
			start_wave_btn.visible = false
			tower_panel.visible = false
		GameManager.GameState.WAVE_COMPLETE:
			start_wave_btn.visible = true
			start_wave_btn.text = "Next Wave"
		GameManager.GameState.VICTORY:
			_drop_in_popup(victory_popup)
		GameManager.GameState.DEFEAT:
			_drop_in_popup(defeat_popup)

func _drop_in_popup(popup: Control) -> void:
	popup.offset_top = -780.0
	popup.visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "offset_top", -260.0, 0.5)
	tween.tween_callback(func(): Engine.time_scale = 0.0)


func _on_wave_started(wave: int) -> void:
	wave_label.text = "Wave: %d/%d" % [wave, WaveManager.total_waves]
	wave_announce.text = "Wave %d Incoming!" % wave
	wave_announce.visible = true
	var tween = create_tween()
	tween.tween_property(wave_announce, "modulate:a", 0.0, 2.0).from(1.0)
	tween.tween_callback(func(): wave_announce.visible = false)

func _on_wave_completed(wave: int) -> void:
	wave_announce.text = "Wave %d Complete!" % wave
	wave_announce.visible = true
	wave_announce.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(wave_announce, "modulate:a", 0.0, 2.0).from(1.0)
	tween.tween_callback(func(): wave_announce.visible = false)

func _on_upgrade_pressed() -> void:
	if _selected_tower and _selected_tower.upgrade():
		_selected_tower.get_node("RangeIndicator").hide_range()
		tower_panel.visible = false
		_selected_tower = null

func _on_sell_pressed() -> void:
	if _selected_tower:
		_selected_tower.sell()
		tower_panel.visible = false
		_selected_tower = null

func _on_restart_pressed() -> void:
	Engine.time_scale = 1.0
	AudioManager.stop_all()
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func select_tower(tower: TowerBase) -> void:
	if _selected_tower and _selected_tower != tower:
		var old_range = _selected_tower.get_node_or_null("RangeIndicator")
		if old_range and old_range.has_method("hide_range"):
			old_range.hide_range()
	_selected_tower = tower
	tower_panel.visible = true
	tower_panel.global_position = tower.global_position + Vector2(60, -40)
	if tower.current_level >= 3:
		upgrade_btn.text = "MAX"
		upgrade_btn.disabled = true
	else:
		upgrade_btn.text = "Upgrade (%dg)" % tower.upgrade_costs[tower.current_level]
		upgrade_btn.disabled = false
	sell_btn.text = "Sell (%dg)" % EconomyManager.get_refund(tower.total_invested)
	var range_indicator = tower.get_node_or_null("RangeIndicator")
	if range_indicator and range_indicator.has_method("show_range"):
		range_indicator.show_range(tower.range_levels[tower.current_level - 1])
