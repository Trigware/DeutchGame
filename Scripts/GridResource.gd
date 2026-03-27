class_name GridState
extends Resource

enum PieceType {
	Unknown,
	Sword,
	Wizard,
	Trickster
}

@export var piece_locations: Dictionary[Vector2i, Piece]
