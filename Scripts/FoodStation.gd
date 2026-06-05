class_name FoodStation
extends Node2D

@export var station_x := 0
@export var x_offset := 0.0
@export var unlocked_left := false
@export var unlocked_right := false
@export var player: RestaurantPlayer
@export var produced_food := Ingredient.FoodType.Unknown

@onready var walkable_area = $"Walkable Area"
@onready var left_connector = $"Static Body/Left Connector"
@onready var right_connector = $"Static Body/Right Connector"
@onready var enterance_collider = $"Static Body/Enterance"
@onready var export_area = $"Export Area"
@onready var import_area = $"Import Area"
@onready var conveyor_out: ConveyorBelt = $ConveyorOut
@onready var conveyor_in: ConveyorBelt = $ConveyorIn
@onready var recipe_screen = $RecipeScreen
@onready var left_unlock_tile = $"Left Extend Area/Left Unlock Tile"
@onready var right_unlock_tile = $"Right Extend Area/Right Unlock Tile"
@onready var left_extend_area = $"Left Extend Area"
@onready var right_extend_area = $"Right Extend Area"
@onready var center_shadow = $CenterShadow

const station_size = 24*7
const middle_tile = Vector2i(-1, 0)
const left_side_tile = Vector2i(-4, 0)
const right_side_tile = Vector2i(2, 0)

enum TileType {
	FreeX,
	XLeftLocked,
	XRightLocked,
	FreeXDown
}

var stored_ingredients: Dictionary[Ingredient.IngredientType, int] = {}
var outputed_food_count: int
var foods_obtainted: int

const tile_atlas_coords: Dictionary[TileType, Vector2] = {
	TileType.FreeX: Vector2(0, 1),
	TileType.XLeftLocked: Vector2(2, 1),
	TileType.XRightLocked: Vector2(3, 1),
	TileType.FreeXDown: Vector2(2, 0)
}

func set_tile(tile_type: TileType, coord: Vector2i):
	walkable_area.set_cell(coord, 0, tile_atlas_coords[tile_type])

func _process(_delta):
	position.x = (station_x + x_offset) * station_size
	var middle_tile_type = TileType.FreeXDown if station_x == 0 else TileType.FreeX
	set_tile(middle_tile_type, middle_tile)
	var left_side_type = TileType.FreeX if unlocked_left else TileType.XLeftLocked
	var right_side_type = TileType.FreeX if unlocked_right else TileType.XRightLocked
	set_tile(left_side_type, left_side_tile)
	set_tile(right_side_type, right_side_tile)
	enterance_collider.disabled = station_x == 0 and x_offset == 0
	left_connector.disabled = unlocked_left
	right_connector.disabled = unlocked_right

func _ready():
	if GameState.active_game == null: GameState.active_game = UID.init_state
	GameState.active_game.foods_encountered.append(produced_food)
	left_unlock_tile.modulate.a = 0
	right_unlock_tile.modulate.a = 0
	player.score_increased.connect(update_unlock_tiles)
	export_area.body_entered.connect(body_enters_export_area)
	export_area.body_exited.connect(body_exits_export_area)
	
	left_extend_area.body_entered.connect(unlock_food_station.bind(true))
	right_extend_area.body_entered.connect(unlock_food_station.bind(false))
	center_shadow.visible = station_x != 0
	conveyor_in.player_root = player
	conveyor_out.player_root = player
	
	recipe_screen.crafted_food = produced_food
	recipe_screen.stored_ingredients = stored_ingredients
	await get_tree().process_frame
	GameState.active_game.ingredient_removed.connect(ingredient_removed_from_inventory)
	GameState.active_game.unlocked_all_foods.connect(hide_unlocked_tiles)
	GameState.active_game.unlocked_foods.append(produced_food)
	GameState.active_game.food_stations[produced_food] = self

func body_enters_export_area(body: Node2D):
	if not body.is_in_group("RestaurantPlayer"): return
	body.can_player_export = true
	body.export_station_index = station_x

func body_exits_export_area(body: Node2D):
	if not body.is_in_group("RestaurantPlayer"): return
	body.can_player_export = false

func ingredient_removed_from_inventory(ingredient_type: Ingredient.IngredientType):
	var export_index = player.export_station_index
	if export_index != station_x: return
	recipe_screen.add_ingredient(ingredient_type)
	conveyor_out.add_to_conveyor(ingredient_type, self)
	var recipe = GridState.get_recipe(produced_food)
	var is_valid_ingredient = ingredient_type in recipe.ingredients
	var score_gain_type = RestaurantPlayer.ScoreGain.IngredientBeltUsage if is_valid_ingredient else RestaurantPlayer.ScoreGain.InvalidIngredientBeltUsage
	if is_valid_ingredient: player.add_score_by_gain_type(score_gain_type)
	
	var held_player_items = GameState.active_game.player_held_items
	var ingredient_node_array = GameState.active_game.player_held_ingredients_nodes
	var removed_ingredient_index = held_player_items.find(ingredient_type)
	held_player_items.remove_at(removed_ingredient_index)
	
	var ingredient_object: IngredientObject = ingredient_node_array[removed_ingredient_index]
	var ingredient_node: PlayerIngredient = ingredient_object.player_ingredient
	
	for i in range(removed_ingredient_index+1, ingredient_node_array.size()):
		var falling_ingredient_node: IngredientObject = ingredient_node_array[i]
		make_ingredient_fall(falling_ingredient_node.player_ingredient, i)
	ingredient_node_array.remove_at(removed_ingredient_index)
	
	await create_tween().tween_property(ingredient_node, "modulate:a", 0, ingredient_disappear_duration).finished
	ingredient_node.queue_free()
	ingredient_object.ingredient_collider.queue_free()

