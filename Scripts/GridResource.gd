class_name GridState
extends Resource

enum PieceType {
	Unknown,
	Sword,
	Wizard,
	Horse
}

const piece_atlas_coords_x: Dictionary[PieceType, int] = {
	PieceType.Wizard: 7, PieceType.Sword: 8, PieceType.Horse: 9
}

@export var piece_locations: Dictionary[Vector2i, Piece]
@export var special_tiles: Dictionary[Vector2i, SpecialTile]

var player_turn := SpecialTile.TeamRelation.Red
var grave_tiles: Array[Vector2i] = []
var flag_origin: Dictionary[SpecialTile.TeamRelation, Vector2i]

static var active_game: GridState

func next_turn():
	player_turn = SpecialTile.TeamRelation.Blue if player_turn == SpecialTile.TeamRelation.Red\
	else SpecialTile.TeamRelation.Red
	update_effect_durations()

func update_effect_durations():
	for piece: Piece in piece_locations.values():
		for effect: Effect in piece.status_effects.values():
			effect.duration_node.progress_effect_timer()
