extends Control

func _ready() -> void:
    $Panel/VBox/RestartButton.pressed.connect(_on_restart_pressed)
    $Panel/VBox/MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _on_restart_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _on_main_menu_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
