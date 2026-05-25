extends Area2D

@onready var ingredient_spr = $Ingredient
@onready var ingredient_collider = $Collider

@export var y_offset: float
var player_pos: Vector2
const invisible_ingredient_y_pos = 28
const fully_visible_ingredient_y_pos = 48

var spawner_dist: float
var throw_velocity: float
var time_since_throw_began: float
var ingredient_data := Ingredient.generate()

const ingredient_scale = 0.65

func _ready():
	ingredient_spr.material = UID.falling_ingredient_shader.duplicate()
	y_offset = 0
	time_since_throw_began = 0
	ingredient_spr.frame_coords.x = ingredient_data.ingredient_type as int
	scale = Vector2(ingredient_scale, ingredient_scale)
	area_entered.connect(area_hit_ingredient)
	z_index = 1
	rotation_tween()

const rotation_range = 30
const rotation_tween_duration = 1

var is_rotation_result_positive = true

func rotation_tween():
	var rotation_result = rotation_range if is_rotation_result_positive else -rotation_range
	await create_tween().tween_property(self, "rotation_degrees", rotation_result, rotation_tween_duration).finished
	is_rotation_result_positive = not is_rotation_result_positive
	rotation_tween()

const spawner_height = 16
const throw_power: float = 300
const velocity_stop_duration: float = 1.1
var reached_y_peak = false

func _process(delta: float):
	y_offset += throw_velocity * delta
	position.y = -y_offset
	
	if reached_y_peak:
		handle_alpha_when_falling()
		return
	throw_ingredient(delta)

func throw_ingredient(delta: float):
	time_since_throw_began += delta
	var velocity_stop_time_diff = velocity_stop_duration - time_since_throw_began
	reached_y_peak = velocity_stop_time_diff < 0

	throw_velocity = velocity_stop_time_diff / velocity_stop_duration * throw_power
	
	var visibility_value = spawner_dist / spawner_height + y_offset / spawner_height
	var peak_y_progress = time_since_throw_began / velocity_stop_duration
	modulate.a = 1 - peak_y_progress
	
	ingredient_spr.material.set_shader_parameter("visibility_value", visibility_value)
	if reached_y_peak: setup_ingredient_fall()

const x_spawn_ingredient_pos = 86
const disallowed_player_spawn_proximity = 0.275
const spawn_restriction_failure_limit = 100

const fall_velocity = 72

var generated_spawn_x: float

func setup_ingredient_fall():
	reached_y_peak = true
	var index = 0
	while true:
		generated_spawn_x = randf_range(-x_spawn_ingredient_pos, x_spawn_ingredient_pos)
		var is_disallowed = is_within_range(player_pos.x, disallowed_player_spawn_proximity)
		var limit_exceeded = index > spawn_restriction_failure_limit
		index += 1
		
		if is_disallowed and not limit_exceeded: continue
		global_position.x = generated_spawn_x
		break
	
	throw_velocity = -fall_velocity
	ingredient_collider.disabled = false

const fall_full_alpha_y_global = 54
const fall_no_alpha_y_global = 72

func is_within_range(compared_x, disallowed_portion):
	var disallowed_zone_width = x_spawn_ingredient_pos * disallowed_portion * 2
	return abs(compared_x - generated_spawn_x) < disallowed_zone_width

func handle_alpha_when_falling():
	var ingredient_based_alpha = 1 - max(inverse_lerp(fall_full_alpha_y_global, fall_no_alpha_y_global, global_position.y), 0)
	var player_based_alpha = clamp(inverse_lerp(invisible_ingredient_y_pos, fully_visible_ingredient_y_pos, player_pos.y), 0, 1)
	modulate.a = min(ingredient_based_alpha, player_based_alpha)
	
	var free_node = global_position.y > fall_no_alpha_y_global
	if free_node: queue_free()

func area_hit_ingredient(area: Area2D):
	if not area.is_in_group("PlayerCatchBody"): return
	var player_root: RestaurantPlayer = area.get_parent()
	var is_unpickable = player_pos.y < invisible_ingredient_y_pos
	if is_unpickable or player_root.player_fallen: return
	player_root.finish_ingredient_pickup.bind(self, ingredient_data, area).call_deferred()
