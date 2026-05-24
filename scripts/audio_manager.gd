extends Node

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

var _menu_music := preload("res://music/主菜单.mp3")
var _phase1_music := preload("res://music/第一阶段.mp3")
var _phase2_music := preload("res://music/第二阶段.mp3")
var _phase3_music := preload("res://music/第三阶段.mp3")
var _result_music := preload("res://music/结算2.mp3")
var _gunfire_sfx := preload("res://music/枪炮声.mp3")

var _current_bgm: AudioStreamMP3 = null


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Master"
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = &"Master"
	add_child(_sfx_player)

	GameManager.game_state_changed.connect(_on_game_state_changed)
	WaveManager.wave_started.connect(_on_wave_started)


func play_menu_music() -> void:
	stop_all()
	_bgm_player.stream = _menu_music
	_bgm_player.play()
	_current_bgm = _menu_music


func stop_all() -> void:
	_bgm_player.stop()
	_sfx_player.stop()
	_current_bgm = null


func _on_wave_started(wave: int) -> void:
	var new_bgm: AudioStreamMP3 = _phase1_music
	if wave <= 3:
		new_bgm = _phase1_music
	elif wave <= 6:
		new_bgm = _phase2_music
	else:
		new_bgm = _phase3_music

	if _current_bgm != new_bgm:
		_bgm_player.stop()
		_bgm_player.stream = new_bgm
		_bgm_player.play()
		_current_bgm = new_bgm

	if not _sfx_player.playing:
		_sfx_player.stream = _gunfire_sfx
		_sfx_player.play()


func _on_game_state_changed(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.VICTORY, GameManager.GameState.DEFEAT:
			_bgm_player.stop()
			_sfx_player.stop()
			_bgm_player.stream = _result_music
			_bgm_player.play()
			_current_bgm = _result_music
