extends StaticBody2D

class_name Obstacle


const SPRITE_PATH = "res://Sprites/Tiles/Forest/tileset_obstacles.png"
const OBSTACLE_SIZE: float = 32.0

var sprite: Sprite2D = null


func _ready() -> void:
	_setup_sprite()
	_setup_collision()


func _setup_sprite() -> void:
	sprite = SpriteFactory.create(SPRITE_PATH)
	add_child(sprite)


func _setup_collision() -> void:
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(OBSTACLE_SIZE, OBSTACLE_SIZE)
	collision.shape = shape
	add_child(collision)
