class_name RestaurantItemSlot
extends Node2D

const item_slot_size = Vector2(32, 32)
const slot_padding = 1.25
const fit_item_slot_count: int = 5
const used_window_portion: float = 0.7
const corner_offset: float = 0.1

@onready var item_sprite = $Item
@onready var main_sprite = $Slot/Main
@onready var count_label = $Count
@onready var slot_root = $Slot

var item_type := Ingredient.IngredientType.Unknown
var food_type := Ingredient.FoodType.Unknown
var item_index: int
var transition_value: float
var is_food = false

const item_slot_count_base_pos = Vector2(-3, 16)
const food_slot_count_offset = 4

func _process(_delta):
	handle_item_slot_drawing()

func handle_item_slot_drawing():
	var window_size = DisplayServer.window_get_size()
	var modified_window_size = window_size * used_window_portion
	var x_coords = food_type if is_food else item_type
	var y_coords = 0 if is_food else 1
	var frame_coords = Vector2(x_coords as int, y_coords)
	slot_root.visible = not is_food
	var count_pos = item_slot_count_base_pos
	if is_food: count_pos += Vector2.ONE * food_slot_count_offset
	count_label.position = count_pos
	
	item_sprite.frame_coords = frame_coords
	var used_dict = GameState.active_game.player_held_foods if is_food else GameState.active_game.ingredient_count_per_type
	var item_count = 0
	if not is_food and item_type in used_dict: item_count = used_dict[item_type]
	if is_food and food_type in used_dict: item_count = used_dict[food_type]
	
	var scale_value = modified_window_size.y / (item_slot_size.y * slot_padding * fit_item_slot_count)
	
	var x_index = item_index / fit_item_slot_count
	if is_food: x_index += 1
	var y_index = item_index % fit_item_slot_count
	var vec_offset = Vector2.ONE * corner_offset
	if is_food: vec_offset = Vector2(-vec_offset.x, vec_offset.y)
	var vector_index = Vector2(x_index, y_index) + vec_offset
	
	count_label.text = str(item_count)
	position = vector_index * item_slot_size * slot_padding * scale_value
	var x_pos = position.x
	if is_food: x_pos = window_size.x - x_pos
	position.x = x_pos
	modulate.a = transition_value
	scale = Vector2.ONE * scale_value

func does_cursor_overlap():
	var cursor_local_space = get_local_mouse_position()
	var item_slot_rect = Rect2(Vector2.ZERO, item_slot_size * scale / 2)
	return item_slot_rect.has_point(cursor_local_space)
	
