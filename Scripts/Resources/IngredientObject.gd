class_name IngredientObject
extends Resource

var player_ingredient: PlayerIngredient
var ingredient_collider: IngredientCollider

static func ctor(ingredient: PlayerIngredient, collider: IngredientCollider) -> IngredientObject:
	var instance := IngredientObject.new()
	instance.player_ingredient = ingredient
	instance.ingredient_collider = collider
	return instance
