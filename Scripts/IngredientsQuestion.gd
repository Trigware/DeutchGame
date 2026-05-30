class_name IngredientsQuestion
extends Control

const number_of_generated_foods = 6

var generated_ingredients: Array = []

func _ready():
	for i in range(number_of_generated_foods):
		var question_ingredient: QuestionIngredient = UID.question_ingredient_scene.instantiate()
		question_ingredient.ingredient_index = i
		
		var chosen_ingredient = Ingredient.IngredientType.Unknown
		while true:
			var max_ingredient_index = Ingredient.IngredientType.size()-1
			var chosen_ingredient_index = randi_range(1, max_ingredient_index)
			chosen_ingredient = Ingredient.IngredientType.values()[chosen_ingredient_index]
			if not chosen_ingredient in generated_ingredients: break
		generated_ingredients.append(chosen_ingredient)
		question_ingredient.ingredient_type = chosen_ingredient
		
		add_child(question_ingredient)
