class_name RestaurantPlayer
extends CharacterBody2D

@export var points_bar: PointsBar
@export var time_view: TimeView

@onready var anim_sprite = $Sprite
@onready var camera = $Camera
@onready var item_slots_manager = $"../Restaurant Item Slots Manager"
@onready var spawner = $"../Left Spawner"
@onready var hitbox_collider = $Hitbox/Collider
@onready var ingredients_root = $"CatchArea/Player Ingredients"
@onready var score_root = $"Score Root"

const minimal_player_speed = 20
const maximum_player_speed = 115
const minimal_speed_item_count = 12
const basic_window_size = Vector2(1152, 648)

var movement_disabled = true
var player_fallen = false
var can_player_export = false
var export_station_index = 0
var points_multiplier : float = 1

signal score_increased

enum MoveDir { None, Left, Right, Up, Down }

func _ready():
	set_anim(get_walk_anim_name(MoveDir.Down))

var was_jumping_over_barrel = false
var latest_barrel_jump_hit_player = false

func _process(delta: float):
	handle_jumping_over_barrel()
	handle_jumping(delta)
	handle_movement()
	handle_camera()
	var offset_y = anim_sprite.offset.y
	ingredients_root.position.y = ingredients_y_offset + offset_y
	is_jumping_over_barrel = false

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

enum ScoreGain {
	Unknown,
	JumpOverBarrel,
	PickupIngredient,
	FoodDelivery,
	IngredientBeltUsage,
	InvalidIngredientBeltUsage,
	PickupFood
}

func handle_jumping_over_barrel():
	var jumping_over_barrel_ended = not is_jumping_over_barrel and was_jumping_over_barrel
	if jumping_over_barrel_ended:
		if not latest_barrel_jump_hit_player: add_score_by_gain_type(ScoreGain.JumpOverBarrel)
		latest_barrel_jump_hit_player = false
	was_jumping_over_barrel = is_jumping_over_barrel

func handle_movement():
	if movement_disabled or preparing_to_jump: return
	var move_dir_flags = get_move_dir()
	var move_dir_vec = get_dir_as_vec(move_dir_flags)
	
	var item_portion = clamp(1 - inverse_lerp(0, minimal_speed_item_count, GameState.active_game.player_held_items.size()), 0, 1)
	var player_speed = lerp(minimal_player_speed, maximum_player_speed, item_portion)
	velocity = move_dir_vec * player_speed
	var move_dir = get_prioritized_move_dir(move_dir_flags)
	var anim_name = get_walk_anim_name(move_dir)
	var prev_position = position

	move_and_slide()
	if pos_approx_equal(prev_position): return
	if anim_sprite.sprite_frames.has_animation(anim_name): anim_sprite.play(anim_name)

const base_camera_zoom: float = 2.85

func handle_camera():
	var window_size: Vector2 = DisplayServer.window_get_size()
	var size_multiplier = window_size / basic_window_size
	var camera_zoom = max(size_multiplier.x, size_multiplier.y)
	camera.zoom = Vector2.ONE * camera_zoom * base_camera_zoom

const player_going_down_tween_dur = 0.185
const player_fallen_offset = 4
const fallen_player_alpha_mod = 0.6
const player_restore_duration = 0.75
const barrel_hit_jump_maximum = 14

var is_jumping_over_barrel = false

func fall_down():
	var sprite_offset = abs(anim_sprite.offset.y)
	is_jumping_over_barrel = true
	if is_jumping and sprite_offset > barrel_hit_jump_maximum: return
	latest_barrel_jump_hit_player = true
	
	upward_velocity = 0
	is_jumping = false
	
	anim_sprite.play("fallen")
	movement_disabled = true
	player_fallen = true
	drop_items()
	
	create_tween().tween_property(anim_sprite, "offset:y", player_fallen_offset, player_going_down_tween_dur).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(anim_sprite, "modulate:a", fallen_player_alpha_mod, player_going_down_tween_dur)
	await get_tree().create_timer(player_restore_duration).timeout
	
	movement_disabled = false
	anim_sprite.modulate.a = 1
	anim_sprite.offset.y = 0
	player_fallen = false
	set_anim(get_walk_anim_name(MoveDir.Down))

func set_anim(anim_name: String):
	anim_sprite.play(anim_name, 0)

func drop_items():
	GameState.active_game.ingredient_count_per_type.clear()
	for removed_ingredient: Ingredient.IngredientType in item_slots_manager.item_slots:
		var item_slot = item_slots_manager.item_slots[removed_ingredient]
		item_slot.queue_free()
	item_slots_manager.item_slots.clear()
	GameState.active_game.player_held_items.clear()
	
	for ingredient_object: IngredientObject in GameState.active_game.player_held_ingredients_nodes:
		var dropped_ingredient = UID.dropped_ingredient.instantiate()
		var current_ingredient = ingredient_object.player_ingredient
		dropped_ingredient.ingredient_type = current_ingredient.ingredient_type
		dropped_ingredient.restaurant_player = self
		spawner.add_child(dropped_ingredient)
		
		dropped_ingredient.global_transform = current_ingredient.global_transform
		ingredient_object.ingredient_collider.queue_free()
		ingredient_object.player_ingredient.queue_free()
		
	GameState.active_game.player_held_ingredients_nodes.clear()

