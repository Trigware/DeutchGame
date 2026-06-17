class_name ItemSlot
extends Node2D

var power_up_kind := GridState.PowerUpType.None
var item_slot_team := SpecialTile.TeamRelation.Other

@onready var main_sprite = $Main
@onready var item_sprite = $Item
@onready var count_label = $Count
@onready var points_label = $Points

var item_slot_size: Vector2
var deactivated: bool = false

func setup(parent: CanvasLayer, container: Array[Node2D], power_up: GridState.PowerUpType, team: SpecialTile.TeamRelation, last_power_up: GridState.PowerUpType):
	power_up_kind = power_up
	item_slot_team = team
	container.append(self)
	parent.add_child(self)
	item_slot_size = main_sprite.texture.get_size()
	item_sprite.frame_coords.x = power_up - 1
	number_of_slots = last_power_up

const slot_occupied_height_portion := 0.925
const item_slot_multiplier := 0.8
var number_of_slots: int
var unoccupied_height: float
var actual_slot_combined_height: float

func _process(_delta):
	modulate.a = 0 if deactivated else 1
	update_points_label()

const upper_points_pos_y = -37
const lower_points_pos_y = 27
const right_align_points_label_x = -112

func update_points_label():
	var belongs_to_blue_team = item_slot_team == SpecialTile.TeamRelation.Blue
	points_label.position.y = upper_points_pos_y if belongs_to_blue_team else lower_points_pos_y
	var points_visible_power_up_slot_type = GridState.PowerUpType.SpeedBoost if belongs_to_blue_team else GridState.PowerUpType.OpponentSlowness
	points_label.visible = power_up_kind == points_visible_power_up_slot_type
	
	var points_count = GameState.active_game.team_gathered_points.get(item_slot_team, 0)
	points_label.text = str(points_count)
	points_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT if belongs_to_blue_team else HorizontalAlignment.HORIZONTAL_ALIGNMENT_FILL
	points_label.position.x = right_align_points_label_x if belongs_to_blue_team else 0

func update_slot():
	var window_size = DisplayServer.window_get_size()
	var occupied_height = window_size.y * slot_occupied_height_portion
	var used_scale_component = occupied_height / item_slot_size.y / number_of_slots
	var used_scale = Vector2(used_scale_component, used_scale_component)
	
	var item_actual_size = item_slot_size * used_scale
	actual_slot_combined_height = item_actual_size.y * number_of_slots
	unoccupied_height = window_size.y - actual_slot_combined_height
	var unoffseted_y_pos = item_actual_size.y * (power_up_kind - 0.5)
	var used_y_pos = unoffseted_y_pos + unoccupied_height / 2
	var x_offset = item_actual_size.x / 8
	
	var belongs_slot_to_blue_team = item_slot_team == SpecialTile.TeamRelation.Blue
	if belongs_slot_to_blue_team: x_offset = window_size.x - item_actual_size.x
	position = Vector2(x_offset, used_y_pos)
	used_scale *= item_slot_multiplier
	scale = used_scale
	
	var item_count = get_item_count()
	count_label.text = "" if item_count >= GridState.int_max / 2 else str(item_count)
	return used_scale

func get_item_count() -> int:
	if not item_slot_team in GameState.active_game.player_power_ups: return 0
	var team_items: PlayerPowerUp = GameState.active_game.player_power_ups[item_slot_team]
	if not power_up_kind in team_items.power_ups: return 0
	var power_up = team_items.power_ups[power_up_kind]
	return power_up.amount

func is_mouse_inside_slot() -> bool:
	if deactivated: return false
	var mouse_pos = get_viewport().get_mouse_position()
	var slot_size = item_slot_size * scale
	var slot_rect = Rect2(position, slot_size)
	return slot_rect.has_point(mouse_pos)
