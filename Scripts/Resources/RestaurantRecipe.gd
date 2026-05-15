class_name RestaurantRecipe
extends Resource

@export var resulting_food := Ingredient.FoodType.Unknown
@export var ingredients : Array[Ingredient.IngredientType]
