extends Node2D

@onready var player = $Player
@onready var countdown = $MinigameCountdown

func _ready():
	if GridState.active_game == null: GridState.active_game = UID.init_state
	GridState.active_game.player_held_items = []
	GridState.active_game.player_held_ingredients_nodes = []
	Audio.play_music(UID.restaurant_music)
	GridState.active_game.create_recipe_list()

var been_enabled = false

func _process(_delta):
	if been_enabled: return
	player.movement_disabled = not countdown.minigame_started
	if not player.movement_disabled: been_enabled = true
