extends Node

func get_piece_positions_dict():
	var game_state: GridState = GameState.active_game
	var piece_positions: Dictionary
	
	for piece_pos in game_state.piece_locations:
		var piece = game_state.piece_locations[piece_pos]
		var effects_dict = {}
		for effect_type: Effect.StatusEffect in piece.status_effects.keys():
			var effect: Effect = piece.status_effects[effect_type]
			effects_dict[effect_type] = effect.remaining_duration
		
		var piece_dict = {
			"color": piece.team_relation,
			"kind": piece.kind,
			"effects": effects_dict
		}
		piece_positions[piece_pos] = piece_dict
	
	return piece_positions

func get_power_up_dict():
	var game_state: GridState = GameState.active_game
	var power_ups = {}
	
	for team_color in game_state.player_power_ups:
		var power_up_dict = game_state.player_power_ups[team_color].power_ups
		var team_power_ups_dict = {}
		for power_up_type in power_up_dict.keys():
			var power_up = power_up_dict[power_up_type]
			team_power_ups_dict[power_up_type] = power_up.amount
		power_ups[team_color] = team_power_ups_dict 
	return power_ups

const save_path = "user://previous_game.json"

func save_game():
	var game_state: GridState = GameState.active_game
	var piece_positions = get_piece_positions_dict()
	var power_ups = get_power_up_dict()
	var team_dict = get_team_dict()
	var respawn_info = get_power_up_respawn_info()
	var tricky_question_tiles = get_tricky_question_tiles()
	var power_up_positions_dict = GameState.active_game.power_up_tiles
	
	var save_file = {
		"piece_positions": piece_positions,
		"power_ups": power_ups,
		"player_turn": game_state.player_turn,
		"team_info": team_dict,
		"power_up_respawn_info": respawn_info,
		"power_up_tiles": power_up_positions_dict,
		"tricky_question_tiles": tricky_question_tiles,
		"team_points": GameState.active_game.team_gathered_points
	}
	
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	var json_contents := JSON.stringify(save_file, '\t')
	file.store_string(json_contents)
	file.close()

func load_game(path):
	var save_dict = load_dictionary(path)
	if save_dict.size() == 0: return
	load_piece_positions(save_dict)
	load_power_ups(save_dict)
	GameState.active_game.player_turn = save_dict["player_turn"]
	
	load_gathered_team_points(save_dict)
	load_team_info(save_dict)
	load_power_up_tiles(save_dict)
	load_power_up_respawn_info(save_dict)
	load_trick_question_tiles(save_dict)

func load_autosave():
	load_game(save_path)

func load_piece_positions(save_dict):
	var piece_loc_dict = GameState.active_game.piece_locations
	piece_loc_dict.clear()
	var piece_positions = save_dict["piece_positions"]
	
	for piece_pos_str: String in piece_positions.keys():
		var piece_data = piece_positions[piece_pos_str]
		var piece_pos = parse_vector(piece_pos_str)
		
		var piece_color: SpecialTile.TeamRelation = piece_data["color"]
		var piece_type = piece_data["kind"]
		var piece_effects = piece_data["effects"]
		var piece_value = Piece.ctor(piece_type, piece_color)
		
		for effect_str in piece_effects.keys():
			var effect_type = int(effect_str)
			var effect_value = Effect.ctor(effect_type, piece_value)
			piece_value.status_effects[effect_type] = effect_value
		piece_loc_dict[piece_pos] = piece_value

func load_dictionary(path):
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var file_contents = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var json_parse_error = json.parse(file_contents)
	if json_parse_error != OK: return {}
	var result = JSON.parse_string(file_contents)
	return result

func load_power_ups(save_dict):
	var power_up_dict = GameState.active_game.player_power_ups
	var power_up_json = save_dict["power_ups"]
	
	for team_color_str: String in power_up_json.keys():
		var team_color = int(team_color_str)
		var team_power_ups = power_up_json[team_color_str]
		var team_power_up_val = PlayerPowerUp.new()
		for power_up_str: String in team_power_ups.keys():
			var power_up_type = int(power_up_str)
			var power_up_amount = team_power_ups[power_up_str]
			var power_up_value = PowerUp.ctor(power_up_type, power_up_amount)
			team_power_up_val.power_ups[power_up_type] = power_up_value
		power_up_dict[team_color] = team_power_up_val

func get_team_dict():
	var team_dict = {}
	var team_name_dict = GameState.active_game.team_names
	for team_color: SpecialTile.TeamRelation in team_name_dict.keys():
		var team_name = team_name_dict[team_color]
		var member_count_dict = GameState.active_game.team_member_count
		var team_member_count = 1
		if team_color in member_count_dict:
			team_member_count = member_count_dict[team_color]
		
		team_dict[team_color] = {
			"name": team_name,
			"member_count": team_member_count
		}
	
	return team_dict

