extends Node2D

@onready var ingredient_sprite = $IngredientSprite

var item_type := Ingredient.IngredientType.Unknown

const convayor_tile_size = 24
const ingredient_scale = 0.65
var convayor_belt_scale : float
var init_x_position: float
var time_traveled : float = 0

const ingredient_speed = convayor_tile_size
const modulate_alpha_duration = 0.45

func _ready():
	rotation_degrees = 90
	scale = Vector2.ONE * ingredient_scale
	ingredient_sprite.frame_coords = Vector2(item_type as int, 1)
	init_x_position = -(convayor_belt_scale / 2 - 0.5) * convayor_tile_size
	position.x = init_x_position
	modulate.a = 0

func _process(delta: float):
	time_traveled += delta
	position.x = init_x_position + time_traveled * ingredient_speed
	modulate.a = min(time_traveled, modulate_alpha_duration) / modulate_alpha_duration
