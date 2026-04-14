extends Resource
class_name PermanentUpgradeData

enum UpgradeType {
    STAT_BONUS,
    UNLOCK_CLASS,
    UNLOCK_SPELL,
    PASSIVE_BONUS,
}

@export var id: StringName
@export var display_name: String = "Amélioration permanente"
@export_multiline var description: String = ""
@export var upgrade_type: UpgradeType = UpgradeType.STAT_BONUS

@export_group("Économie")
@export var base_cost: int = 50
@export var cost_increment_per_rank: int = 25
@export var max_rank: int = 1

@export_group("Stat")
@export var stat_name: StringName
@export var stat_amount_per_rank: int = 0

@export_group("Déblocage")
@export var class_id: StringName
@export var spell_resource: SpellData

@export_group("Passif")
@export var passive_key: StringName
@export var passive_amount_per_rank: float = 0.0

func get_cost_for_rank(current_rank: int) -> int:
    return base_cost + (current_rank * cost_increment_per_rank)
