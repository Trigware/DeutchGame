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

var ingredient_type: IngredientType

static func generate() -> Ingredient:
	var instance := Ingredient.new()
	var ingredient_count = IngredientType.size() - 2
	instance.ingredient_type = randi_range(0, ingredient_count) as IngredientType
	return instance
