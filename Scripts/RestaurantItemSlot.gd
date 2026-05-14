class_name RestaurantItemSlot
extends Node2D

const item_slot_size = Vector2(32, 32)
const slot_padding = 1.25
const fit_item_slot_count: int = 5
const used_window_portion: float = 0.7
const corner_offset: float = 0.1

@onready var item_sprite = $Item
@onready var main_sprite = $Main
@onready var count_label = $Count

var item_type := Ingredient.IngredientType.Unknown
var item_index: int
var transition_value: float

func _process(_delta):
	handle_item_slot_drawing()

func handle_item_slot_drawing():
	var window_size = DisplayServer.window_get_size() * used_window_portion
	item_sprite.frame_coords = Vector2(item_type as int, 1)
	var ingredient_dict = GridState.active_game.ingredient_count_per_type
	var item_count = 0
	if item_type in ingredient_dict: item_count = ingredient_dict[item_type]
	
	var scale_value = window_size.y / (item_slot_size.y * slot_padding * fit_item_slot_count)
	
	var x_index = item_index / fit_item_slot_count
	var y_index = item_index % fit_item_slot_count
	var vector_index = Vector2(x_index, y_index) + Vector2.ONE * corner_offset
	
	count_label.text = str(item_count)
	position = vector_index * item_slot_size * slot_padding * scale_value
	modulate.a = transition_value
	scale = Vector2.ONE * scale_value

func does_cursor_overlap():
	var cursor_local_space = get_local_mouse_position()
	var item_slot_rect = Rect2(Vector2.ZERO, item_slot_size * scale / 2)
	return item_slot_rect.has_point(cursor_local_space)
	
