extends Node2D

@onready var player = $Player
@onready var countdown = $MinigameCountdown
@onready var stations_root = $"Stations Root"

func _ready():
	if GameState.active_game == null: GameState.active_game = UID.init_state
	GameState.active_game.player_held_items = []
	GameState.active_game.player_held_ingredients_nodes = []
	GameState.active_game.unlocked_foods = []
	Audio.play_music(UID.restaurant_music)
	GameState.active_game.recipe_screens = {}
	GameState.active_game.foods_thrown = []
	GameState.active_game.custom_food_requests = {}
	GameState.active_game.food_stations = {}

var been_enabled = false

func _process(_delta):
	if been_enabled: return
	player.movement_disabled = not countdown.minigame_started
	if not player.movement_disabled: been_enabled = true
