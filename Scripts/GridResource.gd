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

enum PowerUpType {
	None,
	SpeedBoost,
	Shield,
	TrickyItem,
	WizardFreeze,
	OpponentSlowness
}

@export var piece_locations: Dictionary[Vector2i, Piece]
@export var special_tiles: Dictionary[Vector2i, SpecialTile]
@export var power_up_tiles: Dictionary[Vector2i, PowerUpType] = {}

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
			if effect.duration_node == null: continue
			effect.duration_node.progress_effect_timer()

func generate_power_up(tile_coord: Vector2i, tile_map: TileMapLayer):
	var last_power_up = PowerUpType.values()[PowerUpType.values().size()-1]-1
	var chosen_power_up = 0
	power_up_tiles[tile_coord] = chosen_power_up
	var atlas_coord = Vector2i(chosen_power_up, 0)
	print(atlas_coord)
	tile_map.set_cell(tile_coord, 1, atlas_coord)
