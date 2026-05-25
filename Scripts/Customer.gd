extends Node2D
class_name Customer

var player_root: RestaurantPlayer

@onready var sprite = $Sprite
@onready var message_label = $Message/MessageText
@onready var message_box = $Message/MessageBox
@onready var message = $Message
@onready var request = $Request
@onready var request_sprite = $Request/Sprite
@onready var throw_hint = $ThrowHint

const customer_speed = 40
const customer_slow_down_start = 130
const customer_slow_down_end = 105
const customer_sit_pos_y = 115
const customer_message_trigger = 160

var customer_kind: int
var is_sitting = false
var requested_food := Ingredient.FoodType.Unknown
var customer_manager: CustomerManager
var time_since_order: float

func _ready():
	message.hide()
	request.modulate.a = 0
	request_sprite.frame_coords = Vector2(requested_food as int, 0)
	update_sprite()

var greetings_message_trigged = false
var movement_direction := 1

func _process(delta: float):
	time_since_order += delta
	var speed_multiplier = clamp(inverse_lerp(customer_slow_down_end, customer_slow_down_start, position.y), 0, 1)
	if movement_direction == -1: speed_multiplier = 1
	if position.y < customer_sit_pos_y and not is_sitting and movement_direction == 1:
		is_sitting = true
		sprite.stop()
	if not is_sitting:
		var y_pos_change = delta * customer_speed * speed_multiplier * movement_direction
		position.y -= y_pos_change
	if position.y < customer_message_trigger and not greetings_message_trigged: handle_messages()
	handle_player_food_throw()

func update_sprite():
	sprite.play("move_up" if movement_direction == 1 else "move_down")

const message_box_padding = 18
const message_char_size = 4.4
const red_color_tag = "[color=red]"
const color_close_tag = "[/color]"

func display_message(full_text: String, shown_portion: float, color_annotation_index, color_annotation_length):
	var full_text_length = full_text.length()
	var substr_length = int(shown_portion * full_text_length)
	var lhs_length = min(substr_length, color_annotation_index)
	if color_annotation_index == -1: lhs_length = substr_length
	
	var used_text_lhs = full_text.substr(0, lhs_length)
	var bb_code_tag_length = 0
	if substr_length >= color_annotation_index and color_annotation_index != -1:
		bb_code_tag_length += red_color_tag.length()
		used_text_lhs += red_color_tag
	
	var rhs_length = clamp(substr_length - color_annotation_index, 0, color_annotation_length)
	var used_text_rhs = full_text.substr(color_annotation_index, rhs_length)
	if color_annotation_length != -1 and bb_code_tag_length > 0:
		bb_code_tag_length += color_close_tag.length()
		used_text_rhs += color_close_tag
	
	var after_highlight_start = color_annotation_index + color_annotation_length
	var after_highlight_length = max(substr_length - after_highlight_start, 0)
	var after_highlight = full_text.substr(after_highlight_start, after_highlight_length)
	var processed_text = used_text_lhs + used_text_rhs + after_highlight
	var final_text_length = processed_text.length() - bb_code_tag_length
	
	var box_size = message_box_padding * 2 + message_char_size * final_text_length
	message_box.size.x = box_size
	message_box.position.x = -box_size/2
	message_label.text = processed_text
	message_label.size.x = box_size
	message_label.position.x = -box_size/2

const char_speak_duration = 0.1

func animate_message(message_text: String, color_annotation_index = -1, color_annotation_length = -1):
	message.show()
	message.modulate.a = 1
	var message_length = message_text.length()
	var tween_duration = char_speak_duration * message_length
	await create_tween().tween_method(
		func(value_t: float):
			display_message(message_text, value_t, color_annotation_index, color_annotation_length),
		0.0, 1.0, tween_duration
	).set_ease(Tween.EASE_IN_OUT).finished

const greetings_messages = ["Hallo!", "Guten Tag!", "Guten Morgen!", "Schöner Tag!", "..."]
const order_messages = ["Ich bestelle {}!", "Ich möchte {}!", "{}, bitte.", "Ich würde nehmen {}.", "Ich wünsche {}!"]

func handle_messages():
	await handle_greetings()
	await handle_order()
	handle_request()

func handle_greetings():
	var chosen_greeting_index = randi_range(0, greetings_messages.size() - 1)
	var chosen_greeting_message = greetings_messages[chosen_greeting_index]
	greetings_message_trigged = true
	await animate_message(chosen_greeting_message)
	await get_tree().create_timer(order_message_delay).timeout

func handle_order():
	var chosen_order_index = randi_range(0, order_messages.size() - 1)
	var chosen_order_message: String = order_messages[chosen_order_index]
	var requested_food_as_str = Ingredient.get_food_as_german(requested_food)
	
	var bracket_index = chosen_order_message.find("{}")
	var order_message_lhs = chosen_order_message.substr(0, bracket_index)
	var order_message_rhs = chosen_order_message.substr(bracket_index + 2)
	var processed_order_message = order_message_lhs + requested_food_as_str + order_message_rhs 
	
	await animate_message(processed_order_message, bracket_index, requested_food_as_str.length())
	await get_tree().create_timer(order_message_time_until_hide).timeout
	await create_tween().tween_property(message, "modulate:a", 0, message_hide_tween_duration).finished
	message.hide()
	order_completed = true
	time_since_order = 0

const order_message_delay = 3
const order_message_time_until_hide = 3
const message_hide_tween_duration = 0.7
const request_show_tween_duration = 0.6
const final_request_y_offset = -6

var order_completed = false
var food_delivered = false
const max_dist_from_player = 60
const min_modulate_affecting_player_dist = 55

func handle_request():
	request.show()
	var final_request_y = request.position.y + final_request_y_offset
	create_tween().tween_property(request, "modulate:a", 1, request_show_tween_duration)
	create_tween().tween_property(request, "position:y", final_request_y, request_show_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

func handle_player_food_throw():
	var held_foods = GridState.active_game.player_held_foods
	var does_player_have_food = requested_food in held_foods
	
	var x_dist_to_player = abs(player_root.position.x - position.x)
	var hint_visibility_end = customer_manager.customer_range / 2
	
	var hint_alpha = 1 - clamp(x_dist_to_player / hint_visibility_end, 0, 1)
	if not does_player_have_food or not order_completed or food_delivered: hint_alpha = 0
	throw_hint.modulate.a = hint_alpha

const after_delivery_dialogue = 2
const customer_after_food_delivered_exit_duration = 1

const after_food_received_messages = ["Danke!", "Tschüss!", "Auf Wiedersehen!", "Vielen Dank!", "Danke schön!"]

func order_delivered():
	create_tween().tween_property(request, "modulate:a", 0, request_show_tween_duration)
	food_delivered = true
	await get_tree().create_timer(after_delivery_dialogue).timeout
	var food_receive_message_index = randi_range(0, after_food_received_messages.size() - 1)
	var food_receive_message = after_food_received_messages[food_receive_message_index]
	await animate_message(food_receive_message)
	await create_tween().tween_property(message, "modulate:a", 0, 0.75).set_delay(customer_after_food_delivered_exit_duration).finished
	is_sitting = false
	movement_direction = -1
	update_sprite()
