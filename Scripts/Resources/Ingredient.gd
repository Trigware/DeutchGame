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

static func generate() -> Ingredient:
	var instance := Ingredient.new()
	var ingredient_count = IngredientType.size() - 2
	var chosen_ingredient = [IngredientType.Sausage, IngredientType.Tomato, IngredientType.Potato][randi_range(0, 2)]
	instance.ingredient_type = chosen_ingredient as Ingredient.IngredientType
	return instance

static func make(type: IngredientType) -> Ingredient:
	var instance := Ingredient.new()
	instance.ingredient_type = type
	return instance
