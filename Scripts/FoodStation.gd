@tool
extends Node2D

@export var station_x := 0
@export var x_offset := 0.0
@export var unlocked_left := false
@export var unlocked_right := false

@onready var walkable_area = $"Walkable Area"
@onready var left_connector = $"Static Body/Left Connector"
@onready var right_connector = $"Static Body/Right Connector"
@onready var enterance_collider = $"Static Body/Enterance"

const station_size = 24*7
const middle_tile = Vector2i(-1, 0)
const left_side_tile = Vector2i(-4, 0)
const right_side_tile = Vector2i(2, 0)

enum TileType {
	FreeX,
	XLeftLocked,
	XRightLocked,
	FreeXDown
}

const tile_atlas_coords: Dictionary[TileType, Vector2] = {
	TileType.FreeX: Vector2(0, 1),
	TileType.XLeftLocked: Vector2(2, 1),
	TileType.XRightLocked: Vector2(3, 1),
	TileType.FreeXDown: Vector2(2, 0)
}

func set_tile(tile_type: TileType, coord: Vector2i):
	walkable_area.set_cell(coord, 0, tile_atlas_coords[tile_type])

func _process(_delta):
	position.x = (station_x + x_offset) * station_size
	var middle_tile_type = TileType.FreeXDown if station_x == 0 else TileType.FreeX
	set_tile(middle_tile_type, middle_tile)
	var left_side_type = TileType.FreeX if unlocked_left else TileType.XLeftLocked
	var right_side_type = TileType.FreeX if unlocked_right else TileType.XRightLocked
	set_tile(left_side_type, left_side_tile)
	set_tile(right_side_type, right_side_tile)
	enterance_collider.disabled = station_x == 0 and x_offset == 0
	left_connector.disabled = unlocked_left
	right_connector.disabled = unlocked_right
