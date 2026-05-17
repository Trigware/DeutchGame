extends Node

@onready var music_player = $"Music Player"

func play_music(music: AudioStream = null):
	if music != null: music_player.stream = music
	music_player.play()
	await music_player.finished
	play_music()
