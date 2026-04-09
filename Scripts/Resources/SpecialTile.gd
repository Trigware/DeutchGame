@tool
class_name SpecialTile
extends Resource

enum TileType {
	Unknown,
	Wall,
	Flag,
	TrickQuestion,
	PowerUp
}

enum TeamRelation {
	Red,
	Blue,
	Other
}

enum WallSurround {
	Left,
	Center,
	Right
}

@export var kind := TileType.Unknown:
	set(value):
		kind = value
		notify_property_list_changed()
@export var relation := TeamRelation.Other
@export var wall_surround := WallSurround.Center

static func ctor(special_tile_type: TileType, team: TeamRelation):
	var instance := SpecialTile.new()
	instance.kind = special_tile_type
	instance.relation = team
	return instance

static func flag(team: SpecialTile.TeamRelation) -> SpecialTile: return ctor(TileType.Flag, team)
static func trick(team: SpecialTile.TeamRelation) -> SpecialTile: return ctor(TileType.TrickQuestion, team)

func is_flag():
	return kind == TileType.Flag

func _validate_property(property: Dictionary):
	match property.name:
		"relation": if kind != TileType.Flag: property.usage = PROPERTY_USAGE_NO_EDITOR
		"wall_surround": if kind != TileType.Wall: property.usage = PROPERTY_USAGE_NO_EDITOR

enum AtlasTile {
	WallLeft = 0,
	WallCenter = 1,
	WallRight = 2,
	RedFlag = 3,
	BlueFlag = 4,
	TrickQuestion = 5,
	RedTrick = 6,
	BlueTrick = 7
}

func get_atlas_x() -> int:
	match kind:
		TileType.Wall: match wall_surround:
			WallSurround.Left: return int(AtlasTile.WallLeft)
			WallSurround.Center: return int(AtlasTile.WallCenter)
			WallSurround.Right: return int(AtlasTile.WallRight)
		TileType.Flag:
			return int(AtlasTile.RedFlag) if relation == TeamRelation.Red else int(AtlasTile.BlueFlag)
		TileType.TrickQuestion: match relation:
			TeamRelation.Red: return int(AtlasTile.RedTrick)
			TeamRelation.Blue: return int(AtlasTile.BlueTrick)
			TeamRelation.Other: return int(AtlasTile.TrickQuestion)
	return -1

func get_atlas() -> Vector2i:
	var atlas_x = get_atlas_x()
	var atlas_y = 1 if kind == TileType.Wall else 0
	return Vector2(atlas_x, atlas_y)
