extends CanvasLayer

@onready var overlay_color = $OverlayColor
var used_color = Color("1a1a1aff")
var alpha_value := 0.0

func _process(_delta):
	var overlay_size = DisplayServer.window_get_size()
	overlay_color.size = overlay_size
	overlay_color.color = used_color
	overlay_color.color.a = alpha_value

const default_visibility_diff = 0.65
const default_inbetween_duration = 0.35
const show_alpha := 0.0; const hide_alpha := 1.0

func switch_scene(next_scene: PackedScene, visibility_change_duration = default_visibility_diff, in_between_wait_duration = default_inbetween_duration, scene_modifier = null):
	await tween_alpha(hide_alpha, visibility_change_duration)
	var switched_scene = next_scene.instantiate()
	await get_tree().create_timer(in_between_wait_duration).timeout
	if scene_modifier is Callable:
		scene_modifier.call(switched_scene)
	get_tree().change_scene_to_node(switched_scene)
	await tween_alpha(show_alpha, visibility_change_duration)

func tween_alpha(final_alpha, duration: float = default_visibility_diff):
	await create_tween().tween_property(self, "alpha_value", final_alpha, duration).set_ease(Tween.EASE_IN_OUT).finished
