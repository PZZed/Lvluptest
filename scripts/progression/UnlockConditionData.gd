extends Resource
class_name UnlockConditionData

enum ConditionType {
    PLAYER_LEVEL,
    WAVE_REACHED,
    BOSS_DEFEATED,
    EVENT_FLAG,
}

@export var condition_type: ConditionType = ConditionType.PLAYER_LEVEL
@export var required_value: int = 1
@export var required_id: StringName

func is_met(context: Dictionary) -> bool:
    match condition_type:
        ConditionType.PLAYER_LEVEL:
            return int(context.get("player_level", 1)) >= required_value
        ConditionType.WAVE_REACHED:
            return int(context.get("wave", 1)) >= required_value
        ConditionType.BOSS_DEFEATED:
            var defeated_bosses: Dictionary = context.get("defeated_bosses", {})
            return defeated_bosses.has(required_id)
        ConditionType.EVENT_FLAG:
            var run_events: Dictionary = context.get("run_events", {})
            return run_events.has(required_id)
        _:
            return false
