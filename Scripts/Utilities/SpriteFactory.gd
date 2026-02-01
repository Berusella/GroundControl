extends RefCounted

class_name SpriteFactory


static func create(image_path: String) -> Sprite2D:
	var sprite = Sprite2D.new()
	var valid_path = ImageValidator.get_valid_path(image_path)
	sprite.texture = load(valid_path)
	return sprite


static func create_and_attach(parent: Node, image_path: String) -> Sprite2D:
	var sprite = create(image_path)
	parent.add_child(sprite)
	return sprite
