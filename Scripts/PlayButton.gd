extends Node2D

var button_saturation_progress: float = 0
var button_relative_pos = Vector2(0.5, 1.5)
const final_y_relative_pos = 0.875

const button_show_up_tween_duration = 0.6
@export var final_play_button_color: Color

func _ready():
	create_tween().tween_property(self, "button_relative_pos:y", final_y_relative_pos, button_show_up_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

func _process(_delta):
	QuestionButton.handle_button_mouse_interaction(self)
	QuestionButton.handle_button_transform(self)
	modulate = final_play_button_color
	modulate.s = final_play_button_color.s * button_saturation_progress / button_show_up_tween_duration

func on_press():
	Overlay.switch_scene(UID.board_scene)
