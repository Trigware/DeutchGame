extends Node2D

var time_since_spawn_started: float = 0

func _ready():
	if GridState.active_game == null: GridState.active_game = UID.init_state
	await GridState.active_game.restaurant_game_started
	handle_spawning()

func _process(delta: float):
	time_since_spawn_started += delta

const tile_size = 24
const spawn_position = Vector2(tile_size * 12, tile_size * 2)

func spawn_barrel(most_effective_barrel_progress):
	var barrel_instance = UID.barrel_scene.instantiate()
	var spawned_left = randi_range(0, 1) as bool
	var x_pos = -spawn_position.x if spawned_left else spawn_position.x
	barrel_instance.position = Vector2(x_pos, spawn_position.y)
	barrel_instance.barrel_speed = lerp(barrel_min_speed, barrel_max_speed, most_effective_barrel_progress)
	
	barrel_instance.spawned_left = spawned_left
	add_child(barrel_instance)

const spawn_delay_range = Vector2(6, 8.5)
const lowest_multiplier = 0.725
const time_at_lowest = 80
const barrel_min_speed = 125
const barrel_max_speed = 160

func handle_spawning():
	while true:
		var most_effective_barrel_progress = min(time_since_spawn_started / time_at_lowest, 1)
		spawn_barrel(most_effective_barrel_progress)
		var delay_mutiplier = max(1 - most_effective_barrel_progress, lowest_multiplier)
		
		var random_t = randi_range(0, 1)
		var barrel_spawn_delay = lerp(spawn_delay_range.x, spawn_delay_range.y, random_t) * delay_mutiplier
		await get_tree().create_timer(barrel_spawn_delay).timeout
