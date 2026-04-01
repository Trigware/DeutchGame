class_name GridState
extends Resource

enum PieceType {
	Unknown,
	Sword,
	Wizard,
	Horse
}

enum GameEndType {
	Ongoing,
	FlagCaptured,
	PiecelessOpponent
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

const team_modulate : Dictionary[SpecialTile.TeamRelation, Color] = {
	SpecialTile.TeamRelation.Red: Color(0xff8787ff),
	SpecialTile.TeamRelation.Blue: Color(0x7ab8ffff)
}

@export var piece_locations: Dictionary[Vector2i, Piece]
@export var special_tiles: Dictionary[Vector2i, SpecialTile]
@export var power_up_tiles: Dictionary[Vector2i, PowerUpType] = {}
@export var player_power_ups: Dictionary[SpecialTile.TeamRelation, PlayerPowerUp] = {}

var player_turn := SpecialTile.TeamRelation.Red
var grave_tiles: Array[Vector2i] = []
var flag_origin: Dictionary[SpecialTile.TeamRelation, Vector2i]
var game_end_type := GameEndType.Ongoing

const team_names : Dictionary[SpecialTile.TeamRelation, String] = {
	SpecialTile.TeamRelation.Red: "červení",
	SpecialTile.TeamRelation.Blue: "modří"
}

static var active_game: GridState

func invert_turn(): player_turn = get_inverted_turn()
func get_inverted_turn():
	return SpecialTile.TeamRelation.Blue if player_turn == SpecialTile.TeamRelation.Red\
		else SpecialTile.TeamRelation.Red

func next_turn():
	invert_turn()
	update_effect_durations()

func update_effect_durations():
	for piece: Piece in piece_locations.values():
		for effect: Effect in piece.status_effects.values():
			if effect.duration_node == null: continue
			effect.duration_node.progress_effect_timer()

func generate_power_up(tile_coord: Vector2i, tile_map: TileMapLayer):
	var last_power_up = PowerUpType.values()[PowerUpType.values().size()-1]-1
	var chosen_power_up = randi_range(0, last_power_up) + 1
	power_up_tiles[tile_coord] = chosen_power_up
	var atlas_coord = Vector2i(chosen_power_up-1, 0)
	tile_map.set_cell(tile_coord, 1, atlas_coord)

func has_tile_power_up(tile_coord: Vector2i):
	return tile_coord in power_up_tiles

func receive_power_up(power_up_kind: PowerUpType):
	var actual_team = get_inverted_turn()
	var wanted_player_power_up_setup = actual_team in player_power_ups
	if not wanted_player_power_up_setup: player_power_ups[actual_team] = PlayerPowerUp.new()
	var playing_power_ups = player_power_ups[actual_team]
	var no_wanted_kind_power_up = not power_up_kind in player_power_ups
	if no_wanted_kind_power_up:
		playing_power_ups.power_ups[power_up_kind] = PowerUp.new()
	playing_power_ups.power_ups[power_up_kind].amount += 1
