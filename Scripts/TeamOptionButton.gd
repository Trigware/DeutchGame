extends Control

@export var team_option: TeamOption
@export var going_left: bool = false

@onready var button = $Button

const maximum_member_count = 99

func _process(_delta):
	var local_mouse = get_local_mouse_position()
	var is_hovering = local_mouse.x >= 0 and local_mouse.y >= 0 and local_mouse.x <= button.size.x and local_mouse.y <= button.size.y
	var member_count_dict = GameState.active_game.team_member_count
	var member_count = member_count_dict[team_option.team_color] if team_option.team_color in member_count_dict else 1
	
	show()
	if member_count == 1 and going_left: hide()
	if member_count == maximum_member_count and not going_left: hide()
	
	if not Input.is_action_just_pressed("button_press") or not is_hovering or not visible: return
	team_option.on_arrow_button_pressed(going_left)
