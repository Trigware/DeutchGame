@tool
class_name RecipeScreen
extends Control

@export var crafted_food := Ingredient.FoodType.Unknown

@onready var crafted_food_label = $"Display Elements/Crafted Food"
@onready var producted_food_icon = $"Display Elements/Produced Food Icon"
@onready var ingredients_list = $"Display Elements/Ingredients List"
@onready var display_elements = $"Display Elements"

var stored_ingredients: Dictionary[Ingredient.IngredientType, int]

func _ready():
	display_elements.modulate.a = 0
	await update_ingredients_list()
	GameState.active_game.recipe_screens[crafted_food] = self
	await GameState.active_game.restaurant_game_started
	create_tween().tween_property(display_elements, "modulate:a", 1, ingredients_show_tween_duration)

func _process(_delta):
	if crafted_food == Ingredient.FoodType.Unknown:
		hide()
		return
	show()
	producted_food_icon.frame_coords.x = crafted_food as int
	handle_food_label_size()

const ingredients_show_tween_duration = 0.4
const checkmark_bbcode = "[img=10]" + UID.checkmark_uid + "[/img]"
const food_spritesheet_section_size = Vector2(32, 32)

func update_ingredients_list():
	if GameState.active_game == null: await get_tree().process_frame
	if GameState.active_game == null: return
	
	var recipe_resource = GridState.get_recipe(crafted_food)
	var ingredient_text = ""
	for recipe_ingredient: Ingredient.IngredientType in recipe_resource.ingredients:
		var german_ingredient_name = Ingredient.get_ingredient_as_german(recipe_ingredient)
		var added_text = "- " + german_ingredient_name
		
		var ingredient_count = 0
		if recipe_ingredient in stored_ingredients: ingredient_count = stored_ingredients[recipe_ingredient]
		if ingredient_count >= 1: added_text += checkmark_bbcode
		if ingredient_count >= 2: added_text += "[font_size=10]" + '(' + str(ingredient_count) + ')' + "[/font_size]"
		var ingredient_spritesheet_pos = Vector2(recipe_ingredient as int, 1)
		
		'''added_text += "[img=18 region=" + str(ingredient_spritesheet_pos.x * food_spritesheet_section_size.x) +\
			"," + str(ingredient_spritesheet_pos.y * food_spritesheet_section_size.y) + "," +\
			str(food_spritesheet_section_size.x) + "," + str(food_spritesheet_section_size.y) + "]"\
			+ UID.food_spritesheet_uid + "[/img]"'''
		
		ingredient_text += added_text + '\n'
	ingredients_list.text = ingredient_text

const maximum_regular_label_char_count = 11

func handle_food_label_size():
	var crafted_food_as_text = Ingredient.get_food_as_german(crafted_food) 
	crafted_food_label.text = crafted_food_as_text
	var crafted_food_length = crafted_food_as_text.length()
	var crafted_exceeded_length_portion = float(crafted_food_length) / maximum_regular_label_char_count
	var used_scale_x = min(1.0 / crafted_exceeded_length_portion, 1)
	crafted_food_label.scale.x = used_scale_x

func add_ingredient(ingredient_type: Ingredient.IngredientType):
	if not ingredient_type in stored_ingredients: stored_ingredients[ingredient_type] = 0
	stored_ingredients[ingredient_type] += 1
	var restaurant_recipe = GridState.get_recipe(crafted_food)
	var is_ingredient_allowed = ingredient_type in restaurant_recipe.ingredients
	if not is_ingredient_allowed: return
	update_ingredients_list()
