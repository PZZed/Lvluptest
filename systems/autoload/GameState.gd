extends Node

signal run_started
signal health_updated(new_health: int)
signal player_died

var current_wave: int = 0
var player_health: int = 100

func start_run() -> void:
    current_wave = 1
    player_health = 100
    run_started.emit()
    health_updated.emit(player_health)

func set_player_health(value: int) -> void:
    player_health = max(value, 0)
    health_updated.emit(player_health)

func notify_player_died() -> void:
    player_health = 0
    player_died.emit()
