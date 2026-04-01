extends CanvasLayer

@onready var menu = $Menu
@onready var main_sprite = $Menu/Main
@onready var title = $Title
@onready var description = $Description

var ui_size: Vector2
const axis_coverage_rate = 0.75
var menu_hide_time_value: float = 1

func _ready():
	ui_size = main_sprite.texture.get_size()

func _process(_delta):
	var window_size = DisplayServer.window_get_size()
	var full_covered_window = window_size * axis_coverage_rate
	var unmodified_scale_vec = full_covered_window / ui_size
	var used_scale_component = min(unmodified_scale_vec.x, unmodified_scale_vec.y)
	var used_scale = Vector2(used_scale_component, used_scale_component)
	scale = used_scale
	
	var y_offset = window_size.y * menu_hide_time_value
	var used_pos = window_size / 2
	used_pos.y += y_offset
	offset = used_pos

const menu_show_duration = 0.75

const win_message: Dictionary[GridState.GameEndType, String] = {
	GridState.GameEndType.FlagCaptured: "protože získali soupeřovu vlajku.",
	GridState.GameEndType.PiecelessOpponent: "protože soupeř nemá možnost hrát."
}

func display_end_of_game():
	show()
	GridState.active_game.invert_turn()
	create_tween().tween_property(self, "menu_hide_time_value", 0, menu_show_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	var winning_team = GridState.active_game.player_turn
	var team_name = GridState.active_game.team_names[winning_team]
	title.text = "Vyhrál tým \"" + team_name + "\"!"
	menu.modulate = GridState.team_modulate[winning_team]
	description.text = win_message[GridState.active_game.game_end_type]
