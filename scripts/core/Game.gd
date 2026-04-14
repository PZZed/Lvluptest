extends Node2D

@onready var hud: Control = $CanvasLayer/HUD
@onready var game_over: Control = $CanvasLayer/GameOver
@onready var level_up_panel: LevelUpPanel = $CanvasLayer/LevelUpPanel
@onready var player: CharacterBody2D = $World/Player
@onready var enemy_container: Node2D = $World/EnemyContainer
@onready var progression_manager: ProgressionManager = $ProgressionManager

var enemy_scene: PackedScene = preload("res://scenes/entities/enemy/BasicEnemy.tscn")
var _run_reward_granted: bool = false

func _ready() -> void:
    WaveManager.wave_started.connect(_on_wave_started)
    WaveManager.spawn_requested.connect(_on_spawn_requested)

    GameState.player_died.connect(_on_player_died)
    player.health_changed.connect(_on_player_health_changed)
    player.class_changed.connect(_on_player_class_changed)

    progression_manager.level_changed.connect(_on_level_changed)
    progression_manager.experience_changed.connect(_on_experience_changed)
    progression_manager.level_up_choices_requested.connect(_on_level_up_choices_requested)

    level_up_panel.upgrade_selected.connect(_on_upgrade_selected)
    level_up_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

    MetaProgression.apply_selected_class(player)
    MetaProgression.apply_to_player(player)

    GameState.start_run()
    progression_manager.start_run(player)
    WaveManager.start_waves()

    _run_reward_granted = false
    hud.call("set_class_name", player.call("get_class_display_name"))

func _on_wave_started(wave_index: int, _enemy_count: int) -> void:
    hud.call("set_wave", wave_index)
    if player.has_method("update_unlock_progress"):
        player.call("update_unlock_progress", &"wave", wave_index)

func _on_spawn_requested(spawn_position: Vector2, enemy_stats: Dictionary) -> void:
    var enemy: CharacterBody2D = enemy_scene.instantiate()
    enemy.global_position = spawn_position

    enemy.set("target", player)
    if enemy.has_method("configure"):
        enemy.call("configure", enemy_stats)

    if enemy.has_signal("died"):
        enemy.died.connect(_on_enemy_died)

    enemy_container.add_child(enemy)

func _on_player_health_changed(current_health: int, _max_health: int) -> void:
    GameState.set_player_health(current_health)

func _on_enemy_died(enemy: Node) -> void:
    var xp_reward := int(enemy.get("experience_reward"))
    var xp_multiplier := 1.0
    if player.has_method("get_experience_multiplier"):
        xp_multiplier = float(player.call("get_experience_multiplier"))

    progression_manager.add_experience(int(round(xp_reward * xp_multiplier)))

func _on_player_class_changed(class_data: PlayerClassData) -> void:
    hud.call("set_class_name", class_data.display_name)

func _on_level_changed(level: int) -> void:
    hud.call("set_level", level)
    if player.has_method("update_unlock_progress"):
        player.call("update_unlock_progress", &"player_level", level)

func _on_experience_changed(current_xp: int, required_xp: int) -> void:
    hud.call("set_experience", current_xp, required_xp)

func _on_level_up_choices_requested(level: int, choices: Array[UpgradeData]) -> void:
    get_tree().paused = true
    level_up_panel.call("show_choices", level, choices)

func _on_upgrade_selected(upgrade: UpgradeData) -> void:
    progression_manager.select_upgrade(upgrade, player)
    level_up_panel.call("hide_panel")
    get_tree().paused = false

func notify_boss_defeated(boss_id: StringName) -> void:
    if player.has_method("mark_boss_defeated"):
        player.call("mark_boss_defeated", boss_id)

func notify_run_event(event_id: StringName) -> void:
    if player.has_method("mark_run_event"):
        player.call("mark_run_event", event_id)

func _on_player_died() -> void:
    WaveManager.stop_waves()
    _grant_end_of_run_rewards()
    game_over.show()

func _grant_end_of_run_rewards() -> void:
    if _run_reward_granted:
        return

    _run_reward_granted = true
    var wave_reward := max(WaveManager.current_wave, 1) * 12
    var level_reward := progression_manager.current_level * 20
    MetaProgression.add_essence(wave_reward + level_reward)
