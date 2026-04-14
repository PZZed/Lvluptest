extends CharacterBody2D

## Ennemi de base modulaire.
## - Détection du joueur par rayon
## - Poursuite si détecté
## - Dégâts de contact avec cooldown
## - Système de PV + mort

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int, current_health: int)
signal died(enemy: BasicEnemy)

@export_group("Combat")
@export var max_health: int = 30
@export var touch_damage: int = 8
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 0.7
@export var experience_reward: int = 10

@export_group("Déplacement")
@export var move_speed: float = 120.0
@export var detection_radius: float = 260.0

var target: Node2D
var current_health: int = 0
var is_dead: bool = false
var _cooldown_left: float = 0.0

func _ready() -> void:
    add_to_group("enemies")
    current_health = max_health

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    _cooldown_left = max(_cooldown_left - delta, 0.0)

    var player := _resolve_target()
    if player == null:
        velocity = Vector2.ZERO
        return

    var to_target := player.global_position - global_position
    var distance := to_target.length()

    if distance <= detection_radius:
        velocity = to_target.normalized() * move_speed if distance > 0.01 else Vector2.ZERO
        move_and_slide()

        if distance <= attack_range and _cooldown_left <= 0.0:
            _try_damage_target(player)
            _cooldown_left = attack_cooldown
    else:
        velocity = Vector2.ZERO

func configure(stats: Dictionary) -> void:
    if stats.has("max_health"):
        max_health = int(stats["max_health"])
    if stats.has("touch_damage"):
        touch_damage = int(stats["touch_damage"])
    if stats.has("move_speed"):
        move_speed = float(stats["move_speed"])

    current_health = max_health
    health_changed.emit(current_health, max_health)

func receive_damage(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    current_health = max(current_health - amount, 0)
    damaged.emit(amount, current_health)
    health_changed.emit(current_health, max_health)

    if current_health == 0:
        _die()

func _resolve_target() -> Node2D:
    if target != null and is_instance_valid(target):
        return target

    var players := get_tree().get_nodes_in_group("player")
    if players.is_empty():
        return null

    target = players[0]
    return target

func _try_damage_target(player: Node2D) -> void:
    if player.has_method("receive_damage"):
        player.call("receive_damage", touch_damage)

func _die() -> void:
    if is_dead:
        return

    is_dead = true
    velocity = Vector2.ZERO
    died.emit(self)
    queue_free()
