@tool
extends Control

@onready var wheel = $Wheel

@export var is_item_texture := true:
	set(value):
		is_item_texture = value
		notify_property_list_changed()
		generate_item_nodes()
@export var item_texture: Texture2D:
	set(value): item_texture = value; generate_item_nodes()
@export var number_of_segments: int:
	set(value):
		number_of_segments = value
		set_uniform(UniformType.AmountOfSegments, value)
		set_segment_colors()
		wheel_rotation = wheel_rotation
		generate_item_nodes()
@export var wheel_rotation: float:
	set(value):
		wheel_rotation = value
		set_uniform(UniformType.WheelRotation, shift_rotation(value))
		update_items_pos()
@export var base_wheel_color := Color("d17171ff"):
	set(value): base_wheel_color = value; set_segment_colors()
@export_range(0, 1) var seperator_size: float:
	set(value): seperator_size = value; set_uniform(UniformType.SeperatorSize, value)
@export var seperator_tint := Color.WHITE
@export_range(0, 1) var inner_radius: float:
	set(value): inner_radius = value; set_uniform(UniformType.InnerRadius, value)
@export var inner_tint: Color
@export_range(0, 1) var minimal_seperator_length: float:
	set(value): minimal_seperator_length = value; set_uniform(UniformType.MinimalSeperatorLength, value)
@export_range(0, 1) var item_distance_portion: float:
	set(value): item_distance_portion = value; generate_item_nodes()
@export var item_scale: float:
	set(value): item_scale = value; generate_item_nodes()
@export var maximum_item_scale: float:
	set(value): maximum_item_scale = value; generate_item_nodes()
@export var invisible_index: int = -1:
	set(value): invisible_index = value; generate_item_nodes()

func _validate_property(property: Dictionary):
	if property.name == "item_texture" and not is_item_texture: property.usage = PROPERTY_USAGE_NO_EDITOR 

enum UniformType {
	AmountOfSegments,
	WheelRotation,
	SegmentColors,
	TextureSize,
	SeperatorSize,
	SeperatorTint,
	InnerRadius,
	InnerTint,
	MinimalSeperatorLength,
	RotationShift
}

func shift_rotation(current_rot: float):
	const atan2_normalizer = 0.25
	var center_shift = 0
	var segment_length = 1 / float(number_of_segments)
	if number_of_segments % 2 == 0: center_shift = segment_length / 2
	var original_top_color = (number_of_segments + 1) / 2
	var color_shift = segment_length * (original_top_color - 1)
	var shift = atan2_normalizer + center_shift + color_shift
	var result = current_rot + shift
	return result

func uniform_as_str(uniform: UniformType) -> String: return UniformType.keys()[uniform].to_snake_case()
func set_uniform(parameter: UniformType, value):
	if wheel == null and not Engine.is_editor_hint(): return
	wheel.material.set_shader_parameter(uniform_as_str(parameter), value)

const max_color_count = 8

var wheel_pos_portion := Vector2(0.5, 1)
func _ready():
	set_segment_colors()
	if Engine.is_editor_hint(): return

func _process(delta):
	if wheel == null: return
	uniform_updates()
	update_wheel_display_info()
	if Engine.is_editor_hint(): return
	if wheel_spinned: time_since_spinned += delta
	handle_mouse_event()

const wheel_size = Vector2(100, 109)
var wheel_size_multiplier = 0.675

func update_wheel_display_info():
	var window_size: Vector2 = DisplayServer.window_get_size()
	var used_scale = window_size / wheel_size
	var scale_component = min(used_scale.x, used_scale.y) * wheel_size_multiplier
	scale = Vector2(scale_component, scale_component)
	
	var wheel_offset: Vector2 = wheel_size / 2 * scale_component
	var wheel_portion: Vector2 = wheel_size * scale_component / window_size
	var used_portion: Vector2 = wheel_pos_portion - wheel_portion * (Vector2.ONE - wheel_pos_portion)
	var wheel_pos = wheel_offset + window_size * used_portion
	position = wheel_pos

func uniform_updates():
	var texture_size = wheel.texture.get_size()
	set_uniform(UniformType.TextureSize, texture_size)
	set_uniform(UniformType.SeperatorTint, seperator_tint)
	set_uniform(UniformType.InnerTint, inner_tint)

func set_segment_colors():
	var segment_colors : Array[Color] = []
	var number_count = min(number_of_segments, max_color_count)
	var segment_hue_shift = 1.0 / number_count
	for i in range(number_count):
		var current_color = base_wheel_color
		current_color.h += segment_hue_shift * i
		segment_colors.append(current_color)
	set_uniform(UniformType.SegmentColors, segment_colors)

