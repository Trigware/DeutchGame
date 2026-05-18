class_name RestaurantPlayer
extends CharacterBody2D

@onready var anim_sprite = $Sprite
@onready var camera = $Camera

const minimal_player_speed = 20
const maximum_player_speed = 115
const minimal_speed_item_count = 12
const basic_window_size = Vector2(1152, 648)

var movement_disabled = true
var can_player_export = false
var export_station_index = 0

enum MoveDir { None, Left, Right, Up, Down }

func _process(delta: float):
	handle_movement()
	handle_camera()

const epsilon = 0.001
func pos_approx_equal(prev_pos: Vector2):
	return abs(prev_pos.x - position.x) <= epsilon and abs(prev_pos.y - position.y) <= epsilon

func get_move_dir() -> Array[MoveDir]:
	var result: Array[MoveDir] = []
	if Input.is_action_pressed("walk_left"): result.append(MoveDir.Left)
	if Input.is_action_pressed("walk_right"): result.append(MoveDir.Right)
	if Input.is_action_pressed("walk_up"): result.append(MoveDir.Up)
	if Input.is_action_pressed("walk_down"): result.append(MoveDir.Down)
	return result

func get_dir_as_vec(move_flags: Array[MoveDir]) -> Vector2:
	var result := Vector2.ZERO
	if MoveDir.Left in move_flags: result.x -= 1
	if MoveDir.Right in move_flags: result.x += 1
	if MoveDir.Up in move_flags: result.y -= 1
	if MoveDir.Down in move_flags: result.y += 1
	return result

func get_prioritized_move_dir(move_flags: Array[MoveDir]) -> MoveDir:
	var move_directions = MoveDir.values()
	for move_dir in move_directions:
		if move_dir in move_flags: return move_dir
	return MoveDir.None

func get_walk_anim_name(move_dir: MoveDir) -> String: return "walk_" + MoveDir.keys()[move_dir].to_lower()

func handle_movement():
	if movement_disabled: return
	var move_dir_flags = get_move_dir()
	var move_dir_vec = get_dir_as_vec(move_dir_flags)
	
	var item_portion = clamp(1 - inverse_lerp(0, minimal_speed_item_count, GridState.active_game.player_held_items.size()), 0, 1)
	var player_speed = lerp(minimal_player_speed, maximum_player_speed, item_portion)
	velocity = move_dir_vec * player_speed
	var move_dir = get_prioritized_move_dir(move_dir_flags)
	var anim_name = get_walk_anim_name(move_dir)
	var prev_position = position

	move_and_slide()
	if pos_approx_equal(prev_position): return
	anim_sprite.play(anim_name)

const base_camera_zoom = 2.85

func handle_camera():
	var window_size: Vector2 = DisplayServer.window_get_size()
	var size_multiplier = window_size / basic_window_size
	var camera_zoom = max(size_multiplier.x, size_multiplier.y)
	camera.zoom = Vector2.ONE * camera_zoom * base_camera_zoom
