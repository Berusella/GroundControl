extends Node


const ITEMS_DATA_PATH = "res://data/items.json"

var _items_data: Array = []
var _items_by_id: Dictionary = {}


func _ready() -> void:
	_load_items_data()


func _load_items_data() -> void:
	var file = FileAccess.open(ITEMS_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open items file: " + ITEMS_DATA_PATH)
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse items JSON: " + json.get_error_message())
		return

	var data = json.data
	if data.has("items"):
		_items_data = data["items"]
	else:
		_items_data = data

	for item in _items_data:
		var id = item.get("id", -1)
		if id >= 0:
			_items_by_id[id] = item

	print("ItemManager: Loaded %d items" % _items_data.size())


func get_item_by_id(id: int) -> Dictionary:
	if id in _items_by_id:
		return _items_by_id[id].duplicate()

	if 0 in _items_by_id:
		push_warning("Item ID %d not found, defaulting to ID 0" % id)
		return _items_by_id[0].duplicate()

	if not _items_data.is_empty():
		push_warning("Item ID %d not found, defaulting to first item" % id)
		return _items_data[0].duplicate()

	push_error("No items available")
	return {}


func get_item_by_name(item_name: String) -> Dictionary:
	var search_name = item_name.to_lower()
	for item in _items_data:
		var name = item.get("name", "").to_lower()
		if name == search_name or search_name in name:
			return item.duplicate()

	push_warning("Item '%s' not found" % item_name)
	return get_item_by_id(0)


func get_random_item() -> Dictionary:
	if _items_data.is_empty():
		return {}
	return _items_data.pick_random().duplicate()


func get_random_item_by_rarity(max_rarity: int) -> Dictionary:
	var eligible_items: Array = []

	for item in _items_data:
		var rarity = item.get("rarity", 1)
		if rarity <= max_rarity:
			eligible_items.append(item)

	if eligible_items.is_empty():
		if not _items_data.is_empty():
			return _items_data.pick_random().duplicate()
		return {}

	var weighted_pool: Array = []
	for item in eligible_items:
		var rarity = item.get("rarity", 1)
		var weight = max_rarity - rarity + 1  # Higher weight for lower rarity
		for i in range(weight):
			weighted_pool.append(item)

	return weighted_pool.pick_random().duplicate()


func get_all_items() -> Array:
	return _items_data.duplicate()


func has_items() -> bool:
	return not _items_data.is_empty()
