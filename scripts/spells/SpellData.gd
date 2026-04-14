extends Resource
class_name SpellData

## Définition générique d'un sort.
## Ajouter un nouveau sort = créer une ressource .tres basée sur cette classe.

enum SpellType {
    PROJECTILE,
    AREA_AROUND_CASTER,
    LONG_RANGE_HIT,
}

@export var id: StringName
@export var display_name: String = "Nouveau sort"
@export var spell_type: SpellType = SpellType.PROJECTILE
@export var damage_scaling: PlayerStats.DamageScaling = PlayerStats.DamageScaling.SPELL

@export_group("Gameplay")
@export var damage: int = 10
@export var cooldown: float = 1.0
@export var cast_range: float = 200.0
@export var area_radius: float = 64.0

@export_group("Projectile")
@export var projectile_speed: float = 500.0
@export var projectile_lifetime: float = 1.2
