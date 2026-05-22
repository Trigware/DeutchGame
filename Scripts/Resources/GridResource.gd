class_name GridState
extends Resource

enum PieceType {
	Unknown,
	Sword,
	Wizard,
	Horse
}

enum GameEndType {
	Ongoing,
	FlagCaptured,
	PiecelessOpponent
}

const piece_atlas_coords_x: Dictionary[PieceType, int] = {
	PieceType.Wizard: 7, PieceType.Sword: 8, PieceType.Horse: 9
}

enum PowerUpType {
	None,
	SpeedBoost,
	Shield,
	TrickyItem,
	WizardFreeze,
	OpponentSlowness
}

const team_modulate : Dictionary[SpecialTile.TeamRelation, Color] = {
	SpecialTile.TeamRelation.Red: Color(0xff8787ff),
	SpecialTile.TeamRelation.Blue: Color(0x7ab8ffff)
}

const diagonals_modulate: Dictionary[SpecialTile.TeamRelation, Color] = {
	SpecialTile.TeamRelation.Red: Color("6b3838"),
	SpecialTile.TeamRelation.Blue: Color("38546bff")
}

@export var piece_locations: Dictionary[Vector2i, Piece]
@export var special_tiles: Dictionary[Vector2i, SpecialTile]
@export var power_up_tiles: Dictionary[Vector2i, PowerUpType] = {}

@export var player_power_ups: Dictionary[SpecialTile.TeamRelation, PlayerPowerUp] = {
	SpecialTile.TeamRelation.Red: PlayerPowerUp.ctor([
		PowerUp.ctor(GridState.PowerUpType.SpeedBoost, 5),
		PowerUp.ctor(GridState.PowerUpType.Shield, 5),
		PowerUp.ctor(GridState.PowerUpType.TrickyItem, 5),
		PowerUp.ctor(GridState.PowerUpType.WizardFreeze, 5),
		PowerUp.ctor(GridState.PowerUpType.OpponentSlowness, 5),
	]),
	SpecialTile.TeamRelation.Blue: PlayerPowerUp.ctor([
		PowerUp.ctor(GridState.PowerUpType.SpeedBoost, 5),
		PowerUp.ctor(GridState.PowerUpType.Shield, 5),
		PowerUp.ctor(GridState.PowerUpType.TrickyItem, 5),
		PowerUp.ctor(GridState.PowerUpType.WizardFreeze, 5),
		PowerUp.ctor(GridState.PowerUpType.OpponentSlowness, 5),
	])
}

const team_member_count: Dictionary[SpecialTile.TeamRelation, int] = {
	SpecialTile.TeamRelation.Red: 12,
	SpecialTile.TeamRelation.Blue: 15
} #placeholder

var player_turn := SpecialTile.TeamRelation.Red
var grave_tiles: Array[Vector2i] = []
var flag_origin: Dictionary[SpecialTile.TeamRelation, Vector2i]
var game_end_type := GameEndType.Ongoing
var grid_tiles = null
var latest_move : Move

# Restaurant Minigame
var player_held_items: Array[Ingredient.IngredientType]
var player_held_ingredients_nodes: Array[IngredientObject]
var ingredient_count_per_type: Dictionary[Ingredient.IngredientType, int]
var player_held_foods: Dictionary[Ingredient.FoodType, int]
var unlocked_foods: Array[Ingredient.FoodType]

signal ingredient_type_added(ingredient_type: Ingredient.IngredientType)
signal food_type_added(food_type: Ingredient.FoodType)
signal ingredient_removed(ingredient_type: Ingredient.IngredientType)
signal restaurant_game_started

const team_names : Dictionary[SpecialTile.TeamRelation, String] = {
	SpecialTile.TeamRelation.Red: "červení",
	SpecialTile.TeamRelation.Blue: "modří"
} #placeholder

const number_of_players: Dictionary[SpecialTile.TeamRelation, int] = {
	SpecialTile.TeamRelation.Red: 15,
	SpecialTile.TeamRelation.Blue: 12
}

var restaurant_recipes: Dictionary[Ingredient.FoodType, RestaurantRecipe] = {}

static var active_game: GridState

func invert_turn(): player_turn = get_inverted_turn()
func get_inverted_turn():
	return SpecialTile.TeamRelation.Blue if player_turn == SpecialTile.TeamRelation.Red\
		else SpecialTile.TeamRelation.Red

func next_turn():
	invert_turn()
	update_effect_durations()

func update_effect_durations():
	for piece: Piece in piece_locations.values():
		for effect: Effect in piece.status_effects.values():
			if effect.duration_node == null: continue
			effect.duration_node.progress_effect_timer()

func generate_power_up(tile_coord: Vector2i, tile_map: TileMapLayer):
	var last_power_up = PowerUpType.values()[PowerUpType.values().size()-1]-1
	var chosen_power_up = randi_range(0, last_power_up) + 1
	power_up_tiles[tile_coord] = chosen_power_up
	var atlas_coord = Vector2i(chosen_power_up-1, 0)
	tile_map.set_cell(tile_coord, 1, atlas_coord)

func has_tile_power_up(tile_coord: Vector2i):
	return tile_coord in power_up_tiles

func receive_power_up(power_up_kind: PowerUpType):
	var actual_team = get_inverted_turn()
	var wanted_player_power_up_setup = actual_team in player_power_ups
	if not wanted_player_power_up_setup: player_power_ups[actual_team] = PlayerPowerUp.new()
	var playing_power_ups = player_power_ups[actual_team]
	var no_wanted_kind_power_up = not power_up_kind in playing_power_ups.power_ups
	if no_wanted_kind_power_up:
		playing_power_ups.power_ups[power_up_kind] = PowerUp.new()
	playing_power_ups.power_ups[power_up_kind].amount += 1

func decrement_power_up(power_up_kind: PowerUpType):
	var player_power_up: PlayerPowerUp = player_power_ups[player_turn]
	var power_up: PowerUp = player_power_up.power_ups[power_up_kind]
	power_up.amount -= 1

const recipe_list_directory := "res://Resources/Recipes/"

func create_recipe_list():
	if restaurant_recipes.size() > 0: return
	var recipe_directory = DirAccess.open(recipe_list_directory)
	if recipe_directory == null:
		push_error("Recipe directory not found!")
		return
	
	recipe_directory.list_dir_begin()
	
	while true:
		var current_file := recipe_directory.get_next()
		if current_file == "": break
		if recipe_directory.current_is_dir() or current_file.begins_with("."): continue
		
		var full_file_path = recipe_list_directory + current_file
		var recipe_resource := load(full_file_path)
		if not recipe_resource is RestaurantRecipe: continue
		var current_recipe := recipe_resource as RestaurantRecipe
		restaurant_recipes[current_recipe.resulting_food] = current_recipe
	
	recipe_directory.list_dir_end()

static func get_recipe(crafted_food: Ingredient.FoodType) -> RestaurantRecipe:
	if not crafted_food in GridState.active_game.restaurant_recipes:
		active_game.create_recipe_list()
	return GridState.active_game.restaurant_recipes[crafted_food]

static func add_food(food_type: Ingredient.FoodType):
	var held_food_dict = active_game.player_held_foods 
	if not food_type in held_food_dict:
		held_food_dict[food_type] = 0
		active_game.food_type_added.emit(food_type)
	held_food_dict[food_type] += 1
