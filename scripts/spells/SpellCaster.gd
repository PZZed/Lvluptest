extends Node
class_name SpellCaster

## Gestionnaire générique de sorts : cooldown, déclenchement et application des effets.

signal spell_casted(spell_id: StringName)
signal spell_on_cooldown(spell_id: StringName, remaining: float)

@export var projectile_scene: PackedScene = preload("res://scenes/spells/SpellProjectile.tscn")
@export var equipped_spells: Array[SpellData] = []

var _cooldowns: Dictionary = {}

func _process(delta: float) -> void:
    for spell_id in _cooldowns.keys():
        _cooldowns[spell_id] = max(_cooldowns[spell_id] - delta, 0.0)

func try_cast_spell(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= equipped_spells.size():
        return false

    var spell := equipped_spells[slot_index]
    if spell == null:
        return false

    var current_cd := float(_cooldowns.get(spell.id, 0.0))
    if current_cd > 0.0:
        spell_on_cooldown.emit(spell.id, current_cd)
        return false

    var did_cast := _cast_spell(spell)
    if did_cast:
        _cooldowns[spell.id] = _compute_spell_cooldown(spell.cooldown)
        spell_casted.emit(spell.id)

    return did_cast

func _cast_spell(spell: SpellData) -> bool:
    match spell.spell_type:
        SpellData.SpellType.PROJECTILE:
            return _cast_projectile(spell)
        SpellData.SpellType.AREA_AROUND_CASTER:
            return _cast_area_around_caster(spell)
        SpellData.SpellType.LONG_RANGE_HIT:
            return _cast_long_range_hit(spell)
        _:
            return false

func _cast_projectile(spell: SpellData) -> bool:
    var caster := _get_caster()
    if caster == null:
        return false

    var target := _find_nearest_enemy(caster.global_position, spell.cast_range)
    if target == null:
        return false

    var projectile: Area2D = projectile_scene.instantiate()
    projectile.global_position = caster.global_position

    var direction := (target.global_position - caster.global_position).normalized()
    var damage_bundle := _compute_damage_bundle(spell)
    projectile.call("initialize", damage_bundle["final_damage"], direction, spell.projectile_speed, spell.projectile_lifetime)

    get_tree().current_scene.add_child(projectile)
    return true

func _cast_area_around_caster(spell: SpellData) -> bool:
    var caster := _get_caster()
    if caster == null:
        return false

    var did_hit := false
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not (enemy is Node2D):
            continue

        var distance := caster.global_position.distance_to(enemy.global_position)
        if distance <= spell.area_radius and enemy.has_method("receive_damage"):
            var damage_bundle := _compute_damage_bundle(spell)
            enemy.call("receive_damage", damage_bundle["final_damage"])
            did_hit = true

    return did_hit

func _cast_long_range_hit(spell: SpellData) -> bool:
    var caster := _get_caster()
    if caster == null:
        return false

    var target := _find_nearest_enemy(caster.global_position, spell.cast_range)
    if target == null:
        return false

    if target.has_method("receive_damage"):
        var damage_bundle := _compute_damage_bundle(spell)
        target.call("receive_damage", damage_bundle["final_damage"])
        return true

    return false

func _find_nearest_enemy(origin: Vector2, max_range: float) -> Node2D:
    var nearest_enemy: Node2D
    var best_distance := max_range

    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not (enemy is Node2D):
            continue

        var enemy_node := enemy as Node2D
        var distance := origin.distance_to(enemy_node.global_position)
        if distance <= best_distance:
            best_distance = distance
            nearest_enemy = enemy_node

    return nearest_enemy

func _compute_damage_bundle(spell: SpellData) -> Dictionary:
    var caster := _get_caster()
    if caster != null and caster.has_method("compute_spell_damage"):
        return caster.call("compute_spell_damage", spell.damage, spell.damage_scaling)

    return {
        "final_damage": max(spell.damage, 1),
        "is_critical": false,
    }

func _compute_spell_cooldown(base_cooldown: float) -> float:
    var caster := _get_caster()
    if caster != null and caster.has_method("get_spell_cooldown"):
        return caster.call("get_spell_cooldown", base_cooldown)

    return base_cooldown

func _get_caster() -> Node2D:
    if owner is Node2D:
        return owner as Node2D
    if get_parent() is Node2D:
        return get_parent() as Node2D
    return null



func set_equipped_spells(spells: Array[SpellData]) -> void:
    equipped_spells.clear()
    for spell in spells:
        if spell != null:
            equipped_spells.append(spell.duplicate(true))

func has_spell(spell_id: StringName) -> bool:
    return _has_spell(spell_id)

func unlock_spell(spell_data: SpellData) -> void:
    if spell_data == null or _has_spell(spell_data.id):
        return

    equipped_spells.append(spell_data.duplicate(true))

func upgrade_spell(spell_id: StringName, damage_bonus: int, cooldown_multiplier: float) -> void:
    var target_spell := _find_spell_by_id(spell_id)
    if target_spell == null:
        return

    target_spell.damage += damage_bonus
    target_spell.cooldown = max(target_spell.cooldown * cooldown_multiplier, 0.05)

func _has_spell(spell_id: StringName) -> bool:
    return _find_spell_by_id(spell_id) != null

func _find_spell_by_id(spell_id: StringName) -> SpellData:
    for spell in equipped_spells:
        if spell != null and spell.id == spell_id:
            return spell
    return null
