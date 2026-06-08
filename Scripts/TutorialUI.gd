class_name TutorialUI
extends CanvasLayer

enum TutorialDialogType {
	Unknown = -1,
	ConceptExplain,
	SwordMoveRules,
	BlockingRules,
	CapturingSwords,
	RevivingSwords,
	WizardRules,
	HorseRules,
	MoveCosts,
	PowerUpRules,
	GameObjective
}

const tutorial_dialog: Array[String] = [
	"Tato hra je kombinace šachu, CTF a jsou tu i otázky!",
	"Meč může jít šikmo o políčko, jinak až o 2 políčka!",
	"Zdi a figurky stejné barvy ti blokují tahy!",
	"Zkus sebrat meč jiné barvy!",
	"Pokus se oživit meč!",
	"Když přijdete o čaroděje, nemůžete už meče oživit!",
	"Poslední figurka je kůň, ten skáče do L!",
	"Zelené tahy mají otázku, fialové minihru! (vykřičníky omezují tah figurky)",
	"Musíte získat vlajku, a tak si pomozte power-upy!",
	"Hra končí když vlajku odnesete do své základny nebo když soupeř nemůže hrát!"
]

const disabled_tutorial_progress_dialog_indices := [TutorialDialogType.CapturingSwords, TutorialDialogType.RevivingSwords]

@onready var header_label = $Header
@onready var gradient = $Gradient
@onready var tutorial_button = $"Tutorial Button"
@export var tutorial_boards: Dictionary[TutorialDialogType, GridState]
@export var grid_tiles: GridTiles
@export var items_manager: ItemsManager

const base_window_height = 648
const base_header_font_size = 40

const start_dialog_index = TutorialDialogType.ConceptExplain

func _ready():
	if not grid_tiles.board.is_playing_tutorial: return
	GameState.active_game.current_dialog_index = start_dialog_index - 1
	progress_tutorial()
	tutorial_button.button_pressed.connect(progress_tutorial)
	grid_tiles.tutorial_move_played.connect(progress_tutorial)

const header_label_horizontal_padding_portion = 0.25

func _process(_delta):
	var window_size = Vector2(DisplayServer.window_get_size())
	var header_label_padding = window_size.x * header_label_horizontal_padding_portion / 2
	header_label.size.x = window_size.x - header_label_padding
	header_label.position.x = header_label_padding / 2
	
	var font_size_multiplier = window_size.y / base_window_height
	header_label.label_settings.font_size = base_header_font_size * font_size_multiplier
	gradient.size.y = window_size.x
	gradient.position.x = window_size.x

var can_progress_tutorial = true
const header_text_visibility_change_tween_duration = 0.4
const wait_between_visibility_tweens = 0.2
var progressed_before = false

func progress_tutorial():
	if not can_progress_tutorial: return
	GameState.active_game.current_dialog_index += 1
	can_progress_tutorial = false
	var tutorial_ended = GameState.active_game.current_dialog_index >= tutorial_dialog.size()
	var is_activating_item_slots = GameState.active_game.current_dialog_index == TutorialDialogType.PowerUpRules
	if is_activating_item_slots: items_manager.activate_item_slots()
	if tutorial_ended:
		on_tutorial_ended()
		return
	
	var current_dialog_index = GameState.active_game.current_dialog_index
	var is_loading_tutorial_board = current_dialog_index in tutorial_boards.keys()
	if is_loading_tutorial_board: load_board(current_dialog_index)
	
	if progressed_before:
		await create_tween().tween_property(header_label, "modulate:a", 0, header_text_visibility_change_tween_duration).finished
		await get_tree().create_timer(wait_between_visibility_tweens).timeout
	var tutorial_text = tutorial_dialog[current_dialog_index]
	header_label.text = tutorial_text
	progressed_before = true
	
	header_label.modulate.a = 0
	await create_tween().tween_property(header_label, "modulate:a", 1, header_text_visibility_change_tween_duration).finished
	can_progress_tutorial = true
	
func load_board(dialog_index):
	var tutorial_board = tutorial_boards[dialog_index]
	grid_tiles.load_state(tutorial_board, true)

func on_tutorial_ended():
	Overlay.switch_scene(UID.title_screen_scene)
