extends Node

## WaveManager séparé de la logique des ennemis.
## Responsable du rythme des vagues, du scaling de difficulté et des demandes de spawn.

signal wave_started(wave_index: int, enemy_count: int)
signal spawn_requested(spawn_position: Vector2, enemy_stats: Dictionary)
signal waves_stopped

@export_group("Spawn")
@export var arena_center: Vector2 = Vector2(640, 360)
@export var spawn_radius: float = 420.0
@export var time_between_waves: float = 4.0

@export_group("Progression")
@export var base_enemy_count: int = 4
@export var enemy_count_per_wave: int = 2

@export_group("Stats ennemis")
@export var base_enemy_health: int = 30
@export var health_per_wave: int = 10
@export var base_enemy_damage: int = 8
@export var damage_per_wave: int = 2
@export var base_enemy_speed: float = 120.0
@export var speed_per_wave: float = 6.0

var current_wave: int = 0
var _waves_running: bool = false

func start_waves() -> void:
    _waves_running = true
    current_wave = 0
    _start_next_wave()

func stop_waves() -> void:
    if not _waves_running:
        return

    _waves_running = false
    waves_stopped.emit()

func _start_next_wave() -> void:
    if not _waves_running:
        return

    current_wave += 1

    var enemy_count := _get_enemy_count_for_wave(current_wave)
    var enemy_stats := _get_enemy_stats_for_wave(current_wave)

    wave_started.emit(current_wave, enemy_count)

    for i in enemy_count:
        spawn_requested.emit(_random_spawn_position(), enemy_stats)

    _queue_following_wave()

func _queue_following_wave() -> void:
    if not _waves_running:
        return

    var timer := get_tree().create_timer(time_between_waves)
    timer.timeout.connect(_start_next_wave, CONNECT_ONE_SHOT)

func _get_enemy_count_for_wave(wave_index: int) -> int:
    return base_enemy_count + (wave_index - 1) * enemy_count_per_wave

func _get_enemy_stats_for_wave(wave_index: int) -> Dictionary:
    return {
        "max_health": base_enemy_health + (wave_index - 1) * health_per_wave,
        "touch_damage": base_enemy_damage + (wave_index - 1) * damage_per_wave,
        "move_speed": base_enemy_speed + (wave_index - 1) * speed_per_wave,
    }

func _random_spawn_position() -> Vector2:
    var angle := randf_range(0.0, TAU)
    return arena_center + Vector2.RIGHT.rotated(angle) * spawn_radius
