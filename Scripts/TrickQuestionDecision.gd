extends Control

const original_window_height := 648
const header_text_multiplier = 0.825

var prev_window_size: Vector2i
var header_portion : float = 0

@onready var player_wheel = $"Player Wheel"
@onready var minigame_wheel = $"Minigame Wheel"
@onready var header_text = $HeaderText
@onready var ready_button: Node2D = $ReadyButton

const init_player_wheel_portion = Vector2(0.5, 3)
const final_player_wheel_portion = Vector2(0.5, 0.6)
const header_tween_duration = 0.75
const bbcode_effects = "[pulse color=#ffffff66][wave amp=75]"
var ready_button_y_portion: float = 1
var time_since_pressed_ready: float = 0

func set_header_text(str: String):
	header_text.text = bbcode_effects + str

const amount_of_minigames = 6

func _ready():
	set_header_text("Výběr hráče!")
	player_wheel.tween_portion_init(init_player_wheel_portion, final_player_wheel_portion)
	minigame_wheel.wheel_pos_portion = minigame_init_pos_portion
	minigame_wheel.number_of_segments = amount_of_minigames
	header_pos_tween(1)
	
	var current_turn = SpecialTile.TeamRelation.Red
	if GameState.active_game != null: current_turn = GameState.active_game.player_turn
	var member_count_dict = GameState.active_game.team_member_count
	var playing_team_member_count = member_count_dict[current_turn] if current_turn in member_count_dict else 1
	player_wheel.number_of_segments = playing_team_member_count
	player_wheel.wheel_spin_finished.connect(on_player_wheel_spin_finished)
	minigame_wheel.wheel_spin_finished.connect(on_minigames_wheel_spin_finished)

func header_pos_tween(final: float):
	await create_tween().tween_property(self, "header_portion", final, header_tween_duration).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).finished

const wheel_speed = 0.05

func _process(delta):
	update_wheel()
	if can_press_ready: time_since_able_to_press_ready += delta
	if pressed_ready_button: time_since_pressed_ready += delta

const ready_button_max_anim_range = 0.085
const ready_button_anim_dur = 2.5
const ready_button_scale_portion = 0.35

func update_wheel():
	var window_size: Vector2 = DisplayServer.window_get_size()
	header_text.size.x = window_size.x * 2
	var header_scale_component = window_size.y / original_window_height * header_text_multiplier
	var header_scale = Vector2(header_scale_component, header_scale_component)
	header_text.scale = header_scale
	
	header_text.position.x = -window_size.x * (header_scale_component-1) / 2
	header_text.position.y = -header_text.size.y * header_scale_component * (1 - header_portion)
	header_text.position.x -= window_size.x * header_scale_component / 2
	if can_press_ready:
		ready_button_y_portion = ready_final_tween_y + sin(time_since_able_to_press_ready * ready_button_anim_dur)\
		* ready_button_max_anim_range * min(time_since_able_to_press_ready, 1)
	
	var ready_scale = window_size.x / ready_button_width * ready_button_scale_portion
	ready_button.scale = Vector2(ready_scale, ready_scale)
	
	ready_button.position = window_size / 2
	ready_button.position.y = window_size.y * ready_button_y_portion
	handle_ready_button()

const minigame_init_pos_portion = Vector2(2, final_player_wheel_portion.y)
const minigame_final_pos_portion = Vector2(0.5, final_player_wheel_portion.y)

func change_header_text_tweened(new_text: String):
	await header_pos_tween(0)
	set_header_text(new_text)
	await header_pos_tween(1)

const wheel_after_spin_tween_delay = 0.25
const wheel_x_dist_from_edge = 0.05
const wheel_after_spin_final_size_multiplier = 0.45

func after_spin_wheel_tween(wheel: FortuneWheel, goes_left: bool):
	await get_tree().create_timer(wheel_after_spin_tween_delay).timeout
	var after_spin_player_x_portion = wheel_x_dist_from_edge
	if not goes_left: after_spin_player_x_portion = 1 - wheel_x_dist_from_edge
	create_tween().tween_property(wheel, "wheel_pos_portion:x", after_spin_player_x_portion, 1).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await create_tween().tween_property(wheel, "wheel_size_multiplier", wheel_after_spin_final_size_multiplier, 1).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).finished
	wheel.tween_show_modulate(0)

func on_player_wheel_spin_finished():
	await after_spin_wheel_tween(player_wheel, true)
	on_minigames_wheel_spin_finished()
	#minigame_wheel.tween_portion(minigame_final_pos_portion)
	#change_header_text_tweened("Výběr minihry!")

const ready_button_y_move_tween_dur = 0.75
const ready_final_tween_y = 0.5
const ready_tween_delay = 1.15
var can_press_ready = false
var time_since_able_to_press_ready = 0

func on_minigames_wheel_spin_finished():
	#after_spin_wheel_tween(minigame_wheel, false)
	change_header_text_tweened("Stiskněte READY!")
	await get_tree().create_timer(ready_tween_delay).timeout
	await create_tween().tween_property(self, "ready_button_y_portion", ready_final_tween_y, ready_button_y_move_tween_dur).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).finished
	can_press_ready = true

const y_ready_center_offset = 28
const ready_button_interaction_box = Vector2(100, 40)
const final_ready_button_modulate = Color("9efaff")
const minimal_ready_button_interaction = 0.25
var pressed_ready_button = false
const ready_button_width = 170

func handle_ready_button():
	var local_mouse = ready_button.get_local_mouse_position()
	local_mouse.y -= y_ready_center_offset
	var interaction_progress_vec = abs(local_mouse / ready_button_interaction_box)
	var interaction_progress = min(max(interaction_progress_vec.x, interaction_progress_vec.y), 1)
	if local_mouse.x > ready_button_interaction_box.x or local_mouse.y > ready_button_interaction_box.y:
		interaction_progress = 1
	interaction_progress = max(1 - interaction_progress - time_since_pressed_ready, 0)
	
	ready_button.modulate = Color.WHITE.lerp(final_ready_button_modulate, interaction_progress)
	if interaction_progress < minimal_ready_button_interaction: return
	if not Input.is_action_just_pressed("select_ready_button") or not can_press_ready: return
	var additional_interactable_dur = fmod(time_since_able_to_press_ready, PI)
	pressed_ready_button = true
	can_press_ready = false
	Overlay.switch_scene(UID.restaurant_minigame)
