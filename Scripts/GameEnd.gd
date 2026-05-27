extends CanvasLayer

@onready var menu = $Menu
@onready var main_sprite = $Menu/Main
@onready var title = $Title
@onready var description = $"Extra Info/Description"
@onready var extra_info = $"Extra Info"

var ui_size: Vector2
const axis_coverage_rate = 0.75
var menu_hide_time_value: float = 1
var tween_active = false

func _ready():
	ui_size = main_sprite.texture.get_size()
	show()

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

const menu_show_duration = 0.85

const win_message: Dictionary[GridState.GameEndType, String] = {
	GridState.GameEndType.FlagCaptured: "protože získali soupeřovu vlajku.",
	GridState.GameEndType.PiecelessOpponent: "protože soupeř nemá možnost hrát."
}

func display_menu():
	if tween_active: return
	var game_paused = GameState.active_game.game_end_type == GridState.GameEndType.Ongoing
	extra_info.visible = not game_paused
	handle_tween()
	if not game_paused:
		display_menu_for_game_end()
		return
	title.text = "Hra byla pozastavena!"

func handle_tween():
	tween_active = true
	var final_value = 0 if menu_hide_time_value == 1 else 1
	var menu_tween = create_tween().tween_property(self, "menu_hide_time_value", final_value, menu_show_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	await menu_tween.finished
	tween_active = false

func display_menu_for_game_end():
	GameState.active_game.invert_turn()
	var winning_team = GameState.active_game.player_turn
	var team_name = GameState.active_game.team_names[winning_team]
	title.text = "Vyhrál tým \"" + team_name + "\"!"
	menu.modulate = GridState.team_modulate[winning_team]
	description.text = win_message[GameState.active_game.game_end_type]
