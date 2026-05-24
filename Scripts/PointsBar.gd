class_name PointsBar
extends CanvasLayer

@onready var progress_bar = $"Progress Bar"
@onready var points_gathered = $PointsGathered
@onready var seperators = $Seperators
@export var player_root: RestaurantPlayer

const progress_x_bar = 500
const icon_offset = 45
var timer_y_offset: float
const timer_y_size = 40
const final_y_size_multiplier = 1.5
const maximum_points_count = 1000
var points_count: float = 0
const bar_padding = 0.5

const food_milestones_unlock_order : Array[Ingredient.FoodType] =\
	[Ingredient.FoodType.Currywurst, Ingredient.FoodType.FriedCheese, Ingredient.FoodType.Kasespatzle, Ingredient.FoodType.Grostl, Ingredient.FoodType.Schnitzel]

const score_food_unlock_dict: Dictionary[Ingredient.FoodType, float] = {
	Ingredient.FoodType.Currywurst: 0,
	Ingredient.FoodType.FriedCheese: 125,
	Ingredient.FoodType.Kasespatzle: 335,
	Ingredient.FoodType.Grostl: 700,
	Ingredient.FoodType.Schnitzel: 1200,
}

func _ready():
	var final_timer_offset = timer_y_size * final_y_size_multiplier
	create_tween().tween_property(self, "timer_y_offset", final_timer_offset, 1).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	progress_bar.size.x = progress_x_bar
	initalize_seperators()
	#player_root.add_to_score(1)

func _process(delta: float):
	var window_size = DisplayServer.window_get_size()
	var total_bar_width = progress_x_bar + icon_offset
	var bar_scale = (window_size.x * (1 - bar_padding)) / total_bar_width
	scale = Vector2.ONE * bar_scale
	points_gathered.text = str(floori(points_count)) + "/" + str(maximum_points_count)
	
	offset.x = window_size.x / 2 - progress_x_bar / 2 * bar_scale + icon_offset / 2 * bar_scale
	offset.y = window_size.y - timer_y_offset * bar_scale
	progress_bar.value = points_count / maximum_points_count

const time_per_point = 0.05

func add_score(added_score: float):
	var time_to_update = time_per_point * added_score
	var final_point_count = points_count + added_score
	create_tween().tween_property(self, "points_count", final_point_count, time_to_update)

const score_milestone_x_pos_multiplier = 0.732

func initalize_seperators():
	for food_type: Ingredient.FoodType in score_food_unlock_dict.keys():
		var score_requirement = score_food_unlock_dict[food_type]
		var score_milestone = UID.score_milestone_scene.instantiate()
		var overall_goal = score_requirement / maximum_points_count
		if overall_goal > 1: continue
		score_milestone.position.x = overall_goal * progress_x_bar * score_milestone_x_pos_multiplier
		score_milestone.get_node("Food").frame_coords = Vector2(food_type as int, 0)
		seperators.add_child(score_milestone)

func get_closest_unlocked_food_requirement() -> int:
	var highest_unlocked_requirement = -INF
	for unlocked_food: Ingredient.FoodType in Ingredient.FoodType.values():
		if not unlocked_food in score_food_unlock_dict: continue
		var score_requirement = score_food_unlock_dict[unlocked_food]
		if score_requirement > highest_unlocked_requirement and score_requirement <= points_count:
			highest_unlocked_requirement = score_requirement 
	return highest_unlocked_requirement

func get_food_from_requirement(closest_requirement) -> Ingredient.FoodType:
	return score_food_unlock_dict.keys()[score_food_unlock_dict.values().find(closest_requirement)]

func get_next_food_milestone_requirement() -> int:
	var closest_requirement = get_closest_unlocked_food_requirement()
	var closest_food = get_food_from_requirement(closest_requirement)
	var closest_milestone_index = food_milestones_unlock_order.find(closest_food)
	var next_milestone = food_milestones_unlock_order[closest_milestone_index + 1]
	var next_milestone_requirement = score_food_unlock_dict[next_milestone]
	return next_milestone_requirement
