extends Node2D

@onready var score_label = $"Score Text"

var added_score: int
const final_score_y_pos = -5
const visbility_tween_duration = 0.35
const hide_tween_delay_duration = 0.5

func _ready():
	score_label.text = "+" + str(added_score)
	modulate.a = 1
	create_tween().tween_property(self, "position:y", final_score_y_pos, visbility_tween_duration)
	await create_tween().tween_property(self, "modulate:a", 1, visbility_tween_duration).finished
	await create_tween().tween_property(self, "modulate:a", 0, visbility_tween_duration).set_delay(hide_tween_delay_duration).finished
	queue_free()
