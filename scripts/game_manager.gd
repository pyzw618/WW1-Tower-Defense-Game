extends Node

enum GameState { PREPARING, IN_WAVE, WAVE_COMPLETE, VICTORY, DEFEAT }

@export var starting_gold: int = 400
@export var starting_lives: int = 20

var current_state: GameState = GameState.PREPARING
var lives: int

signal game_state_changed(new_state: GameState)
signal lives_changed(new_lives: int)

func _ready() -> void:
	lives = starting_lives
	EconomyManager.gold = starting_gold

func lose_life(amount: int) -> void:
	lives -= amount
	lives = max(lives, 0)
	lives_changed.emit(lives)
	if lives <= 0:
		_set_state(GameState.DEFEAT)

func start_wave() -> void:
	_set_state(GameState.IN_WAVE)
	WaveManager.start_next_wave()

func _on_wave_completed(wave_number: int) -> void:
	_set_state(GameState.WAVE_COMPLETE)
	if wave_number >= WaveManager.total_waves:
		_set_state(GameState.VICTORY)

func _on_wave_started(_wave_number: int) -> void:
	_set_state(GameState.IN_WAVE)

func reset() -> void:
	lives = starting_lives
	lives_changed.emit(lives)
	EconomyManager.reset()
	_set_state(GameState.PREPARING)

func _set_state(new_state: GameState) -> void:
	current_state = new_state
	game_state_changed.emit(new_state)
