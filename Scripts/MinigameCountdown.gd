class_name MinigameCountdown
extends CanvasLayer

@onready var countdown = $Countdown

const init_wait_time = 3
var countdown_size: float = maximum_size
var time_until_start: float = init_wait_time
const minimum_size = 175
const maximum_size = 450

var tween_running = false
const start_text = "START"

var minigame_started = true

func _ready():
	if minigame_started:
		GridState.active_game = UID.init_state
		GridState.active_game.restaurant_game_started.emit()
	visible = not minigame_started

func _process(delta: float):
	handle_countdown_time(delta)
	handle_countdown_size()

func handle_countdown_size():
	var window_size = DisplayServer.window_get_size()
	countdown.size = window_size
	countdown.label_settings.font_size = countdown_size
	countdown.label_settings.shadow_offset = Vector2.ONE * countdown_size / 20

const start_modulate_tween_duration = 0.5
const movement_enable_prestart_duration = 0.5

func handle_countdown_time(delta: float):
	time_until_start -= delta
	var countdown_text = str(int(ceil(time_until_start)))
	var show_start_text = time_until_start < 0
	var used_text = start_text if show_start_text else countdown_text
	countdown.text = used_text
	if tween_running: return
	
	tween_running = true
	var is_start_activated = time_until_start < 0
	if is_start_activated: countdown_size = minimum_size
	var final_size = maximum_size if is_start_activated else minimum_size
	var countdown_tween = create_tween().tween_property(self, "countdown_size", final_size, 1).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	if is_start_activated: create_tween().tween_property(countdown, "modulate:a", 0, start_modulate_tween_duration)
	await countdown_tween.finished
	
	tween_running = false
	countdown_size = minimum_size if time_until_start < 0 else maximum_size
	if time_until_start < movement_enable_prestart_duration:
		minigame_started = true
		GridState.active_game.restaurant_game_started.emit()
