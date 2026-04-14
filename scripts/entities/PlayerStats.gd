class_name PlayerStats
extends Resource

## Système centralisé d'équilibrage des statistiques joueur.
## Toute la traduction stats -> gameplay est définie ici.

enum DamageScaling {
    PHYSICAL,
    SPELL,
}

@export_group("Attributs principaux")
@export var vitalite: int = 10
@export var force: int = 10
@export var intelligence: int = 10
@export var agilite: int = 10
@export var defense: int = 10
@export var vitesse: int = 10
@export var chance: int = 10

@export_group("PV et mobilité")
@export var base_health: int = 100
@export var health_per_vitalite: int = 12
@export var speed_per_vitesse: float = 4.0
@export var speed_per_agilite: float = 1.5

@export_group("Offensif")
@export var physical_damage_per_force: float = 0.025
@export var spell_damage_per_intelligence: float = 0.03
@export var cooldown_reduction_per_agilite: float = 0.012
@export var max_cooldown_reduction: float = 0.50

@export_group("Défensif et critique")
@export var flat_damage_reduction_per_defense: float = 0.35
@export var min_taken_damage: int = 1
@export var crit_chance_per_chance: float = 0.005
@export var max_crit_chance: float = 0.45
@export var crit_damage_multiplier: float = 1.75

func get_max_health() -> int:
    return base_health + (vitalite * health_per_vitalite)

func get_move_speed(base_speed: float) -> float:
    return base_speed + (vitesse * speed_per_vitesse) + (agilite * speed_per_agilite)

func get_cooldown_duration(base_cooldown: float) -> float:
    var reduction := min(agilite * cooldown_reduction_per_agilite, max_cooldown_reduction)
    return base_cooldown * (1.0 - reduction)

func compute_outgoing_damage(base_damage: int, scaling: DamageScaling) -> Dictionary:
    var multiplier := _get_damage_multiplier_for_scaling(scaling)
    var scaled_damage := max(int(round(base_damage * multiplier)), 1)

    var critical := _roll_critical_hit()
    var final_damage := scaled_damage
    if critical:
        final_damage = max(int(round(scaled_damage * crit_damage_multiplier)), 1)

    return {
        "final_damage": final_damage,
        "is_critical": critical,
    }

func compute_damage_reduction(raw_damage: int) -> int:
    var reduced := raw_damage - int(defense * flat_damage_reduction_per_defense)
    return max(reduced, min_taken_damage)

func get_critical_chance() -> float:
    return min(chance * crit_chance_per_chance, max_crit_chance)

func _get_damage_multiplier_for_scaling(scaling: DamageScaling) -> float:
    match scaling:
        DamageScaling.PHYSICAL:
            return 1.0 + (force * physical_damage_per_force)
        DamageScaling.SPELL:
            return 1.0 + (intelligence * spell_damage_per_intelligence)
        _:
            return 1.0

func _roll_critical_hit() -> bool:
    return randf() <= get_critical_chance()


func apply_stat_bonus(stat_name: StringName, amount: int) -> void:
    if amount == 0:
        return

    match stat_name:
        &"vitalite":
            vitalite += amount
        &"force":
            force += amount
        &"intelligence":
            intelligence += amount
        &"agilite":
            agilite += amount
        &"defense":
            defense += amount
        &"vitesse":
            vitesse += amount
        &"chance":
            chance += amount
