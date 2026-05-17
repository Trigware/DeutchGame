@tool
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
@onready var import_area = $"Import Area"
@onready var conveyor_out: ConveyorBelt = $ConveyorOut
@onready var conveyor_in: ConveyorBelt = $ConveyorIn
@onready var recipe_screen = $RecipeScreen

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
	import_area.body_entered.connect(body_enters_export_area)
	import_area.body_exited.connect(body_exits_export_area)
	recipe_screen.crafted_food = produced_food
	recipe_screen.stored_ingredients = stored_ingredients
	await get_tree().process_frame
	GridState.active_game.ingredient_removed.connect(ingredient_removed_from_inventory)
	
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
	
	var held_player_items = GridState.active_game.player_held_items
	var ingredient_node_array = GridState.active_game.player_held_ingredients_nodes
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
