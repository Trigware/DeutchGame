class_name Question
extends Control

var question_total_time: float = 15
var time_left: float

enum QuestionType {
	Unknown = -1,
	IngredientQuestion
}

@onready var time_left_label = $TimeLeft
@onready var tiled_diagonals: TiledDiagonals = $"Tiled Diagonals"
@onready var question_title = $"Question Title"
@onready var timer_bar = $TimerBar
var question_type := QuestionType.Unknown

const decimal_show_threshold = 10
const max_tiled_diagonals_saturation = 0.4
const time_label_modulate_start_portion = 0.5
const tiled_diagonals_gap_size = 0.55
const base_question_titles_y_pos = -200
const ui_show_up_tween_duration = 0.6
const final_question_titles_y_pos = 22

func _ready():
	time_left = question_total_time
	question_title.position.y = base_question_titles_y_pos
	create_tween().tween_property(question_title, "position:y", final_question_titles_y_pos, ui_show_up_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	pick_question_type()
	add_question_scene()

func _process(delta: float):
	style_tiled_diagonals(delta)
	display_time_left(delta)
	account_for_window_sizes()
	update_question_text()

func display_time_left(delta: float):
	var time_with_decimal = int(time_left * 10) / 10.0
	var show_integer = time_left >= decimal_show_threshold
	var time_label_text = str(int(time_left)) if show_integer else str(time_with_decimal)
	if time_left == 0: time_label_text = "0"
	time_left_label.text = font_size_bbcode(time_left_font_size, time_label_text)
	time_left = max(time_left - delta, 0)

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
	QuestionType.IngredientQuestion: "Diese Essen in Deutsch!"
}

const czech_question_title_dict : Dictionary[QuestionType, String] = {
	QuestionType.IngredientQuestion: "Přeložte tato jídla do němčiny!"
}

var german_question: String
var czech_question: String

func pick_question_type():
	var max_question_index = QuestionType.size() - 1
	var picked_question_index = randi_range(1, max_question_index)
	question_type = QuestionType.values()[picked_question_index]
	german_question = german_question_title_dict[question_type]
	czech_question = czech_question_title_dict[question_type]

func update_question_text():
	var compounded_question = font_size_bbcode(question_title_font_size, german_question) + '\n' +\
		font_size_bbcode(question_title_font_size / 2, czech_question)
	question_title.text = compounded_question

func font_size_bbcode(font_size: float, inner_text: String):
	return "[font_size=" + str(font_size) + "]" + inner_text + "[/font_size]"

func add_question_scene():
	var question_subscene = UID.question_subscene_dict[question_type]
	add_child(question_subscene.instantiate())
