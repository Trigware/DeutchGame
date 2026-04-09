@tool
extends Control

@export_range(0, 1) var radius_portion: float:
	set(value): radius_portion = value; queue_redraw()
@export var wheel_color: Color:
	set(value): wheel_color = value; queue_redraw()
@export_range(0, 1) var inner_radius: float:
	set(value): inner_radius = value; queue_redraw()

func _draw():
	var used_diameter = min(size.x, size.y)
	var radius = used_diameter / 2.0 * radius_portion
	var center = size * 0.5
	draw_circle(center, radius, wheel_color)
