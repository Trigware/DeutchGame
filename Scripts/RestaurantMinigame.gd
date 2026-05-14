extends Node2D

@onready var player = $Player
@onready var countdown = $MinigameCountdown

func _ready():
	if GridState.active_game == null: GridState.active_game = UID.init_state
	GridState.active_game.player_held_items = []
	GridState.active_game.player_held_ingredients_nodes = []

func _process(_delta):
	player.movement_disabled = not countdown.minigame_started
