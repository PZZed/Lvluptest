extends Area2D

## Projectile générique utilisé par les sorts de type projectile.

var damage: int = 0
var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var remaining_lifetime: float = 1.2

func initialize(new_damage: int, new_direction: Vector2, new_speed: float, new_lifetime: float) -> void:
    damage = new_damage
    direction = new_direction.normalized()
    speed = new_speed
    remaining_lifetime = new_lifetime

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
    remaining_lifetime -= delta

    if remaining_lifetime <= 0.0:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if body.has_method("receive_damage"):
        body.call("receive_damage", damage)
        queue_free()
