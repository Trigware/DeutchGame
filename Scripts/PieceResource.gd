class_name Piece
extends Resource

@export var kind := GridState.PieceType.Unknown
@export var team_relation: SpecialTile.TeamRelation
var respawn_pos: Vector2i
var status_effects: Array[Effect]

const red_piece = 1
const blue_piece = 2

func get_atlas() -> Vector2i:
	var y_coord = red_piece if team_relation == SpecialTile.TeamRelation.Red else blue_piece
	return Vector2(GridState.piece_atlas_coords_x[kind], y_coord)
