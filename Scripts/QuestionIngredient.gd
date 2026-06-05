class_name QuestionIngredient
extends Node2D

@onready var sprite = $Sprite
@onready var shadow = $Shadow
@onready var label_offset = $"Label Offset"
@onready var label = $"Label Offset/Label"

var ingredient_type := Ingredient.IngredientType.Unknown
var food_type := Ingredient.FoodType.Unknown
var is_food := false
var ingredient_index: int

const ingredient_size: float = 32
const scale_portion = 0.6
var ingredient_y_portion = 0.47
const init_label_y_pos = 40
const final_label_y_pos = 15

func _ready():
	var frame_coord = Vector2i(food_type as int, 0) if is_food else Vector2i(ingredient_type as int, 1)
	sprite.frame_coords = frame_coord
	shadow.frame_coords = frame_coord
	label.modulate.a = 0
	label_offset.position.y = init_label_y_pos
	var german_name = Ingredient.get_food_as_german(food_type) if is_food else Ingredient.get_ingredient_as_german(ingredient_type)
	label.text = german_name
	var is_fried_cheese = food_type == Ingredient.FoodType.FriedCheese
	if is_fried_cheese: label.label_settings.font_size = 7

func _process(_delta):
	var window_size = DisplayServer.window_get_size()
	var number_of_ingredients = IngredientsQuestion.number_of_generated_foods
	var unmodified_ingredient_size = window_size.x / number_of_ingredients
	var ingredient_scale: float = unmodified_ingredient_size / ingredient_size
	var ingredient_pos_x = ingredient_size * ingredient_scale * (ingredient_index + 0.5)
	scale = Vector2.ONE * ingredient_scale * scale_portion
	position.x = ingredient_pos_x
	position.y = window_size.y * ingredient_y_portion

const label_visibility_tween_duration = 0.6

func show_answers():
	create_tween().tween_property(label, "modulate:a", 1, label_visibility_tween_duration)
	create_tween().tween_property(label_offset, "position:y", final_label_y_pos, label_visibility_tween_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
