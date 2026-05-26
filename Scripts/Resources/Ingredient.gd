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
	var ingredient_evals = get_evaluation_of_ingredients()
	var chosen_ingredient = choose_ingredient(ingredient_evals)
	instance.ingredient_type = chosen_ingredient as Ingredient.IngredientType
	return instance

const player_inventory_item_value = 0.7
const init_food_value = 5
const minimal_ingredient_value_multiplier = 0.425
const ingredient_value_decay_speed: float = 2.2
const undelivered_customer_food_multiplier = 0.8
const score_multiplier_eval_bonus = 1.75

static func get_evaluation_of_ingredients() -> Dictionary[IngredientType, float]:
	var ingredient_evals: Dictionary[IngredientType, float] = {}
	var food_requests = GridState.active_game.custom_food_requests
	var food_stations = GridState.active_game.food_stations
	var ingredient_counts = GridState.active_game.ingredient_count_per_type
	var held_foods = GridState.active_game.player_held_foods
	var score_multipliers = PointsBar.score_multiplier_after_food_unlock
	var milestone_order = PointsBar.food_milestones_unlock_order
	
	for food_type: FoodType in food_stations.keys():
		var food_station = food_stations[food_type]
		var food_recipe = GridState.get_recipe(food_type)
		var customer_requests = food_requests[food_type] if food_type in food_requests else 0
		var player_food_count = held_foods[food_type] if food_type in held_foods else 0
		var food_left_at_station = food_station.outputed_food_count - food_station.foods_obtainted
		
		var was_food_thrown = food_type in GridState.active_game.foods_thrown
		var score_multiplier_value = score_multipliers[food_type]
		var prev_food_index = milestone_order.find(food_type) - 1
		var prev_score_multiplier_value = 1 if prev_food_index == -1 else score_multipliers[milestone_order[prev_food_index]]
		var score_multiplier_diff = score_multiplier_value - prev_score_multiplier_value
		var food_multiplier_bonus = 1 + score_multiplier_diff * score_multiplier_eval_bonus
		var used_food_multiplier_bonus = 1.0 if was_food_thrown else food_multiplier_bonus
		
		for ingredient: IngredientType in food_recipe.ingredients:
			var amount_in_station = food_station.stored_ingredients[ingredient] if\
				ingredient in food_station.stored_ingredients else 0
			var player_item_count = ingredient_counts[ingredient] if ingredient in ingredient_counts else 0
			var effective_item_count = amount_in_station + player_item_count * player_inventory_item_value
			
			var food_necesity = customer_requests - (player_food_count + food_left_at_station) * undelivered_customer_food_multiplier
			var customer_multiplier = max(minimal_ingredient_value_multiplier, food_necesity)
			customer_multiplier *= used_food_multiplier_bonus
			var value_multiplier = init_food_value * customer_multiplier
			var gathered_value = (1.0 / ingredient_value_decay_speed) ** effective_item_count * value_multiplier
			if not ingredient in ingredient_evals: ingredient_evals[ingredient] = 0
			ingredient_evals[ingredient] += gathered_value
	
	return ingredient_evals

const bias_strength = 0.5

static func choose_ingredient(ingredient_evals: Dictionary[IngredientType, float]) -> IngredientType:
	var total_weight : float = 0
	var biased_values = {}
	for ingredient: IngredientType in ingredient_evals:
		var ingredient_value = max(ingredient_evals[ingredient], 0) ** bias_strength
		total_weight += ingredient_value
		biased_values[ingredient] = ingredient_value
		
	var picked_value = randf_range(0, total_weight)
	var accumilated_value = 0
	var chosen_ingredient := IngredientType.Unknown
	for ingredient: IngredientType in biased_values:
		var biased_value = biased_values[ingredient]
		var latest_accum_value = accumilated_value + biased_value
		var was_picked = picked_value >= accumilated_value and picked_value < latest_accum_value
		accumilated_value += biased_value
		if not was_picked: continue
		chosen_ingredient = ingredient
		break
	
	return chosen_ingredient

static func make(type: IngredientType) -> Ingredient:
	var instance := Ingredient.new()
	instance.ingredient_type = type
	return instance
