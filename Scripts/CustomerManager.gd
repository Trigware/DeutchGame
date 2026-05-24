extends Node2D
class_name CustomerManager

@export var item_slots: MinigameCountdown
@export var player_root: RestaurantPlayer
@export var points_bar: PointsBar

const number_of_chairs = 5
const chair_y_pos = 130
const chair_x_origin = -105
const chair_x_endpoint = 105
const total_x_range = chair_x_endpoint - chair_x_origin
const customer_range = total_x_range / number_of_chairs

var active_customers: Dictionary[int, Customer] = {}

const initial_food = Ingredient.FoodType.Currywurst

func _ready():
	player_root.score_increased.connect(on_score_increased)
	for i in range(number_of_chairs):
		var restaurant_chair = UID.restaurant_chair_scene.instantiate()
		restaurant_chair.position.y = chair_y_pos
		var pos_x = get_x_by_index(i)
		restaurant_chair.position.x = pos_x
		add_child(restaurant_chair)
	
	if item_slots.minigame_started:
		spawn_initial_customer()
		return
	await GridState.active_game.restaurant_game_started
	spawn_initial_customer()

func spawn_initial_customer(): spawn_customer(initial_food)

func _process(_delta):
	handle_food_throwing()

const customer_spawning_y = 24*10

func get_x_by_index(index):
	return chair_x_origin + total_x_range / (number_of_chairs - 1) * index

const customer_show_tween_duration = 0.35
const customer_spawn_delay = 2
const customer_kind_count = 4

func spawn_customer(requested_food):
	await get_tree().create_timer(customer_spawn_delay).timeout
	var restaurant_customer = UID.customer_scene.instantiate()
	var customer_x = -1
	restaurant_customer.modulate.a = 0
	var restaurant_full = active_customers.size() == number_of_chairs
	if restaurant_full: return
	while true:
		customer_x = randi_range(0, number_of_chairs - 1)
		var valid_spawn_pos = not customer_x in active_customers
		if valid_spawn_pos: break
	
	restaurant_customer.position = Vector2(get_x_by_index(customer_x), customer_spawning_y)
	restaurant_customer.customer_kind = randi_range(1, customer_kind_count)
	restaurant_customer.player_root = player_root
	restaurant_customer.customer_manager = self
	
	restaurant_customer.requested_food = requested_food
	active_customers[customer_x] = restaurant_customer
	
	create_tween().tween_property(restaurant_customer, "modulate:a", 1, customer_show_tween_duration)
	add_child(restaurant_customer)

const custom_food_scale = 0.65
const customer_food_y_spawn_pos = 72

func handle_food_throwing():
	if not Input.is_action_just_pressed("throw_food"): return
	var player_x = player_root.position.x
	var dist_from_origin = player_x - chair_x_origin
	var customer_index = int(dist_from_origin / customer_range)
	
	if not customer_index in active_customers: return
	var customer_food = UID.customer_food_scene.instantiate()
	var customer_at_index = active_customers[customer_index]
	if not customer_at_index.order_completed or customer_at_index.food_delivered: return
	
	var food_type = customer_at_index.requested_food
	var held_foods = GridState.active_game.player_held_foods
	if not food_type in held_foods: return
	held_foods[food_type] -= 1
	var held_food_count = held_foods[food_type]
	if held_food_count == 0: held_foods.erase(food_type)
	
	customer_food.food_type = food_type
	customer_food.scale = Vector2.ONE * custom_food_scale
	customer_food.position = Vector2(get_x_by_index(customer_index), customer_food_y_spawn_pos)
	customer_at_index.order_delivered()
	customer_food.deliver_food()
	player_root.add_score_by_gain_type(RestaurantPlayer.ScoreGain.FoodDelivery, customer_at_index.time_since_order)
	add_child(customer_food)
	active_customers.erase(customer_index)

const customer_requesting_next_milestone_min_progress = 0.8
var can_spawn_score_customer = true

func on_score_increased():
	await get_tree().process_frame
	var closest_requirement = points_bar.get_closest_unlocked_food_requirement()
	var next_requirement = points_bar.get_next_food_milestone_requirement()
	var milestone_requirement_diff = next_requirement - closest_requirement
	var score_to_next_milestone = next_requirement - points_bar.points_count
	var progress_to_next_milestone = 1 - score_to_next_milestone / milestone_requirement_diff
	if progress_to_next_milestone < customer_requesting_next_milestone_min_progress:
		can_spawn_score_customer = true
		return
	if not can_spawn_score_customer: return
	
	var requested_food = points_bar.get_food_from_requirement(next_requirement)
	can_spawn_score_customer = false
	spawn_customer(requested_food)
