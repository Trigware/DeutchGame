extends Area2D

@onready var ingredient_sprite = $Ingredient
var restaurant_player: RestaurantPlayer

var ingredient_type := Ingredient.IngredientType.Unknown
const throw_velocity = 65

func _ready():
	ingredient_sprite.frame_coords = Vector2(ingredient_type as int, 1)
	z_index = 1
	area_entered.connect(area_hit_ingredient)

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

func area_hit_ingredient(area: Area2D):
	if not area.is_in_group("PlayerCatchBody"): return
	var player_root: RestaurantPlayer = area.get_parent()
	if player_root.player_fallen: return
	player_root.finish_ingredient_pickup.call_deferred(self, Ingredient.make(ingredient_type), area, true)
