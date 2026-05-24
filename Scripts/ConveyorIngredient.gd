class_name ConveyorObject
extends Area2D

@onready var ingredient_sprite = $IngredientSprite
@onready var ingredient_collider = $Collider
@export var player_root: RestaurantPlayer

var item_type := Ingredient.IngredientType.Unknown
var food_type := Ingredient.FoodType.Unknown

var is_output = false

const convayor_tile_size = 24
const ingredient_scale = 0.65
var convayor_belt_scale : float
var init_x_position: float
var time_traveled : float = 0
var food_station_ref = null

const ingredient_speed = convayor_tile_size
const modulate_alpha_duration = 0.45
const output_food_position_offset = convayor_tile_size*6

var init_input_x_pos: int
var output_destination_pos: int
const output_stop_offset = convayor_tile_size / 4
var food_creation_index: int

func _ready():
	rotation_degrees = 90
	scale = Vector2.ONE * ingredient_scale
	set_sprite()
	init_input_x_pos = -(convayor_belt_scale / 2 - 0.5) * convayor_tile_size
	init_x_position = init_input_x_pos
	if is_output: init_x_position += output_food_position_offset
	output_destination_pos = init_input_x_pos - output_stop_offset
	ingredient_collider.disabled = not is_output
	area_entered.connect(area_entered_ingredient)
	
	position.x = init_x_position
	modulate.a = 0

const item_travel_distance = 96
const output_offset_per_food = 12

func _process(delta: float):
	if has_halted(): return
	
	time_traveled += delta
	var distance_traveled = time_traveled * ingredient_speed
	var travel_direction = -1 if is_output else 1
	position.x = init_x_position + distance_traveled * travel_direction
	modulate.a = min(time_traveled, modulate_alpha_duration) / modulate_alpha_duration
	if distance_traveled > item_travel_distance: on_item_reached_destination()

const ingredient_disappear_tween_duration = 0.35

func set_sprite():
	var x_coords = food_type as int if is_output else item_type as int
	var y_coords = 0 if is_output else 1
	var coords = Vector2(x_coords, y_coords)
	ingredient_sprite.frame_coords = coords

func on_item_reached_destination():
	if is_output: return
	await create_tween().tween_property(self, "modulate:a", 0, ingredient_disappear_tween_duration).finished
	if food_station_ref != null: await spawn_crafted_food()
	queue_free()

const food_creation_time: float = 1.5

func spawn_crafted_food():
	if not is_outputting_food(): return
	await get_tree().create_timer(food_creation_time).timeout
	var food_station: FoodStation = food_station_ref
	var food_recipe = GridState.get_recipe(food_station.produced_food)
	
	for food_ingredient: Ingredient.IngredientType in food_recipe.ingredients:
		var ingredient_count = food_station.stored_ingredients[food_ingredient]
		ingredient_count -= 1
		if ingredient_count == 0: food_station.stored_ingredients.erase(food_ingredient)
		else: food_station.stored_ingredients[food_ingredient] = ingredient_count
	
	food_station.recipe_screen.update_ingredients_list()
	food_station.conveyor_in.output_to_conveyor(food_station.produced_food, food_station_ref)

func has_halted() -> bool:
	var belt_index = food_creation_index - food_station_ref.foods_obtainted
	var output_destination_food_count_offset = output_offset_per_food * belt_index
	var actual_output_dest = output_destination_pos + output_destination_food_count_offset
	var movement_halted = is_output and position.x < actual_output_dest or ingredient_obtainted
	return movement_halted

func is_outputting_food():
	var food_recipe = GridState.get_recipe(food_station_ref.produced_food)
	for food_ingredient: Ingredient.IngredientType in food_recipe.ingredients:
		if not food_ingredient in food_station_ref.stored_ingredients: return false
	return true

var ingredient_obtainted = false

func area_entered_ingredient(body: Node2D):
	if not body.is_in_group("PlayerHitbox"): return
	food_station_ref.foods_obtainted += 1
	ingredient_obtainted = true
	player_root.add_score_by_gain_type(RestaurantPlayer.ScoreGain.PickupFood)
	GridState.add_food(food_type)
	
	await create_tween().tween_property(self, "modulate:a", 0, ingredient_disappear_tween_duration).finished
	queue_free()
