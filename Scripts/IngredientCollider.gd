class_name IngredientCollider
extends CollisionShape2D

var player_ingredient: Node2D

func _process(_delta):
	if player_ingredient == null: return
	global_position = player_ingredient.global_position
