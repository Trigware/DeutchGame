class_name TimeView
extends CanvasLayer

@export var minigame_countdown: MinigameCountdown
@export var player_root: RestaurantPlayer
@onready var time_label = $Time
@onready var multiplier_label = $Multiplier
@onready var tutorial_button = $Button

const minigame_duration: float = 240
var time_until_end: float = minigame_duration
const start_time_turn_red = 120

const portion_of_window_width = 0.05
const clock_size_multiplier = 0.785
const diameter_label_offset_portion = 0.01
const init_window_size = Vector2(1152, 648)

var was_previously_time_over = false

func _ready():
	pressed_tutorial_button_before = false
	if GameState.active_game != null: pressed_tutorial_button_before = GameState.active_game.restaurant_minigame_explained

func _process(delta: float):
	var window_size = DisplayServer.window_get_size()
	handle_label_content(window_size)
	handle_offset(window_size)
	handle_tutorial_button()
	var in_minigame_restaurant_tutorial = not GameState.active_game.restaurant_minigame_explained
	time_label.visible = not in_minigame_restaurant_tutorial
	multiplier_label.visible = not in_minigame_restaurant_tutorial
	if not minigame_countdown.minigame_started or in_minigame_restaurant_tutorial: return
	time_until_end = max(time_until_end - delta, 0)
	if time_until_end == 0 and not was_previously_time_over:
		on_time_over()

const seconds_in_minute = 60
var label_size: float

const tutorial_button_relative_pos = Vector2(0.975, 0.975)
const base_tutorial_button_scale: float = 1.4
const base_window_size = Vector2(1152, 648)

var pressed_tutorial_button_before = false

func handle_tutorial_button():
	tutorial_button.visible = not pressed_tutorial_button_before
	if pressed_tutorial_button_before: return
	
	var window_size = Vector2(DisplayServer.window_get_size())
	var scale_multiplier = window_size.x / base_window_size.x * base_tutorial_button_scale
	tutorial_button.scale = Vector2.ONE * scale_multiplier
	tutorial_button.position = window_size * tutorial_button_relative_pos - tutorial_button.size * scale_multiplier
	
	var local_mouse = tutorial_button.get_local_mouse_position()
	var is_hovering = local_mouse.x >= 0 and local_mouse.y >= 0 and local_mouse.x <= tutorial_button.size.x and local_mouse.y <= tutorial_button.size.y
	if not is_hovering or not Input.is_action_just_pressed("button_press"): return
	pressed_tutorial_button_before = true
	GameState.active_game.reload_restaurant_minigame()

func handle_label_content(window_size):
	label_size = window_size.x * portion_of_window_width
	var formatted_time = format_time_until_end()
	var size_bbcode = "[font_size=" + str(label_size) + "][img=" + str(label_size * clock_size_multiplier) + "]" 
	var formatted_time_color = get_formatted_time_color()
	var bbcode_color_tag = "[color=" + formatted_time_color.to_html() + "]"
	var label_text = size_bbcode + UID.timer_clock_uid + "[/img]" + bbcode_color_tag + formatted_time
	handle_multiplier_label()
	
	time_label.text = label_text

const init_time_label_pos = Vector2(-1152, -648)
const multiplier_label_x_offset_label_size_portion = 0.85

func handle_offset(window_size):
	var min_win_size = min(window_size.x, window_size.y)
	var is_width_lesser = window_size.x < window_size.y
	var max_min_size_compare = float(window_size.y) / window_size.x if is_width_lesser\
		else float(window_size.x) / window_size.y
	
	var normalized_win_size = Vector2(1, max_min_size_compare) if is_width_lesser\
		else Vector2(max_min_size_compare, 1)
	var window_diameter = sqrt(init_window_size.x ** 2 + init_window_size.y ** 2)
	var label_offset = init_window_size.x * diameter_label_offset_portion
	time_label.position = init_time_label_pos + init_window_size - label_offset * normalized_win_size
	multiplier_label.position = init_time_label_pos + init_window_size - label_offset * normalized_win_size
	multiplier_label.position.x += label_size * multiplier_label_x_offset_label_size_portion
	time_label.size = window_size
	multiplier_label.size = window_size

func format_time_until_end() -> String:
	var minutes = floori(time_until_end / 60)
	var seconds = floori(time_until_end - minutes * seconds_in_minute)
	var seconds_as_str = str(seconds)
	if seconds_as_str.length() == 1: seconds_as_str = "0" + seconds_as_str
	
	var result: String = str(minutes) + ":" + seconds_as_str
	return result

func get_formatted_time_color():
	var color_progress = clamp(time_until_end / start_time_turn_red, 0, 1)
	return Color.RED.lerp(Color.WHITE, color_progress)

const multiplier_label_size_multiplier = 1.35
const maximum_multiplier_label_color_affected_score_multiplier = 2
const final_multiplier_label_modulate = Color.LIME_GREEN

func handle_multiplier_label():
	var multiplier_val = player_root.points_multiplier
	var has_no_decimal = multiplier_val == floor(multiplier_val)
	var multiplier_as_str = str(int(multiplier_val)) if has_no_decimal else str(floor(multiplier_val * 100) / 100)
	multiplier_label.text = "[font_size=" + str(label_size * multiplier_label_size_multiplier) + "]" + str(multiplier_as_str) + "x"
	var full_multiplier_label_color_progress = (min(multiplier_val, maximum_multiplier_label_color_affected_score_multiplier) - 1) / maximum_multiplier_label_color_affected_score_multiplier
	multiplier_label.modulate = Color.WHITE.lerp(final_multiplier_label_modulate, full_multiplier_label_color_progress)

const minigame_cover_overlay_tween_duration = 0.4
const minigame_overlay_inbetween_duration = 0.2

func on_time_over():
	was_previously_time_over = true
	await Overlay.switch_scene(UID.board_scene, minigame_cover_overlay_tween_duration, minigame_overlay_inbetween_duration, game_over_scene_func)

func game_over_scene_func(board_scene: BoardRoot): board_scene.returned_after_minigame = true
