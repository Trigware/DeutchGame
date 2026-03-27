class_name GridState
extends Resource

enum PieceType {
	Unknown,
	Sword,
	Wizard,
	Trickster
}

const piece_atlas_coords_x: Dictionary[PieceType, int] = {
	PieceType.Wizard: 6, PieceType.Sword: 7, PieceType.Trickster: 8
}

@export var piece_locations: Dictionary[Vector2i, Piece]
