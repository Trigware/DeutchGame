class_name Person
extends Resource

var mother: Person = null
var father: Person = null
var children: Array[Person] = []
var partner: Person

@export var name: String
@export var is_male: bool
var generation_level: int
var distance_from_origin: int

const possible_boys_names = [
	"Honza", "Vojta", "David", "Radek", "Kevin",
	"Jirka", "Dominik", "Martin", "Tomáš", "Šimon",
	"Sam", "Jarda", "Luboš", "Leo", "Artur"
]

const possible_girls_names = [
	"Kamila", "Viktorie", "Jana", "Aneta", "Kája",
	"Kateřina", "Týna", "Sára", "Ira", "Alena",
	"Monika", "Eliška", "Markéta", "Dominika", "Martina"
]

static var chosen_boys_names: Array[String]
static var chosen_girls_names: Array[String]

static func make_tree() -> Person:
	chosen_boys_names.clear()
	chosen_girls_names.clear()
	return ctor()

static func ctor(generation = 0, is_gender_male = null, dist_from_origin = 0, parents_generated = false) -> Person:
	var person := Person.new()
	person.setup_person(generation, is_gender_male, dist_from_origin)
	if generation >= maximum_generation_level or parents_generated: return person
	
	var parent_father = person.generate_parent(false)
	var parent_mother = person.generate_parent(true, parent_father)
	parent_father.partner = parent_mother
	
	return person

const maximum_generation_level = 2

func generate_parent(is_mother: bool, person_partner = null) -> Person:
	var parent = Person.ctor(generation_level + 1, not is_mother, distance_from_origin + 1)
	if is_mother: mother = parent
	else: father = parent
	
	parent.partner = person_partner
	parent.children.append(self)
	if is_mother: parent.add_children()
	return parent

func setup_person(generation, is_gender_male, dist_from_origin):
	is_male = randi_range(0, 1) == 0
	if is_gender_male != null: is_male = is_gender_male
	distance_from_origin = dist_from_origin
	
	var names_list = possible_boys_names if is_male else possible_girls_names
	var used_names_list = chosen_boys_names if is_male else chosen_girls_names
	
	while true:
		var name_index = randi_range(0, names_list.size() - 1)
		name = names_list[name_index]
		var was_used = name in used_names_list
		if was_used: continue
		break
	
	used_names_list.append(name)
	generation_level = generation

const children_max_count = 3
const maximum_distance_from_origin_parents = 3

func add_children():
	if generation_level == 0 or distance_from_origin >= maximum_distance_from_origin_parents: return
	var added_child_count = randi_range(0, children_max_count - 1)
	
	for i in range(added_child_count):
		var child = Person.ctor(generation_level - 1, null, distance_from_origin + 1, true)
		child.mother = self
		child.father = partner
		children.append(child)
		partner.children.append(child)

func create_tree_dict() -> Dictionary[Vector2i, Person]:
	var result_dict: Dictionary[Vector2i, Person] = {}
	explore_family_tree(result_dict, [], [])
	return result_dict

func get_updated_connection(family_connection, connection_type: FamilyConnection.ConnectionType, child_index = 0):
	var updated_collection = family_connection.duplicate()
	var connection_resource = FamilyConnection.ctor(connection_type, child_index)
	updated_collection.append(connection_resource)
	return updated_collection

func explore_family_tree(result_dict, inspected_people: Array[Person], family_connection: Array[FamilyConnection]):
	if self in inspected_people: return
	
	inspected_people.append(self)
	var father_connection = get_updated_connection(family_connection, FamilyConnection.ConnectionType.Father)
	var mother_connection = get_updated_connection(family_connection, FamilyConnection.ConnectionType.Mother)
	
	if father != null: father.explore_family_tree(result_dict, inspected_people, father_connection)
	if mother != null: mother.explore_family_tree(result_dict, inspected_people, mother_connection)
	
	var child_count = children.size()
	for i in range(child_count):
		var child = children[i]
		var child_connection = get_updated_connection(family_connection, FamilyConnection.ConnectionType.Child, i)
		child.explore_family_tree(result_dict, inspected_people, child_connection)
	
	var person_position = get_person_position(family_connection)
	result_dict[person_position] = self

var person_position := Vector2i.ZERO
var current_side = FamilyConnection.ConnectionType.Unknown
var connection: FamilyConnection
var previous_connection: FamilyConnection
var previous_side = FamilyConnection.ConnectionType.Unknown

func get_person_position(family_connection):
	person_position = Vector2i.ZERO
	current_side = FamilyConnection.ConnectionType.Unknown
	previous_connection = FamilyConnection.ctor(FamilyConnection.ConnectionType.Child, 0)
	var is_center_side = true
	
	for i in range(family_connection.size()):
		connection = family_connection[i]
		var is_parent = connection.is_parent()
		previous_side = current_side
		if is_center_side: current_side = connection.kind
		
		var pos_offset = Vector2i.ZERO
		pos_offset.y = 1 if is_parent else -1
		pos_offset.x += get_parent_offset()
		
		person_position += pos_offset
		var is_child = connection.kind == FamilyConnection.ConnectionType.Child
		is_center_side = is_child and person_position.y == 0
		if is_center_side: current_side = FamilyConnection.ConnectionType.Unknown
		
		if is_child: person_position.x = get_child_x()
		previous_connection = connection
	
	return person_position

func get_parent_offset():
	var does_side_match_connection = connection.kind == current_side
	if not connection.is_parent(): return 0
	
	var prev_child_index = previous_connection.child_index
	var parent_offset = 0
	match previous_side:
		FamilyConnection.ConnectionType.Unknown: parent_offset = -get_center_child_x(prev_child_index)
		FamilyConnection.ConnectionType.Father: parent_offset = prev_child_index
		FamilyConnection.ConnectionType.Mother: parent_offset = -prev_child_index
	
	if not does_side_match_connection: return parent_offset
	
	parent_offset += -1 if current_side == FamilyConnection.ConnectionType.Father else 1
	return parent_offset

func get_child_x():
	var child_offset = 0
	var is_prev_connect_same_as_side = previous_connection.kind == current_side
	if is_prev_connect_same_as_side: child_offset = 1 if current_side == FamilyConnection.ConnectionType.Father else -1
	
	match current_side:
		FamilyConnection.ConnectionType.Unknown: return get_center_child_x()
		FamilyConnection.ConnectionType.Father: return person_position.x - connection.child_index + child_offset
		FamilyConnection.ConnectionType.Mother: return person_position.x + connection.child_index + child_offset
	return person_position.x

func get_center_child_x(index = connection.child_index):
	var child_index = index
	var is_index_odd = child_index % 2 == 1
	if is_index_odd: return -ceili(child_index / 2.0)
	return child_index / 2.0