func load_team_info(save_dict):
	var team_info_json = save_dict["team_info"]
	for team_color_str in team_info_json.keys():
		var team_color = int(team_color_str)
		var specific_team_json = team_info_json[team_color_str]
		var member_count = specific_team_json["member_count"]
		var team_name = specific_team_json["name"]
		GameState.active_game.team_member_count[team_color] = member_count
		GameState.active_game.team_names[team_color] = team_name

func load_power_up_tiles(save_dict):
	var power_up_tiles_json = save_dict["power_up_tiles"]
	var power_up_tiles_dict = GameState.active_game.power_up_tiles
	power_up_tiles_dict.clear()
	
	for power_up_str_coord in power_up_tiles_json:
		var power_up_coord = parse_vector(power_up_str_coord)
		var power_up_type = power_up_tiles_json[power_up_str_coord]
		power_up_tiles_dict[power_up_coord] = power_up_type

func parse_vector(str_vec):
	var vector_arr = str_vec.replace(' ', "").replace('(', "").replace(')', "").split(',')
	return Vector2i(vector_arr[0].to_int(), vector_arr[1].to_int())

func get_power_up_respawn_info():
	var result_dict = {}
	
	var power_up_gatherers = GameState.active_game.power_up_piece_info
	var holders_info = {}
	for power_up_gathered_pos in power_up_gatherers.keys():
		var holder_info: PowerUpHolder = power_up_gatherers[power_up_gathered_pos]
		var holder_dict = {
			"piece_pos": holder_info.piece_pos,
			"moves_since_gather": holder_info.moves_since_gather
		}
		holders_info[power_up_gathered_pos] = holder_dict
		
	result_dict["holders"] = holders_info
	result_dict["regen_times"] = GameState.active_game.power_up_regeneration_wait_times
	result_dict["waiting_for_pieces"] = GameState.active_game.power_ups_waiting_for_no_piece
	
	return result_dict

func load_power_up_respawn_info(save_dict):
	var respawn_info = save_dict["power_up_respawn_info"]
	var holder_info_json = respawn_info["holders"]
	var holder_info_dict = GameState.active_game.power_up_piece_info
	holder_info_dict.clear()
	
	for taken_power_up_pos_str in holder_info_json.keys():
		var taken_power_up_pos = parse_vector(taken_power_up_pos_str)
		var taken_power_up_json = holder_info_json[taken_power_up_pos_str]
		var current_piece_pos = parse_vector(taken_power_up_json["piece_pos"])
		var power_up_holder = PowerUpHolder.ctor(current_piece_pos, taken_power_up_json["moves_since_gather"])
		holder_info_dict[taken_power_up_pos] = power_up_holder
	
	var regen_times_json = respawn_info["regen_times"]
	var regen_times_dict = GameState.active_game.power_up_regeneration_wait_times
	regen_times_dict.clear()
	
	for regen_power_up_pos_str in regen_times_json.keys():
		var regen_power_up_pos = parse_vector(regen_power_up_pos_str)
		var time_to_regen = regen_times_json[regen_power_up_pos_str]
		regen_times_dict[regen_power_up_pos] = time_to_regen
	
	var piece_move_to_gen_json = respawn_info["waiting_for_pieces"]
	var piece_move_to_gen_arr = GameState.active_game.power_ups_waiting_for_no_piece
	piece_move_to_gen_arr.clear()
	
	for wanted_to_move_piece_pos_str in piece_move_to_gen_json:
		var wanted_to_move_piece_pos = parse_vector(wanted_to_move_piece_pos_str)
		piece_move_to_gen_arr.append(wanted_to_move_piece_pos)

func get_tricky_question_tiles():
	var result = {}
	var special_tiles = GameState.active_game.special_tiles
	for special_tile_pos in special_tiles.keys():
		var current_special_tile: SpecialTile = special_tiles[special_tile_pos]
		var is_trick = current_special_tile.kind == SpecialTile.TileType.TrickQuestion
		var is_from_power_up = is_trick and current_special_tile.relation != SpecialTile.TeamRelation.Other
		if not is_from_power_up: continue
		result[special_tile_pos] = current_special_tile.relation
	return result

func load_trick_question_tiles(save_dict):
	var special_tiles_dict = GameState.active_game.special_tiles
	var trick_question_json = save_dict["tricky_question_tiles"]
	for tricky_question_pos_str in trick_question_json.keys():
		var tricky_question_pos = parse_vector(tricky_question_pos_str)
		var tricky_question_color = trick_question_json[tricky_question_pos_str]
		special_tiles_dict[tricky_question_pos] = SpecialTile.ctor(SpecialTile.TileType.TrickQuestion, tricky_question_color)

func load_gathered_team_points(save_dict):
	var team_points_json = save_dict["team_points"]
	var team_points_dict = GameState.active_game.team_gathered_points
	for team_color in team_points_json.keys():
		var team_points = int(team_points_json[team_color])
		team_points_dict[int(team_color)] = team_points
	print(team_points_dict)
