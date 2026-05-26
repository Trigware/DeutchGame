class_name ConveyorBelt
extends Node2D

@onready var conveyor = $Conveyor
@onready var moving_arrows = $"Moving Arrows"
@onready var food_root = $"Food Root"
@onready var food_station: FoodStation = get_parent()

@export var going_left := false
@export var invert_color := false
@export var arrow_colors : Dictionary[bool, Color] = {
	false: Color("660000"),
	true: Color("003f66")
}
var player_root: RestaurantPlayer

func _process(_delta):
	var tile_count = scale.x / scale.y
	conveyor.material.set_shader_parameter("tile_count", tile_count)
	moving_arrows.going_left = going_left
	moving_arrows.used_scale = scale
	food_root.scale = Vector2.ONE / scale
	moving_arrows.time_scale = player_root.points_multiplier * GridState.conveyor_belt_speed_multiplier
	
	var used_dir_state = going_left
	if invert_color: used_dir_state = not going_left
	if used_dir_state in arrow_colors:
		moving_arrows.arrow_modulate = arrow_colors[used_dir_state]

func create_conveyor_object(ingredient_or_food, is_food: bool, food_station_ref: FoodStation) -> ConveyorObject:
	var conveyor_ingredient := UID.conveyor_ingredient.instantiate()
	conveyor_ingredient.player_root = player_root
	conveyor_ingredient.food_station = food_station
	match is_food:
		true: conveyor_ingredient.food_type = ingredient_or_food
		false: conveyor_ingredient.item_type = ingredient_or_food
	
	conveyor_ingredient.is_output = is_food
	conveyor_ingredient.convayor_belt_scale = scale.x
	conveyor_ingredient.food_station_ref = food_station_ref
	food_root.add_child(conveyor_ingredient)
	return conveyor_ingredient

func add_to_conveyor(ingredient_type: Ingredient.IngredientType, food_station_ref: FoodStation):
	create_conveyor_object(ingredient_type, false, food_station_ref)

func output_to_conveyor(food_type: Ingredient.FoodType, food_station_ref: FoodStation):
	var convayor_food = create_conveyor_object(food_type, true, food_station_ref)
	convayor_food.food_creation_index = food_station_ref.outputed_food_count
	food_station_ref.outputed_food_count += 1
