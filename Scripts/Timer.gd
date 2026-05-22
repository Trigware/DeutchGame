extends CanvasLayer

@onready var progress_bar = $"Progress Bar"
@onready var points_gathered = $PointsGathered

const progress_x_bar = 500
const icon_offset = 45
var timer_y_offset: float
const timer_y_size = 40
const final_y_size_multiplier = 1.5
const maximum_points_count = 1000
var points_count: float = 0
const bar_padding = 0.5

func _ready():
	var final_timer_offset = timer_y_size * final_y_size_multiplier
	create_tween().tween_property(self, "timer_y_offset", final_timer_offset, 1).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	progress_bar.size.x = progress_x_bar

func _process(delta: float):
	var window_size = DisplayServer.window_get_size()
	var total_bar_width = progress_x_bar + icon_offset
	var bar_scale = (window_size.x * (1 - bar_padding)) / total_bar_width
	scale = Vector2.ONE * bar_scale
	points_gathered.text = str(floori(points_count)) + " / " + str(maximum_points_count)
	
	offset.x = window_size.x / 2 - progress_x_bar / 2 * bar_scale + icon_offset / 2 * bar_scale
	offset.y = window_size.y - timer_y_offset * bar_scale
	progress_bar.value = points_count / maximum_points_count
