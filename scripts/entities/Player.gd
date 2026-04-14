extends CharacterBody2D

## Joueur top-down modulaire.
## - Déplacement fluide (accélération/frottement)
## - Système de PV et dégâts
## - Mort du personnage
## - Statistiques de base extensibles via PlayerStats

signal health_changed(current_health: int, max_health: int)
signal damaged(final_damage: int, current_health: int)
signal died
signal stats_changed(stats: PlayerStats)
signal class_changed(class_data: PlayerClassData)

@export_group("Mouvement")
@export var base_move_speed: float = 180.0
@export var acceleration: float = 1200.0
@export var friction: float = 900.0

@export_group("Combat")
@export var invulnerability_time: float = 0.2

@export_group("Stats")
@export var stats: PlayerStats = PlayerStats.new()

@export_group("Classe")
@export var class_data: PlayerClassData

var current_health: int = 0
var is_dead: bool = false
var _invuln_timer: float = 0.0

var passive_spell_damage_multiplier: float = 1.0
var passive_move_speed_bonus: float = 0.0
var passive_xp_multiplier: float = 1.0

var run_unlock_context := {
    "player_level": 1,
    "wave": 1,
    "defeated_bosses": {},
    "run_events": {},
}

@onready var spell_caster: SpellCaster = $SpellCaster

func _ready() -> void:
    add_to_group("player")
    _apply_class_data_if_needed()
    _initialize_from_stats()

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    _invuln_timer = max(_invuln_timer - delta, 0.0)

    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var target_velocity := input_direction * get_current_move_speed()

    if input_direction.is_zero_approx():
        velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
    else:
        velocity = velocity.move_toward(target_velocity, acceleration * delta)

    move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
    if is_dead or spell_caster == null:
        return

    if event.is_action_pressed("cast_spell_1"):
        spell_caster.try_cast_spell(0)
    elif event.is_action_pressed("cast_spell_2"):
        spell_caster.try_cast_spell(1)
    elif event.is_action_pressed("cast_spell_3"):
        spell_caster.try_cast_spell(2)


func set_class(new_class: PlayerClassData) -> void:
    class_data = new_class
    _apply_class_data_if_needed()
    _initialize_from_stats()

func get_class_display_name() -> String:
    if class_data == null:
        return "Aucune"
    return class_data.display_name

func get_class_upgrade_candidates(current_level: int, context: Dictionary = {}) -> Array[UpgradeData]:
    var upgrades: Array[UpgradeData] = []
    if class_data == null or spell_caster == null:
        return upgrades

    var evaluation_context := run_unlock_context.duplicate(true)
    for key in context.keys():
        evaluation_context[key] = context[key]
    evaluation_context["player_level"] = current_level

    for unlock_data in class_data.unlockable_spells:
        if unlock_data == null or unlock_data.spell == null:
            continue
        if not unlock_data.is_unlocked(evaluation_context):
            continue
        if spell_caster.has_spell(unlock_data.spell.id):
            continue

        var upgrade := UpgradeData.new()
        upgrade.id = StringName("unlock_%s" % unlock_data.spell.id)
        upgrade.display_name = "Débloquer: %s" % unlock_data.spell.display_name
        upgrade.description = _build_unlock_description(unlock_data)
        upgrade.upgrade_type = UpgradeData.UpgradeType.UNLOCK_SPELL
        upgrade.spell_resource = unlock_data.spell
        upgrades.append(upgrade)

    return upgrades


func update_unlock_progress(key: StringName, value: Variant) -> void:
    run_unlock_context[key] = value

func mark_boss_defeated(boss_id: StringName) -> void:
    run_unlock_context["defeated_bosses"][boss_id] = true

func mark_run_event(event_id: StringName) -> void:
    run_unlock_context["run_events"][event_id] = true

func _build_unlock_description(unlock_data: ClassSpellUnlockData) -> String:
    var tokens: Array[String] = []
    for condition in unlock_data.conditions:
        if condition == null:
            continue
        match condition.condition_type:
            UnlockConditionData.ConditionType.PLAYER_LEVEL:
                tokens.append("Niveau %d" % condition.required_value)
            UnlockConditionData.ConditionType.WAVE_REACHED:
                tokens.append("Vague %d" % condition.required_value)
            UnlockConditionData.ConditionType.BOSS_DEFEATED:
                tokens.append("Boss vaincu: %s" % String(condition.required_id))
            UnlockConditionData.ConditionType.EVENT_FLAG:
                tokens.append("Évènement: %s" % String(condition.required_id))

    if tokens.is_empty():
        return unlock_data.note

    if unlock_data.note.is_empty():
        return "Conditions: %s" % ", ".join(tokens)

    return "%s (%s)" % [unlock_data.note, ", ".join(tokens)]

