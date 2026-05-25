class_name Ingredient
extends Resource

enum IngredientType {
	Unknown = -1,
	Pork,
	Egg,
	Cheese,
	Onion,
	Flour,
	Potato,
	Sausage,
	Tomato,
	Breadcrumbs,
	Oil
}

enum FoodType {
	Unknown = -1,
	Schnitzel,
	Kasespatzle,
	Currywurst,
	FriedCheese,
	Grostl
}

const german_food_dict: Dictionary[FoodType, String] = {
	FoodType.Kasespatzle: "Käsespätzle",
	FoodType.FriedCheese: "Gebratener Käse",
	FoodType.Grostl: "Gröstl"
}

const german_ingredient_dict: Dictionary[IngredientType, String] = {
	IngredientType.Pork: "Fleisch",
	IngredientType.Egg: "Ei",
	IngredientType.Cheese: "Käse",
	IngredientType.Onion: "Zweibel",
	IngredientType.Flour: "Mehl",
	IngredientType.Potato: "Kartoffel",
	IngredientType.Sausage: "Paar",
	IngredientType.Tomato: "Tomate",
	IngredientType.Breadcrumbs: "Paniermehl",
	IngredientType.Oil: "Öl"
}

static func get_food_as_german(food: FoodType) -> String:
	if food in german_food_dict: return german_food_dict[food]
	var food_as_str = FoodType.keys()[FoodType.values().find(food)]
	return food_as_str

static func get_ingredient_as_german(ingredient: IngredientType) -> String:
	if not ingredient in german_ingredient_dict: return ""
	return german_ingredient_dict[ingredient]

var ingredient_type: IngredientType
const wanted_ingredient_pick_chance = 40

static func generate() -> Ingredient:
	var instance := Ingredient.new()
	var generatable_ingredients = GridState.active_game.generatable_ingredients
	
	var unlocked_foods = GridState.active_game.unlocked_foods
	var wanted_ingredients = []
	for unlocked_food: Ingredient.FoodType in unlocked_foods:
		var food_recipe = GridState.get_recipe(unlocked_food)
		var recipe_screen_list = GridState.active_game.recipe_screens
		if not unlocked_food in recipe_screen_list: continue
		
		var stored_ingredients = recipe_screen_list[unlocked_food].stored_ingredients
		for ingredient: Ingredient.IngredientType in food_recipe.ingredients:
			if ingredient in stored_ingredients: continue
			wanted_ingredients.append(ingredient)
		
	var pick_from_wanted = randf_range(0, 100) <= wanted_ingredient_pick_chance and wanted_ingredients.size() > 0
	var ingredient_list = wanted_ingredients if pick_from_wanted else generatable_ingredients
	var ingredient_index = randi_range(0, ingredient_list.size() - 1)
	var chosen_ingredient = ingredient_list[ingredient_index]
	instance.ingredient_type = chosen_ingredient as Ingredient.IngredientType
	
	return instance

static func make(type: IngredientType) -> Ingredient:
	var instance := Ingredient.new()
	instance.ingredient_type = type
	return instance
