extends Node2D

@onready var start_button: Button = $CanvasLayer/Buttons/StartButton
@onready var story_button: Button = $CanvasLayer/Buttons/StoryButton
@onready var story_panel: Panel = $CanvasLayer/StoryPanel
@onready var close_button: Button = $CanvasLayer/StoryPanel/CloseButton
@onready var buttons_container: VBoxContainer = $CanvasLayer/Buttons
@onready var story_content: Label = $CanvasLayer/StoryPanel/ScrollContainer/Content


func _ready() -> void:
	AudioManager.play_menu_music()
	start_button.pressed.connect(_on_start_pressed)
	story_button.pressed.connect(_on_story_pressed)
	close_button.pressed.connect(_on_close_pressed)
	var file = FileAccess.open("res://游戏背景.txt", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		if text.length() > 0:
			story_content.text = text


func _on_start_pressed() -> void:
	AudioManager.stop_all()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_story_pressed() -> void:
	story_panel.visible = true
	buttons_container.visible = false


func _on_close_pressed() -> void:
	story_panel.visible = false
	buttons_container.visible = true
