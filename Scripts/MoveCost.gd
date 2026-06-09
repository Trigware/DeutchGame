extends Label

@onready var identifier_label = $Identifier
var board_root: BoardRoot

const tile_size = 32

var move_data: Move

func setup(coord: Vector2i, move: Move, parent: Node):
	position = tile_size * coord
	size = Vector2(tile_size, tile_size)
	text = get_cost_text(move)
	parent.add_child(self)
	move_data = move
	handle_identifier_label.call_deferred()
	var display_move_cost = not board_root.is_playing_tutorial or GameState.active_game.current_dialog_index >= TutorialUI.TutorialDialogType.MoveCosts
	modulate.a = 1 if display_move_cost else 0

const display_move_identifiers = false

func handle_identifier_label():
	identifier_label.modulate.a = 0
	identifier_label.text = "(" + str(move_data.move_index + 1) + ")"

func _process(_delta):
	var identifier_seen = Input.is_action_pressed("move_identifier_show")
	identifier_label.modulate.a = 1 if identifier_seen else 0

func get_cost_text(move: Move):
	var duration = Move.move_cost_duration[move.move_cost]
	if move.trick_move: return "???"
	return str(duration) + "s"
