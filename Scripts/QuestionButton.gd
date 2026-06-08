class_name QuestionButton
extends Control

@export var button_type := ButtonType.Unknown:
	set(value): button_type = value; update_button()

@onready var button_label = $Label
@onready var button_base = $"Button Base"
var question_subscene
var question_root: Question

enum ButtonType {
	Unknown,
	ShowAnswers,
	Incorrect,
	Correct
}

var mouse_inside_button: bool = false
var button_index: int

const button_text: Dictionary[ButtonType, String] =\
	{ButtonType.ShowAnswers: "Odpovědi", ButtonType.Incorrect: "Špatně", ButtonType.Correct: "Správně"}
const button_colors: Dictionary[ButtonType, Color] =\
	{ButtonType.ShowAnswers: Color("3585b0ff"), ButtonType.Incorrect: Color("a83232ff"), ButtonType.Correct: Color("32a846ff")}

const button_label_value_offset = 0.185
const button_size = Vector2(191, 51)

var button_saturation_progress: float = 1.0
const max_button_saturation = 0.7
const offset_from_center = 0.3
const button_relative_center_x = 0.5

func _ready():
	hide()
	await get_tree().process_frame
	show()
	button_relative_pos.y = final_y_progress_after_press
	create_tween().tween_property(self, "button_relative_pos:y", init_relative_y_pos, after_press_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	button_relative_pos.x = button_relative_center_x
	if question_root.number_of_question_buttons == 2:
		button_relative_pos.x = button_relative_center_x - offset_from_center if button_index == 0\
			else button_relative_center_x + offset_from_center

func update_button():
	if button_type == ButtonType.Unknown or button_label == null: return
	button_label.text = button_text[button_type]
	var button_base_color = button_colors[button_type]
	var button_saturation = button_saturation_progress * max_button_saturation
	button_base_color.s = button_saturation
	
	button_base.modulate = button_base_color
	var button_label_color = button_base_color
	button_label_color.v += button_label_value_offset
	button_label.modulate = button_label_color

const init_relative_y_pos = 0.825
var button_relative_pos: Vector2
const base_button_scale: float = 1.55
const base_window_minimal_component: float = 648

func _process(delta: float):
	handle_button_transform(self)
	handle_mouse_interaction()
	update_button()

static func handle_button_transform(button):
	var window_size = DisplayServer.window_get_size()
	var min_dimen_size: float = min(window_size.x, window_size.y)
	var multiplier_win_size_diff = min_dimen_size / base_window_minimal_component
	var button_scale = base_button_scale * multiplier_win_size_diff
	
	var final_position = Vector2(window_size) - button_size * button_scale
	button.position = final_position * button.button_relative_pos
	button.scale = Vector2.ONE * button_scale

const grayscale_button_distance = 60

static func handle_button_mouse_interaction(button):
	var local_mouse = button.get_local_mouse_position()
	var x_inside_box = local_mouse.x >= 0 and local_mouse.x <= button_size.x
	var y_inside_box = local_mouse.y >= 0 and local_mouse.y <= button_size.y
	var distance_vec := Vector2(
		min(abs(local_mouse.x - button_size.x), abs(-local_mouse.x)),
		min(abs(local_mouse.y - button_size.y), abs(-local_mouse.y))
	)
	var not_in_any_button_axis = not x_inside_box and not y_inside_box
	var inside_of_button = x_inside_box and y_inside_box
	
	var distance_from_button: float
	if inside_of_button:
		distance_from_button = 0
		if Input.is_action_just_pressed("button_press"): button.on_press()
	elif not_in_any_button_axis: distance_from_button = distance_vec.length()
	elif y_inside_box: distance_from_button = distance_vec.x
	elif x_inside_box: distance_from_button = distance_vec.y
	
	button.button_saturation_progress = 1 - clamp(distance_from_button / grayscale_button_distance, 0, 1)

func handle_mouse_interaction(): handle_button_mouse_interaction(self)

var pressed_previously = false
const after_press_tween_duration = 0.6
const final_y_progress_after_press = 1.35

func on_press():
	if pressed_previously or question_root.evaluating_question: return
	Audio.play_sound(UID.button_clicked_sfx)
	pressed_previously = true
	create_tween().tween_property(self, "button_relative_pos:y", final_y_progress_after_press, after_press_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(self, "modulate:a", 0, after_press_tween_duration)
	
	if button_type != ButtonType.ShowAnswers:
		question_root.on_answer_evaluate(button_type == ButtonType.Correct)
		return
	
	question_subscene.show_answers()
	question_root.on_show_answers(true)
