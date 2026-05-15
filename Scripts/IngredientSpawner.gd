@tool
extends Node2D

@onready var upper_opener = $UpperOpener
@onready var bottom_opener = $BottomOpener
@onready var ingredient_root = $IngredientRoot

@export var dist_from_center : float = 0
@export var is_right_spawner: bool
@export var player: RestaurantPlayer
@export var minigame_countdown: MinigameCountdown

const default_opener_y = 8
const countdown_wait_duration = 1.4

func _ready():
	if Engine.is_editor_hint(): return
	dist_from_center = 0
	if not minigame_countdown.minigame_started:
		await get_tree().create_timer(countdown_wait_duration).timeout
	if is_right_spawner:
		await get_tree().create_timer(spawn_wait_time).timeout
	handle_spawn()

func _process(_delta):
	upper_opener.position.y = -default_opener_y - dist_from_center
	bottom_opener.position.y = default_opener_y + dist_from_center
	for ingredient in ingredient_root.get_children():
		ingredient.spawner_dist = dist_from_center
		ingredient.player_pos = player.position

const spawn_wait_time = 2.2
const open_duration = 0.65
const full_open_extend = 5

func handle_spawn():
	await create_tween().tween_property(self, "dist_from_center", full_open_extend, open_duration).finished
	await throw_ingredients()
	await create_tween().tween_property(self, "dist_from_center", 0, open_duration).finished
	await get_tree().create_timer(spawn_wait_time).timeout
	handle_spawn()

func spawn_ingredient():
	var falling_ingredient = UID.falling_ingredient_scene.instantiate()
	ingredient_root.add_child(falling_ingredient)

const another_ingredient_rate: int = 3

const another_ingredient_delay = 1.2

func throw_ingredients():
	while true:
		spawn_ingredient()
		var random_value = randi_range(0, another_ingredient_rate-1)
		if random_value != 0: break
		await get_tree().create_timer(another_ingredient_delay).timeout
