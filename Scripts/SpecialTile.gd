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
	TrickQuestion = 5
}

func get_atlas_x() -> int:
	match kind:
		TileType.Wall: match wall_surround:
			WallSurround.Left: return int(AtlasTile.WallLeft)
			WallSurround.Center: return int(AtlasTile.WallCenter)
			WallSurround.Right: return int(AtlasTile.WallRight)
		TileType.Flag:
			return int(AtlasTile.RedFlag) if relation == TeamRelation.Red else int(AtlasTile.BlueFlag)
		TileType.TrickQuestion: return int(AtlasTile.TrickQuestion)
	return -1

func get_atlas() -> Vector2i:
	return Vector2(get_atlas_x(), 1)
