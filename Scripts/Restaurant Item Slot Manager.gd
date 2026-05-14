extends CanvasLayer

var item_slots: Dictionary[Ingredient.IngredientType, Node2D]

@onready var left_gradient = $LeftGradient
@onready var right_gradient = $RightGradient
@onready var player = $"../Player"

const gradient_window_width_portion = 0.2

func _ready():
	await get_tree().process_frame
	GridState.active_game.ingredient_type_added.connect(add_ingredient)

func _process(_delta):
	var window_size = DisplayServer.window_get_size()
	var gradient_width = window_size.x * gradient_window_width_portion
	left_gradient.size = Vector2(gradient_width, window_size.y)
	right_gradient.size = Vector2(gradient_width, window_size.y)
	right_gradient.position.x = window_size.x - gradient_width
	handle_interactable_slot()

const restaurant_slot_tween_duration = 0.4

func add_ingredient(ingredient_type: Ingredient.IngredientType):
	var restaurant_slot = UID.restaurant_item_slot.instantiate()
	restaurant_slot.item_type = ingredient_type
	restaurant_slot.item_index = item_slots.size()
	restaurant_slot.transition_value = 0
	create_tween().tween_property(restaurant_slot, "transition_value", 1, restaurant_slot_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	add_child(restaurant_slot)
	item_slots[ingredient_type] = restaurant_slot

const overlapping_slot_color = Color("ffe991")
var overlapping_type: Ingredient.IngredientType

func handle_interactable_slot():
	overlapping_type = Ingredient.IngredientType.Unknown
	
	for item_type in item_slots.keys():
		var item_slot_node = item_slots[item_type]
		var cursor_overlaps = item_slot_node.does_cursor_overlap()
		item_slot_node.main_sprite.modulate = Color.WHITE
		if not cursor_overlaps or not player.can_player_export: continue
		
		overlapping_type = item_type
		item_slot_node.main_sprite.modulate = overlapping_slot_color
	
	var selecting_item_slot = overlapping_type != Ingredient.IngredientType.Unknown
	if not selecting_item_slot or not Input.is_action_just_pressed("item_slot_used"): return
	
	var item_dict = GridState.active_game.ingredient_count_per_type
	var overlapping_type_count = item_dict[overlapping_type]
	if overlapping_type_count <= 0: return
	
	item_dict[overlapping_type] -= 1
	
	var is_removing_type = item_dict[overlapping_type] == 0
	GridState.active_game.ingredient_removed.emit(overlapping_type)
	if is_removing_type: remove_item_type(overlapping_type)
	else: return
	
	var used_slot = item_slots[overlapping_type]
	item_slots.erase(overlapping_type)
	used_slot.queue_free()

func remove_item_type(removed_type: Ingredient.IngredientType):
	var removed_index = item_slots.keys().find(removed_type)
	for i in range(removed_index+1, item_slots.size()):
		var item_slot: RestaurantItemSlot = item_slots.values()[i]
		item_slot.item_index -= 1
	GridState.active_game.ingredient_count_per_type.erase(removed_type)
