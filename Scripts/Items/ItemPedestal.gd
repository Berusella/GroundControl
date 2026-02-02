extends Node2D

class_name ItemPedestal


signal item_picked_up(item_data: Dictionary)

const ITEM_FLOAT_SPEED: float = 2.0
const ITEM_FLOAT_AMPLITUDE: float = 5.0
const ITEM_ROTATION_SPEED: float = 1.5

var item: Item = null
var item_data: Dictionary = {}
var is_item_taken: bool = false

var _float_time: float = 0.0
var _base_item_position: Vector2 = Vector2.ZERO

@onready var pedestal_container: Node2D = $PedestalSprite
@onready var item_container: Node2D = $ItemContainer


func _ready() -> void:
	z_index = 3
	scale = Vector2(2, 2)
	_base_item_position = item_container.position
	_setup_pedestal_sprite()


func _setup_pedestal_sprite() -> void:
	var sprite = SpriteFactory.create_and_attach(pedestal_container, "res://Sprites/Items/pedestal.png")
	sprite.offset = Vector2(0, 8)


func _process(delta: float) -> void:
	if item and not is_item_taken:
		_animate_item(delta)


func _animate_item(delta: float) -> void:
	_float_time += delta

	var float_offset = sin(_float_time * ITEM_FLOAT_SPEED) * ITEM_FLOAT_AMPLITUDE
	item_container.position.y = _base_item_position.y + float_offset

	if item.sprite:
		item.sprite.rotation += delta * ITEM_ROTATION_SPEED


func set_item(data: Dictionary) -> void:
	item_data = data
	_spawn_item()


func set_item_by_id(id: int) -> void:
	var data = ItemManager.get_item_by_id(id)
	set_item(data)


func set_item_by_name(item_name: String) -> void:
	var data = ItemManager.get_item_by_name(item_name)
	set_item(data)


func set_random_item(max_rarity: int = 4) -> void:
	var data = ItemManager.get_random_item_by_rarity(max_rarity)
	set_item(data)


func _spawn_item() -> void:
	if item_data.is_empty():
		push_warning("ItemPedestal: No item data to spawn")
		return

	item = Item.new()
	item.initialize(item_data)

	item.collision_layer = 0
	item.collision_mask = 1
	item.monitoring = true

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	item.add_child(collision)

	var sprite_path = _get_item_sprite_path()
	item.sprite = SpriteFactory.create_and_attach(item, sprite_path)

	item.body_entered.connect(_on_item_picked_up)

	item_container.add_child(item)


func _get_item_sprite_path() -> String:
	var sprite_name = item_data.get("sprite", "")
	return "res://Sprites/Items/" + sprite_name


func _on_item_picked_up(body: Node2D) -> void:
	if body is Player and not is_item_taken:
		is_item_taken = true
		item_picked_up.emit(item_data)
