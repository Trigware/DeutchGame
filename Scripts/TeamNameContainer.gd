class_name TeamNameContainer
extends Control

const lowest_x_size = 63
const glyph_size = 13

@onready var name_label = $Name
@onready var texture = $Texture
@onready var shadow = $Texture/Shadow

var container_team: SpecialTile.TeamRelation

const default_height = 34
const name_label_x_offset = 8
const blue_container_offset = 64

func set_team_name(team: SpecialTile.TeamRelation):
	var team_as_str = GameState.active_game.team_names[team]
	name_label.text = team_as_str
	var char_count = team_as_str.length()
	var label_size = lowest_x_size + glyph_size * char_count
	texture.modulate = GridState.team_modulate[team]
	texture.size.x = label_size
	shadow.size.x = label_size
	container_team = team

func update_container(slot_x: Dictionary[SpecialTile.TeamRelation, float], slot_scale: Vector2, unoccupied_height: float, combined_slot_height: float):
	position.x = slot_x[container_team]
	scale = slot_scale / 2
	var current_height = default_height * scale.y
	var unused_height = unoccupied_height - current_height
	position.y = unused_height * 2
	
	if container_team == SpecialTile.TeamRelation.Red: return
	position.x += scale.x * blue_container_offset
	texture.scale.x = -1
	name_label.position.x = -name_label.size.x - name_label_x_offset
	name_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	position.y += combined_slot_height - current_height / 2
