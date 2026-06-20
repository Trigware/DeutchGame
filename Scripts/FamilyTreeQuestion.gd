extends Node2D

var family_tree_center_point := Person.make_tree()

func _ready():
	create_family_tree_nodes()

func create_family_tree_nodes():
	var family_tree_dict = family_tree_center_point.create_tree_dict()
	for person_pos in family_tree_dict.keys():
		var person: Person = family_tree_dict[person_pos]
		var family_member = UID.family_member.instantiate()
		family_member.person_pos = person_pos
		family_member.family_member = person
		family_member.update_family_member.call_deferred()
		add_child(family_member)

func show_answers():
	pass
