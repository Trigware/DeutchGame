class_name RestaurantPlayer
extends CharacterBody2D

@onready var anim_sprite = $Sprite
@onready var camera = $Camera
@onready var item_slots_manager = $"../Restaurant Item Slots Manager"
@onready var spawner = $"../Left Spawner"
@onready var hitbox_collider = $Hitbox/Collider
@onready var ingredients_root = $"CatchArea/Player Ingredients"

const minimal_player_speed = 20
const maximum_player_speed = 115
const minimal_speed_item_count = 12
const basic_window_size = Vector2(1152, 648)

var movement_disabled = true
var player_fallen = false
var can_player_export = false
var export_station_index = 0

enum MoveDir { None, Left, Right, Up, Down }

func _ready():
	set_anim(get_walk_anim_name(MoveDir.Down))

func _process(delta: float):
	handle_jumping(delta)
	handle_movement()
	handle_camera()
	var offset_y = anim_sprite.offset.y
	ingredients_root.position.y = ingredients_y_offset + offset_y

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
	if movement_disabled or preparing_to_jump: return
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
	if anim_sprite.sprite_frames.has_animation(anim_name): anim_sprite.play(anim_name)

const base_camera_zoom = 2.85

func handle_camera():
	var window_size: Vector2 = DisplayServer.window_get_size()
	var size_multiplier = window_size / basic_window_size
	var camera_zoom = max(size_multiplier.x, size_multiplier.y)
	camera.zoom = Vector2.ONE * camera_zoom * base_camera_zoom

const player_going_down_tween_dur = 0.185
const player_fallen_offset = 4
const fallen_player_alpha_mod = 0.6
const player_restore_duration = 0.75
const barrel_hit_jump_maximum = 12
 
func fall_down():
	var sprite_offset = abs(anim_sprite.offset.y)
	if is_jumping and sprite_offset > barrel_hit_jump_maximum: return
	
	upward_velocity = 0
	is_jumping = false
	
	anim_sprite.play("fallen")
	movement_disabled = true
	player_fallen = true
	drop_items()
	
	create_tween().tween_property(anim_sprite, "offset:y", player_fallen_offset, player_going_down_tween_dur).set_trans(Tween.TRANS_QUAD)
	await create_tween().tween_property(anim_sprite, "modulate:a", fallen_player_alpha_mod, player_going_down_tween_dur).finished
	await get_tree().create_timer(player_restore_duration).timeout
	
	movement_disabled = false
	anim_sprite.modulate.a = 1
	anim_sprite.offset.y = 0
	player_fallen = false
	set_anim(get_walk_anim_name(MoveDir.Down))

func set_anim(anim_name: String):
	anim_sprite.play(anim_name, 0)

func drop_items():
	GridState.active_game.ingredient_count_per_type.clear()
	for removed_ingredient: Ingredient.IngredientType in item_slots_manager.item_slots:
		var item_slot = item_slots_manager.item_slots[removed_ingredient]
		item_slot.queue_free()
	item_slots_manager.item_slots.clear()
	GridState.active_game.player_held_items.clear()
	
	for ingredient_object: IngredientObject in GridState.active_game.player_held_ingredients_nodes:
		var dropped_ingredient = UID.dropped_ingredient.instantiate()
		var current_ingredient = ingredient_object.player_ingredient
		dropped_ingredient.ingredient_type = current_ingredient.ingredient_type
		dropped_ingredient.restaurant_player = self
		spawner.add_child(dropped_ingredient)
		
		dropped_ingredient.global_transform = current_ingredient.global_transform
		ingredient_object.ingredient_collider.queue_free()
		ingredient_object.player_ingredient.queue_free()
		
	GridState.active_game.player_held_ingredients_nodes.clear()

const jumping_y_peak = 2.15
const player_jumping_speed = 10
var upward_velocity = 0
var is_jumping = false
var reached_jumping_peak = false
const ingredients_y_offset = -18
const jump_y_max_stretch = 1.075
const jump_y_min_stretch = 0.915
const stretch_tween_duration = 0.25
const stretch_short_tween_duration = 0.07
var preparing_to_jump = false
const maximum_jump_preparation_wait = 0.05
const maximum_preparion_wait_item_count = 10

func handle_jumping(delta: float):
	if movement_disabled: return
	if Input.is_action_just_pressed("player_jump") and not is_jumping:
		reached_jumping_peak = false
		upward_velocity = 0
		z_index = 1
		await create_tween().tween_property(self, "scale:y", jump_y_min_stretch, stretch_short_tween_duration).finished
		preparing_to_jump = true
		is_jumping = true
		preparing_to_jump = false
		await create_tween().tween_property(self, "scale:y", jump_y_max_stretch, stretch_tween_duration).finished
		create_tween().tween_property(self, "scale:y", 1, stretch_tween_duration).set_delay(0.1)
	
	var y_velocity_multiplier = -1 if reached_jumping_peak else 1
	if is_jumping: upward_velocity += delta * player_jumping_speed * y_velocity_multiplier
	if upward_velocity > jumping_y_peak: reached_jumping_peak = true
	
	var offset_y = min(anim_sprite.offset.y - upward_velocity, 0)
	if offset_y == 0:
		is_jumping = false
		z_index = 0
	anim_sprite.offset.y = offset_y
