extends Area2D

class_name IProjectile


var direction: Vector2 = Vector2.ZERO
var speed: float = 300.0
var damage: int = 0
var owner_node: Node2D = null
var sprite: Sprite2D = null
var sprite_path: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_sprite()


func _setup_sprite() -> void:
	if not sprite_path.is_empty():
		sprite = SpriteFactory.create_and_attach(self, sprite_path)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func initialize(shooter: Node2D, dir: Vector2) -> void:
	owner_node = shooter
	direction = dir.normalized()
	if shooter is Player:
		damage = shooter.power


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	if body is ICharacter:
		body.take_damage(damage)
	queue_free()
