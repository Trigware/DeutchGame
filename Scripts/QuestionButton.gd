@tool
extends Control

@export var button_type := ButtonType.Unknown:
	set(value): button_type = value; update_button()

@onready var button_label = $Label
@onready var button_base = $"Button Base"
@onready var mouse_area = $"Mouse Area"

enum ButtonType {
	Unknown,
	ShowAnswers,
	Incorrect,
	Correct
}

var mouse_inside_button: bool = false

const button_text: Dictionary[ButtonType, String] =\
	{ButtonType.ShowAnswers: "Odpovědi", ButtonType.Incorrect: "Špatně", ButtonType.Correct: "Správně"}
const button_colors: Dictionary[ButtonType, Color] =\
	{ButtonType.ShowAnswers: Color("2f83b0ff"), ButtonType.Incorrect: Color("a83232ff"), ButtonType.Correct: Color("32a846ff")}

func _ready():
	update_button()
	mouse_area.mouse_entered.connect(on_mouse_enter)
	mouse_area.mouse_exited.connect(on_mouse_exit)

func on_mouse_enter(): mouse_inside_button = true
func on_mouse_exit(): mouse_inside_button = false

const button_label_value_offset = 0.35
const button_size = Vector2(190, 102)

func update_button():
	if button_type == ButtonType.Unknown or button_label == null: return
	button_label.text = button_text[button_type]
	var button_base_color = button_colors[button_type]
	button_base.modulate = button_base_color
	var button_label_color = button_base_color
	button_label_color.v += button_label_value_offset
	button_label.modulate = button_label_color

var y_progress: float = 0.825
const base_button_scale: float = 1.55
const base_window_minimal_component: float = 648

func _process(delta: float):
	var window_size = DisplayServer.window_get_size()
	var min_dimen_size: float = min(window_size.x, window_size.y)
	var multiplier_win_size_diff = min_dimen_size / base_window_minimal_component
	var button_scale = base_button_scale * multiplier_win_size_diff
	
	position.x = window_size.x / 2 - button_size.x / 2 * button_scale
	var final_y_pos = window_size.y - button_size.y / 2 * button_scale
	position.y = final_y_pos * y_progress
	scale = Vector2.ONE * button_scale
	handle_mouse_interaction()

func handle_mouse_interaction():
	if Engine.is_editor_hint(): return
	print(mouse_inside_button)
	if mouse_inside_button and Input.is_action_just_pressed("button_press"): print("!!!")
