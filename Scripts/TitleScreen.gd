class_name TitleScreen
extends Node2D

@onready var info_label = $Info
@onready var tiled_diagonals = $"Tiled Diagonals"
@onready var logo = $Logo

const version_text = "1.1"
const logo_width = 310
const logo_height = 100

const logo_show_up_tween_duration = 0.6

func _ready():
	Audio.play_music(UID.board_music)
	info_label.text = "[font_size=32]Verze " + version_text + "\nJan Kalbáč, Mikuláš Váněček (2026)"
	create_tween().tween_property(self, "y_logo_progress", 1, logo_show_up_tween_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	logo.modulate.a = 0
	create_tween().tween_property(logo, "modulate:a", 1, logo_show_up_tween_duration)

const version_label_offset = 15
const logo_window_width_portion = 0.6
var y_logo_progress: float = 0

func _process(_delta):
	var window_size = DisplayServer.window_get_size()
	tiled_diagonals.size = window_size
	info_label.size = Vector2(window_size.x - version_label_offset, window_size.y - version_label_offset)
	var scale_multiplier = window_size.x * logo_window_width_portion / logo_width
	logo.scale = scale_multiplier * Vector2.ONE
	logo.position.x = window_size.x / 2
	logo.position.y = logo_height * scale_multiplier * y_logo_progress - logo_height * scale_multiplier / 2

const diagonals_tween_duration = 0.8

const title_screen_diagonals_red_team_color = Color("873a3aff")

func diagonals_tween(team_color: SpecialTile.TeamRelation):
	var final_color = GridState.diagonals_modulate[team_color]
	if team_color == SpecialTile.TeamRelation.Red: final_color = title_screen_diagonals_red_team_color
	create_tween().tween_property(tiled_diagonals, "line_color", final_color, diagonals_tween_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
