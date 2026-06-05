class_name IngredientsQuestion
extends Control

const number_of_generated_foods = 4

var generated_ingredients: Array = []
var generated_foods: Array = []
var ingredient_nodes: Array[QuestionIngredient]
const restricted_ingredients = [Ingredient.IngredientType.Flour, Ingredient.IngredientType.Breadcrumbs, Ingredient.IngredientType.Oil]
const restricted_foods = [Ingredient.FoodType.Kasespatzle, Ingredient.FoodType.FriedCheese, Ingredient.FoodType.Grostl]

func _ready():
	generate_ingredients()

func show_answers():
	for ingredient: QuestionIngredient in ingredient_nodes:
		ingredient.show_answers()

var chosen_ingredient = Ingredient.IngredientType.Unknown
var chosen_food = Ingredient.FoodType.Unknown
var has_generated_ingredient = false
var question_ingredient: QuestionIngredient

func generate_ingredients():
	if GameState.active_game == null: GameState.active_game = UID.init_state
	for i in range(number_of_generated_foods):
		question_ingredient = UID.question_ingredient_scene.instantiate()
		question_ingredient.ingredient_index = i
		generate_ingredient_or_food_value()
		initiialize_question_ingredient_scene()

const generation_attempt_limit = 1000

func generate_ingredient_or_food_value(): for i in range(generation_attempt_limit):
	var max_ingredient_index = Ingredient.IngredientType.size()-1
	var chosen_index = pick_ingredient_or_food_index(max_ingredient_index)
	var is_invalid_index = chosen_index == max_ingredient_index
	if is_invalid_index: continue
	
	initialize_ingredient_or_food_value(chosen_index, max_ingredient_index)
	var will_retry = will_retry_generating()
	if will_retry: continue
	break

func pick_ingredient_or_food_index(max_ingredient_index):
	var food_count = Ingredient.FoodType.size()
	var max_total_index = max_ingredient_index + food_count - 1
	var chosen_index = randi_range(1, max_total_index)
	return chosen_index

func initialize_ingredient_or_food_value(chosen_index, max_ingredient_index):
	has_generated_ingredient = chosen_index < max_ingredient_index
	var local_index = chosen_index if has_generated_ingredient else chosen_index - max_ingredient_index
	if has_generated_ingredient: chosen_ingredient = Ingredient.IngredientType.values()[local_index]
	else: chosen_food = Ingredient.FoodType.values()[local_index]

func will_retry_generating():
	var chosen_ingredient_or_food = chosen_ingredient if has_generated_ingredient else chosen_food
	var active_game = GameState.active_game
	var encountered_ingredients_or_food_list = active_game.ingredients_encountered if has_generated_ingredient else active_game.foods_encountered
	var restricted_ingredients_or_food_list = restricted_ingredients if has_generated_ingredient else restricted_foods
	var generated_ingredients_or_food_list = generated_ingredients if has_generated_ingredient else generated_foods
	
	var encounted_before = chosen_ingredient_or_food in encountered_ingredients_or_food_list
	var is_food_restricted = chosen_ingredient_or_food in restricted_ingredients_or_food_list and not encounted_before
	var has_food_generated_before = chosen_ingredient_or_food in generated_ingredients_or_food_list
	return is_food_restricted or has_food_generated_before

func initiialize_question_ingredient_scene():
	var tracker_list = generated_ingredients if has_generated_ingredient else generated_foods
	var ingredient_or_food = chosen_ingredient if has_generated_ingredient else chosen_food
	tracker_list.append(ingredient_or_food)
	if has_generated_ingredient: question_ingredient.ingredient_type = chosen_ingredient
	else: question_ingredient.food_type = chosen_food
	
	question_ingredient.is_food = not has_generated_ingredient
	ingredient_nodes.append(question_ingredient)
	add_child(question_ingredient)
