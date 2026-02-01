extends ICharacter

class_name Player


const SPRITE_PATH = "res://Sprites/Characters/Player/player.png"

var keys: int = 0
var sprite: Sprite2D = null


func _ready() -> void:
	_setup_stats()
	_setup_sprite()


func _setup_stats() -> void:	
	health = 100
	max_health = 100
	speed = 200
	power = 3
	is_alive = true


func _setup_sprite() -> void:
	sprite = SpriteFactory.create_and_attach(self, SPRITE_PATH)


func _physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("Move_left", "Move_right")
	direction.y = Input.get_axis("Move_up", "Move_down")
	direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		die()


func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health


func die() -> void:
	is_alive = false
	queue_free()
