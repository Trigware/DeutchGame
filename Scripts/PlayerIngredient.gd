@tool
extends Area2D

@onready var sprite = $Ingredient
@export var ingredient_type: Ingredient.IngredientType
@export var y_index: int

var y_tile_size = 32 * scale.y
const index_portion = 0.25
const maximum_wave_size_increase = 8
const full_wave_scan_duration: float = 4
const single_dir_completed = 0.5

func _process(_delta):
	if sprite == null: return
	sprite.frame_coords = Vector2(ingredient_type as int, 1)
	position.y = get_y_pos()
	set_x_position()
	
func get_y_pos():
	return -y_tile_size * index_portion * y_index

func set_x_position():
	var time_as_sec = Time.get_ticks_msec() / 1000.0
	var used_increase = min(GridState.active_game.transitional_held_item_count, maximum_wave_size_increase)
	var wave_size = (y_index - 1) * used_increase

	var current_wave_time = fmod(time_as_sec, full_wave_scan_duration)
	var total_progress = current_wave_time / full_wave_scan_duration
	
	var going_right = total_progress < single_dir_completed
	var next_anchor_t = single_dir_completed if going_right else 1
	var dist_to_anchor = next_anchor_t - total_progress
	
	var doubled_dist = dist_to_anchor * 2
	var actual_progress = 1 - doubled_dist if going_right else doubled_dist
	var zero_centric_progress = actual_progress - single_dir_completed
	position.x = zero_centric_progress * wave_size
