extends Node

signal essence_changed(total: int)
signal upgrade_purchased(upgrade_id: StringName, new_rank: int)
signal classes_changed(unlocked_class_ids: Array[StringName])

const SAVE_PATH := "user://meta_progression.save"

const CLASS_REGISTRY := {
    &"warrior": "res://resources/classes/warrior.tres",
    &"mage": "res://resources/classes/mage.tres",
    &"thief": "res://resources/classes/thief.tres",
}

const SHOP_UPGRADES: Array[PermanentUpgradeData] = [
    preload("res://resources/meta/permanent_upgrades/perm_stat_force.tres"),
    preload("res://resources/meta/permanent_upgrades/perm_stat_vitalite.tres"),
    preload("res://resources/meta/permanent_upgrades/perm_unlock_mage.tres"),
    preload("res://resources/meta/permanent_upgrades/perm_unlock_thief.tres"),
    preload("res://resources/meta/permanent_upgrades/perm_unlock_spell_arcane_lance.tres"),
    preload("res://resources/meta/permanent_upgrades/perm_passive_spell_power.tres"),
]

var essence: int = 0
var selected_class_id: StringName = &"warrior"
var unlocked_classes := {
    &"warrior": true,
}
var purchased_ranks := {}

func _ready() -> void:
    load_progression()

func add_essence(amount: int) -> void:
    if amount <= 0:
        return

    essence += amount
    essence_changed.emit(essence)
    save_progression()

func get_shop_upgrades() -> Array[PermanentUpgradeData]:
    return SHOP_UPGRADES

func get_upgrade_rank(upgrade_id: StringName) -> int:
    return int(purchased_ranks.get(upgrade_id, 0))

func can_purchase(upgrade: PermanentUpgradeData) -> bool:
    if upgrade == null:
        return false

    var current_rank := get_upgrade_rank(upgrade.id)
    if current_rank >= upgrade.max_rank:
        return false

    return essence >= upgrade.get_cost_for_rank(current_rank)

func purchase_upgrade(upgrade: PermanentUpgradeData) -> bool:
    if not can_purchase(upgrade):
        return false

    var current_rank := get_upgrade_rank(upgrade.id)
    var cost := upgrade.get_cost_for_rank(current_rank)
    essence -= cost

    var new_rank := current_rank + 1
    purchased_ranks[upgrade.id] = new_rank

    if upgrade.upgrade_type == PermanentUpgradeData.UpgradeType.UNLOCK_CLASS:
        unlocked_classes[upgrade.class_id] = true
        classes_changed.emit(get_unlocked_class_ids())

    essence_changed.emit(essence)
    upgrade_purchased.emit(upgrade.id, new_rank)
    save_progression()
    return true

func apply_to_player(player: Node) -> void:
    for upgrade in SHOP_UPGRADES:
        var rank := get_upgrade_rank(upgrade.id)
        if rank <= 0:
            continue

        match upgrade.upgrade_type:
            PermanentUpgradeData.UpgradeType.STAT_BONUS:
                if player.has_method("apply_stat_bonus"):
                    player.call("apply_stat_bonus", upgrade.stat_name, upgrade.stat_amount_per_rank * rank)
            PermanentUpgradeData.UpgradeType.UNLOCK_SPELL:
                if player.has_method("unlock_spell"):
                    player.call("unlock_spell", upgrade.spell_resource)
            PermanentUpgradeData.UpgradeType.PASSIVE_BONUS:
                if player.has_method("apply_passive_bonus"):
                    player.call("apply_passive_bonus", upgrade.passive_key, upgrade.passive_amount_per_rank * rank)

func apply_selected_class(player: Node) -> void:
    var class_data := get_class_data(selected_class_id)
    if class_data != null and player.has_method("set_class"):
        player.call("set_class", class_data)

func get_class_data(class_id: StringName) -> PlayerClassData:
    if not CLASS_REGISTRY.has(class_id):
        return null

    return load(CLASS_REGISTRY[class_id]) as PlayerClassData

func get_unlocked_class_ids() -> Array[StringName]:
    var ids: Array[StringName] = []
    for key in unlocked_classes.keys():
        if unlocked_classes[key]:
            ids.append(key)
    return ids

func is_class_unlocked(class_id: StringName) -> bool:
    return bool(unlocked_classes.get(class_id, false))

func set_selected_class(class_id: StringName) -> void:
    if not is_class_unlocked(class_id):
        return

    selected_class_id = class_id
    save_progression()

func save_progression() -> void:
    var save_data := {
        "essence": essence,
        "selected_class_id": String(selected_class_id),
        "unlocked_classes": _stringify_keys(unlocked_classes),
        "purchased_ranks": _stringify_keys(purchased_ranks),
    }

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return

    file.store_string(JSON.stringify(save_data))

func load_progression() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        save_progression()
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return

    var raw := file.get_as_text()
    var parsed = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    essence = int(parsed.get("essence", 0))
    selected_class_id = StringName(parsed.get("selected_class_id", "warrior"))

    unlocked_classes = _string_key_dict_to_string_name_dict(parsed.get("unlocked_classes", {&"warrior": true}))
    if not unlocked_classes.has(&"warrior"):
        unlocked_classes[&"warrior"] = true

    purchased_ranks = _string_key_dict_to_string_name_dict(parsed.get("purchased_ranks", {}))

    essence_changed.emit(essence)
    classes_changed.emit(get_unlocked_class_ids())

func _stringify_keys(dict: Dictionary) -> Dictionary:
    var result := {}
    for key in dict.keys():
        result[String(key)] = dict[key]
    return result

func _string_key_dict_to_string_name_dict(dict: Dictionary) -> Dictionary:
    var result := {}
    for key in dict.keys():
        result[StringName(key)] = dict[key]
    return result
