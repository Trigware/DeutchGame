extends Node2D

var button_saturation_progress: float = 0
var button_relative_pos = Vector2(0.5, 1.5)
const center_x_offset = 0.215
const final_y_relative_pos = 0.835

const button_show_up_tween_duration = 0.6
@export var final_play_button_color: Color
@export var is_play_button: bool
@onready var label = $Label

func _ready():
	create_tween().tween_property(self, "button_relative_pos:y", final_y_relative_pos, button_show_up_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	label.text = "Začni hru!" if is_play_button else "Tutoriál"
	var x_offset_multiplier = -1 if is_play_button else 1
	button_relative_pos.x += center_x_offset * x_offset_multiplier

const unable_to_interact_alpha = 0.5

func _process(_delta):
	var team_name_dict = GameState.active_game.team_names
	var unable_to_start = team_name_dict[SpecialTile.TeamRelation.Red] == "" or team_name_dict[SpecialTile.TeamRelation.Blue] == ""
	if not is_play_button: unable_to_start = false
	if not unable_to_start: QuestionButton.handle_button_mouse_interaction(self)
	QuestionButton.handle_button_transform(self)
	
	modulate = final_play_button_color
	modulate.s = final_play_button_color.s * button_saturation_progress / button_show_up_tween_duration
	modulate.a = unable_to_interact_alpha if unable_to_start else 1

func on_press():
	var scene_init = func(board: BoardRoot):
		board.is_playing_tutorial = not is_play_button
	Overlay.switch_scene_def(UID.board_scene, scene_init)
