extends Resource
class_name ClassSpellUnlockData

@export var spell: SpellData
@export_multiline var note: String = ""
@export var conditions: Array[UnlockConditionData] = []

func is_unlocked(context: Dictionary) -> bool:
    if conditions.is_empty():
        return true

    for condition in conditions:
        if condition == null:
            continue
        if not condition.is_met(context):
            return false

    return true
