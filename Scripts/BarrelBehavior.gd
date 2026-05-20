extends Area2D

var spawned_left := false

var barrel_speed: float
const barrel_drop_off_x = 108
const final_barrel_fall_y = 64
const fall_speed_increase = 7
const speed_decrease_mutliplier = 0.1
const barrel_destroy_x = 96
var used_destruction_position: float

var fall_speed = 0

func _ready():
	used_destruction_position = barrel_destroy_x if spawned_left else -barrel_destroy_x

func _process(delta: float):
	if destroying_barrel: return
	
	hit_player_if_overlaps()
	var is_on_top = abs(position.x) >= barrel_drop_off_x
	if not is_on_top: fall_speed += fall_speed_increase * delta
	barrel_speed -= barrel_speed * speed_decrease_mutliplier * delta
	
	var move_direction = 1 if spawned_left else -1
	position.x += delta * move_direction * barrel_speed
	var pos_y = position.y + fall_speed
	if pos_y < final_barrel_fall_y: position.y = pos_y
	handle_destruction()

var destroying_barrel = false
const destruction_tween_duration = 0.315

func handle_destruction():
	var is_destroying = position.x > used_destruction_position if spawned_left else position.x < used_destruction_position
	if not is_destroying: return
	destroying_barrel = true
	await create_tween().tween_property(self, "modulate:a", 0, destruction_tween_duration).finished
	queue_free()

func hit_player_if_overlaps():
	for area: Area2D in get_overlapping_areas():
		if not area.is_in_group("PlayerHitbox"): return
		var player_root: RestaurantPlayer = area.get_parent()
		player_root.fall_down()
