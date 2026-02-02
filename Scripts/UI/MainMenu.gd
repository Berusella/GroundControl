extends CanvasLayer

class_name MainMenu


signal new_run_pressed
signal exit_pressed


func _ready() -> void:
	$Panel/VBoxContainer/NewRunButton.pressed.connect(_on_new_run_pressed)
	$Panel/VBoxContainer/ExitButton.pressed.connect(_on_exit_pressed)


func _on_new_run_pressed() -> void:
	new_run_pressed.emit()


func _on_exit_pressed() -> void:
	exit_pressed.emit()
