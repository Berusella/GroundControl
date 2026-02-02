extends Node2D

class_name Explosion


const SPRITE_PATH = "res://Sprites/Projectiles/explosion.png"
const DURATION: float = 0.3

var radius: float = 150.0
var sprite: Sprite2D = null


func _ready() -> void:
	z_index = 10
	_setup_sprite()
	_start_timer()


func _setup_sprite() -> void:
	sprite = SpriteFactory.create(SPRITE_PATH)
	add_child(sprite)

	if not sprite.texture:
		push_warning("Explosion texture not found: " + SPRITE_PATH)
		return

	# Scale sprite to match radius (diameter = radius * 2)
	var texture_size = sprite.texture.get_size()
	var target_diameter = radius * 2
	var scale_factor = target_diameter / max(texture_size.x, texture_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)


func _start_timer() -> void:
	var timer = get_tree().create_timer(DURATION)
	timer.timeout.connect(queue_free)
