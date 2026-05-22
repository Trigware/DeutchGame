extends Node2D
 
@onready var sprite = $Sprite

var food_type := Ingredient.FoodType.Unknown

func _ready():
	sprite.frame_coords = Vector2(food_type as int, 0)

const customer_food_y_dest = 96
const food_delivery_duration = 0.55
const obscure_food_tween_duration = 0.7
const obscure_tween_delay = 2.5

func deliver_food():
	await create_tween().tween_property(self, "position:y", customer_food_y_dest, food_delivery_duration).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(self, "modulate:a", 0, obscure_food_tween_duration).set_delay(obscure_tween_delay)
