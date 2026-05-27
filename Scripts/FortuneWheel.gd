@tool
class_name FortuneWheel
extends Control

@onready var wheel = $Wheel
@onready var footer = get_node(footer_path)
@onready var shadow = $Shadow
@onready var pointer = $Pointer
@onready var result_root = $"Result Root"
@onready var result_sprite: Sprite2D = $"Result Root/Result"
@onready var result_shadow: Sprite2D = $"Result Root/Result Shadow"

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

const footer_distance: float = 30
var footer_display_progress: float = 0
const footer_min_y_pos = 55.0
var wheel_show_modulate : float = 1

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

const footer_path = "Footer"

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

func update_footer():
	var max_y_pos = footer_min_y_pos + footer_distance
	var used_t = 1 - clamp(footer_display_progress, 0, 1)
	var pos_y = lerp(footer_min_y_pos, max_y_pos, used_t)
	footer.position.y = pos_y
	footer.modulate.a = footer_display_progress

func uniform_as_str(uniform: UniformType) -> String: return UniformType.keys()[uniform].to_snake_case()
func set_uniform(parameter: UniformType, value):
	if wheel == null and not Engine.is_editor_hint(): return
	wheel.material.set_shader_parameter(uniform_as_str(parameter), value)

const max_color_count = 8

var wheel_pos_portion := Vector2(0.5, 1)

func _ready():
	set_segment_colors()
	wheel.material = UID.fortune_wheel_shader.duplicate_deep()
	if Engine.is_editor_hint(): return

func _process(delta):
	if wheel == null: return
	uniform_updates()
	if Engine.is_editor_hint(): return
	if wheel_spinned: time_since_spinned += delta
	handle_mouse_event()
	update_wheel_display_info()
	update_footer()

const wheel_size = Vector2(100, 109)
var wheel_size_multiplier = 0.675

func update_wheel_display_info():
	var window_size: Vector2 = DisplayServer.window_get_size()
	var used_scale = window_size / wheel_size
	var scale_component = min(used_scale.x, used_scale.y) * wheel_size_multiplier
	scale = Vector2(scale_component, scale_component)
	
	var upper_left_corner: Vector2 = wheel_size / 2 * scale_component
	var bottom_right_corner = window_size - upper_left_corner
	var used_pos_x = lerp(upper_left_corner.x, bottom_right_corner.x, wheel_pos_portion.x)
	var used_pos_y = lerp(upper_left_corner.y, bottom_right_corner.y, wheel_pos_portion.y)
	position.x = used_pos_x
	position.y = used_pos_y
	
	wheel.modulate.a = wheel_show_modulate
	shadow.modulate.a = wheel_show_modulate
	pointer.modulate.a = wheel_show_modulate
	if items_node != null: items_node.modulate.a = wheel_show_modulate
	result_root.modulate.a = 1 - wheel_show_modulate

func tween_show_modulate(final: float):
	await create_tween().tween_property(self, "wheel_show_modulate", final, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).finished

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

func setup_result_image_sprites(land_index: int):
	result_root.show()
	if not is_item_texture: setup_piece_sprites()
	else: setup_minigame_sprites(land_index)

func setup_piece_sprites():
	var latest_move: Move = null
	if GameState.active_game != null: latest_move = GameState.active_game.latest_move
	var latest_moved_piece: Piece = Piece.ctor(GridState.PieceType.Wizard, SpecialTile.TeamRelation.Red)
	if latest_move != null: latest_moved_piece = latest_move.moved_piece
	var piece_atlas_pos = latest_moved_piece.get_atlas()
	result_sprite.frame_coords = piece_atlas_pos
	result_shadow.frame_coords = piece_atlas_pos

func setup_minigame_sprites(land_index: int):
	var texture_size = item_texture.get_size()
	var tile_count = texture_size.x / texture_size.y
	result_sprite.hframes = tile_count
	result_shadow.hframes = tile_count
	result_sprite.vframes = 1
	result_shadow.vframes = 1
	
	result_sprite.frame_coords.x = land_index
	result_shadow.frame_coords.x = land_index
	result_sprite.texture = item_texture
	result_shadow.texture = item_texture

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
const wheel_spin_duration = 4

signal wheel_spin_finished(item_node)

const footer_progress_tween_duration = 1

func spin_wheel():
	if wheel_spinned: return
	wheel_spinned = true
	var chosen_rotation = randf_range(0, 1)
	var additional_wheel_rotations = minimum_wheel_rotations + chosen_rotation
	await create_tween().tween_property(self, "wheel_rotation", wheel_rotation + additional_wheel_rotations, wheel_spin_duration).\
		set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).finished
	var land_index = determine_land_index()
	wheel_spin_finished.emit()
	create_tween().tween_property(self, "footer_display_progress", 1, footer_progress_tween_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	handle_footer_text(land_index + 1)
	setup_result_image_sprites(land_index)

func handle_footer_text(id_number):
	var footer_text = "Hráč " + str(id_number)
	if is_item_texture: footer_text = "Minihra " + str(id_number)
	footer.text = footer_text

var items_node: Node2D = null

func generate_item_nodes():
	if items_node != null:
		items_node.queue_free()
		items_node = null
	items_node = Node2D.new()
	
	for i in range(number_of_segments):
		items_node.add_child(make_item_node(i))
	
	add_child(items_node)

func make_item_node(index: int) -> Node:
	return make_item_sprite(index) if is_item_texture else make_item_label(index)

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

func make_item_sprite(index: int) -> Sprite2D:
	var tile_height = item_texture.get_height() if is_item_texture else 0
	var tile_size = Vector2.ONE * tile_height
	
	var item_sprite := Sprite2D.new()
	var atlas_texture := AtlasTexture.new()
	var tile_index = Vector2(index, 0)
	atlas_texture.atlas = item_texture
	atlas_texture.region = Rect2(tile_index * tile_size, tile_size)
	
	item_sprite.texture = atlas_texture
	set_item_pos(item_sprite, index)
	item_sprite.z_index = 1
	return item_sprite

func make_item_label(index: int) -> Node2D:
	var item_container := Node2D.new()
	var item_label := UID.wheel_item_label.instantiate()
	
	set_item_pos(item_container, index)
	item_label.text = str(index + 1)
	item_label.z_index = 1
	
	item_container.add_child(item_label)
	return item_container

const wheel_tween_duration = 0.75
const wheel_tween_delay = 0.15

func tween_portion_init(init_portion: Vector2, final_portion: Vector2):
	wheel_pos_portion = init_portion
	modulate.a = 0
	create_tween().tween_property(self, "wheel_pos_portion", final_portion, wheel_tween_duration).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_delay(wheel_tween_delay)
	create_tween().tween_property(self, "modulate:a", 1, wheel_tween_duration).set_trans(Tween.TRANS_QUAD)

func tween_portion(final_portion: Vector2):
	tween_portion_init(wheel_pos_portion, final_portion)
