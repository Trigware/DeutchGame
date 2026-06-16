extends Node2D

@export var is_from_file: bool

@onready var title = $Title

func _ready():
	title.text = "Soubor" if is_from_file else "Autosave"

var position_portion = Vector2(0.98, 0.02)
const button_size = Vector2(60, 60)
const padding_multiplier = 1.45

const default_screen_width = 1152

func _process(_delta):
	var window_size = Vector2(DisplayServer.window_get_size())
	var size_multiplier = window_size.x / default_screen_width
	scale = Vector2.ONE * size_multiplier
	position = window_size * position_portion - button_size * position_portion * size_multiplier
	if is_from_file: position.y += button_size.y * padding_multiplier * size_multiplier
	else: handle_autosave_file_button_visibility()
	handle_mouse_interaction()

const autosave_file_not_present_alpha_modulate = 0.35

var is_interactable = true

func handle_autosave_file_button_visibility():
	is_interactable = FileAccess.file_exists(Save.save_path)
	modulate.a = 1 if is_interactable else autosave_file_not_present_alpha_modulate

func handle_mouse_interaction():
	var local_mouse = get_local_mouse_position()
	var is_hovering = local_mouse.x >= 0 and local_mouse.y >= 0 and\
		local_mouse.x <= button_size.x and local_mouse.y <= button_size.y
	var is_clicking = Input.is_action_just_pressed("button_press")
	if not is_clicking or not is_hovering or not is_interactable: return
	on_click_load_button()

const final_load_from_file_alpha = 0.65
const load_from_file_tween_duration = 0.225

func on_click_load_button():
	if not is_from_file:
		Overlay.switch_scene_def(UID.board_scene, func(_scene): Save.load_game())
		return
	
	Overlay.tween_alpha(final_load_from_file_alpha, load_from_file_tween_duration)
