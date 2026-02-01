extends RefCounted

class_name ImageValidator


const ERROR_IMAGE_PATH = "res://Sprites/error_image.png"


static func get_valid_path(image_path: String) -> String:
	if ResourceLoader.exists(image_path):
		return image_path
	return ERROR_IMAGE_PATH


static func exists(image_path: String) -> bool:
	return ResourceLoader.exists(image_path)