const ingredient_fall_tween_duration = 0.35
const ingredient_disappear_duration = 0.2

func make_ingredient_fall(falling_ingredient: PlayerIngredient, final_y_index):
	create_tween().tween_property(falling_ingredient, "y_index", final_y_index, ingredient_fall_tween_duration).\
		set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func cheapest_unlockable_food() -> Ingredient.FoodType:
	var score_count = player.points_bar.points_count
	var score_milestones_foods = player.points_bar.food_milestones_unlock_order
	var score_milestone_dict = player.points_bar.score_food_unlock_dict
	var unlocked_foods = GameState.active_game.unlocked_foods
	
	for food_type: Ingredient.FoodType in score_milestones_foods:
		var already_unlocked = food_type in unlocked_foods
		if already_unlocked: continue
		var score_requirement = score_milestone_dict[food_type]
		if score_requirement > score_count: break
		return food_type
	
	return Ingredient.FoodType.Unknown

const unlock_tile_alpha_tween_duration = 0.5

func update_unlock_tiles():
	var can_unlock = cheapest_unlockable_food() != Ingredient.FoodType.Unknown
	if not can_unlock: return
	if not unlocked_left: create_tween().tween_property(left_unlock_tile, "modulate:a", 1, unlock_tile_alpha_tween_duration)
	if not unlocked_right: create_tween().tween_property(right_unlock_tile, "modulate:a", 1, unlock_tile_alpha_tween_duration)

const init_station_offset = 0.75
const food_station_show_duration = 0.8
const food_station_offset_tween_duration = 0.925

func setup_food_station(unlocking_left: bool) -> FoodStation:
	var food_station = UID.food_station_scene.instantiate()
	var next_station_offset = -1 if unlocking_left else 1
	var next_station_x = station_x + next_station_offset
	
	food_station.station_x = next_station_x
	food_station.player = player
	var restaurant_root = player.get_parent()
	restaurant_root.stations_root.add_child.call_deferred(food_station)
	if unlocking_left: food_station.unlocked_right = true
	else: food_station.unlocked_left = true
	return food_station

func unlock_food_station(body: Node2D, unlocking_left: bool):
	if not body.is_in_group("RestaurantPlayer"): return
	var cheapest_unlockable = cheapest_unlockable_food()
	var unlocking_disabled = food_station_unlocking_disabled(unlocking_left)
	if unlocking_disabled: return
	
	var food_station = setup_food_station(unlocking_left)
	await handle_station_tween_and_restrict(food_station, unlocking_left, cheapest_unlockable)
	handle_station_all_food_unlocked_signal()

func handle_station_all_food_unlocked_signal():
	await get_tree().process_frame
	GameState.active_game.cannot_unlock_foods = false
	var amount_of_foods = Ingredient.FoodType.size() - 1
	var unlocked_food_count = GameState.active_game.unlocked_foods.size()
	if amount_of_foods != unlocked_food_count: return
	GameState.active_game.unlocked_all_foods.emit()

const unlock_tile_alpha_hide_duration = 0.45

func handle_station_tween_and_restrict(food_station: FoodStation, unlocking_left: bool, cheapest_unlockable: Ingredient.FoodType):
	var next_station_offset = -1 if unlocking_left else 1
	var actual_init_offset = init_station_offset * next_station_offset
	food_station.modulate.a = 0
	create_tween().tween_property(food_station, "modulate:a", 1, food_station_show_duration)
	food_station.produced_food = cheapest_unlockable
	hide_station_extend_tiles(unlocking_left)
	food_station.x_offset = actual_init_offset
	GameState.active_game.cannot_unlock_foods = true
	
	await get_tree().process_frame
	food_station.recipe_screen.update_ingredients_list()
	food_station.update_unlock_tiles()
	await create_tween().tween_property(food_station, "x_offset", 0, food_station_offset_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).finished
	if unlocking_left: unlocked_left = true
	else: unlocked_right = true

func hide_unlocked_tiles():
	create_tween().tween_property(left_unlock_tile, "modulate:a", 0, unlock_tile_alpha_hide_duration)
	create_tween().tween_property(right_unlock_tile, "modulate:a", 0, unlock_tile_alpha_hide_duration)

func food_station_unlocking_disabled(unlocking_left: bool) -> bool:
	var cheapest_unlockable = cheapest_unlockable_food()
	var cannot_unlock = GameState.active_game.cannot_unlock_foods
	if cheapest_unlockable == Ingredient.FoodType.Unknown or cannot_unlock: return true

	var unlocking_disabled = unlocking_left and unlocked_left or not unlocking_left and unlocked_right
	return unlocking_disabled

func hide_station_extend_tiles(unlocking_left: bool):
	var connected_unlock_tile = left_unlock_tile if unlocking_left else right_unlock_tile
	create_tween().tween_property(connected_unlock_tile, "modulate:a", 0, unlock_tile_alpha_hide_duration)
	var cheapest_unlockable = cheapest_unlockable_food()
	var unlocking_enabled = cheapest_unlockable != Ingredient.FoodType.Unknown
	if unlocking_enabled: return
	
	var disconnected_unlock_tile = right_unlock_tile if unlocking_left else left_unlock_tile
	create_tween().tween_property(disconnected_unlock_tile, "modulate:a", 0, unlock_tile_alpha_hide_duration)