func _apply_class_data_if_needed() -> void:
    if class_data == null:
        return

    if class_data.base_stats != null:
        stats = class_data.base_stats.duplicate(true)

    if spell_caster != null:
        spell_caster.set_equipped_spells(class_data.starting_spells)

    run_unlock_context["defeated_bosses"] = {}
    run_unlock_context["run_events"] = {}
    run_unlock_context["player_level"] = 1
    run_unlock_context["wave"] = 1

    class_changed.emit(class_data)

func set_stats(new_stats: PlayerStats) -> void:
    stats = new_stats
    stats_changed.emit(stats)
    _initialize_from_stats()

func get_stat_snapshot() -> Dictionary:
    return {
        "vitalite": stats.vitalite,
        "force": stats.force,
        "intelligence": stats.intelligence,
        "agilite": stats.agilite,
        "defense": stats.defense,
        "vitesse": stats.vitesse,
        "chance": stats.chance,
        "max_health": get_max_health(),
        "move_speed": get_current_move_speed(),
        "critical_chance": stats.get_critical_chance(),
        "cooldown_multiplier": get_spell_cooldown_multiplier()
    }

func get_max_health() -> int:
    return stats.get_max_health()

func get_current_move_speed() -> float:
    return stats.get_move_speed(base_move_speed) + passive_move_speed_bonus


func get_spell_cooldown_multiplier() -> float:
    return stats.get_cooldown_duration(1.0)

func get_spell_cooldown(base_cooldown: float) -> float:
    return stats.get_cooldown_duration(base_cooldown)

func compute_spell_damage(base_damage: int, scaling: PlayerStats.DamageScaling) -> Dictionary:
    var damage_bundle := stats.compute_outgoing_damage(base_damage, scaling)
    damage_bundle["final_damage"] = int(round(damage_bundle["final_damage"] * passive_spell_damage_multiplier))
    return damage_bundle


func apply_stat_bonus(stat_name: StringName, amount: int) -> void:
    if amount == 0 or not stats.has_method("apply_stat_bonus"):
        return

    var previous_max_health := get_max_health()
    stats.apply_stat_bonus(stat_name, amount)

    var max_health := get_max_health()
    if max_health > previous_max_health:
        current_health += max_health - previous_max_health

    current_health = clamp(current_health, 0, max_health)
    stats_changed.emit(stats)
    health_changed.emit(current_health, max_health)

func unlock_spell(spell_data: SpellData) -> void:
    if spell_caster != null:
        spell_caster.unlock_spell(spell_data)

func upgrade_spell(spell_id: StringName, damage_bonus: int, cooldown_multiplier: float) -> void:
    if spell_caster != null:
        spell_caster.upgrade_spell(spell_id, damage_bonus, cooldown_multiplier)

func apply_passive_bonus(passive_key: StringName, value: float) -> void:
    match passive_key:
        &"spell_power_multiplier":
            passive_spell_damage_multiplier += value
        &"move_speed_flat":
            passive_move_speed_bonus += value
        &"xp_gain_multiplier":
            passive_xp_multiplier += value

func get_experience_multiplier() -> float:
    return passive_xp_multiplier

func heal(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    current_health = min(current_health + amount, get_max_health())
    health_changed.emit(current_health, get_max_health())

func receive_damage(raw_damage: int) -> void:
    if is_dead or raw_damage <= 0:
        return
    if _invuln_timer > 0.0:
        return

    var final_damage := stats.compute_damage_reduction(raw_damage)
    current_health = max(current_health - final_damage, 0)
    _invuln_timer = invulnerability_time

    damaged.emit(final_damage, current_health)
    health_changed.emit(current_health, get_max_health())

    if current_health == 0:
        _die()

func _initialize_from_stats() -> void:
    if stats == null:
        stats = PlayerStats.new()

    is_dead = false
    _invuln_timer = 0.0
    current_health = get_max_health()
    health_changed.emit(current_health, get_max_health())

func _die() -> void:
    if is_dead:
        return

    is_dead = true
    velocity = Vector2.ZERO
    died.emit()
    GameState.notify_player_died()
