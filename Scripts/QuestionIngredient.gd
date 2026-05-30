class_name QuestionIngredient
extends Node2D

@onready var sprite = $Sprite
@onready var shadow = $Shadow
@onready var label = $Label

var ingredient_type := Ingredient.IngredientType.Unknown
var ingredient_index: int

const ingredient_size = 32
const scale_portion = 0.6
var ingredient_y_portion = 0.435

func _ready():
	var frame_coord = Vector2i(ingredient_type as int, 1)
	sprite.frame_coords = frame_coord
	shadow.frame_coords = frame_coord

func _process(_delta):
	var window_size = DisplayServer.window_get_size()
	var number_of_ingredients = IngredientsQuestion.number_of_generated_foods
	var unmodified_ingredient_size = window_size.x / number_of_ingredients
	var ingredient_scale: float = unmodified_ingredient_size / ingredient_size
	var ingredient_pos_x = ingredient_size * ingredient_scale * (ingredient_index + 0.5)
	scale = Vector2.ONE * ingredient_scale * scale_portion
	position.x = ingredient_pos_x
	position.y = window_size.y * ingredient_y_portion
