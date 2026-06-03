class_name TeamOption
extends Node2D

@onready var team_name_input = $"Team Name/Team Name Input"
@onready var member_count_label = $Button/MemberCount
@onready var name_container = $"Team Name/Container"
@onready var container_shadow = $"Team Name/Container Shadow"
@onready var team_name_root = $"Team Name"

@export var team_color :=  SpecialTile.TeamRelation.Other
@export var title_screen: TitleScreen

var final_x_relative_pos: float
var relative_position := Vector2(0.2, 0.4)

const team_option_width = 75
const team_option_height = 100

const filled_portion = 0.3
const x_relative_from_edge = 0.25

func _ready():
	var is_red = team_color == SpecialTile.TeamRelation.Red
	relative_position.x = x_relative_from_edge if is_red else 1 - x_relative_from_edge
	if GameState.active_game == null: GameState.active_game = UID.init_state
	GameState.active_game.team_member_count.clear()

func _process(_delta):
	var window_size = Vector2(DisplayServer.window_get_size())
	var scale_multiplier = window_size.y * filled_portion / team_option_height
	position = window_size * relative_position
	position.x -= team_option_width * scale_multiplier / 2
	scale = Vector2.ONE * scale_multiplier
	var num_of_player_dict = GameState.active_game.team_member_count
	var number_of_players = num_of_player_dict[team_color] if team_color in num_of_player_dict else 1
	member_count_label.text = str(number_of_players)
	team_name_container_interaction()

func on_arrow_button_pressed(pressed_left):
	var offset = -1 if pressed_left else 1
	var num_of_player_dict = GameState.active_game.team_member_count
	var has_team_count_entry = team_color in num_of_player_dict
	
	if not has_team_count_entry: num_of_player_dict[team_color] = 1
	num_of_player_dict[team_color] += offset

const glyph_size = 8.4
const name_input_x_offset = -5
const minimum_container_width = 60

func team_name_container_interaction():
	var local_mouse = name_container.get_local_mouse_position()
	var hovering_over = local_mouse.x >= 0 and local_mouse.y >= 0 and local_mouse.x <= name_container.size.x and local_mouse.y <= name_container.size.y
	var team_name = team_name_input.text if team_name_input.text != "" else team_name_input.placeholder_text
	var team_name_dict = GameState.active_game.team_names
	team_name_dict[team_color] = team_name_input.text
	
	var name_length = team_name.length()
	var container_width = max(glyph_size * name_length, minimum_container_width)
	name_container.size.x = container_width
	container_shadow.size.x = container_width
	team_name_input.size.x = container_width + name_input_x_offset
	var container_pos_x = -(container_width - team_option_width) / 2
	team_name_root.position.x = container_pos_x
	
	var trying_to_press = Input.is_action_just_pressed("team_name_container_edit")
	if trying_to_press and not hovering_over:
		team_name_input.unedit()
		return
	
	if not trying_to_press or not hovering_over: return
	team_name_input.edit()
	title_screen.diagonals_tween(team_color)
