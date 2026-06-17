class_name Question
extends Control

var question_total_time: float = 30
var time_left: float

enum QuestionType {
	Unknown = -1,
	IngredientQuestion,
	ClockQuestion,
	FamilyTree
}

@onready var time_left_label = $TimeLeft
@onready var tiled_diagonals: TiledDiagonals = $"Tiled Diagonals"
@onready var question_title = $"Question Title"
@onready var timer_bar = $TimerBar
@onready var ready_button = $ReadyButton
var question_type := QuestionType.Unknown

const decimal_show_threshold = 10
const max_tiled_diagonals_saturation = 0.4
const time_label_modulate_start_portion = 0.5
const tiled_diagonals_gap_size = 0.55
const base_question_titles_y_pos = -200
const ui_show_up_tween_duration = 0.6
const final_question_titles_y_pos = 22

var timeout_previously = false
var pressed_ready = false
var ready_from_init = pressed_ready

signal pressed_ready_event

func _ready():
	Audio.play_music(UID.quiz_music)
	time_left = question_total_time
	question_title.position.y = base_question_titles_y_pos
	create_tween().tween_property(question_title, "position:y", final_question_titles_y_pos, ui_show_up_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	pick_question_type()
	if not pressed_ready: await pressed_ready_event
	add_question_scene()

func _process(delta: float):
	style_tiled_diagonals(delta)
	display_time_left(delta)
	account_for_window_sizes()
	handle_ready_button()
	update_question_text()

var ready_button_relative_pos = Vector2(0.5, 0.5)
const ready_button_size = Vector2(110, 40)
const ready_button_screen_size_portion = 0.2
const button_origin_offset = Vector2(-79, 13)
const ready_button_tween_duration = 0.5

func handle_ready_button():
	if ready_from_init:
		ready_button.hide()
		return
	
	var window_size = Vector2(DisplayServer.window_get_size())
	var scale_multiplier = window_size.y * ready_button_screen_size_portion / ready_button_size.y
	ready_button.position = window_size * ready_button_relative_pos
	ready_button.position.y -= ready_button_size.y * scale_multiplier / 2
	ready_button.scale = Vector2.ONE * scale_multiplier
	
	var local_mouse = ready_button.get_local_mouse_position()
	local_mouse -= button_origin_offset
	var hovering_over_button = local_mouse.x >= 0 and local_mouse.y >= 0 and\
		local_mouse.x <= ready_button_size.x and local_mouse.y <= ready_button_size.y
	var is_clicking = Input.is_action_just_pressed("button_press")
	if not hovering_over_button or not is_clicking or pressed_ready: return
	
	pressed_ready_event.emit()
	pressed_ready = true
	create_tween().tween_property(ready_button, "modulate:a", 0, ready_button_tween_duration * 2.0/3)
	create_tween().tween_property(self, "ready_button_relative_pos:y", 1, ready_button_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

func display_time_left(delta: float):
	var time_with_decimal = int(time_left * 10) / 10.0
	var show_integer = time_left >= decimal_show_threshold
	var time_label_text = str(int(time_left)) if show_integer else str(time_with_decimal)
	
	if time_left == 0: time_label_text = "0"
	time_label_text += 's'
	time_left_label.text = font_size_bbcode(time_left_font_size, time_label_text)
	if not shown_answers_early and pressed_ready: time_left = max(time_left - delta, 0)
	if time_left != 0 or timeout_previously: return
	
	timeout_previously = true
	on_show_answers()

var timeout_progress: float

func style_tiled_diagonals(delta: float):
	timeout_progress = 1 - time_left / question_total_time
	if is_nan(timeout_progress): timeout_progress = 1
	var diagonals_saturation = (1 - timeout_progress) * max_tiled_diagonals_saturation
	tiled_diagonals.line_color.s = diagonals_saturation
	tiled_diagonals.gap_size = tiled_diagonals_gap_size
	timer_bar.progress_to_timeout = timeout_progress

const time_left_label_x_offset = 15
const time_left_label_total_edge_offset = 6.5
const base_window_minimal_component: float = 648
const base_time_left_label_font_size = 70
const time_left_label_base_size = 115

var question_title_font_size: float
var time_left_font_size: float

func account_for_window_sizes():
	var window_size = DisplayServer.window_get_size()
	var normalized_window_size = Vector2(window_size).normalized()
	var time_left_label_pos = -normalized_window_size * time_left_label_total_edge_offset
	time_left_label_pos = Vector2(time_left_label_pos.x - time_left_label_x_offset, time_left_label_pos.y)
	
	var min_dimen_size: float = min(window_size.x, window_size.y)
	var multiplier_win_size_diff = min_dimen_size / base_window_minimal_component
	question_title_font_size = base_time_left_label_font_size * multiplier_win_size_diff
	time_left_font_size = time_left_label_base_size * multiplier_win_size_diff
	
	time_left_label.position = time_left_label_pos
	tiled_diagonals.size = window_size
	time_left_label.size = window_size
	
	question_title.size.x = window_size.x

const german_question_title_dict : Dictionary[QuestionType, String] = {
	QuestionType.IngredientQuestion: "Diese Essen in Deutsch!",
	QuestionType.ClockQuestion: "Wieviel Uhr ist es?",
	QuestionType.FamilyTree: "QGermanFamilyTree"
}

const czech_question_title_dict : Dictionary[QuestionType, String] = {
	QuestionType.IngredientQuestion: "Přeložte tato jídla do němčiny!",
	QuestionType.ClockQuestion: "Řekněte v němčině, kolik hodin je na obrázku!",
	QuestionType.FamilyTree: "QEnglishFamilyTree"
}

var german_question: String
var czech_question: String

func pick_question_type():
	var max_question_index = QuestionType.size() - 1
	var picked_question_index = randi_range(1, max_question_index)
	question_type = QuestionType.FamilyTree
	german_question = german_question_title_dict[question_type]
	czech_question = czech_question_title_dict[question_type]

const press_ready_notice_text_upper = "Zmáčkněte READY!"
const press_ready_notice_text_lower = "Pak se spustí otázka."

func update_question_text():
	var displayed_upper = german_question if pressed_ready else press_ready_notice_text_upper
	var displayed_lower = czech_question if pressed_ready else press_ready_notice_text_lower
	var compounded_question = font_size_bbcode(question_title_font_size, displayed_upper) + '\n' +\
		font_size_bbcode(question_title_font_size / 2, displayed_lower)
	question_title.text = compounded_question

func font_size_bbcode(font_size: float, inner_text: String):
	return "[font_size=" + str(font_size) + "]" + inner_text + "[/font_size]"

var answer_button: QuestionButton

func create_question_button(button_type: QuestionButton.ButtonType, question_subscene = null, index = 0) -> QuestionButton:
	var question_button = UID.question_button.instantiate()
	question_button.button_type = button_type
	question_button.question_subscene = question_subscene
	question_button.question_root = self
	question_button.button_index = index
	add_child(question_button)
	return question_button

func add_question_scene():
	var question_subscene = UID.question_subscene_dict[question_type].instantiate()
	add_child(question_subscene)
	answer_button = create_question_button(QuestionButton.ButtonType.ShowAnswers, question_subscene)
	
	number_of_question_buttons = 1

var number_of_question_buttons = 0
var shown_answers_early = false

func on_show_answers(interacted_with_answer_button = false):
	if not interacted_with_answer_button: answer_button.on_press()
	shown_answers_early = true
	number_of_question_buttons = 2
	if not interacted_with_answer_button: return
	create_question_button(QuestionButton.ButtonType.Correct, null, 0)
	create_question_button(QuestionButton.ButtonType.Incorrect, null, 1)

var evaluating_question = false

func on_answer_evaluate(answered_correctly: bool):
	if evaluating_question: return
	evaluating_question = true
	var scene_modifier = func(board_scene: BoardRoot): board_scene.push_piece()
	var used_modifier = scene_modifier if answered_correctly else func(board_scene: BoardRoot): board_scene.returned_to_board = true
	Overlay.switch_scene_def(UID.board_scene, used_modifier)