const spin_radius = 15

func dist_from_center(compare: Vector2) -> float:
	return sqrt(compare.x ** 2 + compare.y ** 2)

const minimum_inner_tint = Color("ccd1e6")
const maximum_inner_tint = Color("deda90ff")
const maximum_tint_dist = 5
var time_since_spinned = 0
const highlight_disapate_duration = 0.4

func handle_mouse_event():
	var local_mouse_pos = get_local_mouse_position()
	var mouse_from_dist = dist_from_center(local_mouse_pos)
	var in_spin_radius = mouse_from_dist < spin_radius
	var used_distance = max(mouse_from_dist - maximum_tint_dist, 0)
	var spin_disapation = time_since_spinned / highlight_disapate_duration
	var dist_value = max(1 - used_distance / (spin_radius - maximum_tint_dist) - spin_disapation, 0)
	inner_tint = minimum_inner_tint.lerp(maximum_inner_tint, dist_value)
	var attempting_to_spin = Input.is_action_just_pressed("spin_wheel")
	if not in_spin_radius or not attempting_to_spin: return
	spin_wheel()

var wheel_spinned = false
const minimum_wheel_rotations = 5
const wheel_spin_duration = 5

signal wheel_spin_finished

func spin_wheel():
	if wheel_spinned: return
	wheel_spinned = true
	var chosen_rotation = randf_range(0, 1)
	var additional_wheel_rotations = minimum_wheel_rotations + chosen_rotation
	await create_tween().tween_property(self, "wheel_rotation", wheel_rotation + additional_wheel_rotations, wheel_spin_duration).\
		set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).finished
	wheel_spin_finished.emit()
	var land_index = determine_land_index()
	invisible_index = land_index

var items_node: Node2D = null

func generate_item_nodes():
	if items_node != null:
		items_node.queue_free()
		items_node = null
	items_node = Node2D.new()
	var tile_height = item_texture.get_height() if is_item_texture else 0
	var tile_size = Vector2.ONE * tile_height
	
	for i in range(number_of_segments):
		if i == invisible_index: continue
		if is_item_texture: make_item_sprite(i, tile_size)
		else: make_item_label(i)
	
	add_child(items_node)

func update_items_pos():
	if items_node == null: return
	for i in range(items_node.get_child_count()):
		var item_sprite = items_node.get_child(i)
		set_item_pos(item_sprite, i)

const wheel_radius = 50
const label_scale_multiplier = 3

func set_item_pos(item_node: Node, index: int):
	var center_shift = 1.0 / number_of_segments / 2.0
	var shifted_angle = shift_rotation(1.0 / number_of_segments * index) + wheel_rotation + center_shift
	var item_angle = shifted_angle * TAU
	
	var item_scale_component = 1.0 / number_of_segments * item_scale * item_distance_portion
	var used_scale = min(item_scale_component, maximum_item_scale)
	if item_node is Node2D: used_scale *= label_scale_multiplier
	item_node.scale = Vector2.ONE * used_scale
	var actual_item_half_size = 0 if item_node is Node2D else item_texture.get_height() * used_scale / 2
	
	var item_distance = item_distance_portion * (wheel_radius - actual_item_half_size)
	var result_pos = Vector2(cos(item_angle), sin(item_angle)) * item_distance
	item_node.position = result_pos

func determine_land_index() -> int:
	var used_rotation = wheel_rotation + 1.0 / number_of_segments / 2
	var spin_value = fmod(used_rotation, 1)
	var section_portion = 1.0 / number_of_segments
	var unflipped_index = floor(spin_value / section_portion)
	var result = 0 if unflipped_index == 0 else number_of_segments - unflipped_index
	return result

func make_item_sprite(index: int, tile_size: Vector2):
	var item_sprite := Sprite2D.new()
	var atlas_texture := AtlasTexture.new()
	var tile_index = Vector2(index, 0)
	atlas_texture.atlas = item_texture
	atlas_texture.region = Rect2(tile_index * tile_size, tile_size)
	
	item_sprite.texture = atlas_texture
	set_item_pos(item_sprite, index)
	item_sprite.z_index = 1
	items_node.add_child(item_sprite)

func make_item_label(index: int):
	var item_container := Node2D.new()
	var item_label := UID.wheel_item_label.instantiate()
	
	set_item_pos(item_container, index)
	item_label.text = str(index)
	item_label.z_index = 1
	
	item_container.add_child(item_label)
	items_node.add_child(item_container)
