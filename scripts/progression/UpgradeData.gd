extends Resource
class_name UpgradeData

enum UpgradeType {
    STAT_INCREASE,
    UNLOCK_SPELL,
    UPGRADE_SPELL,
    PASSIVE_BONUS,
}

@export var id: StringName
@export var display_name: String = "Amélioration"
@export_multiline var description: String = ""
@export var upgrade_type: UpgradeType = UpgradeType.STAT_INCREASE

@export_group("Stat")
@export var stat_name: StringName
@export var stat_amount: int = 0

@export_group("Sort")
@export var spell_resource: SpellData
@export var target_spell_id: StringName
@export var spell_damage_bonus: int = 0
@export var spell_cooldown_multiplier: float = 1.0

@export_group("Passif")
@export var passive_key: StringName
@export var passive_value: float = 0.0
