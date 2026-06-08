class_name QuestionClock
extends Node2D

@onready var answer_label = $"Label Offset/Answer"
@onready var hour_hand = $HourHand
@onready var minute_hand = $MinuteHand

var clock_index: int
var spawner: ClockQuestion
const relative_pos = Vector2(0.5, 0.43)
const relative_size = 0.35
const clock_size = 60
const spacing_multiplier = 1.4
const init_y_answer_label = 25

const minutes_in_hour = 60
const hours_in_half_day = 12
const minutes_in_half_day = minutes_in_hour * hours_in_half_day
const generatable_time_interval = 5

func _ready():
	answer_label.modulate.a = 0
	answer_label.position.y = init_y_answer_label
	initialize_clock()

func _process(_delta):
	var window_size = Vector2(DisplayServer.window_get_size())
	var scale_multiplier = min(window_size.x, window_size.y) * relative_size / clock_size
	position = relative_pos * window_size
	var drawn_index = clock_index - ClockQuestion.spawned_clock_count / 2.0 + 0.5
	position.x += clock_size * scale_multiplier * spacing_multiplier * drawn_index
	scale = Vector2.ONE * scale_multiplier

const label_visibility_tween_duration = 0.6

func show_answer():
	create_tween().tween_property(answer_label, "position:y", 0, label_visibility_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(answer_label, "modulate:a", 1, label_visibility_tween_duration)

var chosen_hour: int
var local_minute: int

const clock_time_generation_limit = 1000

func initialize_clock():
	var exact_minute: int
	for i in range(clock_time_generation_limit):
		exact_minute = generate_time()
		chosen_hour = exact_minute / minutes_in_hour
		local_minute = exact_minute - chosen_hour * minutes_in_hour
		var cannot_be_used = chosen_hour in spawner.used_hours or local_minute in spawner.used_minutes
		if cannot_be_used: continue
		spawner.used_hours.append(chosen_hour)
		spawner.used_minutes.append(local_minute)
	
	var hour_hand_progress = float(exact_minute) / minutes_in_half_day
	var minute_hand_progress = float(local_minute) / minutes_in_hour
	hour_hand.rotation = TAU * hour_hand_progress
	minute_hand.rotation = TAU * minute_hand_progress
	answer_label.text = get_german_time()

func generate_time():
	var intervals_in_hour = minutes_in_hour / generatable_time_interval
	var intervals_count = intervals_in_hour * hours_in_half_day
	var interval_index = randi_range(0, intervals_count-1)
	var exact_minute = interval_index * generatable_time_interval
	return exact_minute

const german_numbers := ["null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn", "elf", "zwölf", "dreizehn", "vierzehn"]
const hour_segments := ["", "Viertel", "halb", "drei Viertel"]
const hour_segment_minute_anchor := [0, minutes_in_hour / 2, minutes_in_hour / 2, minutes_in_hour]

const hour_segment_minutes : float = 15

func get_german_time():
	var segment_index = local_minute / hour_segment_minutes
	var segment_index_int = floori(segment_index)
	var is_full_segment = segment_index == segment_index_int
	
	var minute_anchor = hour_segment_minute_anchor[segment_index_int]
	var minutes_from_anchor = local_minute - minute_anchor
	
	var segment_str = hour_segments[segment_index]
	if not is_full_segment:
		var hour_prefix = "vor" if minutes_from_anchor < 0 else "nach"
		var minutes_distance = abs(minutes_from_anchor)
		var german_min_dist = german_numbers[minutes_distance]
		segment_str = german_min_dist + " " + hour_prefix
	
	var chosen_hour_index = chosen_hour + 1
	var is_segment_after_current = not is_full_segment and local_minute < minutes_in_hour / 4
	if local_minute == 0 or is_segment_after_current:
		chosen_hour_index = chosen_hour
	var hour_as_str = german_numbers[chosen_hour_index]
	var is_anchor_half_hour = minute_anchor == minutes_in_hour / 2
	if is_anchor_half_hour and not is_full_segment: hour_as_str = "halb " + hour_as_str
	
	var time_as_str = segment_str + " " + hour_as_str
	if local_minute == 0: time_as_str = hour_as_str + " Uhr"
	return time_as_str
