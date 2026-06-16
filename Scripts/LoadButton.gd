extends Node2D

@export var is_from_file: bool
@export var file_drop_label: Label

@onready var title = $Title

func _ready():
	title.text = "Soubor" if is_from_file else "Autosave"
	if not is_from_file: return
	get_window().files_dropped.connect(on_files_dropped)

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
	
	handle_file_drop_label()

const autosave_file_not_present_alpha_modulate = 0.35

var is_interactable = true
var is_dropping_files = false

func handle_file_drop_label():
	if file_drop_label == null: return
	file_drop_label.modulate.a = 0
	if not is_dropping_files: return
	
	var overlay_alpha = Overlay.alpha_value
	var file_drop_modulate = overlay_alpha / final_load_from_file_alpha
	if overlay_alpha > final_load_from_file_alpha:
		file_drop_modulate = 1 - (overlay_alpha - final_load_from_file_alpha) / (1 - final_load_from_file_alpha)
	file_drop_label.modulate.a = file_drop_modulate

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
		Overlay.switch_scene_def(UID.board_scene, func(_scene): Save.load_autosave())
		return
	
	if not is_dropping_files:
		on_drop_files()
		return
	
	Overlay.tween_alpha(0, load_from_file_tween_duration)
	is_dropping_files = false

func on_drop_files():
	Overlay.tween_alpha(final_load_from_file_alpha, load_from_file_tween_duration)
	is_dropping_files = true

func on_files_dropped(dropped_files):
	if dropped_files.size() != 1: return
	var dropped_file_path = dropped_files[0]
	Overlay.switch_scene_def(UID.board_scene, func(_scene): Save.load_game(dropped_file_path))
