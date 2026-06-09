class_name PointsBar
extends CanvasLayer

@onready var progress_bar = $"Progress Bar"
@onready var points_gathered = $PointsGathered
@onready var seperators = $Seperators
@export var player_root: RestaurantPlayer
@export var time_view: TimeView

const progress_x_bar = 500
const icon_offset = 45
var timer_y_offset: float
const timer_y_size = 40
const final_y_size_multiplier = 1.5
const maximum_points_count = 1000
var points_count: float = 0
const bar_padding = 0.5

signal new_food_thrown(food_type: Ingredient.FoodType)

static var food_milestones_unlock_order : Array[Ingredient.FoodType] =\
	[Ingredient.FoodType.Currywurst, Ingredient.FoodType.FriedCheese, Ingredient.FoodType.Kasespatzle, Ingredient.FoodType.Grostl, Ingredient.FoodType.Schnitzel]

const score_food_unlock_dict: Dictionary[Ingredient.FoodType, float] = {
	Ingredient.FoodType.Currywurst: 0,
	Ingredient.FoodType.FriedCheese: 200,
	Ingredient.FoodType.Kasespatzle: 450,
	Ingredient.FoodType.Grostl: 725,
	Ingredient.FoodType.Schnitzel: 1200,
}

static var score_multiplier_after_food_unlock: Dictionary[Ingredient.FoodType, float] = {
	Ingredient.FoodType.Currywurst: 1.35,
	Ingredient.FoodType.FriedCheese: 1.7,
	Ingredient.FoodType.Kasespatzle: 2,
	Ingredient.FoodType.Grostl: 2.4,
	Ingredient.FoodType.Schnitzel: 2.75
}

func _ready():
	var final_timer_offset = timer_y_size * final_y_size_multiplier
	create_tween().tween_property(self, "timer_y_offset", final_timer_offset, 1).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	progress_bar.size.x = progress_x_bar
	new_food_thrown.connect(on_food_throw_bonus_unlocked)
	initalize_seperators()

const final_multiplier_label_modulate = Color("55ff3b")
const milestone_multiplier_label_modulate_tween_duration = 0.6
const score_multiplier_tween_duration = 1.35

func on_food_throw_bonus_unlocked(food_type: Ingredient.FoodType):
	if not food_type in progress_bar_seperator_dict: return
	var milestone_root = progress_bar_seperator_dict[food_type]
	var multiplier_label = milestone_root.get_node("Multiplier")
	create_tween().tween_property(multiplier_label, "modulate", final_multiplier_label_modulate, milestone_multiplier_label_modulate_tween_duration)
	var final_score_multiplier = score_multiplier_after_food_unlock[food_type]
	create_tween().tween_property(player_root, "points_multiplier", final_score_multiplier, score_multiplier_tween_duration)

func _process(delta: float):
	var window_size = DisplayServer.window_get_size()
	var total_bar_width = progress_x_bar + icon_offset
	var bar_scale = (window_size.x * (1 - bar_padding)) / total_bar_width
	scale = Vector2.ONE * bar_scale
	var used_points = min(maximum_points_count, points_count) if time_view.was_previously_time_over else points_count
	points_gathered.text = str(floori(used_points)) + "/" + str(maximum_points_count)
	
	offset.x = window_size.x / 2 - progress_x_bar / 2 * bar_scale + icon_offset / 2 * bar_scale
	offset.y = window_size.y - timer_y_offset * bar_scale
	progress_bar.value = used_points / maximum_points_count
	var restaurant_tutorial_explained = GameState.active_game.restaurant_minigame_explained
	if points_count > maximum_points_count and not goal_reached_previously and restaurant_tutorial_explained:
		point_goal_reached()

var goal_reached_previously = false

func point_goal_reached():
	goal_reached_previously = true
	Overlay.switch_scene(UID.board_scene, TimeView.minigame_cover_overlay_tween_duration, TimeView.minigame_overlay_inbetween_duration, goal_reached)

func goal_reached(board_scene: BoardRoot): board_scene.push_piece()

const time_per_point = 0.05

func add_score(added_score: float):
	var time_to_update = time_per_point * added_score
	var final_point_count = points_count + added_score
	create_tween().tween_property(self, "points_count", final_point_count, time_to_update)

const score_milestone_x_pos_multiplier = 0.732
var progress_bar_seperator_dict: Dictionary[Ingredient.FoodType, Node2D]

func initalize_seperators():
	for food_type: Ingredient.FoodType in score_food_unlock_dict.keys():
		var score_requirement = score_food_unlock_dict[food_type]
		var score_milestone = UID.score_milestone_scene.instantiate()
		var overall_goal = score_requirement / maximum_points_count
		if overall_goal > 1: continue
		score_milestone.position.x = overall_goal * progress_x_bar * score_milestone_x_pos_multiplier
		
		var food_sprite = score_milestone.get_node("Food")
		var multiplier_label = score_milestone.get_node("Multiplier")
		food_sprite.frame_coords = Vector2(food_type as int, 0)
		var unlocked_multiplier = score_multiplier_after_food_unlock[food_type]
		var multiplier_as_str = str(unlocked_multiplier) if unlocked_multiplier != floor(unlocked_multiplier) else str(int(unlocked_multiplier))
		multiplier_label.text = multiplier_as_str + "x"
		seperators.add_child(score_milestone)
		progress_bar_seperator_dict[food_type] = score_milestone

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
