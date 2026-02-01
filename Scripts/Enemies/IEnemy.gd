extends ICharacter

class_name IEnemy


var target: Node2D = null
var attack_damage: int = 10
var attack_range: float = 50.0
var detection_range: float = 200.0
var sprite: Sprite2D = null
var sprite_path: String = ""


func _ready() -> void:
	_setup_sprite()


func _setup_sprite() -> void:
	if not sprite_path.is_empty():
		sprite = SpriteFactory.create_and_attach(self, sprite_path)


func attack() -> void:
	pass


func detect_player() -> void:
	pass


func chase_target() -> void:
	pass


func on_death() -> void:
	pass
