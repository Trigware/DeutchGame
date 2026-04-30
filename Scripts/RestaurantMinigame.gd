extends Node2D

@onready var player = $Player
@onready var countdown = $MinigameCountdown

func _ready():
	if GridState.active_game == null: GridState.active_game = UID.init_state
	GridState.active_game.player_held_ingredient_count = 0
	GridState.active_game.transitional_held_item_count = 0

const transitional_progress_speed: float = 6

func _process(delta: float):
	player.movement_disabled = not countdown.minigame_started
	var transition_count_not_caught_up = GridState.active_game.transitional_held_item_count < GridState.active_game.player_held_ingredient_count
	if transition_count_not_caught_up:
		GridState.active_game.transitional_held_item_count += delta * transitional_progress_speed
