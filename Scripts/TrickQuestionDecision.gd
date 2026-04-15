extends Control

const original_window_height := 648
const header_text_multiplier = 0.825

var prev_window_size: Vector2i
var header_portion : float = 0

@onready var task_wheel = $"Task Wheel"
@onready var header_text = $HeaderText

const final_wheel_pos_y = 0.535
const wheel_tween_duration = 0.75
const wheel_tween_delay = 0.15

func _ready():
	create_tween().tween_property(task_wheel, "wheel_pos_portion:y", final_wheel_pos_y, wheel_tween_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_delay(wheel_tween_delay)
	create_tween().tween_property(self, "header_portion", 1, wheel_tween_duration).set_ease(Tween.EASE_IN_OUT)
	var current_turn = SpecialTile.TeamRelation.Red
	if GridState.active_game != null: current_turn = GridState.active_game.player_turn
	var playing_team_member_count = GridState.active_game.team_member_count[current_turn]
	task_wheel.number_of_segments = playing_team_member_count
	task_wheel.wheel_spin_finished.connect(on_wheel_spin_finished)

func _process(_delta):
	update_wheel()

func update_wheel():
	var window_size: Vector2 = DisplayServer.window_get_size()
	header_text.size.x = window_size.x * 2
	var header_scale_component = window_size.y / original_window_height * header_text_multiplier
	var header_scale = Vector2(header_scale_component, header_scale_component)
	header_text.scale = header_scale
	
	header_text.position.x = -window_size.x * (header_scale_component-1) / 2
	header_text.position.y = -header_text.size.y * header_scale_component * (1 - header_portion)
	header_text.position.x -= window_size.x * header_scale_component / 2

func on_wheel_spin_finished():
	await get_tree().create_timer(0.25).timeout
	create_tween().tween_property(task_wheel, "wheel_pos_portion:x", 0.25, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await create_tween().tween_property(task_wheel, "wheel_size_multiplier", 0.45, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).finished
