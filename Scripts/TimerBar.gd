extends CanvasLayer

@onready var timer_ui_root = $"Timer UI Root"
@onready var progress_bar = $"Timer UI Root/Progress Bar"
@onready var timeout_label = $"Timer UI Root/Timeout Label"

const progress_bar_width = 630
var progress_to_timeout: float = 0
const base_window_minimal_component: float = 648
const base_timebar_scale = 1.115
const timebar_height = 40
const timerbar_y_multiplier = 1.5
var timerbar_y_progress: float = 1

var timeout_reached_before = false

func _ready():
	timeout_label.modulate.a = 0

func _process(_delta):
	var window_size = DisplayServer.window_get_size()
	var min_dimen_size: float = min(window_size.x, window_size.y)
	var multiplier_win_size_diff = min_dimen_size / base_window_minimal_component
	var timebar_scale = base_timebar_scale * multiplier_win_size_diff
	
	var timebar_x = window_size.x / 2 - progress_bar_width * timebar_scale / 2
	var timebar_y = window_size.y - timebar_height * timebar_scale * timerbar_y_multiplier * timerbar_y_progress
	timer_ui_root.position = Vector2(timebar_x, timebar_y)
	timer_ui_root.scale = Vector2.ONE * timebar_scale
	progress_bar.value = progress_to_timeout
	
	if progress_to_timeout >= 1 and not timeout_reached_before:
		timeout_reached_before = true
		create_tween().tween_property(timeout_label, "modulate:a", 1, timeout_label_modulate_alpha_tween_duration)

const timeout_label_modulate_alpha_tween_duration = 0.6
