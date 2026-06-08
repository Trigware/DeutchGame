class_name TutorialButton
extends Control

signal button_pressed

@onready var button_base = $Button

func _process(_delta):
	handle_position_and_scale()
	handle_mouse_interaction()

var relative_pos = Vector2(0.99, 0.015)
var relative_size = 0.1

func handle_position_and_scale():
	var window_size = Vector2(DisplayServer.window_get_size())
	var scale_multiplier = min(window_size.x, window_size.y) * relative_size / button_base.size.x
	position = window_size * relative_pos
	position.x -= button_base.size.x * scale_multiplier
	scale = Vector2.ONE * scale_multiplier

func handle_mouse_interaction():
	var local_mouse = button_base.get_local_mouse_position()
	var is_hovering = local_mouse.x >= 0 and local_mouse.y >= 0 and\
		local_mouse.x <= button_base.size.x and local_mouse.y <= button_base.size.y
	var tutorial_dialog_index = GameState.active_game.current_dialog_index
	var is_button_disabled = tutorial_dialog_index in TutorialUI.disabled_tutorial_progress_dialog_indices
	visible = not is_button_disabled
	if is_button_disabled: return
	
	var is_clicking = Input.is_action_just_pressed("button_press")
	if not is_hovering or not is_clicking: return
	button_pressed.emit()
