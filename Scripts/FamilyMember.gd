extends Node2D

var family_member: Person

@onready var person_sprite = $Person
@onready var name_label = $NameLabel
var person_pos: Vector2

const family_member_size = Vector2(48, 52)

func _process(_delta):
	var window_size = DisplayServer.window_get_size()
	position = window_size / 2
	var used_person_pos = Vector2(person_pos.x, -person_pos.y)
	
	scale = Vector2.ONE * 2
	var person_offset = family_member_size * used_person_pos * scale
	position += person_offset

func update_family_member():
	if family_member == null: return
	name_label.text = family_member.name
	person_sprite.frame_coords.x = int(not family_member.is_male)
