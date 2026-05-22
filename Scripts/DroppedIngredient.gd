extends Area2D

@onready var ingredient_sprite = $Ingredient
var restaurant_player: RestaurantPlayer

var ingredient_type := Ingredient.IngredientType.Unknown
const throw_velocity = 72

func _ready():
	ingredient_sprite.frame_coords = Vector2(ingredient_type as int, 1)
	z_index = 1

func _process(delta: float):
	position.y += delta * throw_velocity
	handle_alpha_when_falling()

const fall_full_alpha_y_global = 54
const fall_no_alpha_y_global = 72
const invisible_ingredient_y_pos = 28
const fully_visible_ingredient_y_pos = 48

func handle_alpha_when_falling():
	var ingredient_based_alpha = 1 - max(inverse_lerp(fall_full_alpha_y_global, fall_no_alpha_y_global, global_position.y), 0)
	var player_based_alpha = clamp(inverse_lerp(invisible_ingredient_y_pos, fully_visible_ingredient_y_pos, restaurant_player.position.y), 0, 1)
	modulate.a = min(ingredient_based_alpha, player_based_alpha)
	
	var free_node = global_position.y > fall_no_alpha_y_global
	if free_node: queue_free()
