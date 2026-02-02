extends Area2D

class_name NextFloor


const SPRITE_PATH = "res://Sprites/Tiles/Forest/next_floor.png"

var sprite: Sprite2D = null


func _ready() -> void:
	_setup_sprite()
	_setup_collision()
	body_entered.connect(_on_body_entered)


func _setup_sprite() -> void:
	sprite = SpriteFactory.create_and_attach(self, SPRITE_PATH)


func _setup_collision() -> void:
	# Create collision shape if not already present
	if not has_node("CollisionShape2D"):
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 20.0
		collision.shape = shape
		add_child(collision)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_go_to_next_floor()


func _go_to_next_floor() -> void:
	var floor_manager = _get_floor_manager()
	if floor_manager:
		floor_manager.go_to_next_floor()


func _get_floor_manager() -> FloorManager:
	var main = get_tree().current_scene
	for child in main.get_children():
		if child is FloorManager:
			return child
	return null
