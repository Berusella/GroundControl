extends CanvasLayer

class_name GameOver


signal restart_pressed
signal exit_pressed

var collected_items: Array[Dictionary] = []

@onready var items_container: VBoxContainer = $Panel/VBoxContainer/ItemsScroll/ItemsContainer


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Panel/VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$Panel/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)


func show_game_over(items: Array[Dictionary]) -> void:
	collected_items = items
	_populate_items()
	visible = true
	get_tree().paused = true


func _populate_items() -> void:
	for child in items_container.get_children():
		child.queue_free()

	if collected_items.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "No items collected"
		no_items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_container.add_child(no_items_label)
		return

	for item in collected_items:
		var item_label = Label.new()
		item_label.text = "- " + item.get("name", "Unknown Item")
		items_container.add_child(item_label)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	restart_pressed.emit()


func _on_exit_pressed() -> void:
	get_tree().paused = false
	exit_pressed.emit()
