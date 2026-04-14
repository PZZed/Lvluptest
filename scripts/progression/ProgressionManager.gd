extends Node
class_name ProgressionManager

signal level_changed(level: int)
signal experience_changed(current_xp: int, required_xp: int)
signal level_up_choices_requested(new_level: int, choices: Array[UpgradeData])
signal upgrade_applied(upgrade_id: StringName)

@export_group("Courbe XP")
@export var base_xp_to_level: int = 30
@export var xp_growth_factor: float = 1.28
@export var xp_linear_growth: int = 8

@export_group("Choix")
@export var choices_per_level: int = 3
@export var upgrade_pool: Array[UpgradeData] = []

var current_level: int = 1
var current_xp: int = 0

var _player: Node
var _awaiting_choice: bool = false
var _cached_choices: Array[UpgradeData] = []

func start_run(player: Node) -> void:
    _player = player
    current_level = 1
    current_xp = 0
    _awaiting_choice = false
    _cached_choices.clear()

    level_changed.emit(current_level)
    experience_changed.emit(current_xp, get_required_xp_for_next_level())

func add_experience(amount: int) -> void:
    if amount <= 0:
        return

    current_xp += amount
    _process_level_ups()
    experience_changed.emit(current_xp, get_required_xp_for_next_level())

func select_upgrade(upgrade: UpgradeData, player: Node) -> void:
    if not _awaiting_choice or upgrade == null:
        return

    _apply_upgrade_to_player(upgrade, player)
    _awaiting_choice = false
    _cached_choices.clear()
    upgrade_applied.emit(upgrade.id)

    _process_level_ups()
    experience_changed.emit(current_xp, get_required_xp_for_next_level())

func get_required_xp_for_next_level(level: int = current_level) -> int:
    var level_offset := max(level - 1, 0)
    var geometric_part := base_xp_to_level * pow(xp_growth_factor, level_offset)
    return int(round(geometric_part)) + (level_offset * xp_linear_growth)

func _process_level_ups() -> void:
    if _awaiting_choice:
        return

    var required_xp := get_required_xp_for_next_level()
    while current_xp >= required_xp:
        current_xp -= required_xp
        current_level += 1
        level_changed.emit(current_level)

        _cached_choices = _build_upgrade_choices()
        _awaiting_choice = true
        level_up_choices_requested.emit(current_level, _cached_choices)
        return

func _build_upgrade_choices() -> Array[UpgradeData]:
    var eligible_pool: Array[UpgradeData] = []
    var seen_ids := {}

    for upgrade in upgrade_pool:
        if upgrade == null:
            continue
        if seen_ids.has(upgrade.id):
            continue
        seen_ids[upgrade.id] = true
        eligible_pool.append(upgrade)

    if _player != null and _player.has_method("get_class_upgrade_candidates"):
        var class_upgrades: Array[UpgradeData] = _player.call("get_class_upgrade_candidates", current_level)
        for class_upgrade in class_upgrades:
            if class_upgrade == null:
                continue
            if seen_ids.has(class_upgrade.id):
                continue
            seen_ids[class_upgrade.id] = true
            eligible_pool.append(class_upgrade)

    eligible_pool.shuffle()

    var picked: Array[UpgradeData] = []
    var limit := min(choices_per_level, eligible_pool.size())
    for i in limit:
        picked.append(eligible_pool[i])

    return picked

func _apply_upgrade_to_player(upgrade: UpgradeData, player: Node) -> void:
    match upgrade.upgrade_type:
        UpgradeData.UpgradeType.STAT_INCREASE:
            if player.has_method("apply_stat_bonus"):
                player.call("apply_stat_bonus", upgrade.stat_name, upgrade.stat_amount)
        UpgradeData.UpgradeType.UNLOCK_SPELL:
            if player.has_method("unlock_spell"):
                player.call("unlock_spell", upgrade.spell_resource)
        UpgradeData.UpgradeType.UPGRADE_SPELL:
            if player.has_method("upgrade_spell"):
                player.call(
                    "upgrade_spell",
                    upgrade.target_spell_id,
                    upgrade.spell_damage_bonus,
                    upgrade.spell_cooldown_multiplier
                )
        UpgradeData.UpgradeType.PASSIVE_BONUS:
            if player.has_method("apply_passive_bonus"):
                player.call("apply_passive_bonus", upgrade.passive_key, upgrade.passive_value)
