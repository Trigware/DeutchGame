extends Node2D

@export var points_bar: PointsBar

func _ready():
	if GridState.active_game == null: GridState.active_game = UID.init_state
	await GridState.active_game.restaurant_game_started
	handle_spawning()

const tile_size = 24
const spawn_position = Vector2(tile_size * 12, tile_size * 2)

func spawn_barrel(barrel_speed: float):
	var barrel_instance = UID.barrel_scene.instantiate()
	var spawned_left = randi_range(0, 1) as bool
	var x_pos = -spawn_position.x if spawned_left else spawn_position.x
	barrel_instance.position = Vector2(x_pos, spawn_position.y)
	barrel_instance.barrel_speed = barrel_speed
	
	barrel_instance.spawned_left = spawned_left
	barrel_instance.modulate.a = 0
	create_tween().tween_property(barrel_instance, "modulate:a", 1, barrel_show_tween_duration)
	add_child(barrel_instance)

const spawn_delay_range = Vector2(5, 7.5)
const lowest_delay_multiplier = 0.65
const barrel_min_speed = 130
const barrel_max_speed = 215
const barrel_show_tween_duration = 0.6

func handle_spawning():
	while true:
		var progress_to_finish = clamp(points_bar.points_count / points_bar.maximum_points_count, 0, 1)
		var barrel_speed = lerp(barrel_min_speed, barrel_max_speed, progress_to_finish)
		spawn_barrel(barrel_speed)
		
		var random_delay = lerp(spawn_delay_range.x, spawn_delay_range.y, randf_range(0, 1))
		var delay_multiplier = lerp(1.0, lowest_delay_multiplier, progress_to_finish)
		var used_delay = random_delay * delay_multiplier
		await get_tree().create_timer(used_delay).timeout
