extends Resource
class_name PlayerClassData

@export var id: StringName
@export var display_name: String = "Classe"
@export_multiline var description: String = ""

@export var base_stats: PlayerStats
@export var starting_spells: Array[SpellData] = []
@export var unlockable_spells: Array[ClassSpellUnlockData] = []