const jumping_y_peak = 2.3 
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
		is_jumping = true
	
	var y_velocity_multiplier = -1 if reached_jumping_peak else 1
	if is_jumping: upward_velocity += delta * player_jumping_speed * y_velocity_multiplier
	if upward_velocity > jumping_y_peak: reached_jumping_peak = true
	
	var offset_y = min(anim_sprite.offset.y - upward_velocity, 0)
	if offset_y == 0:
		is_jumping = false
		z_index = 0
	anim_sprite.offset.y = offset_y

const base_jump_over_barrel_score = 8.5
const base_ingredient_pickup_score = 7
const base_ingredient_belt_throw_score = 6
const base_food_pickup_score = 35
const jump_over_score_log_expo = 2.8
const jump_over_score_log_divisor = 15
const maximum_food_delivery_score_gain = 60
const maximum_important_delivery_duration = 40
const min_food_delivery_portion := 1.0 / 2

func log10(x): return log(x) / log(10)

func add_score_by_gain_type(score_gain_type: ScoreGain, customer_order_time = -1, food_type := Ingredient.IngredientType.Unknown):
	var added_score: float
	var held_ingredient_count = GameState.active_game.player_held_items.size()
	match score_gain_type:
		ScoreGain.JumpOverBarrel: added_score = get_point_count_using_log(base_jump_over_barrel_score)
		ScoreGain.PickupIngredient: added_score = get_point_count_using_log(base_ingredient_pickup_score)
		ScoreGain.FoodDelivery: added_score = get_food_delivery_points(customer_order_time, food_type)
		ScoreGain.IngredientBeltUsage: added_score = base_ingredient_belt_throw_score
		ScoreGain.InvalidIngredientBeltUsage: added_score = base_ingredient_belt_throw_score / 2
		ScoreGain.PickupFood: added_score = base_food_pickup_score
	if added_score <= 0: return
	add_to_score(added_score * points_multiplier)

func get_point_count_using_log(base_score):
	var held_ingredient_count = GameState.active_game.player_held_items.size()
	var log_input = held_ingredient_count ** jump_over_score_log_expo / jump_over_score_log_divisor + 1
	var score_multiplier = 1 + log10(log_input)
	var added_score = base_score * score_multiplier
	return added_score

const food_delivery_multiplier_portion = 0.75

func get_food_delivery_points(customer_order_time, food_type: Ingredient.IngredientType):
	var min_gain_progress = clamp(customer_order_time / maximum_important_delivery_duration, 0, 1)
	var max_score_gain: float = maximum_food_delivery_score_gain
	var min_score_gain = max_score_gain * min_food_delivery_portion
	var food_delivery_points = lerp(max_score_gain, min_score_gain, min_gain_progress)
	var used_multiplier_index = PointsBar.food_milestones_unlock_order.find(food_type) - 1
	var used_multiplier_food = PointsBar.food_milestones_unlock_order[used_multiplier_index] if used_multiplier_index >= 0 else Ingredient.IngredientType.Unknown
	var used_multiplier = 1.0 if used_multiplier_food == Ingredient.IngredientType.Unknown else PointsBar.score_multiplier_after_food_unlock[used_multiplier_food]
	used_multiplier = 1 + (used_multiplier - 1) * food_delivery_multiplier_portion
	food_delivery_points *= used_multiplier
	return food_delivery_points

func add_to_score(added_score: float):
	var score_notice = UID.score_notice_scene.instantiate()
	score_notice.added_score = added_score
	points_bar.add_score(added_score)
	score_root.add_child(score_notice)
	score_increased.emit()

const ingredient_scale = 0.65
const regular_ingredients_root_y_pos = -19

func finish_ingredient_pickup(falling_ingredient, ingredient_data, area: Area2D, picking_dropped = false):
	var ingredient_dict = GameState.active_game.ingredient_count_per_type
	
	var picked_type = ingredient_data.ingredient_type
	GameState.active_game.player_held_items.append(picked_type)
	var ingredient_count = GameState.active_game.player_held_items.size()
	
	var is_type_new = not picked_type in ingredient_dict.keys()
	if is_type_new:
		ingredient_dict[picked_type] = 0
		GameState.active_game.ingredient_type_added.emit(picked_type)
	ingredient_dict[picked_type] += 1

	var player_ingredient = UID.player_ingredient_scene.instantiate()
	player_ingredient.scale = Vector2.ONE * ingredient_scale
	player_ingredient.ingredient_type = picked_type
	player_ingredient.y_index = ingredient_count
	
	if not picking_dropped: add_score_by_gain_type(RestaurantPlayer.ScoreGain.PickupIngredient)
	if ingredient_count == 1:
		ingredients_root.position.y = regular_ingredients_root_y_pos
	ingredients_root.add_child(player_ingredient)
	
	var collider_scene = UID.ingredient_collider_scene.instantiate()
	collider_scene.player_ingredient = player_ingredient
	area.add_child.call_deferred(collider_scene)
	var ingredient_object = IngredientObject.ctor(player_ingredient, collider_scene)
	GameState.active_game.player_held_ingredients_nodes.append(ingredient_object)
	falling_ingredient.queue_free()
