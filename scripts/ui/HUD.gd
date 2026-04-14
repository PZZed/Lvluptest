extends Control

@onready var wave_label: Label = $Margin/Stats/WaveLabel
@onready var health_label: Label = $Margin/Stats/HealthLabel
@onready var level_label: Label = $Margin/Stats/LevelLabel
@onready var xp_label: Label = $Margin/Stats/XPLabel
@onready var class_label: Label = $Margin/Stats/ClassLabel

func _ready() -> void:
    GameState.health_updated.connect(set_health)

func set_wave(wave_index: int) -> void:
    wave_label.text = "Vague: %d" % wave_index

func set_health(health_value: int) -> void:
    health_label.text = "Vie: %d" % health_value

func set_level(level_value: int) -> void:
    level_label.text = "Niveau: %d" % level_value

func set_experience(current_xp: int, required_xp: int) -> void:
    xp_label.text = "XP: %d / %d" % [current_xp, required_xp]

func set_class_name(value: String) -> void:
    class_label.text = "Classe: %s" % value
